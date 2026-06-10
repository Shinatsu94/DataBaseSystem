# 教室租用系統：實體關聯圖

本文件依據 [`完整資料庫Schema.sql`](../../資料庫/完整資料庫Schema.sql) 繪製 Mermaid 實體關聯圖。為提升報告與簡報之可讀性，線段中央明確標示 `1 : N`。允許空值之外鍵參照使用虛線表示。

完整欄位、資料型別與限制條件位於 [資料表詳細規格](../資料表規格/README.md)，含欄位之詳細圖面位於 [詳細實體關聯圖](ER_Diagram_Detailed.md)。

## 實體關聯圖

```mermaid
flowchart LR
    users["users<br/>使用者<br/>PK: user_id"]
    classrooms["classrooms<br/>教室<br/>PK: classroom_id"]
    sections["sections<br/>節次<br/>PK: section_id"]
    statuses["booking_statuses<br/>審核狀態<br/>PK: status_id"]

    course_info["course_info<br/>課程資訊<br/>PK: course_id"]
    course_times["course_times<br/>固定授課時間<br/>PK: course_time_id"]
    long_term["long_term_bookings<br/>長期借用<br/>PK: long_term_id"]
    bookings["bookings<br/>單次預約<br/>PK: booking_id"]
    reviews["booking_reviews<br/>審核歷程<br/>PK: review_id"]
    notifications["notifications<br/>通知<br/>PK: notification_id"]

    users -->|"1 : N<br/>教授"| course_info
    users -->|"1 : N<br/>提出長期借用"| long_term
    users -->|"1 : N<br/>提出單次預約"| bookings
    users -->|"1 : N<br/>執行審核"| reviews
    users -->|"1 : N<br/>接收通知"| notifications

    classrooms -->|"1 : N<br/>安排固定課表"| course_times
    classrooms -->|"1 : N<br/>提供長期借用"| long_term
    classrooms -->|"1 : N<br/>提供單次預約"| bookings

    sections -->|"1 : N<br/>開始與結束節次"| course_times
    sections -->|"1 : N<br/>開始與結束節次"| long_term
    sections -->|"1 : N<br/>開始與結束節次"| bookings

    statuses -->|"1 : N<br/>定義長期借用狀態"| long_term
    statuses -->|"1 : N<br/>定義單次預約狀態"| bookings
    statuses -->|"1 : N<br/>定義審核結果"| reviews

    course_info -->|"1 : N<br/>包含固定授課時間"| course_times
    course_times -.->|"1 : N<br/>可選課程參照"| bookings
    long_term -.->|"1 : N<br/>可選長期借用參照"| bookings
    bookings -->|"1 : N<br/>保留審核歷程"| reviews
    bookings -.->|"1 : N<br/>可選預約參照"| notifications

    classDef basic fill:#EAF2FF,stroke:#1F5AA6,stroke-width:1.5px,color:#102A43
    classDef transaction fill:#FFF4E5,stroke:#B26A00,stroke-width:1.5px,color:#4A2B00
    classDef core fill:#FDECEC,stroke:#B42318,stroke-width:2px,color:#5A1510

    class users,classrooms,sections,statuses basic
    class course_info,course_times,long_term,reviews,notifications transaction
    class bookings core
```

## 線段說明

| 線段樣式 | 標示 | 意義 |
|---|---|---|
| 實線 | `1 : N` | 一筆父實體資料得對應多筆子實體資料；子實體之外鍵為必填欄位。 |
| 虛線 | `1 : N` 與「可選參照」 | 一筆父實體資料得對應多筆子實體資料；子實體之外鍵允許為空值。 |

## 關聯類型說明

| 關聯類型 | 本系統是否存在 | 說明 |
|---|---|---|
| `1 : N` | 是 | 本系統現有關聯皆屬一對多關聯。 |
| `1 : 1` | 否 | Schema 未定義任一一對一關聯。 |
| `N : N` | 否 | Schema 未直接定義多對多關聯；多對多需求須以中介實體轉換為兩組一對多關聯。 |

## 可選參照說明

| 子實體欄位 | 父實體 | 說明 |
|---|---|---|
| `bookings.course_time_id` | `course_times` | 非課程相關借用無須參照固定授課時間。 |
| `bookings.long_term_id` | `long_term_bookings` | 一般單次預約無須參照長期借用。 |
| `notifications.booking_id` | `bookings` | 一般系統通知無須參照單次預約。 |
