# 教室租用系統：詳細實體關聯圖

> [返回專案總覽](../../專案總覽.md) | [簡要 ER 圖](ER_Diagram.md) | [diagrams.net 原始檔](ER_Diagram_Detailed.drawio)

本圖依據 [`完整資料庫Schema.sql`](../../資料庫/完整資料庫Schema.sql) 繪製。實體方塊列出完整欄位與鍵值類型；每條線均直接標示 `1 : N`，虛線表示子實體外鍵允許 `NULL`。

```mermaid
flowchart LR
    users["<b>users 使用者</b><br/>PK user_id : CHAR(8)<br/>username : VARCHAR(60)<br/>UK email : VARCHAR(254)<br/>role : ENUM<br/>department : VARCHAR(80), NULL"]
    classrooms["<b>classrooms 教室</b><br/>PK classroom_id : VARCHAR(10)<br/>classroom_name : VARCHAR(80)<br/>capacity : SMALLINT UNSIGNED<br/>is_active : BOOLEAN"]
    sections["<b>sections 節次</b><br/>PK section_id : TINYINT UNSIGNED<br/>UK section_name : VARCHAR(20)<br/>start_time : TIME(0)<br/>end_time : TIME(0)"]
    statuses["<b>booking_statuses 預約狀態</b><br/>PK status_id : TINYINT UNSIGNED<br/>UK status_code : VARCHAR(32)<br/>status_name : VARCHAR(20)"]
    course_info["<b>course_info 課程資訊</b><br/>PK course_id : VARCHAR(20)<br/>academic_year : SMALLINT UNSIGNED<br/>semester : TINYINT UNSIGNED<br/>course_name : VARCHAR(120)<br/>FK teacher_id : CHAR(8)"]
    course_times["<b>course_times 固定授課時段</b><br/>PK course_time_id : BIGINT UNSIGNED<br/>FK course_id : VARCHAR(20)<br/>FK classroom_id : VARCHAR(10)<br/>day_of_week : TINYINT UNSIGNED<br/>FK start_section_id : TINYINT UNSIGNED<br/>FK end_section_id : TINYINT UNSIGNED"]
    long_term["<b>long_term_bookings 週期性借用</b><br/>PK long_term_id : BIGINT UNSIGNED<br/>FK applicant_id : CHAR(8)<br/>FK classroom_id : VARCHAR(10)<br/>start_date : DATE<br/>end_date : DATE<br/>day_of_week : TINYINT UNSIGNED<br/>FK start_section_id : TINYINT UNSIGNED<br/>FK end_section_id : TINYINT UNSIGNED<br/>reason : TEXT<br/>FK status_id : TINYINT UNSIGNED<br/>created_at : TIMESTAMP(6)"]
    bookings["<b>bookings 單次預約</b><br/>PK booking_id : BIGINT UNSIGNED<br/>FK applicant_id : CHAR(8)<br/>FK classroom_id : VARCHAR(10)<br/>FK long_term_id : BIGINT UNSIGNED, NULL<br/>FK course_time_id : BIGINT UNSIGNED, NULL<br/>booking_date : DATE<br/>FK start_section_id : TINYINT UNSIGNED<br/>FK end_section_id : TINYINT UNSIGNED<br/>reason : TEXT<br/>FK status_id : TINYINT UNSIGNED<br/>created_at : TIMESTAMP(6)"]
    reviews["<b>booking_reviews 審核歷程</b><br/>PK review_id : BIGINT UNSIGNED<br/>FK booking_id : BIGINT UNSIGNED<br/>FK reviewer_id : CHAR(8)<br/>FK status_id : TINYINT UNSIGNED<br/>comment : TEXT, NULL<br/>reviewed_at : TIMESTAMP(6)"]
    notifications["<b>notifications 通知</b><br/>PK notification_id : BIGINT UNSIGNED<br/>FK recipient_id : CHAR(8)<br/>FK booking_id : BIGINT UNSIGNED, NULL<br/>message : TEXT<br/>is_read : BOOLEAN<br/>created_at : TIMESTAMP(6)"]

    users -->|"1 : N<br/>teacher_id 教授"| course_info
    users -->|"1 : N<br/>applicant_id 提出週期性借用"| long_term
    users -->|"1 : N<br/>applicant_id 提出單次預約"| bookings
    users -->|"1 : N<br/>reviewer_id 執行審核"| reviews
    users -->|"1 : N<br/>recipient_id 接收通知"| notifications
    classrooms -->|"1 : N<br/>classroom_id 安排固定課表"| course_times
    classrooms -->|"1 : N<br/>classroom_id 提供週期性借用"| long_term
    classrooms -->|"1 : N<br/>classroom_id 提供單次預約"| bookings
    sections -->|"1 : N<br/>start_section_id 固定課表開始"| course_times
    sections -->|"1 : N<br/>end_section_id 固定課表結束"| course_times
    sections -->|"1 : N<br/>start_section_id 週期借用開始"| long_term
    sections -->|"1 : N<br/>end_section_id 週期借用結束"| long_term
    sections -->|"1 : N<br/>start_section_id 單次預約開始"| bookings
    sections -->|"1 : N<br/>end_section_id 單次預約結束"| bookings
    statuses -->|"1 : N<br/>status_id 週期性借用狀態"| long_term
    statuses -->|"1 : N<br/>status_id 單次預約狀態"| bookings
    statuses -->|"1 : N<br/>status_id 審核決策"| reviews
    course_info -->|"1 : N<br/>course_id 包含固定授課時段"| course_times
    course_times -.->|"1 : N<br/>course_time_id 可選參照"| bookings
    long_term -.->|"1 : N<br/>long_term_id 可選參照"| bookings
    bookings -->|"1 : N<br/>booking_id 保存審核歷程"| reviews
    bookings -.->|"1 : N<br/>booking_id 可選參照"| notifications

    classDef basic fill:#EAF2FF,stroke:#1F5AA6,stroke-width:1.5px,color:#102A43
    classDef transaction fill:#FFF4E5,stroke:#B26A00,stroke-width:1.5px,color:#4A2B00
    classDef core fill:#FDECEC,stroke:#B42318,stroke-width:2px,color:#5A1510
    class users,classrooms,sections,statuses basic
    class course_info,course_times,long_term,reviews,notifications transaction
    class bookings core
```

## 圖例

| 標示 | 意義 |
|---|---|
| `PK` | Primary Key，唯一識別資料列且不得為空。 |
| `FK` | Foreign Key，參照另一資料表的主鍵。 |
| `UK` | Unique Key，限制欄位值不得重複。 |
| `NULL` | 欄位允許空值，表示該關聯屬於選擇性參照。 |
| 實線 `1 : N` | 子實體外鍵必填。 |
| 虛線 `1 : N` | 子實體外鍵可為 `NULL`。 |

## 關聯基數

完整 Schema 共有 22 條外鍵關聯，全部屬於 `1:N`。系統未建立 `1:1` 關聯；需要表達多對多關係時，應先建立具有雙方外鍵的中介實體，再轉換為兩組 `1:N` 關聯。

## 可選參照

| 子實體欄位 | 父實體 | 使用情境 |
|---|---|---|
| `bookings.course_time_id` | `course_times` | 課程相關借用可連結固定授課時段；一般活動借用不需要此參照。 |
| `bookings.long_term_id` | `long_term_bookings` | 週期性借用展開的單次資料可連結主紀錄；臨時預約不需要此參照。 |
| `notifications.booking_id` | `bookings` | 預約處理通知連結案件；一般系統公告不需要此參照。 |
