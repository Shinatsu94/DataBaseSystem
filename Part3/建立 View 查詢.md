# 建立 View 查詢

本文件說明 `查詢與View範例.sql` 中每一段查詢程式碼的用途、查詢邏輯與示範意義。此檔案負責展示概念層查詢、十個實體 View 的呼叫方式、View Schema 查詢方式，以及透過 View 操作資料的範例。

## 一、執行目的

`查詢與View範例.sql` 的完整用途是驗證資料庫建立與範例資料匯入後，系統是否能透過 SQL 查詢取得可讀且具實務意義的結果。此檔案不建立資料表，也不匯入主要資料，而是用於查詢、驗證與展示。

本檔案必須在 `完整資料庫Schema.sql` 與 `範例資料.sql` 執行完成後執行，否則會因資料表、View 或範例資料不存在而無法完整展示結果。

## 二、查詢前設定

| 程式碼段落 | 用途 | 設計原因 |
| --- | --- | --- |
| `USE classroom_rental;` | 指定查詢資料庫 | 確保後續 SELECT、SHOW CREATE VIEW 與 View 操作都在教室租借系統資料庫中執行。 |
| `SET NAMES utf8mb4;` | 設定查詢連線字元集 | 查詢結果包含中文姓名、課程名稱、教室名稱與通知訊息，需正確顯示中文。 |
| `SET time_zone = '+08:00';` | 設定查詢時間語意 | 讓查詢結果中的建立時間、審核時間與通知時間對應台灣時間。 |

完整用意：查詢前設定確保查詢資料庫、字元顯示與時間解讀一致，使查詢結果可直接用於報告與系統驗證。

## 三、查詢一：使用者提出教室預約

此查詢示範概念層中的「使用者提出教室預約」。

| SQL 組成 | 用途 | 設計原因 |
| --- | --- | --- |
| `SELECT ...` | 指定要顯示的欄位 | 顯示預約編號、申請人、教室、日期、節次、用途、狀態與建立時間。 |
| `FROM bookings b` | 以單次預約作為查詢主體 | 單次預約是教室租借系統的主要交易資料。 |
| `JOIN users u ON b.applicant_id = u.user_id` | 連接申請人資料 | 將申請人代碼轉換為可讀姓名與身份。 |
| `JOIN classrooms c ON b.classroom_id = c.classroom_id` | 連接教室資料 | 將教室代碼轉換為教室名稱。 |
| `JOIN sections ss ON b.start_section_id = ss.section_id` | 連接開始節次 | 顯示借用開始節次名稱。 |
| `JOIN sections es ON b.end_section_id = es.section_id` | 連接結束節次 | 顯示借用結束節次名稱。 |
| `JOIN booking_statuses st ON b.status_id = st.status_id` | 連接預約狀態 | 顯示待審核、已核准、退回等狀態名稱。 |
| `ORDER BY b.booking_date, b.booking_id` | 排序查詢結果 | 依日期與預約編號排序，方便閱讀與核對。 |

完整用意：此查詢把 `bookings` 的外鍵欄位轉換成可讀資訊，展示一筆預約如何連接申請人、教室、節次與狀態。

## 四、查詢二：課程具有固定教室時段

此查詢示範概念層中的「課程固定占用教室時段」。

| SQL 組成 | 用途 | 設計原因 |
| --- | --- | --- |
| `SELECT ...` | 指定課程時段顯示欄位 | 顯示課程、教師、教室、星期與節次。 |
| `FROM course_info ci` | 以課程主檔作為查詢起點 | 課程主檔保存課程名稱、學年度、學期與教師。 |
| `JOIN users teacher ON ci.teacher_id = teacher.user_id` | 連接授課教師 | 顯示教師姓名並驗證教師存在於使用者資料表。 |
| `JOIN course_times ct ON ci.course_id = ct.course_id` | 連接課程時段 | 顯示課程實際上課教室與節次。 |
| `JOIN classrooms c ON ct.classroom_id = c.classroom_id` | 連接教室 | 顯示上課教室名稱。 |
| `JOIN sections ss` 與 `JOIN sections es` | 連接開始與結束節次 | 顯示課程時段範圍。 |
| `ORDER BY ct.weekday, ss.start_time` | 排序課表結果 | 依星期與開始時間排序，接近實際課表閱讀方式。 |

完整用意：此查詢證明課程主檔與課程時段分離的設計可以支援一門課對多個時段，並能用於檢查教室是否已被固定課程占用。

## 五、查詢三：管理員查看教室使用情況

此查詢示範管理員查詢教室使用率與已核准借用次數。

| SQL 組成 | 用途 | 設計原因 |
| --- | --- | --- |
| `FROM classrooms c` | 以教室作為查詢主體 | 管理者通常以教室資源角度查看使用情況。 |
| `LEFT JOIN bookings b ON c.classroom_id = b.classroom_id` | 連接預約資料 | 使用 `LEFT JOIN` 可保留沒有預約的教室。 |
| `LEFT JOIN booking_statuses st ON b.status_id = st.status_id` | 連接狀態資料 | 用於判斷哪些預約是已核准。 |
| `COUNT(b.booking_id)` | 統計總預約數 | 顯示該教室有多少預約紀錄。 |
| `SUM(CASE WHEN st.status_code = 'approved' THEN 1 ELSE 0 END)` | 統計已核准次數 | 將狀態轉換為管理統計數字。 |
| `MAX(b.booking_date)` | 顯示最近預約日期 | 協助管理者掌握教室近期使用情況。 |
| `GROUP BY ...` | 依教室彙總 | 每一間教室產生一列統計結果。 |
| `ORDER BY approved_booking_count DESC` | 依核准次數排序 | 優先顯示使用率較高的教室。 |

完整用意：此查詢展示資料庫不只保存交易資料，也能產生管理報表，支援教室資源分配與使用狀況分析。

## 六、十個 View 的實際呼叫方式

`查詢與View範例.sql` 提供十個實體 View 的直接呼叫範例。

| View 呼叫 | 對應實體 | 用途 | 查詢結果意義 |
| --- | --- | --- | --- |
| `SELECT * FROM vw_users;` | 使用者 | 查詢學生、教師與管理員資料 | 驗證使用者主檔可被查詢。 |
| `SELECT * FROM vw_classrooms ORDER BY classroom_id;` | 教室 | 查詢所有教室 | 驗證教室資源與啟用狀態。 |
| `SELECT * FROM vw_sections ORDER BY section_id;` | 節次 | 查詢節次與時間 | 驗證節次設定是否完整。 |
| `SELECT * FROM vw_booking_statuses ORDER BY status_id;` | 預約狀態 | 查詢所有狀態代碼 | 驗證流程狀態是否完整。 |
| `SELECT * FROM vw_course_info ORDER BY course_id;` | 課程 | 查詢課程與教師資訊 | 驗證課程與授課教師關聯。 |
| `SELECT * FROM vw_course_times ORDER BY course_time_id;` | 課程時段 | 查詢課程固定教室時段 | 驗證課程、教室與節次關聯。 |
| `SELECT * FROM vw_long_term_bookings ORDER BY created_at DESC;` | 長期借用 | 查詢長期借用申請 | 驗證長期借用、申請人、教室、節次與狀態關聯。 |
| `SELECT * FROM vw_bookings ORDER BY created_at DESC;` | 單次預約 | 查詢單次預約 | 驗證預約、申請人、教室、節次與狀態關聯。 |
| `SELECT * FROM vw_booking_reviews ORDER BY reviewed_at DESC;` | 審核紀錄 | 查詢審核歷程 | 驗證審核者、預約與審核狀態關聯。 |
| `SELECT * FROM vw_notifications ORDER BY created_at DESC;` | 通知 | 查詢通知資料 | 驗證通知接收者與相關預約關聯。 |

完整用意：這十個 View 是對應十個實體的查詢入口。使用 View 可以避免每次查詢都手寫多個 JOIN，並讓報告與系統頁面使用一致的資料呈現方式。

## 七、查詢 View Schema

此段使用 `SHOW CREATE VIEW vw_bookings;` 查詢 View 的建立語法。

| SQL 組成 | 用途 | 設計原因 |
| --- | --- | --- |
| `SHOW CREATE VIEW` | 顯示 View 的完整建立語法 | 可檢查 View 由哪些資料表與欄位組成。 |
| `vw_bookings` | 指定要查詢的 View | `vw_bookings` 是單次預約的主要展示 View，最能代表多表關聯查詢。 |

完整用意：`SHOW CREATE VIEW` 可驗證 View Schema 是否符合設計文件，也能讓開發者確認 View 的欄位來源與 JOIN 條件。

## 八、透過 View 新增預約範例

檔案中保留註解形式的 `INSERT INTO vw_bookings (...) VALUES ...`。

| 程式碼段落 | 用途 | 設計原因 |
| --- | --- | --- |
| `INSERT INTO vw_bookings` | 示範可透過 View 新增單次預約 | 若 View 符合 MariaDB 可更新 View 條件，應用程式可使用 View 作為資料寫入介面。 |
| `applicant_id` | 指定申請人 | 必須存在於 `users`。 |
| `classroom_id` | 指定教室 | 必須存在於 `classrooms`。 |
| `booking_date` | 指定借用日期 | 使用 `DATE` 表示年月日。 |
| `start_section_id` 與 `end_section_id` | 指定借用節次 | 必須存在於 `sections` 且開始節次不可晚於結束節次。 |
| `reason` | 指定借用用途 | 提供審核依據。 |

此範例以註解保留，是為了避免每次執行查詢檔都新增重複資料。需要測試新增功能時，可在測試環境解除註解後執行。

完整用意：此範例展示 View 不只可用於查詢，也可作為應用程式寫入資料的介面，但實際使用時仍會受到資料表限制、外鍵與觸發器保護。

## 九、透過 View 更新通知已讀狀態

檔案中保留註解形式的 `UPDATE vw_notifications SET is_read = TRUE ...`。

| 程式碼段落 | 用途 | 設計原因 |
| --- | --- | --- |
| `UPDATE vw_notifications` | 示範透過通知 View 更新資料 | 使用者可將自己的通知標示為已讀。 |
| `SET is_read = TRUE` | 將通知改為已讀 | 對應通知中心的已讀功能。 |
| `WHERE notification_id = ...` | 指定更新哪一筆通知 | 避免一次更新所有通知。 |

此範例以註解保留，是為了避免每次執行查詢檔都改變範例資料狀態。需要測試通知已讀功能時，可在測試環境解除註解後執行。

完整用意：此範例展示 View 可支援部分日常操作，例如通知已讀更新，同時保留資料庫權限控管的設計空間。

## 十、完整總結

`查詢與View範例.sql` 的整體作用是展示資料庫從概念層到實際查詢層的使用方式。前三段查詢分別示範使用者預約、課程固定時段與管理員統計，十個 View 呼叫則驗證每個實體都能以可讀方式查詢。`SHOW CREATE VIEW` 用於檢查 View Schema，而註解形式的新增與更新範例則說明 View 可作為應用程式與資料庫之間的操作介面。
