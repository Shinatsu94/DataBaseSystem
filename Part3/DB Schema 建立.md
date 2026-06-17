# DB Schema 建立

本文件說明 `完整資料庫Schema.sql` 中各段 MariaDB SQL 程式碼的用途、設計依據與完整作用。此檔案負責建立教室租借系統的資料庫、十個主要實體、完整性限制、觸發器、索引、View 與角色權限。

## 一、執行目的

`完整資料庫Schema.sql` 的完整用途是建立一個可重複部署的 MariaDB 資料庫架構，使教室租借系統能夠保存使用者、教室、節次、課程、固定課程時段、長期借用、單次預約、審核紀錄與通知資料。

此檔案不匯入範例資料，主要負責資料庫結構本身。因此在執行順序上，必須先執行本檔案，再執行 `範例資料.sql` 與 `查詢與View範例.sql`。

## 二、資料庫初始化設定

| 程式碼段落 | 用途 | 設計原因 |
| --- | --- | --- |
| `SET NAMES utf8mb4;` | 設定連線字元集 | 系統資料包含中文姓名、課程名稱、教室名稱與通知文字，使用 `utf8mb4` 可完整支援中文與特殊字元。 |
| `CREATE DATABASE IF NOT EXISTS classroom_rental ...` | 建立資料庫 | 若資料庫尚未存在則建立，避免首次部署時缺少資料庫。 |
| `CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci` | 指定資料庫字元集與排序規則 | 確保中文資料在儲存、排序與比對時具備一致性。 |
| `USE classroom_rental;` | 切換目前操作資料庫 | 後續建立資料表、View、Trigger、Role 都會套用到此資料庫。 |

## 三、重新建立架構前的清理順序

Schema 檔案先刪除既有 View、Trigger 與資料表，再重新建立完整架構。

| 程式碼段落 | 用途 | 設計原因 |
| --- | --- | --- |
| `DROP VIEW IF EXISTS ...` | 移除既有 View | View 依賴資料表，重新建立資料表前必須先移除 View。 |
| `DROP TRIGGER IF EXISTS ...` | 移除既有 Trigger | Trigger 綁定在資料表上，若資料表重建，Trigger 也需要重新建立。 |
| `DROP TABLE IF EXISTS ...` | 移除既有資料表 | 確保 Schema 每次執行都能回到一致狀態。 |

資料表刪除順序依照外鍵相依關係安排。例如 `booking_reviews` 與 `notifications` 依賴 `bookings`，因此必須先刪除；`bookings` 依賴 `users`、`classrooms`、`sections`、`booking_statuses` 等資料表，因此較晚刪除。

## 四、十個實體資料表說明

### 1. users

`users` 儲存系統帳號資料，是學生、教師與管理員權限判斷的基礎。

| 程式碼設定 | 用途 | 設計原因 |
| --- | --- | --- |
| `user_id CHAR(8) PRIMARY KEY` | 使用學號或員工編號作為主鍵 | 帳號編號長度固定，使用 `CHAR(8)` 比 `VARCHAR` 更能表達固定格式。 |
| `username NVARCHAR(50) NOT NULL` | 儲存使用者姓名 | 中文姓名長度不固定，使用 `NVARCHAR` 可支援 Unicode 文字。 |
| `email NVARCHAR(120) NOT NULL UNIQUE` | 儲存電子郵件並避免重複 | 電子郵件是通知與身份識別的重要欄位，必須唯一。 |
| `role ENUM('student','teacher','admin') NOT NULL` | 定義使用者身份 | 系統權限分為學生、教師、管理員三種，使用 ENUM 可限制資料只能落在合法身份。 |
| `department NVARCHAR(80)` | 儲存系所或單位 | 用於查詢、審核與管理統計。 |
| `CHECK (user_id REGEXP '^[0-9]{8}$')` | 限制帳號編號格式 | 避免輸入非八碼數字造成資料不一致。 |
| `CHECK (email LIKE '%@%.%')` | 基本檢查電子郵件格式 | 避免明顯不合法的電子郵件進入資料庫。 |

完整用意：`users` 是所有預約、課程、審核與通知資料的身份來源。後續資料表透過外鍵連接 `users`，確保預約申請人、授課教師、審核人員與通知接收者都是系統中已存在的帳號。

### 2. classrooms

`classrooms` 儲存可被借用或排課的教室資料。

| 程式碼設定 | 用途 | 設計原因 |
| --- | --- | --- |
| `classroom_id CHAR(6) PRIMARY KEY` | 定義教室代碼 | 教室代碼通常為固定長度，例如建物與教室編號組合。 |
| `classroom_name NVARCHAR(80) NOT NULL` | 儲存教室名稱 | 供使用者查詢與顯示。 |
| `capacity INT NOT NULL` | 儲存容納人數 | 預約活動可依人數選擇合適教室。 |
| `is_active BOOLEAN NOT NULL DEFAULT TRUE` | 標示教室是否可用 | 可停用維修中或不開放租借的教室。 |
| `CHECK (capacity > 0)` | 限制容量必須大於零 | 教室容量不可為零或負數。 |

完整用意：`classrooms` 是空間資源管理的核心。課程時段、長期借用與單次預約都必須連接到此資料表，以避免不存在的教室被排入系統。

### 3. sections

`sections` 定義學校節次與節次時間。

| 程式碼設定 | 用途 | 設計原因 |
| --- | --- | --- |
| `section_id CHAR(2) PRIMARY KEY` | 定義節次代碼 | 節次如 01、02、03 屬固定格式，使用 `CHAR(2)` 較明確。 |
| `section_name NVARCHAR(20) NOT NULL UNIQUE` | 儲存節次名稱 | 避免同一節次名稱重複。 |
| `start_time TIME(0) NOT NULL` | 儲存節次開始時間 | `TIME(0)` 明確表示只記錄時分秒，不記錄日期。 |
| `end_time TIME(0) NOT NULL` | 儲存節次結束時間 | 搭配 `start_time` 判斷課程與借用時間。 |
| `CHECK (start_time < end_time)` | 限制開始時間必須早於結束時間 | 避免產生不合理的節次區間。 |

完整用意：`sections` 將抽象節次轉換為可驗證的時間區間，使課程安排與教室預約能以一致的節次邏輯運作。

### 4. booking_statuses

`booking_statuses` 儲存預約、審核與長期借用使用的狀態代碼。

| 程式碼設定 | 用途 | 設計原因 |
| --- | --- | --- |
| `status_id TINYINT PRIMARY KEY` | 定義狀態編號 | 狀態數量有限，使用 `TINYINT` 可節省儲存空間。 |
| `status_code NVARCHAR(30) NOT NULL UNIQUE` | 儲存狀態代碼 | 程式與查詢可使用穩定代碼判斷狀態。 |
| `status_name NVARCHAR(30) NOT NULL` | 儲存中文狀態名稱 | 供畫面顯示與報告閱讀。 |
| `CHECK (status_code IN (...))` | 限制狀態代碼範圍 | 避免出現系統未定義的審核狀態。 |

完整用意：`booking_statuses` 將狀態集中管理，避免在多個資料表重複寫入狀態文字，並讓預約、審核與通知能使用一致的狀態語意。

### 5. course_info

`course_info` 儲存課程基本資料。

| 程式碼設定 | 用途 | 設計原因 |
| --- | --- | --- |
| `course_id CHAR(8) PRIMARY KEY` | 定義課程代碼 | 課程代碼通常為固定長度，使用 `CHAR(8)` 可表達固定格式。 |
| `academic_year SMALLINT NOT NULL` | 儲存學年度 | 學年度數值範圍有限，使用 `SMALLINT` 足夠且明確。 |
| `semester ENUM('1','2','summer') NOT NULL` | 儲存學期 | 學期選項固定，使用 ENUM 可避免輸入任意文字。 |
| `course_name NVARCHAR(120) NOT NULL` | 儲存課程名稱 | 中文課名長度不一，需支援 Unicode。 |
| `teacher_id CHAR(8) NOT NULL` | 指向授課教師 | 必須連接 `users.user_id`。 |
| `FOREIGN KEY (teacher_id) REFERENCES users(user_id)` | 建立教師關聯 | 確保授課教師是系統內已存在的使用者。 |

完整用意：`course_info` 表示課程主檔。它不直接表示上課時間，而是與 `course_times` 分離，使一門課可以有多個上課時段。

### 6. course_times

`course_times` 儲存課程固定上課時段。

| 程式碼設定 | 用途 | 設計原因 |
| --- | --- | --- |
| `course_time_id INT AUTO_INCREMENT PRIMARY KEY` | 定義課程時段流水號 | 一門課可能有多個時段，使用流水號識別每筆時段。 |
| `course_id CHAR(8) NOT NULL` | 指向課程 | 連接 `course_info`。 |
| `classroom_id CHAR(6) NOT NULL` | 指向上課教室 | 連接 `classrooms`。 |
| `weekday TINYINT NOT NULL` | 儲存星期 | 使用 1 至 7 表示星期一至星期日。 |
| `start_section_id CHAR(2) NOT NULL` | 指向開始節次 | 連接 `sections`。 |
| `end_section_id CHAR(2) NOT NULL` | 指向結束節次 | 連接 `sections`。 |
| `CHECK (weekday BETWEEN 1 AND 7)` | 限制星期範圍 | 避免出現不存在的星期。 |
| `CHECK (start_section_id <= end_section_id)` | 限制節次順序 | 避免結束節次早於開始節次。 |

完整用意：`course_times` 將課程與固定教室時段建立關聯，並作為單次預約檢查衝突時的重要依據。

### 7. long_term_bookings

`long_term_bookings` 儲存跨日期區間的固定借用需求。

| 程式碼設定 | 用途 | 設計原因 |
| --- | --- | --- |
| `long_term_booking_id INT AUTO_INCREMENT PRIMARY KEY` | 定義長期借用流水號 | 長期借用資料量會持續增加，流水號便於追蹤。 |
| `applicant_id CHAR(8) NOT NULL` | 指向申請人 | 連接 `users`，表示由誰提出申請。 |
| `classroom_id CHAR(6) NOT NULL` | 指向教室 | 連接 `classrooms`。 |
| `start_date DATE NOT NULL` | 儲存開始日期 | `DATE` 僅表示年月日，適合描述長期借用區間起點。 |
| `end_date DATE NOT NULL` | 儲存結束日期 | 與 `start_date` 組成借用期間。 |
| `weekday TINYINT NOT NULL` | 儲存每週借用星期 | 表示固定每週哪一天借用。 |
| `start_section_id CHAR(2) NOT NULL` | 指向開始節次 | 連接 `sections`。 |
| `end_section_id CHAR(2) NOT NULL` | 指向結束節次 | 連接 `sections`。 |
| `reason NVARCHAR(255) NOT NULL` | 儲存借用原因 | 審核人員需要依用途判斷是否核准。 |
| `status_id TINYINT NOT NULL DEFAULT 1` | 指向狀態 | 預設為待審核狀態。 |
| `created_at DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP` | 儲存建立時間 | `DATETIME(0)` 記錄年月日時分秒，不依資料庫時區自動轉換。 |

完整用意：`long_term_bookings` 用於社團活動、固定輔導、跨週借用等需求。它與單次預約分開，可避免用大量單次資料表達長期規律需求。

### 8. bookings

`bookings` 儲存單次教室預約紀錄。

| 程式碼設定 | 用途 | 設計原因 |
| --- | --- | --- |
| `booking_id INT AUTO_INCREMENT PRIMARY KEY` | 定義預約流水號 | 預約紀錄會持續新增，流水號便於追蹤。 |
| `applicant_id CHAR(8) NOT NULL` | 指向申請人 | 連接 `users`。 |
| `classroom_id CHAR(6) NOT NULL` | 指向教室 | 連接 `classrooms`。 |
| `long_term_booking_id INT NULL` | 指向長期借用 | 若單次預約由長期借用展開，可保留來源。 |
| `course_time_id INT NULL` | 指向課程時段 | 若預約與課程相關，可保留關聯。 |
| `booking_date DATE NOT NULL` | 儲存借用日期 | `DATE` 明確表示單次借用發生的年月日。 |
| `start_section_id CHAR(2) NOT NULL` | 指向開始節次 | 連接 `sections`。 |
| `end_section_id CHAR(2) NOT NULL` | 指向結束節次 | 連接 `sections`。 |
| `reason NVARCHAR(255) NOT NULL` | 儲存預約用途 | 提供審核判斷與查詢依據。 |
| `status_id TINYINT NOT NULL DEFAULT 1` | 指向預約狀態 | 預設為待審核。 |
| `created_at DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP` | 儲存建立時間 | 保留申請發生時間，便於排序與稽核。 |

完整用意：`bookings` 是教室租借系統最核心的交易資料表。它記錄每一次借用申請，並透過外鍵與觸發器確保同一教室同一日期與節次不會被重複核准。

### 9. booking_reviews

`booking_reviews` 儲存管理員或教師對預約的審核紀錄。

| 程式碼設定 | 用途 | 設計原因 |
| --- | --- | --- |
| `review_id INT AUTO_INCREMENT PRIMARY KEY` | 定義審核流水號 | 一筆預約可能有審核過程紀錄，流水號便於保存紀錄。 |
| `booking_id INT NOT NULL` | 指向被審核預約 | 連接 `bookings`。 |
| `reviewer_id CHAR(8) NOT NULL` | 指向審核者 | 連接 `users`。 |
| `status_id TINYINT NOT NULL` | 指向審核後狀態 | 連接 `booking_statuses`。 |
| `review_comment NVARCHAR(255)` | 儲存審核意見 | 可說明核准、退回或拒絕原因。 |
| `reviewed_at DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP` | 儲存審核時間 | 作為審核歷程與責任追蹤依據。 |

完整用意：`booking_reviews` 將審核結果與預約資料分離，保留誰在何時做出何種審核判斷，支援後續稽核與查詢。

### 10. notifications

`notifications` 儲存系統通知。

| 程式碼設定 | 用途 | 設計原因 |
| --- | --- | --- |
| `notification_id INT AUTO_INCREMENT PRIMARY KEY` | 定義通知流水號 | 通知資料會持續新增，流水號便於識別。 |
| `recipient_id CHAR(8) NOT NULL` | 指向通知接收者 | 連接 `users`。 |
| `booking_id INT NULL` | 指向相關預約 | 若通知與預約有關，可建立追蹤關聯。 |
| `message NVARCHAR(255) NOT NULL` | 儲存通知內容 | 顯示給學生、教師或管理員閱讀。 |
| `is_read BOOLEAN NOT NULL DEFAULT FALSE` | 標示是否已讀 | 可查詢未讀通知。 |
| `created_at DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP` | 儲存通知建立時間 | 支援通知排序與查詢。 |

完整用意：`notifications` 提供系統回饋機制，例如預約送出、審核完成、退回補件與借用提醒。

## 五、觸發器說明

觸發器用於補足單純外鍵與檢查限制無法處理的跨資料表規則。

| 觸發器 | 對應資料表 | 用途 | 設計原因 |
| --- | --- | --- | --- |
| `trg_course_info_validate_teacher_insert` | `course_info` | 新增課程前檢查授課者身份必須為教師或管理員 | 外鍵只能確認使用者存在，無法確認角色是否符合授課資格。 |
| `trg_course_info_validate_teacher_update` | `course_info` | 修改課程教師時重新檢查角色 | 避免更新後將課程指派給學生身份。 |
| `trg_course_times_prevent_overlap_insert` | `course_times` | 新增課程時段前檢查同教室同星期節次是否衝突 | 避免同一教室同一時間被多門課占用。 |
| `trg_course_times_prevent_overlap_update` | `course_times` | 修改課程時段前檢查衝突 | 避免原本合法資料在更新後產生重疊。 |
| `trg_long_term_validate_insert` | `long_term_bookings` | 新增長期借用前檢查申請人、日期、節次與教室衝突 | 長期借用跨日期與星期，需使用觸發器驗證。 |
| `trg_long_term_validate_update` | `long_term_bookings` | 修改長期借用前重新檢查規則 | 避免更新造成跨週期衝突。 |
| `trg_bookings_prevent_overlap_insert` | `bookings` | 新增單次預約前檢查課程、長期借用與既有預約衝突 | 確保教室在同日期與節次只能被一個有效用途占用。 |
| `trg_bookings_prevent_overlap_update` | `bookings` | 修改單次預約前重新檢查衝突 | 避免更新後破壞教室可用性。 |
| `trg_reviews_validate_insert` | `booking_reviews` | 新增審核紀錄前檢查審核者身份 | 確保只有教師或管理員可進行審核。 |
| `trg_reviews_validate_update` | `booking_reviews` | 修改審核紀錄前重新檢查審核者身份 | 避免審核紀錄被改成不具權限的審核者。 |

完整用意：觸發器將教室租借系統的重要邏輯放在資料庫層保護，即使未來由不同前端或後端程式存取資料庫，也能維持核心資料一致性。

## 六、索引說明

| 索引 | 對應資料表 | 用途 | 設計原因 |
| --- | --- | --- | --- |
| `idx_bookings_classroom_date` | `bookings` | 加速依教室與日期查詢預約 | 預約衝突檢查與日曆查詢會頻繁使用此條件。 |
| `idx_bookings_applicant_date` | `bookings` | 加速依申請人與日期查詢 | 使用者查詢個人預約紀錄時可提升效率。 |
| `idx_course_times_classroom_weekday` | `course_times` | 加速依教室與星期查詢課程時段 | 課程衝突檢查需要快速找到同教室同星期資料。 |
| `idx_notifications_recipient_read` | `notifications` | 加速查詢特定使用者未讀通知 | 系統首頁或通知中心會頻繁查詢未讀通知。 |

完整用意：索引用於提升常見查詢與衝突檢查效率，使資料量增加後仍能維持合理查詢速度。

## 七、View 說明

Schema 檔案為十個實體各建立一個 View。

| View | 來源資料表 | 用途 |
| --- | --- | --- |
| `vw_users` | `users` | 提供使用者資料查詢介面。 |
| `vw_classrooms` | `classrooms` | 提供教室資料查詢介面。 |
| `vw_sections` | `sections` | 提供節次資料查詢介面。 |
| `vw_booking_statuses` | `booking_statuses` | 提供狀態代碼查詢介面。 |
| `vw_course_info` | `course_info`、`users` | 顯示課程與教師名稱。 |
| `vw_course_times` | `course_times`、`course_info`、`classrooms`、`sections` | 顯示課程固定時段與教室節次資訊。 |
| `vw_long_term_bookings` | `long_term_bookings` 與相關主檔 | 顯示長期借用完整可讀資料。 |
| `vw_bookings` | `bookings` 與相關主檔 | 顯示單次預約完整可讀資料。 |
| `vw_booking_reviews` | `booking_reviews` 與相關主檔 | 顯示審核紀錄與審核者資料。 |
| `vw_notifications` | `notifications`、`users`、`bookings` | 顯示通知與相關預約資料。 |

完整用意：View 將多資料表關聯查詢封裝為可直接呼叫的資料介面，降低使用者或應用程式查詢時的複雜度。

## 八、角色與權限說明

| 角色 | 權限設定 | 用途 |
| --- | --- | --- |
| `classroom_student_role` | 可查詢基本 View、建立與修改個人預約、更新個人通知已讀狀態 | 對應學生使用者，支援查詢教室、送出預約、查看通知。 |
| `classroom_teacher_role` | 繼承學生權限，並可查詢課程與建立長期借用 | 對應教師使用者，支援課程相關借用與固定活動申請。 |
| `classroom_admin_role` | 繼承教師權限，並擁有資料庫完整管理權限 | 對應管理員，支援審核、維護資料與系統管理。 |

完整用意：角色權限將學生、教師與管理員的操作範圍分開，避免一般使用者直接修改主檔或審核紀錄，同時讓管理員具備完整維護能力。

## 九、完整總結

`完整資料庫Schema.sql` 的整體作用是建立教室租借系統的資料庫骨架。它先完成資料庫初始化與清理，再建立十個實體資料表，透過主鍵、外鍵、唯一限制、檢查限制與觸發器保護資料正確性，並使用索引提升查詢效率。最後，Schema 檔案建立十個 View 與三種身份角色權限，使資料庫不只是保存資料，也能支援查詢、審核、權限控管與後續系統實作。
