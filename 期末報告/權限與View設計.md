# 教室租用系統：權限、View 與 Domain 設計

本文件說明 MariaDB 的學生、教師及管理員權限設定、驗證方式、10 個資料表的 View、欄位 Domain 選擇，以及日期與時間型別的精確定義。

## 1. 權限架構

系統同時使用兩層角色資料：

1. `users.role` 保存業務身分，供 View 與 Trigger 驗證資料所有權及操作規則。
2. MariaDB Role 保存資料庫權限，限制帳號可執行的 `SELECT`、`INSERT`、`UPDATE`、`DELETE` 與 `SHOW VIEW`。

MariaDB 登入帳號名稱必須與 `users.user_id` 相同。例如資料列 `user_id = '41243149'` 應對應資料庫帳號 `'41243149'@'localhost'`。View 使用 `USER()` 取得登入帳號並執行資料列過濾。

只有管理員或受控的資料庫服務帳號可取得基礎資料表直接權限。Trigger 將未登錄於 `users` 的帳號視為資料庫維運帳號，因此不得將基礎資料表權限授與一般應用程式帳號。

| 系統身分 | MariaDB Role | 主要權限 |
|---|---|---|
| 學生 | `classroom_student_role` | 查詢公開主資料、自己的帳號、預約、審核結果與通知；建立或修改自己的待審核預約 |
| 教師 | `classroom_teacher_role` | 繼承學生權限；增加課程、固定課表查詢及自己的長期借用維護權限 |
| 管理員 | `classroom_admin_role` | 繼承教師權限；管理全部基礎資料表、交易資料表與 View |

角色繼承順序如下：

```text
classroom_student_role
        ↓
classroom_teacher_role
        ↓
classroom_admin_role
```

## 2. 權限建立語法

完整語法位於 [`security.sql`](./security.sql)。執行帳號必須具有 `CREATE ROLE` 及授權權限。

```sql
CREATE ROLE IF NOT EXISTS classroom_student_role;
CREATE ROLE IF NOT EXISTS classroom_teacher_role;
CREATE ROLE IF NOT EXISTS classroom_admin_role;

GRANT classroom_student_role TO classroom_teacher_role;
GRANT classroom_teacher_role TO classroom_admin_role;
```

帳號建立及預設角色設定範例：

```sql
CREATE USER IF NOT EXISTS '41243149'@'localhost'
  IDENTIFIED BY '由密碼管理器產生的高強度密碼';
GRANT classroom_student_role TO '41243149'@'localhost';
SET DEFAULT ROLE classroom_student_role FOR '41243149'@'localhost';
```

教師及管理員分別套用 `classroom_teacher_role` 與 `classroom_admin_role`。正式密碼不得寫入 Git 儲存庫。

## 3. 權限驗證

登入後先確認目前帳號及啟用角色：

```sql
SELECT USER(), CURRENT_USER(), CURRENT_ROLE();
SELECT * FROM information_schema.ENABLED_ROLES;
SHOW GRANTS;
```

管理員可檢查各角色授權：

```sql
SHOW GRANTS FOR classroom_student_role;
SHOW GRANTS FOR classroom_teacher_role;
SHOW GRANTS FOR classroom_admin_role;
```

必要驗證案例：

| 測試帳號 | 操作 | 預期結果 |
|---|---|---|
| 學生 | `SELECT * FROM vw_users` | 僅顯示自己的使用者資料 |
| 學生 | `SELECT * FROM users` | 拒絕，學生沒有基礎資料表讀取權限 |
| 學生 | 新增自己的 `pending` 預約 | 接受 |
| 學生 | 以其他人的 `applicant_id` 新增預約 | Trigger 拒絕 |
| 學生 | 將自己的案件改為 `approved` | Trigger 拒絕 |
| 學生 | 查詢 `vw_course_info` | 拒絕 |
| 教師 | 查詢 `vw_course_info` 與 `vw_course_times` | 接受 |
| 教師 | 新增自己的 `pending` 長期借用 | 接受 |
| 教師 | 新增其他人的長期借用 | Trigger 拒絕 |
| 管理員 | 查詢及維護所有基礎資料表 | 接受 |
| 管理員 | 建立審核紀錄 | 僅 `reviewer_id` 對應 `admin` 時接受 |

## 4. View 安全設定

完整 View 建立語法位於 [`views.sql`](./views.sql)，亦已整合於 [`schema.sql`](./schema.sql)。

- `SQL SECURITY DEFINER`：使用 View 定義者的基礎資料表權限執行查詢，使學生及教師無須取得資料表直接讀取權限。
- `USER()`：取得實際登入帳號，依 `users.user_id` 過濾個人資料。
- `WITH CASCADED CHECK OPTION`：透過可更新 View 新增或修改資料時，修改後的資料仍必須符合 View 篩選條件。
- 欄位級 `INSERT`／`UPDATE`：學生及教師不能指定自動編號、建立時間、申請人異動或未授權關聯欄位。
- `SHOW CREATE VIEW view_name`：顯示 MariaDB 實際保存的 View Schema。

View 不能取代 Trigger。View 負責資料列可見範圍，Trigger 負責禁止冒用申請人、越權變更狀態、指定錯誤角色及建立衝突時段。

## 5. 十個 View 與呼叫方式

| 基礎資料表 | View | 可見範圍 | 呼叫語法 |
|---|---|---|---|
| `users` | `vw_users` | 一般使用者僅本人；管理員全部 | `SELECT * FROM vw_users;` |
| `classrooms` | `vw_classrooms` | 一般使用者僅啟用教室；管理員全部 | `SELECT * FROM vw_classrooms;` |
| `sections` | `vw_sections` | 全部節次 | `SELECT * FROM vw_sections ORDER BY section_id;` |
| `booking_statuses` | `vw_booking_statuses` | 全部狀態 | `SELECT * FROM vw_booking_statuses ORDER BY status_id;` |
| `course_info` | `vw_course_info` | 教師及管理員 | `SELECT * FROM vw_course_info;` |
| `course_times` | `vw_course_times` | 教師及管理員 | `SELECT * FROM vw_course_times;` |
| `long_term_bookings` | `vw_long_term_bookings` | 教師本人；管理員全部 | `SELECT * FROM vw_long_term_bookings ORDER BY created_at DESC;` |
| `bookings` | `vw_bookings` | 申請人本人；管理員全部 | `SELECT * FROM vw_bookings ORDER BY created_at DESC;` |
| `booking_reviews` | `vw_booking_reviews` | 申請案件相關歷程；管理員全部 | `SELECT * FROM vw_booking_reviews ORDER BY reviewed_at DESC;` |
| `notifications` | `vw_notifications` | 收件人本人；管理員全部 | `SELECT * FROM vw_notifications ORDER BY created_at DESC;` |

查看任一 View 的完整 Schema：

```sql
SHOW CREATE VIEW vw_bookings;
```

學生透過 View 建立預約：

```sql
INSERT INTO vw_bookings(
  applicant_id, classroom_id, booking_date,
  start_section_id, end_section_id, reason, status_id
) VALUES (
  '41243149', 'B205', DATE '2026-06-11',
  1, 2, '專題討論', 1
);
```

學生將自己的通知設為已讀：

```sql
UPDATE vw_notifications
SET is_read = TRUE
WHERE notification_id = 1;
```

## 6. Domain 與型態選擇

本 Schema 不以 `VARCHAR` 作為所有欄位的通用型別。型別必須反映資料的固定性、值域、運算方式及儲存語意。

| Domain | 採用型別 | 使用欄位 | 設計依據 |
|---|---|---|---|
| 固定長度校內識別碼 | `CHAR(8)` | `user_id`、教師、申請人、審核人及收件人外鍵 | 校內帳號規格固定為 8 碼；父鍵及所有外鍵使用相同型別 |
| 固定上限代碼 | `CHAR(10)`、`CHAR(20)` | 教室編號、課程編號、節次名稱、狀態名稱 | 代碼及短標籤長度受制度控制，避免為每列保存可變長度額外資訊 |
| 封閉集合 | `ENUM` | `users.role`、`booking_statuses.status_code` | 合法值固定且數量少，由資料庫拒絕集合外值 |
| 小範圍整數 | `TINYINT UNSIGNED` | 學期、星期、節次、狀態識別碼 | 值域小且不允許負數，型別直接表達 Domain |
| 人數 | `SMALLINT UNSIGNED` | `classrooms.capacity` | 教室容量不為負數，且不需要一般 `INT` 的大型範圍 |
| 民國學年度 | `SMALLINT UNSIGNED` | `course_info.academic_year` | 值如 `114` 並非西元年，不使用 MariaDB `YEAR`；另以 `CHECK 1..999` 限制 |
| 大量交易識別碼 | `BIGINT UNSIGNED AUTO_INCREMENT` | 課表時段、長期借用、預約、審核、通知主鍵 | 支援長期累積且不允許負數 |
| 布林狀態 | `BOOLEAN` | `is_active`、`is_read` | 明確表示真偽語意；MariaDB 內部以 `TINYINT(1)` 實作 |
| 不定長度敘述 | `TEXT` | 借用原因、審核意見、通知內容 | 內容長度差異大，不以任意 `VARCHAR(200)` 或 `VARCHAR(300)` 截斷業務文字 |
| 真正可變長度文字 | `VARCHAR` | 姓名、電子郵件、系所、課程名稱、教室名稱 | 長度無固定制度值，但仍需要合理上限、排序及唯一性檢查 |

### 為何仍保留部分 VARCHAR

「盡量避免 `VARCHAR`」不表示完全禁止使用。姓名、電子郵件、系所與課程名稱確實具有可變長度，使用 `CHAR` 會補齊空白並浪費空間；使用 `TEXT` 又會失去清楚的長度上限。此類欄位保留 `VARCHAR` 才符合資料語意。

`email` 採 `VARCHAR(254)`，對應一般電子郵件地址長度上限；`course_name`、`classroom_name`、`department` 與 `username` 依系統可接受內容設定明確上限。

## 7. 日期與時間型別

本系統不以「date」統稱所有時間資料。每個欄位依是否包含日期、時刻、絕對事件時間與時區轉換需求分別定義。

| 欄位 | 精確型別 | 保存內容 | 精度與格式 | 時區行為 |
|---|---|---|---|---|
| `sections.start_time` | `TIME(0)` | 每日節次開始的時刻 | 秒級，`HH:MM:SS`，不保存日期 | 無時區轉換 |
| `sections.end_time` | `TIME(0)` | 每日節次結束的時刻 | 秒級，`HH:MM:SS`，不保存日期 | 無時區轉換 |
| `long_term_bookings.start_date` | `DATE` | 長期借用第一個日曆日期 | 日級，`YYYY-MM-DD`，不保存時刻 | 無時區轉換 |
| `long_term_bookings.end_date` | `DATE` | 長期借用最後一個日曆日期 | 日級，`YYYY-MM-DD`，不保存時刻 | 無時區轉換 |
| `bookings.booking_date` | `DATE` | 教室實際使用的日曆日期 | 日級，`YYYY-MM-DD`，不保存時刻 | 無時區轉換 |
| `long_term_bookings.created_at` | `TIMESTAMP(6)` | 長期借用建立的事件時間 | 微秒級，`YYYY-MM-DD HH:MM:SS.ffffff` | 寫入時由連線時區轉 UTC，讀取時轉回連線時區 |
| `bookings.created_at` | `TIMESTAMP(6)` | 單次預約建立的事件時間 | 微秒級 | 同上 |
| `booking_reviews.reviewed_at` | `TIMESTAMP(6)` | 審核動作發生的事件時間 | 微秒級 | 同上 |
| `notifications.created_at` | `TIMESTAMP(6)` | 通知建立的事件時間 | 微秒級 | 同上 |

### TIME(0)

MariaDB `TIME` 同時可表達時刻與時間間隔，範圍可超過 24 小時。因此 Schema 另加 `CHECK`，限制節次必須位於 `00:00:00` 至 `23:59:59`，並要求 `start_time < end_time`。`(0)` 表示不保存小數秒，因課堂節次不需要微秒精度。

### DATE

借用日期只表示校曆上的某一天，不表示當天幾點，也不應因使用者時區而改變。因此使用 `DATE`，而不是 `DATETIME` 或 `TIMESTAMP`。SQL 應以完整四位年份輸入：

```sql
DATE '2026-06-11'
```

正式環境應啟用嚴格 SQL Mode 及 `NO_ZERO_DATE`、`NO_ZERO_IN_DATE`，拒絕 `0000-00-00` 或不完整日期。

### TIMESTAMP(6)

`created_at` 與 `reviewed_at` 表示事件發生的絕對時間，採 `TIMESTAMP(6)` 並明確指定：

```sql
created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
```

MariaDB 儲存時會依連線時區轉為 UTC，讀取時再轉為目前連線時區。應用程式連線後應設定時區，例如臺灣顯示需求可使用：

```sql
SET time_zone = '+08:00';
```

若跨系統交換資料，API 應輸出包含時區的 ISO 8601 格式，例如 `2026-06-10T10:30:15.123456+08:00`。

### 為何目前不使用 DATETIME

`DATETIME(6)` 可保存日期與時間，但 MariaDB 不會執行時區轉換，適合「不論所在地都固定顯示相同鐘面時間」的資料。本系統目前的日期欄位只需要 `DATE`，事件紀錄則需要可轉換時區的 `TIMESTAMP(6)`，因此沒有欄位需要 `DATETIME`。未來若新增「校方公告固定於當地時間生效」且不允許時區轉換的資料，才適合使用 `DATETIME(6)`。

## 8. 執行順序

```powershell
mariadb -u root -p -e "CREATE DATABASE IF NOT EXISTS classroom_rental CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mariadb -u root -p classroom_rental < schema.sql
mariadb -u root -p classroom_rental < examples.sql
mariadb -u root -p classroom_rental < security.sql
```

`views.sql` 是獨立重建 View 的腳本；完整安裝已由 `schema.sql` 建立相同的 10 個 View。

## 9. 官方文件依據

- [MariaDB Roles Overview](https://mariadb.com/docs/server/security/user-account-management/roles/roles_overview)
- [GRANT](https://mariadb.com/docs/server/reference/sql-statements/account-management-sql-statements/grant)
- [SET DEFAULT ROLE](https://mariadb.com/docs/server/reference/sql-statements/account-management-sql-statements/set-default-role)
- [CREATE VIEW](https://mariadb.com/docs/server/server-usage/views/create-view)
- [SHOW CREATE VIEW](https://mariadb.com/docs/server/reference/sql-statements/administrative-sql-statements/show/show-create-view)
- [DATE](https://mariadb.com/docs/server/reference/data-types/date-and-time-data-types/date)
- [TIME](https://mariadb.com/docs/server/reference/data-types/date-and-time-data-types/time)
- [DATETIME](https://mariadb.com/docs/server/reference/data-types/date-and-time-data-types/datetime)
- [TIMESTAMP](https://mariadb.com/docs/server/reference/data-types/date-and-time-data-types/timestamp)
- [YEAR](https://mariadb.com/docs/server/reference/data-types/date-and-time-data-types/year-data-type)
