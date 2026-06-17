# Part2：完整資料庫 Schema SQL 與舉例說明

本文件對應專案總攬中的「完整 DB Schema 架構」、「各實體與資料表設計」、「SQL：概念層到關聯式 Schema」與「範例資料」等內容，作為期末專題 Part2 的獨立閱讀版本。

## 對映專案總攬章節

| Part2 項目 | 專案總攬對應章節 | 說明 |
|---|---|---|
| 完整資料庫 Schema | [完整 DB Schema 架構](../專案總攬/專案總覽.md#完整-db-schema-架構) | 說明資料表分層、欄位型態、鍵值與限制。 |
| SQL 語法建立 Schema | [SQL：概念層到關聯式 Schema](../專案總攬/專案總覽.md#sql概念層到關聯式-schema) | 說明概念層實體如何轉換成 MariaDB 關聯式資料表。 |
| Schema 詳細說明 | [各實體與資料表設計](../專案總攬/專案總覽.md#各實體與資料表設計) | 連結 10 張資料表的用途、欄位、關聯與限制理由。 |
| 舉例說明 | [範例資料](../專案總攬/專案總覽.md#範例資料) | 使用預設資料與查詢範例說明資料表如何被操作。 |

## Part2 檔案

| 檔案 | 說明 |
|---|---|
| [完整資料庫Schema.sql](完整資料庫Schema.sql) | 建立 `classroom_rental` 資料庫、10 張資料表、Trigger、View、索引與 Role。 |
| [範例資料.sql](範例資料.sql) | 匯入每張資料表至少 10 筆相互一致的預設資料。 |
| [完整資料庫Schema架構與說明.md](完整資料庫Schema架構與說明.md) | 說明 Schema 設計方法、型態選擇、完整性限制、View 與權限。 |

## Schema 設計方法

資料庫採用 MariaDB，並以概念層、邏輯層、實體層與操作層四個層次描述。

| 層次 | 說明 | 對應內容 |
|---|---|---|
| 概念層 | 定義使用者、教室、節次、課程、預約、審核、通知等實體 | ER Diagram 與資料表分類 |
| 邏輯層 | 將實體轉換為資料表、主鍵、外鍵與關聯基數 | 10 張資料表與 Foreign Key |
| 實體層 | 使用 MariaDB SQL 建立資料型態、限制、索引與 Trigger | `完整資料庫Schema.sql` |
| 操作層 | 透過 View、Role 與範例資料示範查詢與操作方式 | `範例資料.sql`、View、GRANT |

## SQL 建立順序

`完整資料庫Schema.sql` 的建立順序如下：

1. 建立資料庫與字元集設定。
2. 建立基礎資料表：`users`、`classrooms`、`sections`、`booking_statuses`。
3. 建立課程與預約資料表：`course_info`、`course_times`、`long_term_bookings`、`bookings`。
4. 建立審核與通知資料表：`booking_reviews`、`notifications`。
5. 建立 Trigger，檢查教師身分、時段重疊與審核限制。
6. 建立索引與 View。
7. 建立 MariaDB Role 並授權。

## SQL 舉例說明

以 `bookings` 為例，單次預約資料表會同時參照使用者、教室、長期借用、課程時段、節次與預約狀態。

```sql
CREATE TABLE bookings (
    booking_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    applicant_id CHAR(8) NOT NULL,
    classroom_id VARCHAR(10) NOT NULL,
    long_term_id BIGINT UNSIGNED NULL,
    course_time_id BIGINT UNSIGNED NULL,
    booking_date DATE NOT NULL,
    start_section_id TINYINT UNSIGNED NOT NULL,
    end_section_id TINYINT UNSIGNED NOT NULL,
    reason TEXT NOT NULL,
    status_id TINYINT UNSIGNED NOT NULL,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
);
```

此資料表的設計重點：

| 欄位或限制 | 用途 |
|---|---|
| `booking_id` | 作為單次預約的唯一識別。 |
| `applicant_id` | 參照 `users.user_id`，記錄申請人。 |
| `classroom_id` | 參照 `classrooms.classroom_id`，記錄借用教室。 |
| `long_term_id` | 可為 `NULL`，代表此筆預約可由長期借用展開，也可獨立存在。 |
| `course_time_id` | 可為 `NULL`，代表此筆預約可對應課程固定時段，也可為一般借用。 |
| `booking_date` | 使用 `DATE` 記錄實際借用日期，不包含時間，時間由節次控制。 |
| `start_section_id`、`end_section_id` | 參照 `sections`，避免直接輸入不一致的時間文字。 |
| `status_id` | 參照 `booking_statuses`，使狀態資料可集中維護。 |

## 匯入範例資料

Part2 的範例資料可用於展示 10 張資料表之間的關聯一致性：

```powershell
mariadb -u root -p < "Part2/完整資料庫Schema.sql"
mariadb -u root -p < "Part2/範例資料.sql"
```

匯入後可用下列查詢檢查主要資料：

```sql
USE classroom_rental;
SELECT COUNT(*) AS booking_count FROM bookings;
SELECT booking_id, applicant_id, classroom_id, booking_date, status_id
FROM bookings
ORDER BY booking_id;
```
