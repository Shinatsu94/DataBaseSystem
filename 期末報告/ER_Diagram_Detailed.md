# 教室租用系統：詳細實體關聯圖

本文件依據 `Part2_schema.sql` 繪製詳細版 Mermaid 實體關聯圖。各實體方塊列出完整欄位、資料型別與鍵值類型；線段中央標示 `1 : N`。允許空值之外鍵參照使用虛線表示。

適合簡報使用之精簡版本位於 [`ER_Diagram.md`](./ER_Diagram.md)。

## 詳細實體關聯圖

```mermaid
flowchart LR
    users["<b>users 使用者</b><br/>PK user_id : CHAR(8)<br/>username : VARCHAR(30)<br/>UK email : VARCHAR(100)<br/>role : VARCHAR(10)<br/>department : VARCHAR(50), NULL"]

    classrooms["<b>classrooms 教室</b><br/>PK classroom_id : VARCHAR(10)<br/>classroom_name : VARCHAR(50)<br/>capacity : INTEGER<br/>is_active : INTEGER"]

    sections["<b>sections 節次</b><br/>PK section_id : INTEGER<br/>UK section_name : VARCHAR(20)<br/>start_time : CHAR(5)<br/>end_time : CHAR(5)"]

    statuses["<b>booking_statuses 審核狀態</b><br/>PK status_id : INTEGER<br/>UK status_code : VARCHAR(10)<br/>status_name : VARCHAR(20)"]

    course_info["<b>course_info 課程資訊</b><br/>PK course_id : VARCHAR(20)<br/>academic_year : INTEGER<br/>semester : INTEGER<br/>course_name : VARCHAR(100)<br/>FK teacher_id : CHAR(8)"]

    course_times["<b>course_times 固定授課時間</b><br/>PK course_time_id : INTEGER<br/>FK course_id : VARCHAR(20)<br/>FK classroom_id : VARCHAR(10)<br/>day_of_week : INTEGER<br/>FK start_section_id : INTEGER<br/>FK end_section_id : INTEGER"]

    long_term["<b>long_term_bookings 長期借用</b><br/>PK long_term_id : INTEGER<br/>FK applicant_id : CHAR(8)<br/>FK classroom_id : VARCHAR(10)<br/>start_date : DATE<br/>end_date : DATE<br/>day_of_week : INTEGER<br/>FK start_section_id : INTEGER<br/>FK end_section_id : INTEGER<br/>reason : VARCHAR(200)<br/>FK status_id : INTEGER<br/>created_at : DATETIME"]

    bookings["<b>bookings 單次預約</b><br/>PK booking_id : INTEGER<br/>FK applicant_id : CHAR(8)<br/>FK classroom_id : VARCHAR(10)<br/>FK long_term_id : INTEGER, NULL<br/>FK course_time_id : INTEGER, NULL<br/>booking_date : DATE<br/>FK start_section_id : INTEGER<br/>FK end_section_id : INTEGER<br/>reason : VARCHAR(200)<br/>FK status_id : INTEGER<br/>created_at : DATETIME"]

    reviews["<b>booking_reviews 審核歷程</b><br/>PK review_id : INTEGER<br/>FK booking_id : INTEGER<br/>FK reviewer_id : CHAR(8)<br/>FK status_id : INTEGER<br/>comment : VARCHAR(300), NULL<br/>reviewed_at : DATETIME"]

    notifications["<b>notifications 通知</b><br/>PK notification_id : INTEGER<br/>FK recipient_id : CHAR(8)<br/>FK booking_id : INTEGER, NULL<br/>message : VARCHAR(300)<br/>is_read : INTEGER<br/>created_at : DATETIME"]

    users -->|"1 : N<br/>teacher_id 教授"| course_info
    users -->|"1 : N<br/>applicant_id 提出長期借用"| long_term
    users -->|"1 : N<br/>applicant_id 提出單次預約"| bookings
    users -->|"1 : N<br/>reviewer_id 執行審核"| reviews
    users -->|"1 : N<br/>recipient_id 接收通知"| notifications

    classrooms -->|"1 : N<br/>classroom_id 安排固定課表"| course_times
    classrooms -->|"1 : N<br/>classroom_id 提供長期借用"| long_term
    classrooms -->|"1 : N<br/>classroom_id 提供單次預約"| bookings

    sections -->|"1 : N<br/>start_section_id 固定課表開始節次"| course_times
    sections -->|"1 : N<br/>end_section_id 固定課表結束節次"| course_times
    sections -->|"1 : N<br/>start_section_id 長期借用開始節次"| long_term
    sections -->|"1 : N<br/>end_section_id 長期借用結束節次"| long_term
    sections -->|"1 : N<br/>start_section_id 單次預約開始節次"| bookings
    sections -->|"1 : N<br/>end_section_id 單次預約結束節次"| bookings

    statuses -->|"1 : N<br/>status_id 定義長期借用狀態"| long_term
    statuses -->|"1 : N<br/>status_id 定義單次預約狀態"| bookings
    statuses -->|"1 : N<br/>status_id 定義審核結果"| reviews

    course_info -->|"1 : N<br/>course_id 包含固定授課時間"| course_times
    course_times -.->|"1 : N<br/>course_time_id 可選課程參照"| bookings
    long_term -.->|"1 : N<br/>long_term_id 可選長期借用參照"| bookings
    bookings -->|"1 : N<br/>booking_id 保留審核歷程"| reviews
    bookings -.->|"1 : N<br/>booking_id 可選預約參照"| notifications

    classDef basic fill:#EAF2FF,stroke:#1F5AA6,stroke-width:1.5px,color:#102A43
    classDef transaction fill:#FFF4E5,stroke:#B26A00,stroke-width:1.5px,color:#4A2B00
    classDef core fill:#FDECEC,stroke:#B42318,stroke-width:2px,color:#5A1510

    class users,classrooms,sections,statuses basic
    class course_info,course_times,long_term,reviews,notifications transaction
    class bookings core
```

## 鍵值標記

| 標記 | 名稱 | 說明 |
|---|---|---|
| `PK` | Primary Key | 主鍵，用於唯一識別每筆資料。 |
| `FK` | Foreign Key | 外鍵，用於參照其他實體。 |
| `UK` | Unique Key | 唯一鍵，用於限制欄位值不得重複。 |
| `NULL` | Nullable | 欄位允許為空值。 |

## 線段說明

| 線段樣式 | 標示 | 意義 |
|---|---|---|
| 實線 | `1 : N` | 一筆父實體資料得對應多筆子實體資料；子實體之外鍵為必填欄位。 |
| 虛線 | `1 : N` 與「可選參照」 | 一筆父實體資料得對應多筆子實體資料；子實體之外鍵允許為空值。 |

## 可選參照說明

| 子實體欄位 | 父實體 | 說明 |
|---|---|---|
| `bookings.course_time_id` | `course_times` | 非課程相關借用無須參照固定授課時間。 |
| `bookings.long_term_id` | `long_term_bookings` | 一般單次預約無須參照長期借用。 |
| `notifications.booking_id` | `bookings` | 一般系統通知無須參照單次預約。 |

## 關聯類型說明

本系統現有關聯皆屬 `1 : N`。目前未設置 `1 : 1` 或 `N : N` 關聯。
