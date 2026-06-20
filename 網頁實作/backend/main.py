# 教室租用系統 - 核心 API 完整版
import re
import csv
from io import StringIO
from datetime import date
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, EmailStr
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
from sqlalchemy.pool import NullPool

app = FastAPI(title="教室租用系統 - 核心 API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],  
    allow_headers=["*"],  
)

security = HTTPBasic()
SYSTEM_ADMIN_URL = "mysql+aiomysql://api_admin:1234567890@localhost:3306/classroom_rental"
admin_engine = create_async_engine(SYSTEM_ADMIN_URL, echo=False, poolclass=NullPool)
AdminSessionLocal = sessionmaker(admin_engine, class_=AsyncSession, expire_on_commit=False)

# ==================== 資料庫連線驗證 (強化除錯版) ====================
# ==================== 資料庫連線驗證 (強化除錯版) ====================
async def get_user_db_session(credentials: HTTPBasicCredentials = Depends(security)):
    db_url = f"mysql+aiomysql://{credentials.username}:{credentials.password}@localhost:3306/classroom_rental"
    engine = create_async_engine(db_url, echo=False, poolclass=NullPool)
    UserSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        async with UserSessionLocal() as session:
            # MariaDB 連線時會自動載入 Default Role，無需手動 SET ROLE DEFAULT
            yield session
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail=f"資料庫連線或角色啟用失敗：{str(e)}",
            headers={"WWW-Authenticate": "Basic"},
        )
    finally:
        await engine.dispose()

class RegisterPayload(BaseModel):
    user_id: str = Field(..., max_length=8)
    username: str = Field(..., max_length=60)
    email: EmailStr
    password: str = Field(..., min_length=4)
    role: str
    department: str | None = Field(None, max_length=80)
    def validate_payload(self):
        if self.role not in ['student', 'teacher', 'admin']: raise ValueError("角色設定錯誤")
        if not re.match(r'^([0-9]{8}|[A-Z][0-9]{5,7})$', self.user_id): raise ValueError("帳號格式不符合規範")

class BookingPayload(BaseModel):
    classroom_id: str
    booking_date: date
    start_section_id: int
    end_section_id: int
    reason: str

class LongTermPayload(BaseModel):
    classroom_id: str
    start_date: date
    end_date: date
    day_of_week: int
    start_section_id: int
    end_section_id: int
    reason: str

class ReviewPayload(BaseModel):
    booking_id: int
    action: str
    comment: str | None = Field(None)

class ClassroomStatusPayload(BaseModel):
    is_active: bool

class CSVImportPayload(BaseModel):
    csv_text: str

async def get_status_id(db: AsyncSession, status_code: str) -> int:
    res = await db.execute(text("SELECT status_id FROM vw_booking_statuses WHERE status_code = :code"), {"code": status_code})
    sid = res.scalar()
    if not sid: raise HTTPException(status_code=400, detail="無效的狀態碼")
    return sid

@app.post("/api/auth/register", status_code=status.HTTP_201_CREATED)
async def register_user(payload: RegisterPayload):
    try: payload.validate_payload()
    except ValueError as ve: raise HTTPException(status_code=400, detail=str(ve))
    async with AdminSessionLocal() as session:
        try:
            async with session.begin():
                await session.execute(text("INSERT INTO users (user_id, username, email, role, department) VALUES (:uid, :uname, :email, :role, :dept)"), 
                                      {"uid": payload.user_id, "uname": payload.username, "email": payload.email, "role": payload.role, "dept": payload.department})
                await session.execute(text(f"CREATE USER '{payload.user_id}'@'localhost' IDENTIFIED BY :pwd;"), {"pwd": payload.password})
                db_role = f"classroom_{payload.role}_role"
                await session.execute(text(f"GRANT {db_role} TO '{payload.user_id}'@'localhost';"))
                await session.execute(text(f"SET DEFAULT ROLE {db_role} FOR '{payload.user_id}'@'localhost';"))
            return {"message": "註冊並開戶成功！"}
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"註冊失敗：({str(e)})")

@app.get("/api/auth/login")
async def login(db: AsyncSession = Depends(get_user_db_session)):
    try:
        query = text("SELECT user_id, username, role FROM vw_users WHERE user_id = SUBSTRING_INDEX(USER(), '@', 1)")
        result = await db.execute(query)
        user = result.mappings().fetchone()
        if not user: raise HTTPException(status_code=404, detail="找不到您的資料")
        return {"message": "登入成功", "user": dict(user)}
    except Exception as e: 
        raise HTTPException(status_code=400, detail=f"資料庫查詢權限錯誤：{str(e)}")

@app.get("/api/classrooms")
async def get_classrooms(db: AsyncSession = Depends(get_user_db_session)):
    res = await db.execute(text("SELECT classroom_id, classroom_name, capacity, is_active FROM vw_classrooms"))
    return {"data": [dict(row) for row in res.mappings().fetchall()]}

@app.get("/api/sections")
async def get_sections(db: AsyncSession = Depends(get_user_db_session)):
    res = await db.execute(text("SELECT section_id, section_name, start_time, end_time FROM vw_sections ORDER BY section_id"))
    return {"data": [{"section_id": r["section_id"], "section_name": r["section_name"], "start_time": str(r["start_time"]), "end_time": str(r["end_time"])} for r in res.mappings().fetchall()]}

@app.post("/api/bookings")
async def create_booking(payload: BookingPayload, db: AsyncSession = Depends(get_user_db_session)):
    try:
        uid = (await db.execute(text("SELECT SUBSTRING_INDEX(USER(), '@', 1)"))).scalar()
        sid = await get_status_id(db, 'pending')
        await db.execute(text("INSERT INTO vw_bookings (applicant_id, classroom_id, booking_date, start_section_id, end_section_id, reason, status_id) VALUES (:uid, :cid, :date, :ss, :es, :rs, :sid)"),
                         {"uid": uid, "cid": payload.classroom_id, "date": payload.booking_date, "ss": payload.start_section_id, "es": payload.end_section_id, "rs": payload.reason, "sid": sid})
        await db.commit()
        return {"message": "單次預約申請已送出！"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=400, detail=str(e))

@app.patch("/api/bookings/{booking_id}/cancel")
async def cancel_booking(booking_id: int, db: AsyncSession = Depends(get_user_db_session)):
    try:
        sid = await get_status_id(db, 'canceled')
        await db.execute(text("UPDATE vw_bookings SET status_id = :sid WHERE booking_id = :bid"), {"sid": sid, "bid": booking_id})
        await db.commit()
        return {"message": "預約已成功取消。"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=400, detail=f"取消失敗：{str(e)}")

@app.get("/api/bookings")
async def get_my_bookings(db: AsyncSession = Depends(get_user_db_session)):
    res = await db.execute(text("SELECT b.booking_id, b.classroom_id, b.booking_date, b.start_section_id, b.end_section_id, b.reason, s.status_name, s.status_code FROM vw_bookings b JOIN vw_booking_statuses s ON b.status_id = s.status_id ORDER BY b.booking_date DESC"))
    return {"data": [{"booking_id": r["booking_id"], "classroom_id": r["classroom_id"], "booking_date": str(r["booking_date"]), "start_section_id": r["start_section_id"], "end_section_id": r["end_section_id"], "reason": r["reason"], "status_name": r["status_name"], "status_code": r["status_code"]} for r in res.mappings().fetchall()]}

@app.get("/api/classrooms/{classroom_id}/schedule")
async def get_classroom_schedule(classroom_id: str, query_date: date):
    async with AdminSessionLocal() as session:
        b_res = await session.execute(text("SELECT start_section_id, end_section_id FROM bookings b JOIN booking_statuses s ON b.status_id = s.status_id WHERE b.classroom_id = :cid AND b.booking_date = :qdate AND s.status_code = 'approved'"), {"cid": classroom_id, "qdate": query_date})
        c_res = await session.execute(text("SELECT start_section_id, end_section_id FROM course_times WHERE classroom_id = :cid AND day_of_week = WEEKDAY(:qdate) + 1"), {"cid": classroom_id, "qdate": query_date})
        occupied = []
        for r in b_res.mappings().fetchall(): occupied.append({"start": r["start_section_id"], "end": r["end_section_id"]})
        for r in c_res.mappings().fetchall(): occupied.append({"start": r["start_section_id"], "end": r["end_section_id"]})
        return {"data": occupied}

@app.get("/api/classrooms/{classroom_id}/weekly_schedule")
async def get_classroom_weekly_schedule(classroom_id: str, start_date: date, end_date: date):
    async with AdminSessionLocal() as session:
        b_query = text("SELECT booking_date, start_section_id, end_section_id FROM bookings b JOIN booking_statuses s ON b.status_id = s.status_id WHERE b.classroom_id = :cid AND b.booking_date BETWEEN :sd AND :ed AND s.status_code = 'approved'")
        b_res = await session.execute(b_query, {"cid": classroom_id, "sd": start_date, "ed": end_date})
        c_query = text("SELECT day_of_week, start_section_id, end_section_id FROM course_times WHERE classroom_id = :cid")
        c_res = await session.execute(c_query, {"cid": classroom_id})
        occupied = []
        for r in b_res.mappings().fetchall(): occupied.append({"type": "booking", "date": str(r["booking_date"]), "start": r["start_section_id"], "end": r["end_section_id"]})
        for r in c_res.mappings().fetchall(): occupied.append({"type": "course", "day_of_week": r["day_of_week"], "start": r["start_section_id"], "end": r["end_section_id"]})
        return {"data": occupied}

@app.get("/api/notifications")
async def get_my_notifications(db: AsyncSession = Depends(get_user_db_session)):
    res = await db.execute(text("SELECT notification_id, booking_id, message, is_read, created_at FROM vw_notifications ORDER BY created_at DESC"))
    return {"data": [{"id": r["notification_id"], "booking_id": r["booking_id"], "message": r["message"], "is_read": r["is_read"], "created_at": str(r["created_at"])} for r in res.mappings().fetchall()]}

@app.patch("/api/notifications/{n_id}/read")
async def mark_notification_read(n_id: int, db: AsyncSession = Depends(get_user_db_session)):
    try:
        await db.execute(text("UPDATE vw_notifications SET is_read = TRUE WHERE notification_id = :nid"), {"nid": n_id})
        await db.commit()
        return {"message": "已標示為已讀"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/api/teacher/long_term_bookings")
async def create_long_term_booking(payload: LongTermPayload, db: AsyncSession = Depends(get_user_db_session)):
    try:
        uid = (await db.execute(text("SELECT SUBSTRING_INDEX(USER(), '@', 1)"))).scalar()
        sid = await get_status_id(db, 'pending')
        await db.execute(text("INSERT INTO vw_long_term_bookings (applicant_id, classroom_id, start_date, end_date, day_of_week, start_section_id, end_section_id, reason, status_id) VALUES (:uid, :cid, :sd, :ed, :dow, :ss, :es, :rs, :sid)"),
                         {"uid": uid, "cid": payload.classroom_id, "sd": payload.start_date, "ed": payload.end_date, "dow": payload.day_of_week, "ss": payload.start_section_id, "es": payload.end_section_id, "rs": payload.reason, "sid": sid})
        await db.commit()
        return {"message": "週期性借用申請已送出！"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/api/teacher/courses")
async def get_my_courses(db: AsyncSession = Depends(get_user_db_session)):
    res = await db.execute(text("SELECT ci.course_id, ci.course_name, ct.classroom_id, ct.day_of_week, ct.start_section_id, ct.end_section_id FROM vw_course_info ci LEFT JOIN vw_course_times ct ON ci.course_id = ct.course_id"))
    return {"data": [dict(r) for r in res.mappings().fetchall()]}

@app.get("/api/teacher/long_term_bookings")
async def get_long_term_bookings(db: AsyncSession = Depends(get_user_db_session)):
    res = await db.execute(text("SELECT l.long_term_id, l.classroom_id, l.start_date, l.end_date, l.day_of_week, l.reason, s.status_name FROM vw_long_term_bookings l JOIN vw_booking_statuses s ON l.status_id = s.status_id ORDER BY l.created_at DESC"))
    return {"data": [{"id": r["long_term_id"], "classroom_id": r["classroom_id"], "sd": str(r["start_date"]), "ed": str(r["end_date"]), "dow": r["day_of_week"], "reason": r["reason"], "status_name": r["status_name"]} for r in res.mappings().fetchall()]}

@app.get("/api/admin/bookings/pending")
async def get_pending_bookings(db: AsyncSession = Depends(get_user_db_session)):
    query = text("SELECT b.booking_id, b.applicant_id, b.classroom_id, b.booking_date, b.start_section_id, b.end_section_id, b.reason FROM vw_bookings b JOIN vw_booking_statuses s ON b.status_id = s.status_id WHERE s.status_code = 'pending' ORDER BY b.booking_date ASC, b.start_section_id ASC")
    result = await db.execute(query)
    return {"data": [dict(r) for r in result.mappings().fetchall()]}

@app.post("/api/admin/reviews")
async def submit_booking_review(payload: ReviewPayload, db: AsyncSession = Depends(get_user_db_session)):
    """送出審核結果"""
    try:
        reviewer_id = (await db.execute(text("SELECT SUBSTRING_INDEX(USER(), '@', 1)"))).scalar()
        new_status_id = await get_status_id(db, payload.action)
        
        # 直接執行 INSERT 與 UPDATE，因為 Session 已經自動開啟 Transaction 了
        await db.execute(text("INSERT INTO booking_reviews (booking_id, reviewer_id, status_id, comment) VALUES (:b_id, :r_id, :s_id, :comment)"),
                         {"b_id": payload.booking_id, "r_id": reviewer_id, "s_id": new_status_id, "comment": payload.comment})
        await db.execute(text("UPDATE bookings SET status_id = :s_id WHERE booking_id = :b_id"), {"s_id": new_status_id, "b_id": payload.booking_id})
        
        await db.commit() # 手動提交
        return {"message": "審核完成！"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=400, detail=str(e))

@app.patch("/api/admin/classrooms/{classroom_id}/status")
async def update_classroom_status(classroom_id: str, payload: ClassroomStatusPayload, db: AsyncSession = Depends(get_user_db_session)):
    """修改教室啟用狀態"""
    try:
        # 同樣移除 async with db.begin()
        await db.execute(text("UPDATE classrooms SET is_active = :is_active WHERE classroom_id = :cid"),
                         {"is_active": payload.is_active, "cid": classroom_id})
        await db.commit()
        return {"message": f"已成功變更 {classroom_id} 借用狀態！"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/api/admin/bookings/history")
async def get_all_bookings_history(db: AsyncSession = Depends(get_user_db_session)):
    query = text("SELECT b.booking_id, b.applicant_id, b.classroom_id, b.booking_date, b.start_section_id, b.end_section_id, b.reason, s.status_name, b.created_at FROM vw_bookings b JOIN vw_booking_statuses s ON b.status_id = s.status_id ORDER BY b.created_at DESC")
    result = await db.execute(query)
    return {"data": [dict(r) for r in result.mappings().fetchall()]}

@app.post("/api/admin/courses/import")
async def import_courses_csv(payload: CSVImportPayload, db: AsyncSession = Depends(get_user_db_session)):
    reader = csv.DictReader(StringIO(payload.csv_text))
    async with db.begin():
        for row in reader:
            check = await db.execute(text("SELECT course_id FROM course_info WHERE course_id = :cid"), {"cid": row['course_id']})
            if not check.scalar():
                await db.execute(text("INSERT INTO course_info (course_id, academic_year, semester, course_name, teacher_id) VALUES (:cid, :ay, :sem, :cname, :tid)"), {"cid": row['course_id'], "ay": row['academic_year'], "sem": row['semester'], "cname": row['course_name'], "tid": row['teacher_id']})
            await db.execute(text("INSERT INTO course_times (course_id, classroom_id, day_of_week, start_section_id, end_section_id) VALUES (:cid, :cls, :dow, :start, :end)"), {"cid": row['course_id'], "cls": row['classroom_id'], "dow": row['day_of_week'], "start": row['start_section_id'], "end": row['end_section_id']})
    return {"message": "匯入成功"}
    
import uvicorn

if __name__ == "__main__":
    # 啟動伺服器，對應此檔案(main)裡的 FastAPI 實例(app)
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
