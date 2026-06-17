# 完整資料庫 Schema 架構與說明

> [返回專案總覽](../../專案總覽.md) | [完整 Schema SQL](../../資料庫/完整資料庫Schema.sql) | [範例資料](../../資料庫/範例資料.sql)

## 文件目的

本文件集中說明教室租用系統的完整資料庫 Schema。可執行的資料表、限制、Trigger、索引、View 與角色權限全部集中於 [`完整資料庫Schema.sql`](../../資料庫/完整資料庫Schema.sql)，避免多份 Schema 產生版本差異。

## 架構分層

| 層級 | 設計內容 | 實作成果 |
|---|---|---|
| 概念層 | 實體、屬性、關聯及基數 | 10 個實體與 `1:N` 關聯 |
| 邏輯層 | 關聯式資料表、主鍵、外鍵及正規化 | 10 張資料表 |
| 實體層 | MariaDB 型態、限制、索引、Trigger、字元集及儲存引擎 | 完整 DDL |
| 存取層 | 角色、View、資料列過濾及欄位級權限 | 3 個 Role、10 個 View |

## 正規化與責任分離

資料模型依第三正規化原則分離重複資料與不同責任：

1. 使用者姓名、角色與信箱只保存於 `users`。
2. 教室名稱、容量與啟用狀態只保存於 `classrooms`。
3. 節次起訖時間只保存於 `sections`。
4. 預約生命週期代碼只保存於 `booking_statuses`。
5. 課程基本資料與固定授課時段分為 `course_info`、`course_times`。
6. 週期性借用規則與實際日期預約分為 `long_term_bookings`、`bookings`。
7. 現行狀態與歷次審核決策分為 `bookings`、`booking_reviews`。
8. 通知內容獨立保存於 `notifications`，不直接寫入預約資料。

## 資料表總覽

| 資料表 | 主鍵 | 主要外鍵 | 用途 |
|---|---|---|---|
| `users` | `user_id` | 無 | 使用者身分與聯絡資料 |
| `classrooms` | `classroom_id` | 無 | 教室主資料 |
| `sections` | `section_id` | 無 | 節次主資料 |
| `booking_statuses` | `status_id` | 無 | 預約生命週期狀態 |
| `course_info` | `course_id` | `teacher_id` | 課程及授課教師 |
| `course_times` | `course_time_id` | 課程、教室、起訖節次 | 固定課表 |
| `long_term_bookings` | `long_term_id` | 申請人、教室、起訖節次、狀態 | 週期性借用規則 |
| `bookings` | `booking_id` | 申請人、教室、週期性借用、課程時段、起訖節次、狀態 | 實際日期預約 |
| `booking_reviews` | `review_id` | 預約、審核人、狀態 | 審核歷程 |
| `notifications` | `notification_id` | 收件人、預約 | 通知與讀取狀態 |

完整逐欄規格位於 [資料表規格索引](../資料表規格/資料表規格索引.md)。

## 型態選擇規則

| 資料特性 | 型態 | 使用理由 |
|---|---|---|
| 固定八碼校內帳號 | `CHAR(8)` | 所有合法帳號均為八碼，固定長度可直接表達 Domain。 |
| 長度可變的代碼或名稱 | `VARCHAR(n)` | 教室代碼、課程代碼、姓名及狀態代碼長度不完全相同，使用 `CHAR` 會產生不必要的補白。 |
| 固定角色集合 | `ENUM` | 系統角色只有學生、教師、管理員三種，集合穩定且數量有限。 |
| 小範圍非負整數 | `TINYINT UNSIGNED` | 學期、星期、節次與狀態編號不需要負數或大型範圍。 |
| 教室容量與民國學年度 | `SMALLINT UNSIGNED` | 範圍足夠且禁止負值。 |
| 長期累積交易識別碼 | `BIGINT UNSIGNED AUTO_INCREMENT` | 支援大量預約、審核與通知資料。 |
| 長度不固定的敘述 | `TEXT` | 借用原因、審核意見及通知內容不應受任意短字數限制。 |
| 真偽狀態 | `BOOLEAN` | 清楚表示啟用及已讀語意。 |
| 每日時刻 | `TIME(0)` | 保存秒級鐘面時刻，不包含日期與時區。 |
| 日曆日期 | `DATE` | 保存借用日期，不包含時刻且不因時區改變。 |
| 事件時間 | `TIMESTAMP(6)` | 保存建立、審核及通知的事件瞬間，保留六位小數秒。 |

## 完整性限制

### 實體完整性

每張資料表均具有 `PRIMARY KEY`。自然識別碼用於 `users`、`classrooms`、`course_info`；長期累積交易使用自動遞增數值主鍵。

### 參照完整性

所有外鍵由 `InnoDB` 執行檢查。Schema 未設定自動串聯刪除，刪除父資料時預設採 `RESTRICT` 行為，避免預約、審核與通知歷程被連帶刪除。

### Domain 完整性

| 限制 | 套用資料 |
|---|---|
| `chk_users_id_format` | 學號為八位數字；教職員帳號為一個大寫英文字母加五至七位數字。 |
| `chk_classrooms_capacity` | 教室容量必須大於零。 |
| `chk_sections_clock_time` | 節次時刻限制於單一日的 `00:00:00` 至 `23:59:59`。 |
| `chk_sections_range` | 開始時刻必須早於結束時刻。 |
| `chk_statuses_code` | 狀態代碼限於十種正式生命週期狀態。 |
| `chk_course_info_academic_year` | 民國學年度限制於 `1` 至 `999`。 |
| `chk_course_info_semester` | 學期只接受 `1` 或 `2`。 |
| 星期檢查 | 星期值限制於 `1` 至 `7`。 |
| 節次範圍檢查 | 開始節次不得晚於結束節次。 |
| 日期範圍檢查 | 週期性借用開始日期不得晚於結束日期。 |

## 預約狀態生命週期

| ID | 代碼 | 名稱 | 意義 |
|---:|---|---|---|
| 1 | `draft` | 草稿 | 尚未送出審核 |
| 2 | `pending` | 待審核 | 已送出並等待處理 |
| 3 | `under_review` | 審核中 | 管理員正在確認資料或設備 |
| 4 | `approved` | 已核准 | 已取得教室使用權，納入衝突檢查 |
| 5 | `rejected` | 已拒絕 | 申請未通過 |
| 6 | `canceled` | 已取消 | 申請人或管理員取消 |
| 7 | `expired` | 已逾期 | 使用日期已過且未取得有效核准 |
| 8 | `completed` | 已完成 | 教室使用已完成 |
| 9 | `suspended` | 已暫停 | 因設備、場地或行政因素暫停 |
| 10 | `resubmission_required` | 待補件 | 需要補充資料後重新送審 |

只有 `approved` 會在新增或修改時占用教室並觸發完整時段衝突檢查。

## Trigger

| Trigger | 時機 | 驗證內容 |
|---|---|---|
| `trg_course_info_validate_teacher_insert` | 新增課程前 | 授課者必須是教師；教師帳號只能建立指派給自己的課程。 |
| `trg_course_info_validate_teacher_update` | 修改課程前 | 維持授課教師角色與資料所有權。 |
| `trg_course_times_prevent_overlap_insert` | 新增固定課表前 | 阻擋同教室、同星期、重疊節次的固定課表或已核准預約。 |
| `trg_course_times_prevent_overlap_update` | 修改固定課表前 | 修改後仍須符合課表與預約衝突限制。 |
| `trg_long_term_validate_insert` | 新增週期性借用前 | 學生不得申請；教師只能建立自己的待審核資料。 |
| `trg_long_term_validate_update` | 修改週期性借用前 | 教師只能修改或取消自己的待審核資料。 |
| `trg_bookings_prevent_overlap_insert` | 新增單次預約前 | 驗證申請人、教室啟用狀態、申請所有權及核准時段衝突。 |
| `trg_bookings_prevent_overlap_update` | 修改單次預約前 | 驗證狀態轉換、資料所有權、教室狀態及核准時段衝突。 |
| `trg_reviews_validate_insert` | 新增審核歷程前 | 審核人必須是管理員。 |
| `trg_reviews_validate_update` | 修改審核歷程前 | 修改後的審核人仍必須是管理員。 |

## 索引

| 索引 | 欄位 | 查詢用途 |
|---|---|---|
| `idx_bookings_classroom_date` | 教室、日期、起訖節次 | 教室可用性與時段衝突查詢 |
| `idx_bookings_applicant_date` | 申請人、日期 | 個人預約歷史 |
| `idx_course_times_classroom_weekday` | 教室、星期、起訖節次 | 固定課表與衝突查詢 |
| `idx_notifications_recipient_read` | 收件人、已讀狀態 | 個人未讀通知 |

## View

所有 View 使用 `SQL SECURITY DEFINER`。一般帳號不需要基礎資料表權限，由 View 定義者權限執行查詢；資料列條件仍以實際登入帳號 `USER()` 判斷。

| View | 資料範圍 | 可更新性 |
|---|---|---|
| `vw_users` | 本人；管理員全部 | 僅供查詢 |
| `vw_classrooms` | 啟用教室；管理員全部 | 管理員可直接管理基礎表 |
| `vw_sections` | 全部節次 | 查詢 |
| `vw_booking_statuses` | 全部狀態 | 查詢 |
| `vw_course_info` | 全部課程，僅教師與管理員獲授權 | 查詢 |
| `vw_course_times` | 全部固定課表，僅教師與管理員獲授權 | 查詢 |
| `vw_long_term_bookings` | 教師本人；管理員全部 | 教師可新增及修改獲授權欄位 |
| `vw_bookings` | 申請人本人；管理員全部 | 學生與教師可新增及修改獲授權欄位 |
| `vw_booking_reviews` | 申請人相關歷程；管理員全部 | 查詢 |
| `vw_notifications` | 收件人本人；管理員全部 | 使用者只能修改 `is_read` |

View 結構查詢：

```sql
SHOW CREATE VIEW vw_bookings;
```

## Role 與最小權限

| Role | 直接基礎表權限 | View 權限 |
|---|---|---|
| `classroom_student_role` | 無 | 公開主資料、個人預約、審核結果與通知 |
| `classroom_teacher_role` | 無 | 繼承學生權限，增加課程及個人週期性借用 |
| `classroom_admin_role` | 全部資料表 `SELECT/INSERT/UPDATE/DELETE` | 全部 View |

教師繼承學生角色，管理員繼承教師角色。一般帳號名稱必須與 `users.user_id` 相同，View 才能正確執行個人資料隔離。

## 執行順序

```powershell
mariadb -u root -p < "資料庫/完整資料庫Schema.sql"
mariadb -u root -p < "資料庫/範例資料.sql"
mariadb -u root -p < "資料庫/查詢與View範例.sql"
```

## 範例資料規格

[`範例資料.sql`](../../資料庫/範例資料.sql) 對 10 張資料表各建立至少 10 筆具體資料。資料載入使用交易控制，任何一筆違反限制時可避免留下部分完成的資料集。

## 參考資料

完整參考資料及查閱日期統一列於 [專案總覽最後一節](../../專案總覽.md#參考資料)。
