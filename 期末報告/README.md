# 教室租用系統：期末報告資料

## Part 1：簡報

- `Part1_教室租用系統資料庫設計.pptx`
- 內容包含題目、應用情境與使用案例、系統需求、完整性限制、ER Diagram 與關聯說明。
- `ER_Diagram.md`：使用 Mermaid 語法繪製之精簡版實體關聯圖。
- `ER_Diagram_Detailed.md`：包含完整欄位、鍵值與關聯基數之詳細版 Mermaid 實體關聯圖。

## Part 2：SQL Schema

- `Part2_schema.sql`：SQLite 完整建表語法、限制條件、索引與防止重複預約的觸發器（Trigger）。
- `Part2_examples.sql`：範例資料、查詢與衝突測試範例。
- `Part2_驗證說明.md`：已完成的正確資料與錯誤資料測試整理。
- `Part2_專案詳細說明.txt`：完整專案細節、各實體欄位、完整性限制、關聯、觸發器、索引與後續擴充項目。
- `實體資料表格/`：10 個實體的獨立 Markdown 表格與資料夾索引。

## 執行方式

```powershell
sqlite3 classroom_rental.db ".read Part2_schema.sql"
sqlite3 classroom_rental.db ".read Part2_examples.sql"
```

## 核心資料表

| 資料表 | 用途 |
| --- | --- |
| `users` | 學生、教師與管理員 |
| `classrooms` | 教室基本資料與啟用狀態 |
| `sections` | 學校節次與起訖時間 |
| `booking_statuses` | 待審核、已核准、已拒絕與已取消 |
| `course_info` | 學期課程資料 |
| `course_times` | 固定課表安排 |
| `long_term_bookings` | 長期借用父單據 |
| `bookings` | 每一次實際教室借用 |
| `booking_reviews` | 管理員審核歷程 |
| `notifications` | 申請狀態通知 |

## 設計重點

- 以外鍵維持參照完整性。
- 以 `CHECK` 限制身分類型、狀態、日期、節次與容量。
- 固定課表、已核准預約，以及課表與預約之間的交叉驗證，皆使用觸發器防止同一教室的時段重疊。
- 待審核案件得暫時並存；管理員核准案件時，系統將再次執行衝突驗證。
