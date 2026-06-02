# 10. notifications：通知

## 用途

保存預約狀態通知與讀取狀態，供系統顯示使用者未讀取之訊息。

## 欄位表格

| 編號 | 欄位名稱 | 資料型別 | 必填 | 鍵值或參照 | 預設值 | 完整性限制 | 說明 |
|---|---|---|---|---|---|---|---|
| 1 | `notification_id` | `INTEGER` | 是 | PK | 自動編號 | `PRIMARY KEY AUTOINCREMENT` | 通知識別碼 |
| 2 | `recipient_id` | `CHAR(8)` | 是 | FK → `users.user_id` | 無 | `NOT NULL`、外鍵參照必須存在 | 收件人 |
| 3 | `booking_id` | `INTEGER` | 否 | FK → `bookings.booking_id` | `NULL` | 欄位具有值時，外鍵參照必須存在 | 對應預約；一般系統通知允許為空值 |
| 4 | `message` | `VARCHAR(300)` | 是 | - | 無 | `NOT NULL` | 通知內容 |
| 5 | `is_read` | `INTEGER` | 是 | - | `0` | `NOT NULL`、`CHECK (is_read IN (0, 1))` | 讀取狀態：`0` 為未讀，`1` 為已讀 |
| 6 | `created_at` | `DATETIME` | 是 | - | `CURRENT_TIMESTAMP` | `NOT NULL` | 建立時間 |

## 關聯實體

| 關聯實體 | 關聯類型 | 本實體外鍵 | 說明 |
|---|---|---|---|
| `users` | `users` 1:N `notifications` | `recipient_id` → `users.user_id` | 每則通知寄送給一位使用者 |
| `bookings` | `bookings` 1:N `notifications` | `booking_id` → `bookings.booking_id` | 預約相關通知得連結至對應預約 |

## 其他邏輯規則

| 規則 | 說明 |
|---|---|
| 可選預約 | `booking_id` 允許為空值，以支援不屬於特定預約之一般系統通知。 |
| 讀取狀態 | `is_read` 只能為 `0` 或 `1`，預設值為 `0`。 |
| 建立時間 | `created_at` 預設為新增通知時的 `CURRENT_TIMESTAMP`。 |
| 查詢索引 | `idx_notifications_recipient_read` 可加速查詢指定使用者的未讀通知。 |
