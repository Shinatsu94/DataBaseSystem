# 08. `bookings` 單次預約

> [返回規格索引](資料表規格索引.md) | [返回專案總覽](../../README.md)

## 資料表用途

`bookings` 是系統的核心交易資料表。每筆資料表示特定日期、教室與節次範圍的一次借用申請或使用紀錄，無論來源是一般臨時申請、週期性借用展開或課程相關使用。

## 欄位規格與設計理由

| 欄位 | 型態 | 鍵值／預設 | 限制 | 系統用途 | 型態與限制理由 |
|---|---|---|---|---|---|
| `booking_id` | `BIGINT UNSIGNED` | PK、`AUTO_INCREMENT` | `NOT NULL` | 預約識別碼 | 預約會長期大量累積，使用大型無號代理鍵。 |
| `applicant_id` | `CHAR(8)` | FK | `NOT NULL` | 提出申請的學生或教師 | 與使用者主鍵型態一致；Trigger 防止冒用其他使用者。 |
| `classroom_id` | `VARCHAR(10)` | FK | `NOT NULL` | 借用教室 | 外鍵確保教室存在，Trigger 驗證教室是否啟用。 |
| `long_term_id` | `BIGINT UNSIGNED` | FK、`NULL` | 可為空 | 關聯週期性借用主紀錄 | 一般臨時申請沒有週期性來源，因此允許 `NULL`。 |
| `course_time_id` | `BIGINT UNSIGNED` | FK、`NULL` | 可為空 | 關聯特定固定課程時段 | 非課程用途沒有課程時段來源，因此允許 `NULL`。 |
| `booking_date` | `DATE` | 無 | `NOT NULL` | 實際借用日曆日期 | 日期不包含時刻，節次另由外鍵表示；不因時區轉換改變。 |
| `start_section_id` | `TINYINT UNSIGNED` | FK | `NOT NULL` | 借用開始節次 | 參照統一節次主資料。 |
| `end_section_id` | `TINYINT UNSIGNED` | FK | `NOT NULL`、不得早於開始節次 | 借用結束節次 | 以 `CHECK` 阻止反向節次。 |
| `reason` | `TEXT` | 無 | `NOT NULL` | 借用用途與行政審核依據 | 說明長度不固定，且申請不可缺少用途。 |
| `status_id` | `TINYINT UNSIGNED` | FK | `NOT NULL` | 現行處理狀態 | 狀態由主資料統一管理，避免直接保存不一致文字。 |
| `created_at` | `TIMESTAMP(6)` | `CURRENT_TIMESTAMP(6)` | `NOT NULL` | 申請建立事件時間 | 支援時區轉換、微秒排序及稽核。 |

## 嚴格值域與正則表達式限制

單次預約是系統核心交易資料，輸入規則必須在使用者送出申請前先完成驗證。

- `booking_id`：系統自動產生，不提供使用者輸入；若用於查詢條件，只接受正整數。正則：`^[1-9][0-9]{0,18}$`。
- `applicant_id`：使用 `users.user_id` 相同格式。正則：`^([0-9]{8}|[a-z][0-9]{5,7})$`，並須參照已存在的學生或教師帳號；一般使用者只能建立自己的預約。
- `classroom_id`：必須符合教室代碼格式。正則：`^[A-Z]{3}[0-9]{4}$`，並以外鍵參照啟用中的教室。
- `long_term_id`：可為 `NULL`；若填寫，只接受正整數。正則：`^$|^[1-9][0-9]{0,18}$`，並以外鍵參照 `long_term_bookings.long_term_id`。
- `course_time_id`：可為 `NULL`；若填寫，只接受正整數。正則：`^$|^[1-9][0-9]{0,18}$`，並以外鍵參照 `course_times.course_time_id`。
- `booking_date`：使用西元年月日 `YYYY-MM-DD`。正則：`^20[0-9]{2}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$`。後端需另行驗證實際日曆日期與是否允許預約過去日期。
- `start_section_id`：目前只接受一至十三節。正則：`^(?:[1-9]|1[0-3])$`，並以外鍵參照 `sections.section_id`。
- `end_section_id`：格式同 `start_section_id`，正則：`^(?:[1-9]|1[0-3])$`，且必須滿足 `start_section_id <= end_section_id`。
- `reason`：必須填寫五至五百字，允許中文、英文字母、數字、空白與常用標點。正則：`^[\p{Han}A-Za-z0-9，。；：、,.!?()（）《》「」\s\-_]{5,500}$`。資料庫以 `chk_bookings_reason_length` 檢查長度，完整字元集合由輸入層驗證；此欄位不得只填「借用」、「測試」或無法審核的空泛內容。
- `status_id`：必須為一至十的狀態主檔代碼。正則：`^(?:[1-9]|10)$`，一般使用者新增時只能送出 `pending` 對應狀態。
- `created_at`：由資料庫自動產生，不接受使用者輸入；若用於查詢條件，格式為 `YYYY-MM-DD HH:MM:SS[.ffffff]`。正則：`^20\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]) ([01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$`。

## 關聯

| 關聯實體 | 關聯類型 | 對方外鍵 | 說明 | 使用範例 |
|---|---|---|---|---|
| `users` | `users 1:N bookings` | `bookings.applicant_id` -> `users.user_id` | 一位使用者可提出多筆單次預約。 | `41243149` 可申請 `BGC0508` 教室借用。 |
| `classrooms` | `classrooms 1:N bookings` | `bookings.classroom_id` -> `classrooms.classroom_id` | 一間教室可累積多筆不同日期的預約。 | `BRA0102` 可被申請為 AI 研討會場勘。 |
| `sections` | `sections 1:N bookings` | `bookings.start_section_id` -> `sections.section_id` | 一個節次可作為多筆單次預約的開始節次。 | 第 8 節可作為 `BRA0102` 場勘開始節次。 |
| `sections` | `sections 1:N bookings` | `bookings.end_section_id` -> `sections.section_id` | 一個節次可作為多筆單次預約的結束節次。 | 第 9 節可作為 `BRA0102` 場勘結束節次。 |
| `booking_statuses` | `booking_statuses 1:N bookings` | `bookings.status_id` -> `booking_statuses.status_id` | 一種狀態可套用於多筆單次預約。 | `pending` 可代表單次預約待審核。 |
| `long_term_bookings` | `long_term_bookings 1:N bookings` | `bookings.long_term_id` -> `long_term_bookings.long_term_id` | 一筆長期借用可展開為多筆單次預約；此欄位可為空。 | 長期借用 `1` 可展開為 `2026-06-12` 的單次預約。 |
| `course_times` | `course_times 1:N bookings` | `bookings.course_time_id` -> `course_times.course_time_id` | 一筆固定課表可被多筆課程相關預約參照；此欄位可為空。 | 課程補課預約可連結原固定課表。 |
| `booking_reviews` | `bookings 1:N booking_reviews` | `booking_reviews.booking_id` -> `bookings.booking_id` | 一筆預約可保留多筆審核歷程。 | 預約 `3` 可留下場勘核准紀錄。 |
| `notifications` | `bookings 1:N notifications` | `notifications.booking_id` -> `bookings.booking_id` | 一筆預約可產生多則通知；此欄位可為空。 | 預約 `3` 可產生 `BRA0102` 場勘核准通知。 |

## 局部實體關聯圖

```mermaid
flowchart LR
    users["users<br/>使用者"]
    classrooms["classrooms<br/>教室"]
    sections["sections<br/>節次"]
    statuses["booking_statuses<br/>預約狀態"]
    long_term["long_term_bookings<br/>週期性借用"]
    course_times["course_times<br/>固定授課時段"]
    bookings["bookings<br/>單次預約<br/>PK booking_id"]
    reviews["booking_reviews<br/>審核歷程"]
    notifications["notifications<br/>通知"]

    users -->|"1 : N<br/>applicant_id 必填"| bookings
    classrooms -->|"1 : N<br/>classroom_id 必填"| bookings
    sections -->|"1 : N × 2<br/>起訖節次必填"| bookings
    statuses -->|"1 : N<br/>status_id 必填"| bookings
    long_term -.->|"1 : N<br/>long_term_id 可選參照"| bookings
    course_times -.->|"1 : N<br/>course_time_id 可選參照"| bookings
    bookings -->|"1 : N<br/>booking_id 審核歷程"| reviews
    bookings -.->|"1 : N<br/>booking_id 可選通知關聯"| notifications
```

指向 `bookings` 的實線為必填外鍵，虛線為可選來源；由 `bookings` 指向子實體的連線表示一筆預約可保留多次審核及多則通知。

## 其他邏輯規則

1. 學生與教師只能建立自己的 `pending` 預約。
2. 一般使用者只能修改或取消自己的待審核預約。
3. 停用教室不得接受新的待審核或已核准預約。
4. 只有 `approved` 會占用教室。
5. 已核准預約不得與相同教室、相同星期與重疊節次的固定課表衝突。
6. 已核准預約不得與相同教室、相同日期與重疊節次的其他已核准預約衝突。
7. 多筆尚未核准的申請可以並存，管理員核准時重新執行衝突檢查。

## 對應 View

```sql
SELECT * FROM vw_bookings ORDER BY created_at DESC;
```

一般使用者只會看見自己的預約；管理員可看見全部。

## 10 筆範例資料

| ID | 申請人 | 教室 | 日期／節次 | 狀態 |
|---:|---|---|---|---|
| 1 | 41243149 | BGC0508 | 2026-06-08／5–6 | approved |
| 2 | 41243154 | BGC0614 | 2026-06-08／1–2 | approved |
| 3 | b13001 | BRA0102 | 2026-06-08／8–9 | approved |
| 4 | 41243151 | BCB0303 | 2026-06-09／5–5 | approved |
| 5 | 41243149 | BGC0508 | 2026-06-12／5–6 | approved |
| 6 | 41243161 | BGC0614 | 2026-06-10／5–6 | pending |
| 7 | b13005 | BCB0305 | 2026-06-10／7–8 | rejected |
| 8 | 41243154 | BGC0513 | 2026-06-11／5–6 | canceled |
| 9 | b13023 | BGC0601 | 2026-06-12／1–2 | approved |
| 10 | 41243151 | BRA0201 | 2026-06-12／8–9 | pending |
