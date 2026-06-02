# 教室租用系統：實體資料表格

本資料夾將 `Part2_schema.sql` 的 10 個實體分別整理為獨立文件。每份文件皆包含用途、欄位表格、關聯實體與其他邏輯規則，供逐一檢核及納入報告使用。

## 實體一覽

| 編號 | 實體 | 中文名稱 | 用途 |
|---|---|---|---|
| 01 | [users](01_users.md) | 使用者 | 保存學生、教師與管理員資料 |
| 02 | [classrooms](02_classrooms.md) | 教室 | 保存可排課與借用的教室資料 |
| 03 | [sections](03_sections.md) | 節次 | 保存學校定義的上課節次 |
| 04 | [booking_statuses](04_booking_statuses.md) | 審核狀態 | 集中管理預約狀態 |
| 05 | [course_info](05_course_info.md) | 課程資訊 | 保存每學期課程與授課教師 |
| 06 | [course_times](06_course_times.md) | 固定授課時間 | 保存課程固定排課 |
| 07 | [long_term_bookings](07_long_term_bookings.md) | 長期借用 | 保存週期性借用計畫 |
| 08 | [bookings](08_bookings.md) | 單次預約 | 保存每次實際教室借用 |
| 09 | [booking_reviews](09_booking_reviews.md) | 審核歷程 | 保存管理員審核紀錄 |
| 10 | [notifications](10_notifications.md) | 通知 | 保存使用者通知與讀取狀態 |

## 完整性分類

| 類型 | 說明 |
|---|---|
| 實體完整性 | 每個資料表皆有主鍵，主鍵不可重複且不可為空值。 |
| 參照完整性 | 外鍵必須對應至已存在的父資料，例如預約申請人必須存在於 `users`。 |
| 域值完整性 | 使用 `NOT NULL`、`UNIQUE`、`DEFAULT` 與 `CHECK` 限制可接受的值。 |
| 商業規則完整性 | 使用 Trigger 阻擋固定課表與已核准預約的時段衝突。 |
