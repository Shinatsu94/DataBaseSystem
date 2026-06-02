# 03. sections：節次

## 用途

保存學校定義的上課節次與起訖時間。其他實體只需參照節次編號，不必重複保存時間文字。

## 欄位表格

| 編號 | 欄位名稱 | 資料型別 | 必填 | 鍵值或參照 | 預設值 | 完整性限制 | 說明 |
|---|---|---|---|---|---|---|---|
| 1 | `section_id` | `INTEGER` | 是 | PK | 無 | 主鍵不可重複、不可為空值 | 節次編號 |
| 2 | `section_name` | `VARCHAR(20)` | 是 | UK | 無 | `NOT NULL`、`UNIQUE` | 節次名稱，例如 `第 1 節` |
| 3 | `start_time` | `CHAR(5)` | 是 | - | 無 | `NOT NULL` | 開始時間，例如 `08:10` |
| 4 | `end_time` | `CHAR(5)` | 是 | - | 無 | `NOT NULL`、`CHECK (start_time < end_time)` | 結束時間，必須晚於開始時間 |

## 關聯實體

| 關聯實體 | 關聯類型 | 對方外鍵 | 說明 |
|---|---|---|---|
| `course_times` | `sections` 1:N `course_times` | `start_section_id`、`end_section_id` → `sections.section_id` | 固定課表使用開始與結束節次 |
| `long_term_bookings` | `sections` 1:N `long_term_bookings` | `start_section_id`、`end_section_id` → `sections.section_id` | 長期借用使用開始與結束節次 |
| `bookings` | `sections` 1:N `bookings` | `start_section_id`、`end_section_id` → `sections.section_id` | 單次預約使用開始與結束節次 |

## 其他邏輯規則

| 規則 | 說明 |
|---|---|
| 節次名稱唯一 | `section_name` 使用 `UNIQUE`，避免重複定義同名節次。 |
| 時間範圍 | `start_time` 必須早於 `end_time`。 |
| 預約節次範圍 | 參照本實體的固定課表、長期借用與單次預約，皆限制開始節次不可晚於結束節次。 |
| 時間格式 | Schema 使用 `CHAR(5)` 保存時間，例如 `08:10`。輸入格式應由應用程式層執行驗證。 |
