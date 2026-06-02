# Part 2：Schema 驗證說明

## 已驗證項目

| 測試情境 | 結果 | 保護機制 |
| --- | --- | --- |
| 建立合法使用者、教室與預約 | 接受 | Primary Key、Foreign Key |
| 預約引用不存在的教室 | 拒絕 | Foreign Key |
| 預約結束節次早於開始節次 | 拒絕 | Check Constraint |
| 同一教室的固定課表節次重疊 | 拒絕 | `course_times` Trigger |
| 核准預約與既有固定課表重疊 | 拒絕 | `bookings` 交叉檢查 Trigger |
| 同一教室的已核准預約重疊 | 拒絕 | `bookings` Trigger |
| 同一時段存在多筆待審核申請 | 接受 | 核准時再次檢查 |

## 設計理由

待審核申請不會立刻占用教室，因此可以先並存。管理員將案件改為
`approved` 時，Trigger 會再次比對固定課表與其他已核准預約。

如此可以兼顧申請流程與資料一致性。

## 建議執行順序

```powershell
sqlite3 classroom_rental.db ".read Part2_schema.sql"
sqlite3 classroom_rental.db ".read Part2_examples.sql"
```
