-- 教室租用系統：MariaDB 真實範例資料與查詢
-- 先執行「完整資料庫Schema.sql」，再執行本檔案。
--
-- 檔案內容：
-- 1. 建立預約狀態、使用者、教室、節次與固定課表 (皆至少 10 筆)。
-- 2. 建立長期借用、單次預約、審核歷程與通知 (皆至少 10 筆)。
-- 3. 驗證每個資料實體的匯入筆數。
-- 4. 查詢已核准借用與未讀通知。
-- 5. 提供可取消註解之衝突測試 SQL。

USE classroom_rental;
SET NAMES utf8mb4;
SET time_zone = '+08:00';

START TRANSACTION;

-- ==========================================
-- 1. 基礎主資料 (Master Data)
-- ==========================================

-- [booking_statuses] 預約生命週期狀態 10 筆
INSERT INTO booking_statuses(status_id, status_code, status_name) VALUES
  (1,  'pending',                '待審核'),
  (2,  'approved',               '已核准'),
  (3,  'rejected',               '已拒絕'),
  (4,  'canceled',               '已取消'),
  (5,  'draft',                  '草稿'),
  (6,  'under_review',           '審核中'),
  (7,  'expired',                '已逾期'),
  (8,  'completed',              '已完成'),
  (9,  'suspended',              '已暫停'),
  (10, 'resubmission_required',  '待補件');

-- [users] 26筆 (包含 student, teacher, admin)
INSERT INTO users(user_id, username, email, role, department) VALUES
  ('41225244', '劉哲瑋', '41225244@nfu.edu.tw', 'student', '電機工程系'),
  ('41243149', '廖章竹', '41243149@nfu.edu.tw', 'student', '資訊工程系'),
  ('41243151', '劉向榮', '41243151@nfu.edu.tw', 'student', '資訊工程系'),
  ('41243154', '蔡品辰', '41243154@nfu.edu.tw', 'student', '資訊工程系'),
  ('41243161', '羅冠穎', '41243161@nfu.edu.tw', 'student', '資訊工程系'),
  ('B13001', '鄭錦聰', 'tsong@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13005', '江季翰', 'jhjiang@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13007', '林易泉', 'lyc@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13011', '黃建宏', 'chhuang@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13012', '徐元寶', 'hsuyp@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13014', '許永和', 'yhsheu@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13019', '黃惠俞', 'hyhuang@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13020', '張朝陽', 'jychang@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13021', '謝仕杰', 'scshie@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13022', '許乙清', 'hsuic@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13023', '林武杰', 'wjlin@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13024', '黃世昌', 'schuang@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13027', '簡銘伸', 'jianms@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13028', '蔡柏祥', 'ptsai@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13029', '陳國益', 'kuoyichen@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13032', '游允帥', 'yys@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13034', '詹竣傑', 'ccchan@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13035', '莊文河', 'riverjuang@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('B13037', '杜俊育', 'jiunyu.tu@nfu.edu.tw', 'teacher', '資訊工程系'),
  ('E13006', '蔡明靜', 'purple637@nfu.edu.tw', 'admin', '資訊工程系'),
  ('F10013', '鐘佳純', 'sophie@nfu.edu.tw', 'admin', '教務處');

-- [classrooms] 10筆 (教室人數為虛擬數量)
INSERT INTO classrooms(classroom_id, classroom_name, capacity, is_active) VALUES
  ('BGC0501', '基本電學與證照實驗室', 50, 1),
  ('BGC0513', '生物資訊實驗室', 51, 1),
  ('BGC0601', '系統設計實驗室', 52, 1),
  ('BGC0614', '多功能教學實驗室', 53, 1),
  ('BCB0303', '資工科普通教室', 40, 1),
  ('BCB0305', '數位邏輯實驗室', 35, 1),
  ('BRA0102', '人工智慧創新實驗室', 70, 1),
  ('BRA0201', '智慧運算與資訊安全實驗室', 60, 1),
  ('BGC0508', '研討室', 10, 1),
  ('BGC0402', '會議室', 20, 1);

-- [sections] 13節課
INSERT INTO sections(section_id, section_name, start_time, end_time) VALUES
  (1, '第 1 節', '08:10:00', '09:00:00'),
  (2, '第 2 節', '09:10:00', '10:00:00'),
  (3, '第 3 節', '10:10:00', '11:00:00'),
  (4, '第 4 節', '11:10:00', '12:00:00'),
  (5, '第 5 節', '13:20:00', '14:10:00'),
  (6, '第 6 節', '14:20:00', '15:10:00'),
  (7, '第 7 節', '15:20:00', '16:10:00'),
  (8, '第 8 節', '16:20:00', '17:10:00'),
  (9, '第 9 節', '17:20:00', '18:10:00'),
  (10, '第 10 節', '18:30:00', '19:20:00'),
  (11, '第 11 節', '19:20:00', '20:10:00'),
  (12, '第 12 節', '20:15:00', '21:05:00'),
  (13, '第 13 節', '21:05:00', '21:55:00');

-- ==========================================
-- 2. 課程與排課資料
-- ==========================================

-- [course_info] 10門課程
INSERT INTO course_info(course_id, academic_year, semester, course_name, teacher_id) VALUES
  ('11422012', 114, 2, '資料庫系統', 'B13005'),
  ('11422016', 114, 2, '人工智慧', 'B13001'),
  ('11422009', 114, 2, '微處理機實習', 'B13014'),
  ('11422011', 114, 2, '編譯程式', 'B13021'),
  ('11422013', 114, 2, '系統分析與設計', 'B13037'),
  ('11422015', 114, 2, '軟體工程', 'B13022'),
  ('11422014', 114, 2, '科技英文', 'B13028'),
  ('11422018', 114, 2, '可規劃邏輯設計實務', 'B13035'),
  ('11412064', 114, 1, 'JAVA程式設計(一)', 'B13023'),
  ('11412083', 114, 1, '微處理機', 'B13012');

-- [course_times] 固定課表 10筆 (114-2資工課表)
INSERT INTO course_times(course_id, classroom_id, day_of_week, start_section_id, end_section_id) VALUES
  ('11422012', 'BGC0513', 3, 1, 3),   -- 資料庫系統
  ('11422016', 'BGC0614', 5, 5, 7),   -- 人工智慧
  ('11422009', 'BGC0601', 3, 5, 7),   -- 微處理機實習
  ('11422011', 'BGC0513', 4, 8, 9),   -- 編譯程式
  ('11422011', 'BGC0513', 5, 1, 1),   -- 編譯程式
  ('11422013', 'BRA0201', 4, 5, 7),   -- 系統分析與設計
  ('11422014', 'BGC0501', 2, 7, 7),   -- 科技英文
  ('11422014', 'BGC0501', 4, 1, 2),   -- 科技英文
  ('11422015', 'BGC0501', 2, 1, 3),   -- 軟體工程
  ('11422018', 'BGC0513', 5, 2, 4);   -- 可規劃邏輯設計實務

-- ==========================================
-- 3. 預約交易資料 (Transactions)
-- ==========================================

-- [long_term_bookings] 長期借用計畫父單據  10筆
INSERT INTO long_term_bookings(applicant_id, classroom_id, start_date, end_date, day_of_week, start_section_id, end_section_id, reason, status_id) VALUES
  ('41243149', 'BGC0508', '2026-03-01', '2026-06-30', 5, 5, 6, '專題小組定期會議', 2),
  ('41243154', 'BGC0508', '2026-03-01', '2026-06-30', 3, 8, 9, '專題開會', 2),
  ('B13027', 'BGC0601', '2026-03-01', '2026-06-30', 1, 9, 10, 'TA課程', 2),
  ('41243151', 'BGC0508', '2026-03-15', '2026-05-15', 3, 5, 5, '小組討論', 2),
  ('B13014', 'BGC0402', '2026-04-01', '2026-06-01', 5, 8, 8, '實驗儀器定期自主維護', 2),
  ('B13020', 'BGC0402', '2026-03-01', '2026-06-30', 3, 8, 9, '學術論文外審進度會', 1), -- 待審核
  ('B13027', 'BGC0402', '2026-03-01', '2026-06-30', 5, 2, 3, '英文檢定模擬小組', 3), -- 已拒絕
  ('B13035', 'BGC0402', '2026-05-01', '2026-06-30', 4, 5, 6, '專題簡報微調演練', 4), -- 已取消
  ('B13001', 'BGC0402', '2026-03-01', '2026-06-30', 2, 1, 2, '產學合作週會', 2),
  ('B13007', 'BGC0402', '2026-04-01', '2026-06-30', 1, 5, 6, '自主機器人研發實作', 1); -- 待審核

-- [bookings] 單次實際預約 10筆 (不與固定課表及其他已核准衝突)
INSERT INTO bookings(booking_id, applicant_id, classroom_id, long_term_id, course_time_id, booking_date, start_section_id, end_section_id, reason, status_id) VALUES
  (1, '41243149', 'BGC0508', NULL, NULL, '2026-06-08', 5, 6, '期末多媒體報告排練', 2),
  (2, '41243154', 'BGC0614', NULL, NULL, '2026-06-08', 1, 2, 'WJ-lab專題小組定期會議', 2),
  (3, 'B13001',   'BRA0102', NULL, NULL, '2026-06-08', 8, 9, 'AI研討會預備場勘', 2),
  (4, '41243151', 'BCB0303', NULL, NULL, '2026-06-09', 5, 5, '資工三甲班會臨時補開', 2),
  (5, '41243149', 'BGC0508', 1,    NULL, '2026-06-12', 5, 6, '長期展開：畢業專題小組週會', 2), -- 對應 long_term_id = 1 (週五)
  (6, '41243161', 'BGC0614', NULL, NULL, '2026-06-10', 5, 6, '系學會幹部改選投票說明會', 1),    -- 待審核
  (7, 'B13005',   'BCB0305', NULL, NULL, '2026-06-10', 7, 8, '產學合作計畫補實驗', 3),         -- 已拒絕
  (8, '41243154', 'BGC0513', NULL, NULL, '2026-06-11', 5, 6, '物聯網硬體設備壓力測試', 4),      -- 已取消
  (9, 'B13023',   'BGC0601', NULL, NULL, '2026-06-12', 1, 2, 'JAVA程式設計期末考加開考場', 2),
  (10, '41243151', 'BRA0201', NULL, NULL, '2026-06-12', 8, 9, '資安競賽CTF小組模擬賽', 1);       -- 待審核

-- [booking_reviews] 審核歷程紀錄 10筆 (對應單次預約各動態，管理員審核)
INSERT INTO booking_reviews(booking_id, reviewer_id, status_id, comment) VALUES
  (1, 'E13006', 2, '時段可使用，核准借用。'),
  (2, 'E13006', 2, '核准，請至系辦拿取鑰匙並保持環境整潔。'),
  (3, 'F10013', 2, '大型活動場勘核准，請知會當天值班人員。'),
  (4, 'E13006', 2, '確認未撞到正課與常規實驗，核准。'),
  (5, 'E13006', 2, '長期借用計畫內自動核准派發。'),
  (6, 'E13006', 1, '尚在評估資工系學會人數是否超出該教室容納上限。'),
  (7, 'E13006', 3, '該時段數位邏輯實驗室內部進行定期儀器維護工程，不開放。'),
  (8, 'E13006', 4, '申請人已自行送交取消借用申請。'),
  (9, 'F10013', 2, '課務組特殊考場調度核可，准予借用。'),
  (10, 'E13006', 1, '等待專題指導教授簽核同意書送達系辦。');

-- [notifications] 通知系統紀錄 10 筆 (包含實際接收對象)
INSERT INTO notifications(recipient_id, booking_id, message, is_read) VALUES
  ('41243149', 1, '您申請的 BGC0508 教室借用申請已核准。', 0),
  ('41243154', 2, '您申請的 BGC0614 教室借用申請已核准。', 1),
  ('B13001',   3, '老師您好，您申請的 BRA0102 教室場勘已核准', 0),
  ('41243151', 4, '您申請的 BCB0303 教室借用申請已核准。', 0),
  ('41243149', 5, 'BGC0508 長期借用例行單日派發核准通知。', 1),
  ('41243161', 6, '您的 BGC0614 教室借用申請目前處於待審核狀態。', 0),
  ('B13005',   7, '老師您好，您的 BCB0305 教室借用申請已被拒絕，原因：內部定期維護。', 1),
  ('41243154', 8, '您的 BGC0513 教室借用案件已成功辦理取消。', 1),
  ('B13023',   9, '老師您好，BGC0601 考場加開借用申請已核准。', 0),
  ('41243151', 10, '您的 BRA0201 教室借用申請目前處於待審核狀態。', 0);

COMMIT;

-- ==========================================
-- 4. 每個資料實體匯入筆數驗證
-- ==========================================

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


-- ==========================================
-- 5. 核心系統查詢範例 (驗證現有資料)
-- ==========================================

-- 查詢一：特定日期 (2026-06-08) 各教室「已核准」的借用清冊
SELECT
  b.booking_date,
  c.classroom_id,
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

-- 查詢二：特定學生 ('41243149') 的個人未讀通知
SELECT
  n.notification_id,
  n.message,
  n.created_at
FROM notifications AS n
WHERE n.recipient_id = '41243149'
  AND n.is_read = 0
ORDER BY n.created_at DESC;


-- ==========================================
-- 6. 衝突阻擋驗證測試 (驗證 Trigger 運作)
-- ==========================================

-- 驗證測試 A：單次預約衝撞「已核准預約」 (取消註解執行會噴 Error 45000)
-- 預期失敗原因：BGC0508 在 2026-06-08 第 5~6 節已被預約單號 1 (廖章竹) 佔用。
-- INSERT INTO bookings(applicant_id, classroom_id, booking_date, start_section_id, end_section_id, reason, status_id)
-- VALUES ('B13001', 'BGC0508', '2026-06-08', 6, 6, '臨時加碼開會(預期會被預約衝突 Trigger 阻擋)', 2);

-- 驗證測試 B：單次預約衝撞「學期固定課表」 (取消註解執行會噴 Error 45000)
-- 預期失敗原因：BGC0513 教室在每週三(3)的第 1~3 節為江季翰老師的「資料庫系統」正課時間。
-- INSERT INTO bookings(applicant_id, classroom_id, booking_date, start_section_id, end_section_id, reason, status_id)
-- VALUES ('41243154', 'BGC0513', '2026-06-10', 2, 2, '正課時段借用實驗室(預期會被課表衝突 Trigger 阻擋)', 2);
