# 04. booking_statuses：審核狀態

## 用途

集中保存預約狀態，避免各交易資料表重複輸入不一致的狀態文字。

## 欄位表格

| 編號 | 欄位名稱 | 資料型別 | 必填 | 鍵值或參照 | 預設值 | 完整性限制 | 說明 |
|---|---|---|---|---|---|---|---|
| 1 | `status_id` | `INTEGER` | 是 | PK | 無 | 主鍵不可重複、不可為空值 | 狀態識別碼 |
| 2 | `status_code` | `VARCHAR(10)` | 是 | UK | 無 | `NOT NULL`、`UNIQUE`、`CHECK (status_code IN ('pending', 'approved', 'rejected', 'canceled'))` | 程式使用的狀態代碼 |
| 3 | `status_name` | `VARCHAR(20)` | 是 | - | 無 | `NOT NULL` | 顯示名稱，例如待審核、已核准 |

## 關聯實體

| 關聯實體 | 關聯類型 | 對方外鍵 | 說明 |
|---|---|---|---|
| `long_term_bookings` | `booking_statuses` 1:N `long_term_bookings` | `long_term_bookings.status_id` → `booking_statuses.status_id` | 長期借用保存目前狀態 |
| `bookings` | `booking_statuses` 1:N `bookings` | `bookings.status_id` → `booking_statuses.status_id` | 單次預約保存目前狀態 |
| `booking_reviews` | `booking_statuses` 1:N `booking_reviews` | `booking_reviews.status_id` → `booking_statuses.status_id` | 審核歷程保存每次審核結果 |

## 其他邏輯規則

| 狀態代碼 | 中文意義 | 是否占用教室 | 說明 |
|---|---|---|---|
| `pending` | 待審核 | 否 | 可與其他待審核案件並存 |
| `approved` | 已核准 | 是 | Trigger 會檢查固定課表與其他已核准預約 |
| `rejected` | 已拒絕 | 否 | 不占用教室 |
| `canceled` | 已取消 | 否 | 不占用教室 |

`status_code` 使用 `UNIQUE` 與 `CHECK`，只能保存以上四種狀態代碼。
