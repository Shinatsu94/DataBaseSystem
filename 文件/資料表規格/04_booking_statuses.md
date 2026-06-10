# 04. `booking_statuses` 預約狀態

> [返回規格索引](資料表規格索引.md) | [返回專案總覽](../../專案總覽.md)

## 資料表用途

`booking_statuses` 集中管理週期性借用、單次預約與審核歷程使用的狀態。狀態文字不直接重複寫入交易資料，所有交易只保存 `status_id`。

## 欄位規格與設計理由

| 欄位 | 型態 | 鍵值／預設 | 限制 | 系統用途 | 型態與限制理由 |
|---|---|---|---|---|---|
| `status_id` | `TINYINT UNSIGNED` | PK | `NOT NULL` | 狀態外鍵識別碼 | 狀態數量有限且不得為負值，小型無號整數足以表示。 |
| `status_code` | `VARCHAR(32)` | UK | `NOT NULL`、`UNIQUE`、十種代碼 `CHECK` | 程式流程與 API 使用的穩定代碼 | `draft` 與 `resubmission_required` 長度不同，因此使用可變長度文字；唯一與檢查限制阻擋重複或未定義代碼。 |
| `status_name` | `VARCHAR(20)` | 無 | `NOT NULL` | 介面顯示的中文名稱 | 顯示名稱長度可變且每個狀態都必須具有可讀名稱。 |

## 為何不使用 ENUM

本表本身即為正規化的狀態 Domain。若 `status_code` 再使用 `ENUM`，每次新增狀態都必須同時修改資料表型態與狀態資料，造成重複維護。因此採 `VARCHAR(32)` 配合 `UNIQUE` 與 `CHECK`，由本表統一管理狀態。

## 關聯

| 子資料表 | 外鍵 | 基數 |
|---|---|---|
| `long_term_bookings` | `status_id` | `1:N` |
| `bookings` | `status_id` | `1:N` |
| `booking_reviews` | `status_id` | `1:N` |

## 其他邏輯規則

1. `approved` 表示教室已被占用，寫入時必須執行衝突檢查。
2. `draft` 尚未進入審核流程。
3. `pending` 與 `under_review` 尚未取得教室使用權。
4. `completed`、`rejected`、`canceled`、`expired` 為終止或結案狀態。
5. `suspended` 與 `resubmission_required` 表示流程暫停，需後續行政處理。

## 對應 View

```sql
SELECT * FROM vw_booking_statuses ORDER BY status_id;
```

## 10 筆範例資料

| ID | 代碼 | 中文名稱 |
|---:|---|---|
| 1 | draft | 草稿 |
| 2 | pending | 待審核 |
| 3 | under_review | 審核中 |
| 4 | approved | 已核准 |
| 5 | rejected | 已拒絕 |
| 6 | canceled | 已取消 |
| 7 | expired | 已逾期 |
| 8 | completed | 已完成 |
| 9 | suspended | 已暫停 |
| 10 | resubmission_required | 待補件 |
