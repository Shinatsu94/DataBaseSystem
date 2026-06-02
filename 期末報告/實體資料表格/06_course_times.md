# 06. course_times：固定授課時間

## 用途

保存課程固定排課資訊，包括課程、教室、星期與節次範圍。

## 欄位表格

| 編號 | 欄位名稱 | 資料型別 | 必填 | 鍵值或參照 | 預設值 | 完整性限制 | 說明 |
|---|---|---|---|---|---|---|---|
| 1 | `course_time_id` | `INTEGER` | 是 | PK | 自動編號 | `PRIMARY KEY AUTOINCREMENT` | 固定授課時間識別碼 |
| 2 | `course_id` | `VARCHAR(20)` | 是 | FK → `course_info.course_id` | 無 | `NOT NULL`、外鍵參照必須存在 | 所屬課程 |
| 3 | `classroom_id` | `VARCHAR(10)` | 是 | FK → `classrooms.classroom_id` | 無 | `NOT NULL`、外鍵參照必須存在 | 授課教室 |
| 4 | `day_of_week` | `INTEGER` | 是 | - | 無 | `NOT NULL`、`CHECK (day_of_week BETWEEN 1 AND 7)` | 星期：`1` 為星期一，`7` 為星期日 |
| 5 | `start_section_id` | `INTEGER` | 是 | FK → `sections.section_id` | 無 | `NOT NULL`、外鍵參照必須存在 | 開始節次 |
| 6 | `end_section_id` | `INTEGER` | 是 | FK → `sections.section_id` | 無 | `NOT NULL`、外鍵參照必須存在、`CHECK (start_section_id <= end_section_id)` | 結束節次 |

## 關聯實體

| 關聯實體 | 關聯類型 | 本實體外鍵或對方外鍵 | 說明 |
|---|---|---|---|
| `course_info` | `course_info` 1:N `course_times` | `course_times.course_id` → `course_info.course_id` | 每筆固定時段隸屬一門課程 |
| `classrooms` | `classrooms` 1:N `course_times` | `course_times.classroom_id` → `classrooms.classroom_id` | 每筆固定時段使用一間教室 |
| `sections` | `sections` 1:N `course_times` | `start_section_id`、`end_section_id` → `sections.section_id` | 每筆固定時段指定開始與結束節次 |
| `bookings` | `course_times` 1:N `bookings` | `bookings.course_time_id` → `course_times.course_time_id` | 課程相關之額外借用得參照固定授課時間 |

## 其他邏輯規則

| 規則 | 說明 |
|---|---|
| 星期範圍 | `day_of_week` 必須介於 `1` 至 `7`，`1` 為星期一，`7` 為星期日。 |
| 節次範圍 | `start_section_id` 不可大於 `end_section_id`。 |
| 固定課表衝突 | 同一教室、同一星期的固定課表不可發生節次重疊。 |
| 預約衝突 | 新增或修改固定課表時，不可與同一教室、相同星期、節次重疊的已核准預約衝突。 |
| 觸發器 | `trg_course_times_prevent_overlap_insert` 與 `trg_course_times_prevent_overlap_update` 負責執行衝突驗證。 |
