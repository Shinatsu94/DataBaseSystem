-- 教室租用系統：查詢、概念層映射與 View 使用範例
USE classroom_rental;
SET NAMES utf8mb4;
SET time_zone = '+08:00';

-- 1. 概念層「使用者提出預約」映射為 users 與 bookings 的關聯查詢。
SELECT
  b.booking_id,
  u.user_id,
  u.username,
  u.role,
  c.classroom_name,
  b.booking_date,
  s1.section_name AS start_section,
  s2.section_name AS end_section,
  bs.status_name
FROM bookings AS b
JOIN users AS u ON u.user_id = b.applicant_id
JOIN classrooms AS c ON c.classroom_id = b.classroom_id
JOIN sections AS s1 ON s1.section_id = b.start_section_id
JOIN sections AS s2 ON s2.section_id = b.end_section_id
JOIN booking_statuses AS bs ON bs.status_id = b.status_id
ORDER BY b.booking_date, b.start_section_id;

-- 2. 概念層「課程具有固定授課時段」映射為 course_info 與 course_times。
SELECT
  ci.course_id,
  ci.course_name,
  u.username AS teacher_name,
  ct.day_of_week,
  c.classroom_name,
  s1.section_name AS start_section,
  s2.section_name AS end_section
FROM course_info AS ci
JOIN users AS u ON u.user_id = ci.teacher_id
JOIN course_times AS ct ON ct.course_id = ci.course_id
JOIN classrooms AS c ON c.classroom_id = ct.classroom_id
JOIN sections AS s1 ON s1.section_id = ct.start_section_id
JOIN sections AS s2 ON s2.section_id = ct.end_section_id
ORDER BY ci.course_id, ct.day_of_week;

-- 3. 管理員查詢教室使用狀況。
SELECT
  c.classroom_id,
  c.classroom_name,
  b.booking_date,
  b.start_section_id,
  b.end_section_id,
  bs.status_code
FROM classrooms AS c
LEFT JOIN bookings AS b ON b.classroom_id = c.classroom_id
LEFT JOIN booking_statuses AS bs ON bs.status_id = b.status_id
ORDER BY c.classroom_id, b.booking_date;

-- 4. 十個 View 的基本呼叫方式。
SELECT * FROM vw_users;
SELECT * FROM vw_classrooms ORDER BY classroom_id;
SELECT * FROM vw_sections ORDER BY section_id;
SELECT * FROM vw_booking_statuses ORDER BY status_id;
SELECT * FROM vw_course_info ORDER BY course_id;
SELECT * FROM vw_course_times ORDER BY course_time_id;
SELECT * FROM vw_long_term_bookings ORDER BY created_at DESC;
SELECT * FROM vw_bookings ORDER BY created_at DESC;
SELECT * FROM vw_booking_reviews ORDER BY reviewed_at DESC;
SELECT * FROM vw_notifications ORDER BY created_at DESC;

-- 5. 顯示 View 的實際 Schema。
SHOW CREATE VIEW vw_bookings;

-- 6. 學生或教師透過可更新 View 建立自己的待審核單次預約。
-- 執行時 applicant_id 必須等於 MariaDB 登入帳號名稱。
-- INSERT INTO vw_bookings(
--   applicant_id, classroom_id, booking_date,
--   start_section_id, end_section_id, reason, status_id
-- ) VALUES (
--   '41243149', 'BGC0508', DATE '2026-07-01',
--   5, 6, '暑期專題討論', 1
-- );

-- 7. 使用者將自己的通知標記為已讀。
-- UPDATE vw_notifications
-- SET is_read = TRUE
-- WHERE notification_id = 1;
