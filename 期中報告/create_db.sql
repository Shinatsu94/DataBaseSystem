-- 建立使用者表格
CREATE TABLE users(
  user_id   CHAR(8) PRIMARY KEY,                         -- 用戶編號
  user_name VARCHAR(20),                                 -- 用戶名稱
  user_type VARCHAR(10) NOT NULL,                        -- 用戶類型
  
  -- 用戶類型格式約束
  CONSTANT chk_user_type CHECK (user_type IN ('student', 'teacher', 'admin'))
);

-- 建立課程預約表格
CREATE TABLE reserves(
  res_id     INTEGER PRIMARY KEY AUTOINCREMENT, -- 借用申請編號
  class_id   CHAR(7),                           -- 借用教室編號
  t_start    DATETIME,                          -- 借用時間開始
  t_end      DATETIME,                          -- 借用時間截止
  user_id    CHAR(8),                           -- 申請人的編號
  is_success TINYINT(1) DEFAULT NULL            -- 審核狀態: 1為通過 0為未通過 NULL為未審核
);
