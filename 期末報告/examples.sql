-- 教室租用系統：MariaDB 範例資料與查詢
-- 先執行 schema.sql，再執行本檔案。
--
-- 檔案內容：
-- 1. 建立預約狀態、使用者、教室、節次與固定課表。
-- 2. 建立待審核預約、審核歷程與核准通知。
-- 3. 查詢已核准借用與未讀通知。
-- 4. 提供可取消註解之衝突測試 SQL。

SET NAMES utf8mb4;

INSERT INTO booking_statuses(status_id, status_code, status_name) VALUES
  (1, 'pending',  '待審核'),
  (2, 'approved', '已核准'),
  (3, 'rejected', '已拒絕'),
  (4, 'canceled', '已取消');

INSERT INTO users(user_id, username, email, role, department) VALUES
  ('41243149', '廖章竹', 'member49@example.edu.tw', 'student', '資訊工程系'),
  ('T0000001', '王老師', 'teacher1@example.edu.tw', 'teacher', '資訊工程系'),
  ('A0000001', '系辦管理員', 'admin1@example.edu.tw', 'admin', '資訊工程系');

INSERT INTO classrooms(classroom_id, classroom_name, capacity, is_active) VALUES
  ('A101', '一般教室 A101', 50, 1),
  ('B205', '電腦教室 B205', 40, 1);

INSERT INTO sections(section_id, section_name, start_time, end_time) VALUES
  (1, '第 1 節', '08:10:00', '09:00:00'),
  (2, '第 2 節', '09:10:00', '10:00:00'),
  (3, '第 3 節', '10:10:00', '11:00:00'),
  (4, '第 4 節', '11:10:00', '12:00:00'),
  (5, '第 5 節', '13:20:00', '14:10:00'),
  (6, '第 6 節', '14:20:00', '15:10:00');

INSERT INTO course_info(course_id, academic_year, semester, course_name, teacher_id) VALUES
  ('CS-DB-001', 114, 2, '資料庫系統', 'T0000001');

INSERT INTO course_times(course_id, classroom_id, day_of_week, start_section_id, end_section_id) VALUES
  ('CS-DB-001', 'A101', 2, 2, 4);

-- 單次借用：學生申請專題會議，管理員核准。
INSERT INTO bookings(
  applicant_id, classroom_id, booking_date,
  start_section_id, end_section_id, reason, status_id
) VALUES (
  '41243149', 'B205', '2026-06-08',
  5, 6, '專題小組定期會議', 1
);

SET @booking_id = LAST_INSERT_ID();

INSERT INTO booking_reviews(booking_id, reviewer_id, status_id, comment)
VALUES (@booking_id, 'A0000001', 2, '時段可使用，核准借用。');

UPDATE bookings SET status_id = 2 WHERE booking_id = @booking_id;

INSERT INTO notifications(recipient_id, booking_id, message)
VALUES ('41243149', @booking_id, 'B205 教室借用申請已核准。');

-- 查詢指定日期各教室的已核准借用狀況。
SELECT
  b.booking_date,
  c.classroom_name,
  s1.section_name AS start_section,
  s2.section_name AS end_section,
  u.username AS applicant,
  b.reason
FROM bookings AS b
JOIN classrooms AS c ON c.classroom_id = b.classroom_id
JOIN users AS u ON u.user_id = b.applicant_id
JOIN sections AS s1 ON s1.section_id = b.start_section_id
JOIN sections AS s2 ON s2.section_id = b.end_section_id
JOIN booking_statuses AS bs ON bs.status_id = b.status_id
WHERE b.booking_date = '2026-06-08'
  AND bs.status_code = 'approved'
ORDER BY c.classroom_id, b.start_section_id;

-- 查詢使用者尚未讀取的通知。
SELECT
  n.notification_id,
  n.message,
  n.created_at
FROM notifications AS n
WHERE n.recipient_id = '41243149'
  AND n.is_read = 0
ORDER BY n.created_at DESC;

-- 衝突測試：取消註解後應失敗，因 B205 在 2026-06-08 第 6 節已被核准借用。
-- INSERT INTO bookings(
--   applicant_id, classroom_id, booking_date,
--   start_section_id, end_section_id, reason, status_id
-- ) VALUES (
--   'T0000001', 'B205', '2026-06-08',
--   6, 6, '衝突測試', 2
-- );

-- 固定課表衝突測試：取消註解後應失敗，因 A101 星期二第 2 至 4 節已有固定課表。
-- INSERT INTO bookings(
--   applicant_id, classroom_id, booking_date,
--   start_section_id, end_section_id, reason, status_id
-- ) VALUES (
--   '41243149', 'A101', '2026-06-09',
--   3, 3, '固定課表衝突測試', 2
-- );
