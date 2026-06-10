-- 教室租用系統：10 個資料表之 MariaDB View
-- 執行前提：schema.sql 已建立資料表；本檔可用於獨立重建 View。
-- 呼叫方式：
--   SELECT * FROM vw_users;
--   SHOW CREATE VIEW vw_users;

SET NAMES utf8mb4;

DROP VIEW IF EXISTS vw_notifications;
DROP VIEW IF EXISTS vw_booking_reviews;
DROP VIEW IF EXISTS vw_bookings;
DROP VIEW IF EXISTS vw_long_term_bookings;
DROP VIEW IF EXISTS vw_course_times;
DROP VIEW IF EXISTS vw_course_info;
DROP VIEW IF EXISTS vw_booking_statuses;
DROP VIEW IF EXISTS vw_sections;
DROP VIEW IF EXISTS vw_classrooms;
DROP VIEW IF EXISTS vw_users;

-- 僅顯示登入者本人；users.role = admin 的資料庫帳號可顯示全部。
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_users AS
SELECT
  user_id, username, email, role, department
FROM users
WHERE user_id = SUBSTRING_INDEX(USER(), '@', 1)
   OR (
     SELECT CAST(account.role AS CHAR)
     FROM users AS account
     WHERE account.user_id = SUBSTRING_INDEX(USER(), '@', 1)
   ) = 'admin';

-- 一般使用者僅顯示啟用教室；管理員可顯示全部。
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_classrooms AS
SELECT
  classroom_id, classroom_name, capacity, is_active
FROM classrooms
WHERE is_active = TRUE
   OR (
     SELECT CAST(account.role AS CHAR)
     FROM users AS account
     WHERE account.user_id = SUBSTRING_INDEX(USER(), '@', 1)
   ) = 'admin'
WITH CASCADED CHECK OPTION;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_sections AS
SELECT
  section_id, section_name, start_time, end_time
FROM sections;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_booking_statuses AS
SELECT
  status_id, status_code, status_name
FROM booking_statuses;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_course_info AS
SELECT
  course_id, academic_year, semester, course_name, teacher_id
FROM course_info;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_course_times AS
SELECT
  course_time_id, course_id, classroom_id, day_of_week,
  start_section_id, end_section_id
FROM course_times;

-- 教師僅能維護自己的長期借用；管理員可顯示全部。
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_long_term_bookings AS
SELECT
  long_term_id, applicant_id, classroom_id, start_date, end_date,
  day_of_week, start_section_id, end_section_id, reason, status_id, created_at
FROM long_term_bookings
WHERE applicant_id = SUBSTRING_INDEX(USER(), '@', 1)
   OR (
     SELECT CAST(account.role AS CHAR)
     FROM users AS account
     WHERE account.user_id = SUBSTRING_INDEX(USER(), '@', 1)
   ) = 'admin'
WITH CASCADED CHECK OPTION;

-- 學生與教師僅能維護自己的預約；管理員可顯示全部。
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_bookings AS
SELECT
  booking_id, applicant_id, classroom_id, long_term_id, course_time_id,
  booking_date, start_section_id, end_section_id, reason, status_id, created_at
FROM bookings
WHERE applicant_id = SUBSTRING_INDEX(USER(), '@', 1)
   OR (
     SELECT CAST(account.role AS CHAR)
     FROM users AS account
     WHERE account.user_id = SUBSTRING_INDEX(USER(), '@', 1)
   ) = 'admin'
WITH CASCADED CHECK OPTION;

-- 申請人可讀取自己的審核結果；管理員可讀取全部。
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_booking_reviews AS
SELECT
  review_id, booking_id, reviewer_id, status_id, comment, reviewed_at
FROM booking_reviews AS br
WHERE (
     SELECT CAST(account.role AS CHAR)
     FROM users AS account
     WHERE account.user_id = SUBSTRING_INDEX(USER(), '@', 1)
   ) = 'admin'
   OR br.reviewer_id = SUBSTRING_INDEX(USER(), '@', 1)
   OR EXISTS (
     SELECT 1
     FROM bookings AS b
     WHERE b.booking_id = br.booking_id
       AND b.applicant_id = SUBSTRING_INDEX(USER(), '@', 1)
   );

-- 一般使用者僅能顯示自己的通知；管理員可顯示全部。
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_notifications AS
SELECT
  notification_id, recipient_id, booking_id, message, is_read, created_at
FROM notifications
WHERE recipient_id = SUBSTRING_INDEX(USER(), '@', 1)
   OR (
     SELECT CAST(account.role AS CHAR)
     FROM users AS account
     WHERE account.user_id = SUBSTRING_INDEX(USER(), '@', 1)
   ) = 'admin'
WITH CASCADED CHECK OPTION;

-- View 呼叫與結構檢查範例：
-- SELECT * FROM vw_users;
-- SELECT * FROM vw_classrooms;
-- SELECT * FROM vw_sections ORDER BY section_id;
-- SELECT * FROM vw_booking_statuses ORDER BY status_id;
-- SELECT * FROM vw_course_info;
-- SELECT * FROM vw_course_times;
-- SELECT * FROM vw_long_term_bookings ORDER BY created_at DESC;
-- SELECT * FROM vw_bookings ORDER BY created_at DESC;
-- SELECT * FROM vw_booking_reviews ORDER BY reviewed_at DESC;
-- SELECT * FROM vw_notifications ORDER BY created_at DESC;
-- SHOW CREATE VIEW vw_bookings;
