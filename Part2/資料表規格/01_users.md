# 01. `users` 使用者

> [返回規格索引](資料表規格索引.md) | [返回專案總覽](../../README.md)

## 資料表用途

`users` 是全系統的身分主資料。課程授課教師、借用申請人、審核人員與通知收件人均透過外鍵參照本表，避免在交易資料中重複保存姓名、角色與電子郵件。

## 欄位規格與設計理由

| 欄位 | 型態 | 鍵值／預設 | 限制 | 系統用途 | 型態與限制理由 |
|---|---|---|---|---|---|
| `user_id` | `CHAR(8)` | PK | `NOT NULL`、帳號格式 `CHECK` | 使用者與 MariaDB 登入帳號的共同識別碼 | 學號及教職員帳號長度有上限，使用固定長度型態；主鍵確保每位使用者唯一。 |
| `username` | `VARCHAR(60)` | 無 | `NOT NULL`、姓名長度 `CHECK` | 顯示申請人、教師及審核人姓名 | 姓名長度不固定，使用有上限的可變長度文字；資料庫以 `chk_users_username_length` 排除過短或空白姓名。 |
| `email` | `VARCHAR(254)` | UK | `NOT NULL`、`UNIQUE`、Email 格式 `CHECK` | 通知地址及帳號聯絡資料 | 電子郵件長度可變；`chk_users_email_format` 檢查基本格式，唯一限制防止多個帳號共用同一地址。 |
| `role` | `ENUM('student','teacher','admin')` | 無 | `NOT NULL` | 決定申請、查詢與管理權限 | 角色集合固定為三種，`ENUM` 可在資料庫層拒絕其他值。 |
| `department` | `VARCHAR(80)` | `NULL` | 可為空、單位長度 `CHECK` | 所屬系所或行政單位 | 單位名稱長度不固定；外部或尚未分派單位的帳號可暫不填寫，若填寫則由 `chk_users_department_length` 檢查長度。 |

## 嚴格值域與正則表達式限制

以下正則表達式應同時用於前端表單與後端 API 驗證；已可由資料庫直接限制者，需同步保留於 MariaDB `CHECK`、`ENUM`、`UNIQUE` 或外鍵限制中。

- `user_id`：只允許學生八碼數字或教職員小寫英文字母加五至七碼數字。正則：`^([0-9]{8}|[a-z][0-9]{5,7})$`。資料庫已以 `chk_users_id_format` 檢查此格式，範例包含 `41243149`、`b13005`、`e13006`。
- `username`：只允許中文、英文字母與姓名分隔符號，不允許數字、Email、表情符號或控制字元。正則：`^[\p{Han}A-Za-z·．・]{2,60}$`。資料庫以 `chk_users_username_length` 檢查長度，完整字元集合由前端表單與後端 API 驗證。
- `email`：必須為一般電子郵件格式，且全表唯一。正則：`^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,63}$`。資料庫以 `chk_users_email_format` 檢查格式，並以 `UNIQUE` 防止重複。
- `role`：只能為 `student`、`teacher`、`admin`。正則：`^(student|teacher|admin)$`。資料庫以 `ENUM` 限制身份值域。
- `department`：可為 `NULL`；若填寫，只允許中文、英文字母、數字、空白、括號與校內單位常用字詞，長度二至八十字。正則：`^$|^[\p{Han}A-Za-z0-9（）()學院系所科中心處室組 -]{2,80}$`。資料庫以 `chk_users_department_length` 檢查長度，完整字元集合由輸入層驗證。

## 檢查位置與驗證方式

`users` 的格式與長度檢查位於 [`../完整資料庫Schema.sql`](../完整資料庫Schema.sql#L58) 的 `CREATE TABLE users` 區塊內，屬於 MariaDB 資料表層級的 `CHECK` Constraint。其他正則、檢查限制與 Trigger 的位置可見 [檢查限制與正則表達式索引](檢查限制與正則索引.md)。

```sql
CONSTRAINT chk_users_id_format CHECK (
  BINARY user_id REGEXP '^([0-9]{8}|[a-z][0-9]{5,7})$'
),
CONSTRAINT chk_users_email_format CHECK (
  email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,63}$'
)
```

驗證方式如下：

1. 新增或更新 `users.user_id` 時，MariaDB 會自動執行此 `CHECK`。
2. `BINARY user_id` 使正則比對採大小寫敏感方式執行，避免資料庫排序規則 `utf8mb4_unicode_ci` 將 `T13005` 與 `t13005` 視為相同字母而通過大小寫檢查。
3. `41243149` 符合 `[0-9]{8}`，因此可作為學生帳號。
4. `b13005`、`e13006` 符合 `[a-z][0-9]{5,7}`，因此可作為教職員帳號。
5. `T13005` 不符合小寫字母規則，會在 `INSERT` 或 `UPDATE` 時被 `chk_users_id_format` 拒絕。
6. `invalid.teacher` 不符合 Email 格式，會在 `INSERT` 或 `UPDATE` 時被 `chk_users_email_format` 拒絕。

可使用下列 SQL 查看資料庫實際建立的限制：

```sql
SHOW CREATE TABLE users;
```

也可使用下列測試確認限制是否生效：

```sql
-- 應失敗：教職員帳號首字母不可為大寫。
INSERT INTO users (user_id, username, email, role, department)
VALUES ('T13005', '測試教師', 'invalid.teacher@example.edu.tw', 'teacher', '資訊工程系');

-- 應失敗：Email 必須包含帳號、@、網域與有效頂層網域。
INSERT INTO users (user_id, username, email, role, department)
VALUES ('t13005', '測試教師', 'invalid.teacher', 'teacher', '資訊工程系');

-- 應成功：教職員帳號首字母為小寫。
INSERT INTO users (user_id, username, email, role, department)
VALUES ('b99001', '測試教師', 'valid.teacher@example.edu.tw', 'teacher', '資訊工程系');
```

## 關聯

| 關聯實體 | 關聯類型 | 對方外鍵 | 說明 | 使用範例 |
|---|---|---|---|---|
| `course_info` | `users 1:N course_info` | `course_info.teacher_id` -> `users.user_id` | 一位教師可教授多門課程。 | 教師 `b13005` 可對應資料庫系統課程。 |
| `long_term_bookings` | `users 1:N long_term_bookings` | `long_term_bookings.applicant_id` -> `users.user_id` | 一位使用者可提出多筆長期借用。 | `b13001` 可申請產學合作週會。 |
| `bookings` | `users 1:N bookings` | `bookings.applicant_id` -> `users.user_id` | 一位使用者可提出多筆單次預約。 | `41243149` 可申請 `BGC0508` 教室借用。 |
| `booking_reviews` | `users 1:N booking_reviews` | `booking_reviews.reviewer_id` -> `users.user_id` | 一位管理員可執行多次審核。 | 管理員 `e13006` 可留下多筆審核紀錄。 |
| `notifications` | `users 1:N notifications` | `notifications.recipient_id` -> `users.user_id` | 一位使用者可接收多則通知。 | `41243149` 可收到核准通知及長期借用通知。 |

## 局部實體關聯圖

```mermaid
flowchart LR
    users["users<br/>使用者<br/>PK user_id"]
    course_info["course_info<br/>課程資訊"]
    long_term["long_term_bookings<br/>週期性借用"]
    bookings["bookings<br/>單次預約"]
    reviews["booking_reviews<br/>審核歷程"]
    notifications["notifications<br/>通知"]

    users -->|"1 : N<br/>teacher_id 授課教師"| course_info
    users -->|"1 : N<br/>applicant_id 週期申請人"| long_term
    users -->|"1 : N<br/>applicant_id 單次申請人"| bookings
    users -->|"1 : N<br/>reviewer_id 審核人"| reviews
    users -->|"1 : N<br/>recipient_id 收件人"| notifications
```

所有連線均為必填外鍵關聯；角色是否符合教師或管理員身分，另由 Trigger 驗證。

## 其他邏輯規則

1. `course_info.teacher_id` 必須參照 `role = 'teacher'` 的使用者。
2. `booking_reviews.reviewer_id` 必須參照 `role = 'admin'` 的使用者。
3. 一般 MariaDB 帳號名稱必須與 `user_id` 相同，個人 View 才能正確過濾資料。
4. 刪除已被交易資料參照的使用者會被外鍵拒絕，以保留歷史紀錄。

## 對應 View

```sql
SELECT * FROM vw_users;
SHOW CREATE VIEW vw_users;
```

學生與教師只會看見自己的資料；管理員可看見全部使用者。

## 範例資料

| `user_id` | 姓名 | 角色 | 單位 |
|---|---|---|---|
| 41225244 | 劉哲瑋 | student | 電機工程系 |
| 41243149 | 廖章竹 | student | 資訊工程系 |
| 41243151 | 劉向榮 | student | 資訊工程系 |
| 41243154 | 蔡品辰 | student | 資訊工程系 |
| 41243161 | 羅冠穎 | student | 資訊工程系 |
| b13001 | 鄭錦聰 | teacher | 資訊工程系 |
| b13005 | 江季翰 | teacher | 資訊工程系 |
| b13007 | 林易泉 | teacher | 資訊工程系 |
| b13011 | 黃建宏 | teacher | 資訊工程系 |
| e13006 | 蔡明靜 | admin | 資訊工程系 |
| f10013 | 鐘佳純 | admin | 教務處 |
