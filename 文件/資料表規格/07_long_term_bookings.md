# 07. `long_term_bookings` 週期性借用

> [返回規格索引](資料表規格索引.md) | [返回專案總覽](../../專案總覽.md)

## 資料表用途

`long_term_bookings` 保存指定日期範圍內、每週固定一天與固定節次的借用規則。它是週期性借用的主紀錄；每個實際使用日期仍由 `bookings` 保存，以便逐日執行衝突與審核管理。

## 欄位規格與設計理由

| 欄位 | 型態 | 鍵值／預設 | 限制 | 系統用途 | 型態與限制理由 |
|---|---|---|---|---|---|
| `long_term_id` | `BIGINT UNSIGNED` | PK、`AUTO_INCREMENT` | `NOT NULL` | 週期性借用識別碼 | 交易資料會長期累積，使用大型無號代理鍵。 |
| `applicant_id` | `CHAR(8)` | FK | `NOT NULL` | 申請教師 | 與使用者主鍵型態一致；外鍵確保申請人存在，Trigger 限制教師角色。 |
| `classroom_id` | `VARCHAR(10)` | FK | `NOT NULL` | 固定借用教室 | 參照教室主資料，避免保存無效代碼。 |
| `start_date` | `DATE` | 無 | `NOT NULL` | 規則生效的第一個日曆日期 | 不包含時刻且不應受時區影響，因此使用 `DATE`。 |
| `end_date` | `DATE` | 無 | `NOT NULL`、不得早於開始日期 | 規則生效的最後一個日曆日期 | 與開始日期使用相同 Domain，日期範圍由 `CHECK` 保護。 |
| `day_of_week` | `TINYINT UNSIGNED` | 無 | `NOT NULL`、`CHECK 1..7` | 每週固定使用日 | 小範圍非負值可直接對應星期。 |
| `start_section_id` | `TINYINT UNSIGNED` | FK | `NOT NULL` | 每次借用開始節次 | 參照統一節次主資料。 |
| `end_section_id` | `TINYINT UNSIGNED` | FK | `NOT NULL`、不得早於開始節次 | 每次借用結束節次 | 以範圍檢查阻止反向節次。 |
| `reason` | `TEXT` | 無 | `NOT NULL` | 週期性借用用途 | 用途說明長度差異大，不以任意短字數截斷；申請必須提出理由。 |
| `status_id` | `TINYINT UNSIGNED` | FK | `NOT NULL` | 現行處理狀態 | 狀態由 `booking_statuses` 集中管理。 |
| `created_at` | `TIMESTAMP(6)` | `CURRENT_TIMESTAMP(6)` | `NOT NULL` | 建立事件時間 | 事件時間需要時區轉換與高解析度排序，因此保留六位小數秒。 |

## 關聯

- `users 1:N long_term_bookings`
- `classrooms 1:N long_term_bookings`
- `sections 1:N long_term_bookings`
- `booking_statuses 1:N long_term_bookings`
- `long_term_bookings 1:N bookings`

## 其他邏輯規則

1. 學生不能建立週期性借用。
2. 教師只能建立自己的 `pending` 資料，並只能修改或取消自己的待審核資料。
3. 管理員可處理全部狀態與申請人資料。
4. `start_date <= end_date`。
5. `start_section_id <= end_section_id`。
6. 展開為單次預約時，每個實際日期都必須重新接受固定課表與已核准預約衝突檢查。

## 對應 View

```sql
SELECT * FROM vw_long_term_bookings ORDER BY created_at DESC;
```

教師只會看見自己的資料；管理員可看見全部。

## 10 筆範例資料

| ID | 申請人 | 教室 | 星期／節次 | 狀態 |
|---:|---|---|---|---|
| 1 | T0000001 | A101 | 週一 5–6 | approved |
| 2 | T0000002 | A102 | 週二 1–2 | pending |
| 3 | T0000003 | B201 | 週三 5–6 | under_review |
| 4 | T0000004 | B202 | 週四 1–2 | approved |
| 5 | T0000001 | B205 | 週五 5–6 | rejected |
| 6 | T0000002 | C301 | 週一 1–2 | canceled |
| 7 | T0000003 | C302 | 週二 1–2 | expired |
| 8 | T0000004 | D401 | 週三 1–2 | completed |
| 9 | T0000001 | LAB501 | 週四 5–6 | suspended |
| 10 | T0000002 | CONF01 | 週五 3–4 | resubmission_required |
