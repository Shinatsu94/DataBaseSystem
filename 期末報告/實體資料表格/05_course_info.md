# 05. course_info：課程資訊

> [返回專案總覽](../專案總覽.md) | [返回實體索引](./README.md)

## 用途

保存每學期課程資料，包括學年度、學期、課程名稱與授課教師。

## 欄位表格

| 編號 | 欄位名稱 | 資料型別 | 必填 | 鍵值或參照 | 預設值 | 完整性限制 | 說明 |
|---|---|---|---|---|---|---|---|
| 1 | `course_id` | `CHAR(20)` | 是 | PK | 無 | 主鍵不可重複、不可為空值 | 制度化課程識別碼 |
| 2 | `academic_year` | `SMALLINT UNSIGNED` | 是 | - | 無 | `NOT NULL`、`CHECK (academic_year BETWEEN 1 AND 999)` | 民國學年度，例如 `114` |
| 3 | `semester` | `TINYINT UNSIGNED` | 是 | - | 無 | `NOT NULL`、`CHECK (semester IN (1, 2))` | 學期，只能為第 1 或第 2 學期 |
| 4 | `course_name` | `VARCHAR(120)` | 是 | - | 無 | `NOT NULL` | 長度可變的課程名稱 |
| 5 | `teacher_id` | `CHAR(8)` | 是 | FK → `users.user_id` | 無 | `NOT NULL`、外鍵參照必須存在 | 授課教師 |

## 局部實體關聯圖

```mermaid
flowchart LR
    users["users<br/>使用者"]
    course_info["course_info<br/>課程資訊"]
    course_times["course_times<br/>固定授課時間"]

    users -->|"1 : N<br/>授課教師"| course_info
    course_info -->|"1 : N<br/>安排固定時段"| course_times
```

## 關聯實體

| 關聯實體 | 關聯類型 | 本實體外鍵或對方外鍵 | 說明 | 使用範例 |
|---|---|---|---|---|
| `users` | `users` 1:N `course_info` | `course_info.teacher_id` → `users.user_id` | 每門課程指定一位授課教師 | 資料庫系統課程指定教師 `T0000001`。 |
| `course_times` | `course_info` 1:N `course_times` | `course_times.course_id` → `course_info.course_id` | 一門課程得安排多個固定授課時段 | 資料庫系統可安排星期二與星期四兩筆固定授課時間。 |

## 其他邏輯規則

| 規則 | 說明 |
|---|---|
| 學期限制 | `semester` 只能為 `1` 或 `2`。 |
| 教師存在性 | `teacher_id` 必須對應至已存在的 `users.user_id`。 |
| 教師角色 | `trg_course_info_validate_teacher_insert/update` 強制 `teacher_id` 對應角色為 `teacher` 的使用者。 |

## Domain 與對應 View

`academic_year` 保存民國學年度，不使用代表西元年的 MariaDB `YEAR`；`semester` 只有 `1`、`2`，使用 `TINYINT UNSIGNED`。課程名稱長度可變，保留 `VARCHAR(120)`。

```sql
SELECT * FROM vw_course_info;
SHOW CREATE VIEW vw_course_info;
```

此 View 僅授權教師與管理員查詢。
