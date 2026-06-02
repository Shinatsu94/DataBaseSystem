# 教室租用系統：實體關聯圖

本文件依據 `Part2_schema.sql` 繪製 Mermaid 實體關聯圖。圖中包含 10 個實體、主要欄位、鍵值類型與關聯基數。

## 實體關聯圖

```mermaid
erDiagram
    users {
        CHAR user_id PK "使用者識別碼，長度 8"
        VARCHAR username "使用者名稱，長度上限 30"
        VARCHAR email UK "電子郵件，長度上限 100"
        VARCHAR role "角色：student、teacher、admin"
        VARCHAR department "所屬系所或單位，可為 NULL"
    }

    classrooms {
        VARCHAR classroom_id PK "教室識別碼，長度上限 10"
        VARCHAR classroom_name "教室名稱，長度上限 50"
        INTEGER capacity "容納人數，必須大於 0"
        INTEGER is_active "啟用狀態：0 或 1"
    }

    sections {
        INTEGER section_id PK "節次識別碼"
        VARCHAR section_name UK "節次名稱，長度上限 20"
        CHAR start_time "開始時間，格式 HH:MM"
        CHAR end_time "結束時間，格式 HH:MM"
    }

    booking_statuses {
        INTEGER status_id PK "狀態識別碼"
        VARCHAR status_code UK "pending、approved、rejected、canceled"
        VARCHAR status_name "狀態顯示名稱，長度上限 20"
    }

    course_info {
        VARCHAR course_id PK "課程識別碼，長度上限 20"
        INTEGER academic_year "學年度"
        INTEGER semester "學期：1 或 2"
        VARCHAR course_name "課程名稱，長度上限 100"
        CHAR teacher_id FK "授課教師識別碼"
    }

    course_times {
        INTEGER course_time_id PK "固定授課時間識別碼，自動編號"
        VARCHAR course_id FK "課程識別碼"
        VARCHAR classroom_id FK "教室識別碼"
        INTEGER day_of_week "星期：1 至 7"
        INTEGER start_section_id FK "開始節次"
        INTEGER end_section_id FK "結束節次"
    }

    long_term_bookings {
        INTEGER long_term_id PK "長期借用識別碼，自動編號"
        CHAR applicant_id FK "申請人識別碼"
        VARCHAR classroom_id FK "教室識別碼"
        DATE start_date "借用開始日期"
        DATE end_date "借用結束日期"
        INTEGER day_of_week "星期：1 至 7"
        INTEGER start_section_id FK "開始節次"
        INTEGER end_section_id FK "結束節次"
        VARCHAR reason "借用原因，長度上限 200"
        INTEGER status_id FK "狀態識別碼"
        DATETIME created_at "建立時間"
    }

    bookings {
        INTEGER booking_id PK "單次預約識別碼，自動編號"
        CHAR applicant_id FK "申請人識別碼"
        VARCHAR classroom_id FK "教室識別碼"
        INTEGER long_term_id FK "長期借用識別碼，可為 NULL"
        INTEGER course_time_id FK "固定授課時間識別碼，可為 NULL"
        DATE booking_date "實際借用日期"
        INTEGER start_section_id FK "開始節次"
        INTEGER end_section_id FK "結束節次"
        VARCHAR reason "借用原因，長度上限 200"
        INTEGER status_id FK "狀態識別碼"
        DATETIME created_at "建立時間"
    }

    booking_reviews {
        INTEGER review_id PK "審核紀錄識別碼，自動編號"
        INTEGER booking_id FK "單次預約識別碼"
        CHAR reviewer_id FK "審核人員識別碼"
        INTEGER status_id FK "審核結果狀態識別碼"
        VARCHAR comment "審核備註，長度上限 300，可為 NULL"
        DATETIME reviewed_at "審核時間"
    }

    notifications {
        INTEGER notification_id PK "通知識別碼，自動編號"
        CHAR recipient_id FK "收件人識別碼"
        INTEGER booking_id FK "單次預約識別碼，可為 NULL"
        VARCHAR message "通知內容，長度上限 300"
        INTEGER is_read "讀取狀態：0 或 1"
        DATETIME created_at "建立時間"
    }

    users ||--o{ course_info : "教授"
    users ||--o{ long_term_bookings : "提出長期借用"
    users ||--o{ bookings : "提出單次預約"
    users ||--o{ booking_reviews : "執行審核"
    users ||--o{ notifications : "接收通知"

    classrooms ||--o{ course_times : "安排固定課表"
    classrooms ||--o{ long_term_bookings : "提供長期借用"
    classrooms ||--o{ bookings : "提供單次預約"

    sections ||--o{ course_times : "作為固定課表開始節次"
    sections ||--o{ course_times : "作為固定課表結束節次"
    sections ||--o{ long_term_bookings : "作為長期借用開始節次"
    sections ||--o{ long_term_bookings : "作為長期借用結束節次"
    sections ||--o{ bookings : "作為單次預約開始節次"
    sections ||--o{ bookings : "作為單次預約結束節次"

    booking_statuses ||--o{ long_term_bookings : "定義長期借用狀態"
    booking_statuses ||--o{ bookings : "定義單次預約狀態"
    booking_statuses ||--o{ booking_reviews : "定義審核結果"

    course_info ||--o{ course_times : "包含固定授課時間"
    course_times o|--o{ bookings : "作為課程相關借用依據"
    long_term_bookings o|--o{ bookings : "展開為單次預約"
    bookings ||--o{ booking_reviews : "保留審核歷程"
    bookings o|--o{ notifications : "產生預約相關通知"
```

## 關聯基數說明

| Mermaid 符號 | 意義 |
|---|---|
| `||` | 必須且僅能對應一筆資料 |
| `o|` | 得對應零筆或一筆資料 |
| `o{` | 得對應零筆或多筆資料 |

## 設計說明

| 項目 | 說明 |
|---|---|
| 主鍵 | 每個實體皆具有主鍵，以維持實體完整性。 |
| 外鍵 | 關聯欄位以外鍵連結父實體，以維持參照完整性。 |
| 唯一鍵 | `users.email`、`sections.section_name` 與 `booking_statuses.status_code` 使用唯一鍵，避免重複資料。 |
| 可選關聯 | `bookings.long_term_id`、`bookings.course_time_id` 與 `notifications.booking_id` 允許為空值，因此其父實體關聯以 `o|` 表示。 |
| 衝突驗證 | Mermaid 圖呈現資料結構；固定課表與預約時段之衝突驗證由 `Part2_schema.sql` 內的觸發器執行。 |
