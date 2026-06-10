-- 教室租用系統：完整擬真範例資料
-- 執行前提：已執行「完整資料庫Schema.sql」。
-- 本檔為教學與驗證用途，不包含正式環境密碼或未授權個人資料。
-- 10 張資料表各建立 10 筆資料。

USE classroom_rental;
SET NAMES utf8mb4;
SET time_zone = '+08:00';

START TRANSACTION;

INSERT INTO booking_statuses(status_id, status_code, status_name) VALUES
  (1,  'draft',                  '草稿'),
  (2,  'pending',                '待審核'),
  (3,  'under_review',           '審核中'),
  (4,  'approved',               '已核准'),
  (5,  'rejected',               '已拒絕'),
  (6,  'canceled',               '已取消'),
  (7,  'expired',                '已逾期'),
  (8,  'completed',              '已完成'),
  (9,  'suspended',              '已暫停'),
  (10, 'resubmission_required',  '待補件');

INSERT INTO users(user_id, username, email, role, department) VALUES
  ('41243149', '廖章竹',       's41243149@example.edu.tw', 'student', '資訊工程系'),
  ('41243151', '劉向榮',       's41243151@example.edu.tw', 'student', '資訊工程系'),
  ('41243154', '蔡品辰',       's41243154@example.edu.tw', 'student', '資訊工程系'),
  ('41243161', '羅冠穎',       's41243161@example.edu.tw', 'student', '資訊工程系'),
  ('T0000001', '王志明',       't0000001@example.edu.tw', 'teacher', '資訊工程系'),
  ('T0000002', '陳怡君',       't0000002@example.edu.tw', 'teacher', '資訊管理系'),
  ('T0000003', '林建宏',       't0000003@example.edu.tw', 'teacher', '電機工程系'),
  ('T0000004', '張雅雯',       't0000004@example.edu.tw', 'teacher', '通識教育中心'),
  ('A0000001', '教務處管理員', 'a0000001@example.edu.tw', 'admin',   '教務處課務組'),
  ('A0000002', '資產組管理員', 'a0000002@example.edu.tw', 'admin',   '總務處資產組');

INSERT INTO classrooms(classroom_id, classroom_name, capacity, is_active) VALUES
  ('A101',   'A101 一般教室',       50, TRUE),
  ('A102',   'A102 多媒體教室',     45, TRUE),
  ('B201',   'B201 階梯教室',       80, TRUE),
  ('B202',   'B202 討論教室',       36, TRUE),
  ('B205',   'B205 電腦教室',       40, TRUE),
  ('C301',   'C301 智慧教室',       48, TRUE),
  ('C302',   'C302 語言教室',       32, TRUE),
  ('D401',   'D401 專題教室',       30, TRUE),
  ('LAB501', 'LAB501 物聯網實驗室', 24, TRUE),
  ('CONF01', '第一會議室',          20, TRUE);

INSERT INTO sections(section_id, section_name, start_time, end_time) VALUES
  (1,  '第 1 節',  '08:10:00', '09:00:00'),
  (2,  '第 2 節',  '09:10:00', '10:00:00'),
  (3,  '第 3 節',  '10:10:00', '11:00:00'),
  (4,  '第 4 節',  '11:10:00', '12:00:00'),
  (5,  '第 5 節',  '13:20:00', '14:10:00'),
  (6,  '第 6 節',  '14:20:00', '15:10:00'),
  (7,  '第 7 節',  '15:20:00', '16:10:00'),
  (8,  '第 8 節',  '16:20:00', '17:10:00'),
  (9,  '第 9 節',  '17:20:00', '18:10:00'),
  (10, '第 10 節', '18:20:00', '19:10:00');

INSERT INTO course_info(
  course_id, academic_year, semester, course_name, teacher_id
) VALUES
  ('CS-DB-001',    115, 1, '資料庫系統',       'T0000001'),
  ('CS-SE-002',    115, 1, '軟體工程',         'T0000002'),
  ('CS-NET-003',   115, 1, '計算機網路',       'T0000003'),
  ('CS-AI-004',    115, 1, '人工智慧導論',     'T0000004'),
  ('CS-OS-005',    115, 1, '作業系統',         'T0000001'),
  ('CS-WEB-006',   115, 1, '網頁程式設計',     'T0000002'),
  ('CS-SEC-007',   115, 1, '資訊安全',         'T0000003'),
  ('CS-CLOUD-008', 115, 1, '雲端運算',         'T0000004'),
  ('CS-IOT-009',   115, 1, '物聯網系統實務',   'T0000001'),
  ('CS-PROJ-010',  115, 1, '資訊專題實作',     'T0000002');

INSERT INTO course_times(
  course_time_id, course_id, classroom_id, day_of_week,
  start_section_id, end_section_id
) VALUES
  (1,  'CS-DB-001',    'A101',   2, 2, 4),
  (2,  'CS-SE-002',    'A102',   3, 3, 4),
  (3,  'CS-NET-003',   'B201',   4, 1, 2),
  (4,  'CS-AI-004',    'B202',   5, 5, 6),
  (5,  'CS-OS-005',    'B205',   1, 2, 3),
  (6,  'CS-WEB-006',   'C301',   2, 7, 8),
  (7,  'CS-SEC-007',   'C302',   3, 5, 6),
  (8,  'CS-CLOUD-008', 'D401',   4, 7, 9),
  (9,  'CS-IOT-009',   'LAB501', 5, 1, 3),
  (10, 'CS-PROJ-010',  'CONF01', 1, 9, 10);

INSERT INTO long_term_bookings(
  long_term_id, applicant_id, classroom_id,
  start_date, end_date, day_of_week,
  start_section_id, end_section_id, reason, status_id, created_at
) VALUES
  (1,  'T0000001', 'A101',   DATE '2026-06-01', DATE '2026-12-31', 1, 5, 6, '資料庫課程專題輔導',       4,  TIMESTAMP '2026-05-20 09:00:00'),
  (2,  'T0000002', 'A102',   DATE '2026-06-01', DATE '2026-12-31', 2, 1, 2, '軟體工程小組討論',         2,  TIMESTAMP '2026-05-21 10:00:00'),
  (3,  'T0000003', 'B201',   DATE '2026-06-01', DATE '2026-12-31', 3, 5, 6, '網路實務專題說明會',       3,  TIMESTAMP '2026-05-22 11:00:00'),
  (4,  'T0000004', 'B202',   DATE '2026-06-01', DATE '2026-12-31', 4, 1, 2, '人工智慧讀書會',           4,  TIMESTAMP '2026-05-23 13:00:00'),
  (5,  'T0000001', 'B205',   DATE '2026-06-01', DATE '2026-12-31', 5, 5, 6, '作業系統實機演練',         5,  TIMESTAMP '2026-05-24 14:00:00'),
  (6,  'T0000002', 'C301',   DATE '2026-06-01', DATE '2026-12-31', 1, 1, 2, '網頁專題進度審查',         6,  TIMESTAMP '2026-05-25 15:00:00'),
  (7,  'T0000003', 'C302',   DATE '2026-02-01', DATE '2026-05-31', 2, 1, 2, '資訊安全證照輔導',         7,  TIMESTAMP '2026-01-15 09:30:00'),
  (8,  'T0000004', 'D401',   DATE '2026-02-01', DATE '2026-05-31', 3, 1, 2, '雲端系統成果討論',         8,  TIMESTAMP '2026-01-16 10:30:00'),
  (9,  'T0000001', 'LAB501', DATE '2026-06-01', DATE '2026-12-31', 4, 5, 6, '物聯網設備整合實驗',       9,  TIMESTAMP '2026-05-26 16:00:00'),
  (10, 'T0000002', 'CONF01', DATE '2026-06-01', DATE '2026-12-31', 5, 3, 4, '資訊專題口試準備會議',     10, TIMESTAMP '2026-05-27 17:00:00');

INSERT INTO bookings(
  booking_id, applicant_id, classroom_id, long_term_id, course_time_id,
  booking_date, start_section_id, end_section_id,
  reason, status_id, created_at
) VALUES
  (1,  '41243149', 'A101',   NULL, NULL, DATE '2026-06-20', 5, 6, '資料庫期末專題討論',       1,  TIMESTAMP '2026-06-10 08:30:00'),
  (2,  '41243151', 'A102',   NULL, NULL, DATE '2026-06-22', 1, 2, '軟體工程需求訪談演練',     2,  TIMESTAMP '2026-06-10 09:00:00'),
  (3,  '41243154', 'B201',   NULL, NULL, DATE '2026-06-24', 5, 6, '計算機網路成果彩排',       3,  TIMESTAMP '2026-06-10 09:30:00'),
  (4,  'T0000004', 'B202',   4,    4,    DATE '2026-06-25', 1, 2, '人工智慧讀書會',           4,  TIMESTAMP '2026-06-10 10:00:00'),
  (5,  'T0000001', 'B205',   5,    NULL, DATE '2026-06-26', 5, 6, '作業系統實機演練',         5,  TIMESTAMP '2026-06-10 10:30:00'),
  (6,  'T0000002', 'C301',   6,    NULL, DATE '2026-06-29', 1, 2, '網頁專題進度審查',         6,  TIMESTAMP '2026-06-10 11:00:00'),
  (7,  'T0000003', 'C302',   7,    NULL, DATE '2026-05-12', 1, 2, '資訊安全證照輔導',         7,  TIMESTAMP '2026-05-01 13:00:00'),
  (8,  'T0000004', 'D401',   8,    8,    DATE '2026-05-13', 1, 2, '雲端系統成果討論',         8,  TIMESTAMP '2026-05-01 13:30:00'),
  (9,  'T0000001', 'LAB501', 9,    9,    DATE '2026-06-18', 5, 6, '物聯網設備整合實驗',       9,  TIMESTAMP '2026-06-10 14:00:00'),
  (10, 'T0000002', 'CONF01', 10,   NULL, DATE '2026-06-19', 3, 4, '資訊專題口試準備會議',     10, TIMESTAMP '2026-06-10 14:30:00');

INSERT INTO booking_reviews(
  review_id, booking_id, reviewer_id, status_id, comment, reviewed_at
) VALUES
  (1,  2,  'A0000001', 2,  '申請資料已收件，依序等待審核。',           TIMESTAMP '2026-06-10 09:10:00'),
  (2,  3,  'A0000002', 3,  '正在確認投影設備與座位配置。',             TIMESTAMP '2026-06-10 09:45:00'),
  (3,  4,  'A0000001', 4,  '指定時段無固定課表衝突，核准使用。',       TIMESTAMP '2026-06-10 10:15:00'),
  (4,  5,  'A0000002', 5,  '同時段已有設備維護作業，無法提供使用。',   TIMESTAMP '2026-06-10 10:45:00'),
  (5,  6,  'A0000001', 6,  '申請人確認活動延期，依申請取消。',         TIMESTAMP '2026-06-10 11:15:00'),
  (6,  7,  'A0000002', 7,  '申請日期已逾使用期限，系統結案。',         TIMESTAMP '2026-05-13 08:00:00'),
  (7,  8,  'A0000001', 8,  '教室使用完成且設備檢查正常。',             TIMESTAMP '2026-05-13 12:30:00'),
  (8,  9,  'A0000002', 9,  '實驗室設備盤點期間暫停開放。',             TIMESTAMP '2026-06-10 14:15:00'),
  (9,  10, 'A0000001', 10, '請補充參與人數與口試委員名單。',           TIMESTAMP '2026-06-10 14:45:00'),
  (10, 4,  'A0000002', 4,  '完成第二次複核，維持原核准結果。',         TIMESTAMP '2026-06-11 09:00:00');

INSERT INTO notifications(
  notification_id, recipient_id, booking_id, message, is_read, created_at
) VALUES
  (1,  '41243149', 1,  '草稿尚未送出，請確認借用時段與用途。',                     FALSE, TIMESTAMP '2026-06-10 08:31:00'),
  (2,  '41243151', 2,  'A102 教室申請已送出，狀態為待審核。',                      TRUE,  TIMESTAMP '2026-06-10 09:11:00'),
  (3,  '41243154', 3,  'B201 教室申請正在確認設備需求。',                          FALSE, TIMESTAMP '2026-06-10 09:46:00'),
  (4,  'T0000004', 4,  'B202 教室借用已核准。',                                    TRUE,  TIMESTAMP '2026-06-10 10:16:00'),
  (5,  'T0000001', 5,  'B205 教室因設備維護無法核准。',                            FALSE, TIMESTAMP '2026-06-10 10:46:00'),
  (6,  'T0000002', 6,  'C301 教室借用已依申請取消。',                              TRUE,  TIMESTAMP '2026-06-10 11:16:00'),
  (7,  'T0000003', 7,  'C302 教室申請已逾期並完成結案。',                          TRUE,  TIMESTAMP '2026-05-13 08:01:00'),
  (8,  'T0000004', 8,  'D401 教室使用完成，設備檢查結果正常。',                    TRUE,  TIMESTAMP '2026-05-13 12:31:00'),
  (9,  'T0000001', 9,  'LAB501 於設備盤點期間暫停開放。',                          FALSE, TIMESTAMP '2026-06-10 14:16:00'),
  (10, 'T0000002', 10, 'CONF01 申請需要補充參與人數與口試委員名單。',              FALSE, TIMESTAMP '2026-06-10 14:46:00');

COMMIT;

-- 驗證每張資料表至少具有 10 筆資料。
SELECT 'users' AS table_name, COUNT(*) AS row_count FROM users
UNION ALL SELECT 'classrooms', COUNT(*) FROM classrooms
UNION ALL SELECT 'sections', COUNT(*) FROM sections
UNION ALL SELECT 'booking_statuses', COUNT(*) FROM booking_statuses
UNION ALL SELECT 'course_info', COUNT(*) FROM course_info
UNION ALL SELECT 'course_times', COUNT(*) FROM course_times
UNION ALL SELECT 'long_term_bookings', COUNT(*) FROM long_term_bookings
UNION ALL SELECT 'bookings', COUNT(*) FROM bookings
UNION ALL SELECT 'booking_reviews', COUNT(*) FROM booking_reviews
UNION ALL SELECT 'notifications', COUNT(*) FROM notifications
ORDER BY table_name;
