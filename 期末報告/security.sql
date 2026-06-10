-- 教室租用系統：MariaDB 角色與權限設定
-- 執行前提：schema.sql 已建立資料表與 View。
-- 執行帳號需具有 CREATE ROLE 與 GRANT OPTION。
-- 使用方式：mariadb -u root -p classroom_rental < security.sql

CREATE ROLE IF NOT EXISTS classroom_student_role;
CREATE ROLE IF NOT EXISTS classroom_teacher_role;
CREATE ROLE IF NOT EXISTS classroom_admin_role;

-- 教師繼承學生的一般使用者權限；管理員繼承教師權限。
GRANT classroom_student_role TO classroom_teacher_role;
GRANT classroom_teacher_role TO classroom_admin_role;

-- 學生：讀取公開主資料、自己的帳號、預約、審核結果與通知。
GRANT SHOW VIEW ON classroom_rental.* TO classroom_student_role;
GRANT SELECT ON classroom_rental.vw_users TO classroom_student_role;
GRANT SELECT ON classroom_rental.vw_classrooms TO classroom_student_role;
GRANT SELECT ON classroom_rental.vw_sections TO classroom_student_role;
GRANT SELECT ON classroom_rental.vw_booking_statuses TO classroom_student_role;
GRANT SELECT ON classroom_rental.vw_bookings TO classroom_student_role;
GRANT INSERT (
  applicant_id, classroom_id, booking_date,
  start_section_id, end_section_id, reason, status_id
) ON classroom_rental.vw_bookings TO classroom_student_role;
GRANT UPDATE (
  classroom_id, booking_date, start_section_id,
  end_section_id, reason, status_id
) ON classroom_rental.vw_bookings TO classroom_student_role;
GRANT SELECT ON classroom_rental.vw_booking_reviews TO classroom_student_role;
GRANT SELECT ON classroom_rental.vw_notifications TO classroom_student_role;
GRANT UPDATE (is_read)
  ON classroom_rental.vw_notifications TO classroom_student_role;

-- 教師：繼承學生權限，並可查詢課程、固定課表及維護自己的長期借用。
GRANT SELECT ON classroom_rental.vw_course_info TO classroom_teacher_role;
GRANT SELECT ON classroom_rental.vw_course_times TO classroom_teacher_role;
GRANT SELECT ON classroom_rental.vw_long_term_bookings
  TO classroom_teacher_role;
GRANT INSERT (
  applicant_id, classroom_id, start_date, end_date, day_of_week,
  start_section_id, end_section_id, reason, status_id
) ON classroom_rental.vw_long_term_bookings TO classroom_teacher_role;
GRANT UPDATE (
  classroom_id, start_date, end_date, day_of_week,
  start_section_id, end_section_id, reason, status_id
) ON classroom_rental.vw_long_term_bookings TO classroom_teacher_role;

-- 管理員：可管理所有基礎資料表與 View。
GRANT SELECT, INSERT, UPDATE, DELETE, SHOW VIEW
  ON classroom_rental.* TO classroom_admin_role;

-- 帳號設定範例：MariaDB 帳號名稱應與 users.user_id 相同。
-- 正式環境必須改用密碼管理器產生之高強度密碼，不得提交真實密碼。
--
-- CREATE USER IF NOT EXISTS '41243149'@'localhost'
--   IDENTIFIED BY 'replace-with-strong-password';
-- GRANT classroom_student_role TO '41243149'@'localhost';
-- SET DEFAULT ROLE classroom_student_role FOR '41243149'@'localhost';
--
-- CREATE USER IF NOT EXISTS 'T0000001'@'localhost'
--   IDENTIFIED BY 'replace-with-strong-password';
-- GRANT classroom_teacher_role TO 'T0000001'@'localhost';
-- SET DEFAULT ROLE classroom_teacher_role FOR 'T0000001'@'localhost';
--
-- CREATE USER IF NOT EXISTS 'A0000001'@'localhost'
--   IDENTIFIED BY 'replace-with-strong-password';
-- GRANT classroom_admin_role TO 'A0000001'@'localhost';
-- SET DEFAULT ROLE classroom_admin_role FOR 'A0000001'@'localhost';

-- 權限驗證：
-- SELECT USER(), CURRENT_USER(), CURRENT_ROLE();
-- SELECT * FROM information_schema.ENABLED_ROLES;
-- SHOW GRANTS FOR classroom_student_role;
-- SHOW GRANTS FOR classroom_teacher_role;
-- SHOW GRANTS FOR classroom_admin_role;
