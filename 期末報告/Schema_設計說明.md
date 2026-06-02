# 教室租用系統：SQL Schema 設計說明

本文件獨立說明 [`schema.sql`](./schema.sql) 的架構方法、設計依據、完整性限制、觸發器、索引與實際 SQL 範例。Schema 適用於 MariaDB。

## 目錄

- [設計目標](#設計目標)
- [設計方法](#設計方法)
- [設計依據](#設計依據)
- [資料表架構](#資料表架構)
- [完整性限制](#完整性限制)
- [觸發器設計](#觸發器設計)
- [索引設計](#索引設計)
- [執行方式](#執行方式)
- [SQL 範例](#sql-範例)

## 設計目標

教室租用系統需要同時管理固定課表與臨時借用。Schema 的主要目標如下：

1. 保存使用者、教室、節次、狀態與課程基本資料。
2. 保存固定課表、長期借用計畫與每次實際借用紀錄。
3. 保存管理員審核歷程與通知。
4. 維持主鍵、外鍵、欄位值域與必填欄位之完整性。
5. 防止同一教室之固定課表與已核准預約發生時段重疊。

## 設計方法

本 Schema 依關聯式資料庫設計流程建立：

1. **辨識實體**：從使用案例整理出使用者、教室、節次、狀態、課程、固定課表、長期借用、單次預約、審核歷程與通知。
2. **區分主資料與交易資料**：將相對穩定之資料獨立為主資料表，將會持續新增之操作紀錄保存於交易資料表。
3. **指定主鍵**：每個資料表均具有 `PRIMARY KEY`，確保每筆資料得以唯一識別。
4. **建立外鍵**：以 `FOREIGN KEY` 表示一對多關聯，確保子資料不得參照不存在之父資料。
5. **限制欄位值域**：以 `NOT NULL`、`UNIQUE`、`CHECK` 與 `DEFAULT` 限制可接受資料。
6. **處理跨表商業規則**：以 Trigger 查詢其他資料表，阻擋固定課表與已核准預約之衝突。
7. **建立索引**：依常用查詢條件建立複合索引，以支援教室時段查詢、使用者歷史紀錄與未讀通知查詢。

### MariaDB 架構設定

| 設定 | 用途 |
|---|---|
| `ENGINE=InnoDB` | 啟用 MariaDB 外鍵參照完整性與交易型資料表支援。 |
| `DEFAULT CHARSET=utf8mb4` | 完整保存繁體中文與其他 Unicode 文字。 |
| `COLLATE=utf8mb4_unicode_ci` | 提供一般文字欄位之 Unicode 比對規則。 |
| `AUTO_INCREMENT` | 為交易資料表產生自動遞增識別碼。 |
| `TIME` | 保存節次起訖時間，避免以一般文字欄位處理時間。 |
| `SIGNAL SQLSTATE '45000'` | 由觸發器阻擋違反時段衝突規則之異動。 |

## 設計依據

### 正規化原則

本 Schema 依第三正規化概念拆分資料：

- 使用者資料集中於 `users`，避免在申請、審核與通知中重複保存姓名與信箱。
- 教室資料集中於 `classrooms`，避免在課表與預約中重複保存教室名稱與容量。
- 節次資料集中於 `sections`，避免每筆課表與預約重複保存起訖時間。
- 狀態資料集中於 `booking_statuses`，避免使用不同文字表示相同審核狀態。
- 課程基本資料與授課時段分離為 `course_info` 與 `course_times`，使一門課程得具有多個授課時段。

### 操作紀錄保存原則

- `bookings` 保存每一次實際教室借用，是系統之核心交易資料表。
- `long_term_bookings` 保存週期性借用計畫；應由程式流程展開為多筆 `bookings`。
- `booking_reviews` 保存每一次審核動作，不覆蓋歷史紀錄。
- `notifications` 保存通知內容與讀取狀態。

### 衝突驗證原則

僅有 `approved` 狀態之預約占用教室。`pending` 案件得暫時並存，管理員核准時才執行最終衝突驗證。

## 資料表架構

| 分類 | 資料表 | 用途 |
|---|---|---|
| 主資料 | `users` | 使用者基本資料與角色 |
| 主資料 | `classrooms` | 教室名稱、容量與啟用狀態 |
| 主資料 | `sections` | 節次名稱與起訖時間 |
| 主資料 | `booking_statuses` | 預約審核狀態 |
| 課程資料 | `course_info` | 課程名稱、學年度、學期與授課教師 |
| 課程資料 | `course_times` | 固定教室、星期與節次範圍 |
| 借用資料 | `long_term_bookings` | 長期借用計畫 |
| 借用資料 | `bookings` | 每一次實際教室借用 |
| 稽核資料 | `booking_reviews` | 管理員審核歷程 |
| 通知資料 | `notifications` | 通知內容與讀取狀態 |

## 完整性限制

### 實體完整性

每個資料表均設置主鍵。例如：

```sql
CREATE TABLE classrooms (
  classroom_id VARCHAR(10) PRIMARY KEY,
  classroom_name VARCHAR(50) NOT NULL,
  capacity INT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 參照完整性

外鍵必須參照至已存在之父資料。本 Schema 的資料表皆使用 MariaDB `InnoDB` 儲存引擎，由資料庫在新增、修改與刪除時執行參照完整性檢查。

單次預約之申請人與教室皆須存在：

```sql
FOREIGN KEY (applicant_id) REFERENCES users(user_id),
FOREIGN KEY (classroom_id) REFERENCES classrooms(classroom_id)
```

### 域完整性

Schema 使用 `CHECK` 限制合法值：

```sql
CHECK (role IN ('student', 'teacher', 'admin'))
CHECK (status_code IN ('pending', 'approved', 'rejected', 'canceled'))
CHECK (capacity > 0)
CHECK (day_of_week BETWEEN 1 AND 7)
CHECK (start_section_id <= end_section_id)
```

### 可選參照

以下欄位允許為 `NULL`：

| 欄位 | 說明 |
|---|---|
| `bookings.long_term_id` | 一般單次預約無須參照長期借用。 |
| `bookings.course_time_id` | 非課程相關借用無須參照固定授課時間。 |
| `notifications.booking_id` | 一般系統通知無須參照單次預約。 |

## 觸發器設計

跨資料表之時段衝突無法僅使用 `CHECK` 完成，因此使用 Trigger。

| 觸發器 | 執行時機 | 用途 |
|---|---|---|
| `trg_course_times_prevent_overlap_insert` | 新增固定課表前 | 防止固定課表互相重疊，並防止與已核准預約重疊。 |
| `trg_course_times_prevent_overlap_update` | 修改固定課表前 | 防止修改後之固定課表發生衝突。 |
| `trg_bookings_prevent_overlap_insert` | 新增已核准預約前 | 防止已核准預約與固定課表或其他已核准預約重疊。 |
| `trg_bookings_prevent_overlap_update` | 修改為已核准預約前 | 防止審核或異動後之預約發生衝突。 |

節次重疊判斷條件如下：

```sql
NEW.start_section_id <= existing.end_section_id
AND NEW.end_section_id >= existing.start_section_id
```

MariaDB 的 `WEEKDAY(date) + 1` 會將星期一至星期日轉換為 `1` 至 `7`，與本 Schema 的星期欄位定義一致。觸發器遇到衝突時，使用 `SIGNAL SQLSTATE '45000'` 終止資料異動。

## 索引設計

| 索引 | 欄位 | 用途 |
|---|---|---|
| `idx_bookings_classroom_date` | `classroom_id`、`booking_date`、`start_section_id`、`end_section_id` | 加速教室指定日期之時段查詢與衝突驗證。 |
| `idx_bookings_applicant_date` | `applicant_id`、`booking_date` | 加速使用者歷史紀錄查詢。 |
| `idx_course_times_classroom_weekday` | `classroom_id`、`day_of_week`、`start_section_id`、`end_section_id` | 加速固定課表查詢與衝突驗證。 |
| `idx_notifications_recipient_read` | `recipient_id`、`is_read` | 加速未讀通知查詢。 |

## 執行方式

進入本目錄後，依序執行：

```powershell
mariadb -u root -p -e "CREATE DATABASE IF NOT EXISTS classroom_rental CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mariadb -u root -p classroom_rental < schema.sql
mariadb -u root -p classroom_rental < examples.sql
```

## MariaDB 官方文件依據

- [`AUTO_INCREMENT`](https://mariadb.com/docs/server/reference/data-types/auto_increment)
- [`FOREIGN KEY Constraints`](https://mariadb.com/docs/server/architecture/server-constraints/foreign-key-constraints)
- [`CREATE TRIGGER`](https://mariadb.com/docs/server/server-usage/triggers-events/triggers/create-trigger)
- [`SIGNAL`](https://mariadb.com/kb/en/signal/)
- [`WEEKDAY`](https://mariadb.com/docs/server/reference/sql-functions/date-time-functions/weekday)

## SQL 範例

完整範例位於 [`examples.sql`](./examples.sql)。以下節錄主要流程。

### 建立基本資料

```sql
INSERT INTO users(user_id, username, email, role, department) VALUES
  ('41243149', '廖章竹', 'member49@example.edu.tw', 'student', '資訊工程系'),
  ('T0000001', '王老師', 'teacher1@example.edu.tw', 'teacher', '資訊工程系'),
  ('A0000001', '系辦管理員', 'admin1@example.edu.tw', 'admin', '資訊工程系');

INSERT INTO classrooms(classroom_id, classroom_name, capacity, is_active) VALUES
  ('A101', '一般教室 A101', 50, 1),
  ('B205', '電腦教室 B205', 40, 1);
```

### 建立固定課表

```sql
INSERT INTO course_info(course_id, academic_year, semester, course_name, teacher_id)
VALUES ('CS-DB-001', 114, 2, '資料庫系統', 'T0000001');

INSERT INTO course_times(course_id, classroom_id, day_of_week, start_section_id, end_section_id)
VALUES ('CS-DB-001', 'A101', 2, 2, 4);
```

### 建立並核准單次預約

```sql
INSERT INTO bookings(
  applicant_id, classroom_id, booking_date,
  start_section_id, end_section_id, reason, status_id
) VALUES (
  '41243149', 'B205', '2026-06-08',
  5, 6, '專題小組定期會議', 1
);

INSERT INTO booking_reviews(booking_id, reviewer_id, status_id, comment)
VALUES (1, 'A0000001', 2, '時段可使用，核准借用。');

UPDATE bookings SET status_id = 2 WHERE booking_id = 1;
```

### 查詢已核准借用

```sql
SELECT
  b.booking_date,
  c.classroom_name,
  s1.section_name AS start_section,
  s2.section_name AS end_section,
  u.username AS applicant,
  b.reason
FROM bookings b
JOIN classrooms c ON c.classroom_id = b.classroom_id
JOIN users u ON u.user_id = b.applicant_id
JOIN sections s1 ON s1.section_id = b.start_section_id
JOIN sections s2 ON s2.section_id = b.end_section_id
JOIN booking_statuses status ON status.status_id = b.status_id
WHERE b.booking_date = '2026-06-08'
  AND status.status_code = 'approved'
ORDER BY c.classroom_id, b.start_section_id;
```

### 衝突測試

下列 SQL 應被拒絕，因為 `B205` 於 `2026-06-08` 第 6 節已存在已核准預約：

```sql
INSERT INTO bookings(
  applicant_id, classroom_id, booking_date,
  start_section_id, end_section_id, reason, status_id
) VALUES (
  'T0000001', 'B205', '2026-06-08',
  6, 6, '衝突測試', 2
);
```

預期錯誤：

```text
booking overlaps an approved booking
```
