# Part1：應用情境與使用案例、系統需求、完整性限制、ER Diagram

本文件對應專案總攬中的「題目與應用情境」、「系統需求說明」、「完整性限制」與「ER Diagram」等內容，作為期末專題 Part1 的獨立閱讀版本。

## 對映專案總攬章節

| Part1 項目 | 專案總攬對應章節 | 說明 |
|---|---|---|
| 應用情境與使用案例 | [題目與應用情境](../README.md#題目與應用情境) | 說明教室租用系統的使用背景、主要使用者與操作情境。 |
| 系統需求說明 | [系統需求說明](../README.md#系統需求說明) | 整理學生、教師、管理員與系統自動處理需要支援的功能。 |
| 完整性限制 | [完整性限制](../README.md#完整性限制) | 說明主鍵、外鍵、唯一限制、Domain 限制與 Trigger 驗證。 |
| ER Diagram 及詳細說明 | [ER Diagram](../README.md#er-diagram) | 說明 10 個實體之間的關聯基數與參照關係。 |

## 應用情境與使用案例

教室租用系統用於支援校園內教室借用流程，讓學生、教師與管理員在同一套資料庫架構中完成查詢、申請、審核、通知與紀錄保存。系統的核心目標是降低人工確認教室可用性的時間，並避免同一教室、同一日期、同一節次發生重複借用。

主要使用案例如下：

| 使用者 | 使用案例 | 資料庫支援方式 |
|---|---|---|
| 學生 | 查詢可借用教室、建立單次借用申請、查看審核狀態與通知 | 透過 `bookings`、`booking_statuses`、`notifications` 與相關 View 查詢資料。 |
| 教師 | 查詢授課教室、建立課程固定時段、提出長期借用申請 | 透過 `course_info`、`course_times`、`long_term_bookings` 管理課程與固定使用時段。 |
| 管理員 | 審核借用申請、維護教室與狀態資料、檢查衝突紀錄 | 透過 `booking_reviews`、Trigger、View 與 Role 權限控管審核流程。 |
| 系統 | 自動檢查時段衝突、限制不合理資料、產生可讀取 View | 透過 Foreign Key、Check Constraint、Unique Constraint、Trigger 與 View 完成資料一致性控制。 |

## 系統需求說明

系統需求分為功能性需求與非功能性需求。功能性需求描述使用者需要完成的事情；非功能性需求描述系統在安全性、可靠性、可維護性、資料一致性與效能上的品質要求。

| 類型 | 需求重點 | 對應資料庫設計 |
|---|---|---|
| 使用者查詢 | 使用者可以查詢教室、節次、預約狀態與自身通知 | `vw_classrooms`、`vw_sections`、`vw_booking_statuses`、`vw_notifications` |
| 預約申請 | 使用者可以建立單次預約，教師可以建立課程或長期借用資料 | `bookings`、`course_info`、`course_times`、`long_term_bookings` |
| 審核管理 | 管理員可以審核預約並保留審核歷程 | `booking_reviews`、`booking_statuses` |
| 衝突檢查 | 同一教室同一時段不得重複排課或借用 | Trigger 與索引檢查 `classroom_id`、日期、星期、節次範圍 |
| 權限控管 | 學生、教師、管理員可操作的資料範圍不同 | MariaDB Role、GRANT 與 View |

## 完整性限制

完整性限制用於確保資料在新增、修改與查詢時維持一致。

| 限制類型 | 使用方式 | 設計目的 |
|---|---|---|
| Entity Integrity | 每張資料表皆有 Primary Key | 確保每一筆資料可以被唯一識別。 |
| Referential Integrity | 以 Foreign Key 連接使用者、教室、節次、狀態、課程與預約 | 避免引用不存在的資料。 |
| Domain Integrity | 使用 `CHECK`、固定型態與合理欄位長度 | 限制角色、星期、容量、節次時間等資料範圍。 |
| Unique Constraint | 限制帳號、Email、教室名稱、狀態代碼等不可重複 | 避免具唯一意義的資料重複。 |
| Trigger Rule | 檢查教師身分、課程時段、長期借用與單次預約衝突 | 補足跨資料表與跨時段的其他邏輯規則。 |

## ER Diagram 及詳細說明

Part1 的 ER 圖附件如下：

| 檔案 | 用途 |
|---|---|
| [ER_Diagram.md](ER_Diagram.md) | 使用 Mermaid 語法呈現主要實體與 `1:N` 關聯。 |
| [ER_Diagram_Detailed.md](ER_Diagram_Detailed.md) | 顯示完整欄位、鍵值、關聯基數與關聯說明。 |
| [ER_Diagram_Detailed.drawio](ER_Diagram_Detailed.drawio) | 可使用 diagrams.net 開啟的 ER 圖原始檔。 |

主要關聯摘要：

| 關聯 | 基數 | 說明 |
|---|---|---|
| `users` 至 `bookings` | 1:N | 一位使用者可以提出多筆單次預約。 |
| `classrooms` 至 `bookings` | 1:N | 一間教室可以被多筆不同日期或時段的預約引用。 |
| `sections` 至 `bookings` | 1:N | 節次作為預約開始與結束時間的參照。 |
| `booking_statuses` 至 `bookings` | 1:N | 每筆預約擁有一個狀態，同一狀態可套用於多筆預約。 |
| `course_info` 至 `course_times` | 1:N | 一門課程可以有多個固定授課時段。 |
| `long_term_bookings` 至 `bookings` | 1:N | 一筆長期借用可展開成多筆實際預約。 |
| `bookings` 至 `booking_reviews` | 1:N | 一筆預約可以保留多筆審核歷程。 |
| `bookings` 至 `notifications` | 1:N | 一筆預約可產生多筆通知。 |
