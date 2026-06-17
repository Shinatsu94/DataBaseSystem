# Part3：SQL 概念層、預設資料匯入與 View 查詢說明

本文件對應專案總攬中的「SQL：概念層到關聯式 Schema」、「範例資料」、「View Schema 與呼叫」、「執行方式」與「驗證結果」等內容，作為期末專題 Part3 的獨立閱讀版本。

## 對映專案總攬章節

| Part3 項目 | 專案總攬對應章節 | 說明 |
|---|---|---|
| SQL 語法涵蓋概念層 | [SQL：概念層到關聯式 Schema](../README.md#sql概念層到關聯式-schema) | 說明概念層實體如何落實為 MariaDB Schema。 |
| 預設資料匯入 | [範例資料](../README.md#範例資料) | 說明如何匯入每張資料表至少 10 筆資料。 |
| View Schema 與呼叫 | [View Schema 與呼叫](../README.md#view-schema-與呼叫) | 說明 View 的用途、呼叫方式與 `SHOW CREATE VIEW`。 |
| 執行與驗證 | [執行方式](../README.md#執行方式) 與 [驗證結果](../README.md#驗證結果) | 說明建立資料庫、匯入資料與檢查結果的流程。 |

## Part3 檔案

| 檔案 | 說明 |
|---|---|
| [完整資料庫Schema.sql](完整資料庫Schema.sql) | 建立完整 MariaDB Schema、Trigger、View、Role 與權限。 |
| [範例資料.sql](範例資料.sql) | 匯入 10 張資料表的預設資料。 |
| [查詢與View範例.sql](查詢與View範例.sql) | 執行概念層查詢、每個 View 的查詢與 `SHOW CREATE VIEW`。 |
| [DB Schema 建立.md](<DB Schema 建立.md>) | 逐段說明 `完整資料庫Schema.sql` 中資料庫建立、十個實體、限制條件、觸發器、索引、View 與權限設定的用途。 |
| [匯入預設資料.md](匯入預設資料.md) | 逐段說明 `範例資料.sql` 中每一個實體的匯入順序、資料用途、外鍵依據與驗證查詢。 |
| [建立 View 查詢.md](<建立 View 查詢.md>) | 逐段說明 `查詢與View範例.sql` 中概念層查詢、每個 View 的呼叫方式與 View Schema 查詢。 |
| [驗證說明.md](驗證說明.md) | 記錄 Schema、資料筆數、View 與權限驗證結果。 |
| [參考資料](參考資料/) | 存放課程指定 PDF 與 PowerPoint 參考來源。 |

## SQL 概念層對應

概念層先定義「使用者、教室、節次、狀態、課程、預約、審核、通知」等實體，再於 SQL 中建立對應資料表。

| 概念層實體 | 關聯式資料表 | 主要用途 |
|---|---|---|
| 使用者 | `users` | 保存學生、教師、管理員的基本資料與角色。 |
| 教室 | `classrooms` | 保存教室代號、名稱、容量與是否可用。 |
| 節次 | `sections` | 保存每一節課的開始與結束時間。 |
| 預約狀態 | `booking_statuses` | 保存預約流程中的狀態代碼。 |
| 課程 | `course_info` | 保存課程年度、學期、課名與授課教師。 |
| 課程時段 | `course_times` | 保存課程固定上課教室、星期與節次。 |
| 長期借用 | `long_term_bookings` | 保存週期性借用申請。 |
| 單次預約 | `bookings` | 保存實際日期的單次教室借用。 |
| 審核歷程 | `booking_reviews` | 保存管理員審核紀錄。 |
| 通知 | `notifications` | 保存使用者通知與讀取狀態。 |

## DB Schema 建立、匯入預設資料、建立 View 查詢

Part3 的 SQL 執行流程分為三個部分，必須依照順序執行。

| 執行順序 | 部分名稱 | 對應 SQL 檔案 | 詳細說明 |
|---|---|---|---|
| 1 | DB Schema 建立 | `完整資料庫Schema.sql` | [DB Schema 建立.md](<DB Schema 建立.md>) |
| 2 | 匯入預設資料 | `範例資料.sql` | [匯入預設資料.md](匯入預設資料.md) |
| 3 | 建立 View 查詢 | `查詢與View範例.sql` | [建立 View 查詢.md](<建立 View 查詢.md>) |

第一步 `DB Schema 建立` 負責建立資料庫、資料表、完整性限制、觸發器、索引、View 與角色權限。第二步 `匯入預設資料` 負責依照外鍵相依順序匯入十個實體的預設資料。第三步 `建立 View 查詢` 負責示範概念層查詢、實際呼叫每個 View，並查詢 View 的 Schema 定義。

```powershell
mariadb -u root -p < "Part3/完整資料庫Schema.sql"
mariadb -u root -p < "Part3/範例資料.sql"
mariadb -u root -p < "Part3/查詢與View範例.sql"
```

若已登入 MariaDB，也可以使用：

```sql
SOURCE Part3/完整資料庫Schema.sql;
SOURCE Part3/範例資料.sql;
SOURCE Part3/查詢與View範例.sql;
```

上述三個指令只是實際執行方式；每一段程式碼的欄位用途、限制條件、關聯依據、範例資料用途與 View 查詢意義，分別記錄於 `DB Schema 建立`、`匯入預設資料`、`建立 View 查詢` 三份說明文件中。

匯入後可先確認資料庫與資料表：

```sql
SHOW DATABASES LIKE 'classroom_rental';
USE classroom_rental;
SHOW TABLES;
```

## 查詢每個 View

每個實體皆提供對應 View，可用於權限控管與資料展示。

```sql
USE classroom_rental;

SELECT * FROM vw_users;
SELECT * FROM vw_classrooms;
SELECT * FROM vw_sections;
SELECT * FROM vw_booking_statuses;
SELECT * FROM vw_course_info;
SELECT * FROM vw_course_times;
SELECT * FROM vw_long_term_bookings;
SELECT * FROM vw_bookings;
SELECT * FROM vw_booking_reviews;
SELECT * FROM vw_notifications;
```

## 查詢 View Schema

使用 `SHOW CREATE VIEW` 可檢查每個 View 的實際 SQL 定義。

```sql
SHOW CREATE VIEW vw_users;
SHOW CREATE VIEW vw_classrooms;
SHOW CREATE VIEW vw_sections;
SHOW CREATE VIEW vw_booking_statuses;
SHOW CREATE VIEW vw_course_info;
SHOW CREATE VIEW vw_course_times;
SHOW CREATE VIEW vw_long_term_bookings;
SHOW CREATE VIEW vw_bookings;
SHOW CREATE VIEW vw_booking_reviews;
SHOW CREATE VIEW vw_notifications;
```

## View 使用範例

查詢近期預約：

```sql
SELECT booking_id, applicant_id, classroom_id, booking_date, status_id, created_at
FROM vw_bookings
ORDER BY booking_date, start_section_id;
```

查詢使用者通知：

```sql
SELECT notification_id, recipient_id, booking_id, message, is_read, created_at
FROM vw_notifications
ORDER BY created_at DESC;
```

查詢審核歷程：

```sql
SELECT review_id, booking_id, reviewer_id, status_id, comment, reviewed_at
FROM vw_booking_reviews
ORDER BY reviewed_at DESC;
```

## 驗證重點

Part3 驗證時應確認：

1. 10 張資料表皆建立完成。
2. 10 個 View 皆可查詢。
3. 每張資料表至少匯入 10 筆資料。
4. Trigger 可阻擋重複教室時段與不合理審核資料。
5. 學生、教師、管理員 Role 可依權限查詢或操作指定 View 與資料表。

## 參考資料

| 參考資料 | 類型 | 用途 |
|---|---|---|
| [Appendix B: Summary of the Database Design](<參考資料/Appendix B Summary of the database design.pdf>) | PDF | 作為資料庫設計摘要與 Schema 架構整理依據。 |
| [Appendix E: Common Data Models](<參考資料/Appendix E Common data models.pdf>) | PDF | 作為常見資料模型與欄位設計參考。 |
| [Appendix E 20210511](<參考資料/Appendix E 20210511.pptx>) | PowerPoint | 作為課程指定資料庫設計與展示格式參考。 |
