-- 教室租用系統：完整資料庫 Schema
-- Target DBMS: MariaDB
-- 使用方式：mariadb -u root -p classroom_rental < schema.sql
-- 權限設定：建立 Schema 後另行執行 security.sql
-- 設計說明：請參閱 Schema_設計說明.md 與 權限與View設計.md
--
-- 檔案內容：
-- 1. 建立 10 張資料表。
-- 2. 建立主鍵、外鍵、NOT NULL、UNIQUE、DEFAULT 與 CHECK 限制。
-- 3. 建立角色、審核資格與時段衝突驗證 Trigger。
-- 4. 建立常用查詢索引。
-- 5. 為 10 張資料表各建立一個 View。

SET NAMES utf8mb4;

DROP VIEW IF EXISTS vw_notifications;
DROP VIEW IF EXISTS vw_booking_reviews;
DROP VIEW IF EXISTS vw_bookings;
DROP VIEW IF EXISTS vw_long_term_bookings;
DROP VIEW IF EXISTS vw_course_times;
DROP VIEW IF EXISTS vw_course_info;
DROP VIEW IF EXISTS vw_booking_statuses;
DROP VIEW IF EXISTS vw_sections;
DROP VIEW IF EXISTS vw_classrooms;
DROP VIEW IF EXISTS vw_users;

DROP TRIGGER IF EXISTS trg_reviews_validate_update;
DROP TRIGGER IF EXISTS trg_reviews_validate_insert;
DROP TRIGGER IF EXISTS trg_bookings_prevent_overlap_update;
DROP TRIGGER IF EXISTS trg_bookings_prevent_overlap_insert;
DROP TRIGGER IF EXISTS trg_long_term_validate_update;
DROP TRIGGER IF EXISTS trg_long_term_validate_insert;
DROP TRIGGER IF EXISTS trg_course_times_prevent_overlap_update;
DROP TRIGGER IF EXISTS trg_course_times_prevent_overlap_insert;
DROP TRIGGER IF EXISTS trg_course_info_validate_teacher_update;
DROP TRIGGER IF EXISTS trg_course_info_validate_teacher_insert;

DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS booking_reviews;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS long_term_bookings;
DROP TABLE IF EXISTS course_times;
DROP TABLE IF EXISTS course_info;
DROP TABLE IF EXISTS booking_statuses;
DROP TABLE IF EXISTS sections;
DROP TABLE IF EXISTS classrooms;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  user_id     CHAR(8) PRIMARY KEY,
  username    VARCHAR(60) NOT NULL,
  email       VARCHAR(254) NOT NULL UNIQUE,
  role        ENUM('student', 'teacher', 'admin') NOT NULL,
  department  VARCHAR(80)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE classrooms (
  classroom_id    CHAR(10) PRIMARY KEY,
  classroom_name  VARCHAR(80) NOT NULL,
  capacity        SMALLINT UNSIGNED NOT NULL,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT chk_classrooms_capacity CHECK (capacity > 0),
  CONSTRAINT chk_classrooms_active CHECK (is_active IN (FALSE, TRUE))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sections (
  section_id    TINYINT UNSIGNED PRIMARY KEY,
  section_name  CHAR(20) NOT NULL UNIQUE,
  start_time    TIME(0) NOT NULL,
  end_time      TIME(0) NOT NULL,
  CONSTRAINT chk_sections_clock_time CHECK (
    start_time BETWEEN '00:00:00' AND '23:59:59'
    AND end_time BETWEEN '00:00:00' AND '23:59:59'
  ),
  CONSTRAINT chk_sections_range CHECK (start_time < end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE booking_statuses (
  status_id    TINYINT UNSIGNED PRIMARY KEY,
  status_code  ENUM('pending', 'approved', 'rejected', 'canceled') NOT NULL UNIQUE,
  status_name  CHAR(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE course_info (
  course_id       CHAR(20) PRIMARY KEY,
  academic_year   SMALLINT UNSIGNED NOT NULL,
  semester        TINYINT UNSIGNED NOT NULL,
  course_name     VARCHAR(120) NOT NULL,
  teacher_id      CHAR(8) NOT NULL,
  CONSTRAINT chk_course_info_academic_year
    CHECK (academic_year BETWEEN 1 AND 999),
  CONSTRAINT chk_course_info_semester CHECK (semester IN (1, 2)),
  CONSTRAINT fk_course_info_teacher
    FOREIGN KEY (teacher_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE course_times (
  course_time_id    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  course_id         CHAR(20) NOT NULL,
  classroom_id      CHAR(10) NOT NULL,
  day_of_week       TINYINT UNSIGNED NOT NULL,
  start_section_id  TINYINT UNSIGNED NOT NULL,
  end_section_id    TINYINT UNSIGNED NOT NULL,
  CONSTRAINT chk_course_times_weekday CHECK (day_of_week BETWEEN 1 AND 7),
  CONSTRAINT chk_course_times_section_range CHECK (start_section_id <= end_section_id),
  CONSTRAINT fk_course_times_course
    FOREIGN KEY (course_id) REFERENCES course_info(course_id),
  CONSTRAINT fk_course_times_classroom
    FOREIGN KEY (classroom_id) REFERENCES classrooms(classroom_id),
  CONSTRAINT fk_course_times_start_section
    FOREIGN KEY (start_section_id) REFERENCES sections(section_id),
  CONSTRAINT fk_course_times_end_section
    FOREIGN KEY (end_section_id) REFERENCES sections(section_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE long_term_bookings (
  long_term_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  applicant_id       CHAR(8) NOT NULL,
  classroom_id       CHAR(10) NOT NULL,
  start_date         DATE NOT NULL,
  end_date           DATE NOT NULL,
  day_of_week        TINYINT UNSIGNED NOT NULL,
  start_section_id   TINYINT UNSIGNED NOT NULL,
  end_section_id     TINYINT UNSIGNED NOT NULL,
  reason             TEXT NOT NULL,
  status_id          TINYINT UNSIGNED NOT NULL,
  created_at         TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT chk_long_term_date_range CHECK (start_date <= end_date),
  CONSTRAINT chk_long_term_weekday CHECK (day_of_week BETWEEN 1 AND 7),
  CONSTRAINT chk_long_term_section_range CHECK (start_section_id <= end_section_id),
  CONSTRAINT fk_long_term_applicant
    FOREIGN KEY (applicant_id) REFERENCES users(user_id),
  CONSTRAINT fk_long_term_classroom
    FOREIGN KEY (classroom_id) REFERENCES classrooms(classroom_id),
  CONSTRAINT fk_long_term_start_section
    FOREIGN KEY (start_section_id) REFERENCES sections(section_id),
  CONSTRAINT fk_long_term_end_section
    FOREIGN KEY (end_section_id) REFERENCES sections(section_id),
  CONSTRAINT fk_long_term_status
    FOREIGN KEY (status_id) REFERENCES booking_statuses(status_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE bookings (
  booking_id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  applicant_id       CHAR(8) NOT NULL,
  classroom_id       CHAR(10) NOT NULL,
  long_term_id       BIGINT UNSIGNED,
  course_time_id     BIGINT UNSIGNED,
  booking_date       DATE NOT NULL,
  start_section_id   TINYINT UNSIGNED NOT NULL,
  end_section_id     TINYINT UNSIGNED NOT NULL,
  reason             TEXT NOT NULL,
  status_id          TINYINT UNSIGNED NOT NULL,
  created_at         TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT chk_bookings_section_range CHECK (start_section_id <= end_section_id),
  CONSTRAINT fk_bookings_applicant
    FOREIGN KEY (applicant_id) REFERENCES users(user_id),
  CONSTRAINT fk_bookings_classroom
    FOREIGN KEY (classroom_id) REFERENCES classrooms(classroom_id),
  CONSTRAINT fk_bookings_long_term
    FOREIGN KEY (long_term_id) REFERENCES long_term_bookings(long_term_id),
  CONSTRAINT fk_bookings_course_time
    FOREIGN KEY (course_time_id) REFERENCES course_times(course_time_id),
  CONSTRAINT fk_bookings_start_section
    FOREIGN KEY (start_section_id) REFERENCES sections(section_id),
  CONSTRAINT fk_bookings_end_section
    FOREIGN KEY (end_section_id) REFERENCES sections(section_id),
  CONSTRAINT fk_bookings_status
    FOREIGN KEY (status_id) REFERENCES booking_statuses(status_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE booking_reviews (
  review_id    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id   BIGINT UNSIGNED NOT NULL,
  reviewer_id  CHAR(8) NOT NULL,
  status_id    TINYINT UNSIGNED NOT NULL,
  comment      TEXT,
  reviewed_at  TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_reviews_booking
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
  CONSTRAINT fk_reviews_reviewer
    FOREIGN KEY (reviewer_id) REFERENCES users(user_id),
  CONSTRAINT fk_reviews_status
    FOREIGN KEY (status_id) REFERENCES booking_statuses(status_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE notifications (
  notification_id  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  recipient_id     CHAR(8) NOT NULL,
  booking_id       BIGINT UNSIGNED,
  message          TEXT NOT NULL,
  is_read          BOOLEAN NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT chk_notifications_read CHECK (is_read IN (FALSE, TRUE)),
  CONSTRAINT fk_notifications_recipient
    FOREIGN KEY (recipient_id) REFERENCES users(user_id),
  CONSTRAINT fk_notifications_booking
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER $$

-- course_info.teacher_id 必須對應 teacher 角色。
CREATE TRIGGER trg_course_info_validate_teacher_insert
BEFORE INSERT ON course_info
FOR EACH ROW
BEGIN
  DECLARE actor_id CHAR(80);
  DECLARE actor_role CHAR(10);

  SET actor_id = SUBSTRING_INDEX(USER(), '@', 1);
  SET actor_role = (
    SELECT CAST(u.role AS CHAR)
    FROM users AS u
    WHERE u.user_id = actor_id
  );

  IF NOT EXISTS (
    SELECT 1 FROM users AS u
    WHERE u.user_id = NEW.teacher_id
      AND u.role = 'teacher'
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'course teacher must reference a teacher user';
  END IF;

  IF actor_role = 'teacher' AND NEW.teacher_id <> actor_id THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'teacher may only create courses assigned to self';
  END IF;
END$$

CREATE TRIGGER trg_course_info_validate_teacher_update
BEFORE UPDATE ON course_info
FOR EACH ROW
BEGIN
  DECLARE actor_id CHAR(80);
  DECLARE actor_role CHAR(10);

  SET actor_id = SUBSTRING_INDEX(USER(), '@', 1);
  SET actor_role = (
    SELECT CAST(u.role AS CHAR)
    FROM users AS u
    WHERE u.user_id = actor_id
  );

  IF NOT EXISTS (
    SELECT 1 FROM users AS u
    WHERE u.user_id = NEW.teacher_id
      AND u.role = 'teacher'
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'course teacher must reference a teacher user';
  END IF;

  IF actor_role = 'teacher'
     AND (OLD.teacher_id <> actor_id OR NEW.teacher_id <> actor_id) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'teacher may only update courses assigned to self';
  END IF;
END$$

-- 固定課表：同一教室、同一星期不可出現節次重疊。
CREATE TRIGGER trg_course_times_prevent_overlap_insert
BEFORE INSERT ON course_times
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1
    FROM course_times AS existing
    WHERE existing.classroom_id = NEW.classroom_id
      AND existing.day_of_week = NEW.day_of_week
      AND NEW.start_section_id <= existing.end_section_id
      AND NEW.end_section_id >= existing.start_section_id
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'course time overlaps an existing classroom schedule';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM bookings AS existing
    JOIN booking_statuses AS bs ON bs.status_id = existing.status_id
    WHERE existing.classroom_id = NEW.classroom_id
      AND WEEKDAY(existing.booking_date) + 1 = NEW.day_of_week
      AND bs.status_code = 'approved'
      AND NEW.start_section_id <= existing.end_section_id
      AND NEW.end_section_id >= existing.start_section_id
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'course time overlaps an approved booking';
  END IF;
END$$

CREATE TRIGGER trg_course_times_prevent_overlap_update
BEFORE UPDATE ON course_times
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1
    FROM course_times AS existing
    WHERE existing.course_time_id <> NEW.course_time_id
      AND existing.classroom_id = NEW.classroom_id
      AND existing.day_of_week = NEW.day_of_week
      AND NEW.start_section_id <= existing.end_section_id
      AND NEW.end_section_id >= existing.start_section_id
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'course time overlaps an existing classroom schedule';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM bookings AS existing
    JOIN booking_statuses AS bs ON bs.status_id = existing.status_id
    WHERE existing.classroom_id = NEW.classroom_id
      AND WEEKDAY(existing.booking_date) + 1 = NEW.day_of_week
      AND bs.status_code = 'approved'
      AND NEW.start_section_id <= existing.end_section_id
      AND NEW.end_section_id >= existing.start_section_id
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'course time overlaps an approved booking';
  END IF;
END$$

-- 長期借用：僅教師可建立自己的待審核申請，管理員可管理全部案件。
CREATE TRIGGER trg_long_term_validate_insert
BEFORE INSERT ON long_term_bookings
FOR EACH ROW
BEGIN
  DECLARE actor_id CHAR(80);
  DECLARE actor_role CHAR(10);
  DECLARE new_status CHAR(10);

  SET actor_id = SUBSTRING_INDEX(USER(), '@', 1);
  SET actor_role = (
    SELECT CAST(u.role AS CHAR)
    FROM users AS u
    WHERE u.user_id = actor_id
  );
  SET new_status = (
    SELECT CAST(bs.status_code AS CHAR)
    FROM booking_statuses AS bs
    WHERE bs.status_id = NEW.status_id
  );

  IF NOT EXISTS (
    SELECT 1 FROM users AS u
    WHERE u.user_id = NEW.applicant_id
      AND u.role IN ('student', 'teacher')
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'long-term applicant must be a student or teacher';
  END IF;

  IF actor_role = 'student' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'student role cannot create long-term bookings';
  END IF;

  IF actor_role = 'teacher'
     AND (NEW.applicant_id <> actor_id OR new_status <> 'pending') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'teacher may only create own pending long-term booking';
  END IF;
END$$

CREATE TRIGGER trg_long_term_validate_update
BEFORE UPDATE ON long_term_bookings
FOR EACH ROW
BEGIN
  DECLARE actor_id CHAR(80);
  DECLARE actor_role CHAR(10);
  DECLARE old_status CHAR(10);
  DECLARE new_status CHAR(10);

  SET actor_id = SUBSTRING_INDEX(USER(), '@', 1);
  SET actor_role = (
    SELECT CAST(u.role AS CHAR)
    FROM users AS u
    WHERE u.user_id = actor_id
  );
  SET old_status = (
    SELECT CAST(bs.status_code AS CHAR)
    FROM booking_statuses AS bs
    WHERE bs.status_id = OLD.status_id
  );
  SET new_status = (
    SELECT CAST(bs.status_code AS CHAR)
    FROM booking_statuses AS bs
    WHERE bs.status_id = NEW.status_id
  );

  IF actor_role = 'student' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'student role cannot update long-term bookings';
  END IF;

  IF actor_role = 'teacher'
     AND (
       OLD.applicant_id <> actor_id
       OR NEW.applicant_id <> actor_id
       OR old_status <> 'pending'
       OR new_status NOT IN ('pending', 'canceled')
     ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'teacher may only update or cancel own pending long-term booking';
  END IF;
END$$

-- 單次預約：一般使用者只能建立自己的 pending 案件，管理員負責審核。
CREATE TRIGGER trg_bookings_prevent_overlap_insert
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
  DECLARE actor_id CHAR(80);
  DECLARE actor_role CHAR(10);
  DECLARE new_status CHAR(10);

  SET actor_id = SUBSTRING_INDEX(USER(), '@', 1);
  SET actor_role = (
    SELECT CAST(u.role AS CHAR)
    FROM users AS u
    WHERE u.user_id = actor_id
  );
  SET new_status = (
    SELECT CAST(bs.status_code AS CHAR)
    FROM booking_statuses AS bs
    WHERE bs.status_id = NEW.status_id
  );

  IF NOT EXISTS (
    SELECT 1 FROM users AS u
    WHERE u.user_id = NEW.applicant_id
      AND u.role IN ('student', 'teacher')
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'booking applicant must be a student or teacher';
  END IF;

  IF actor_role IN ('student', 'teacher')
     AND (NEW.applicant_id <> actor_id OR new_status <> 'pending') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'user may only create own pending booking';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM classrooms AS c
    WHERE c.classroom_id = NEW.classroom_id
      AND c.is_active = TRUE
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'booking classroom must be active';
  END IF;

  IF new_status = 'approved' THEN
    IF EXISTS (
      SELECT 1
      FROM course_times AS fixed
      WHERE fixed.classroom_id = NEW.classroom_id
        AND fixed.day_of_week = WEEKDAY(NEW.booking_date) + 1
        AND NEW.start_section_id <= fixed.end_section_id
        AND NEW.end_section_id >= fixed.start_section_id
    ) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'booking overlaps classroom course schedule';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM bookings AS existing
      JOIN booking_statuses AS bs ON bs.status_id = existing.status_id
      WHERE existing.classroom_id = NEW.classroom_id
        AND existing.booking_date = NEW.booking_date
        AND bs.status_code = 'approved'
        AND NEW.start_section_id <= existing.end_section_id
        AND NEW.end_section_id >= existing.start_section_id
    ) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'booking overlaps an approved booking';
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_bookings_prevent_overlap_update
BEFORE UPDATE ON bookings
FOR EACH ROW
BEGIN
  DECLARE actor_id CHAR(80);
  DECLARE actor_role CHAR(10);
  DECLARE old_status CHAR(10);
  DECLARE new_status CHAR(10);

  SET actor_id = SUBSTRING_INDEX(USER(), '@', 1);
  SET actor_role = (
    SELECT CAST(u.role AS CHAR)
    FROM users AS u
    WHERE u.user_id = actor_id
  );
  SET old_status = (
    SELECT CAST(bs.status_code AS CHAR)
    FROM booking_statuses AS bs
    WHERE bs.status_id = OLD.status_id
  );
  SET new_status = (
    SELECT CAST(bs.status_code AS CHAR)
    FROM booking_statuses AS bs
    WHERE bs.status_id = NEW.status_id
  );

  IF actor_role IN ('student', 'teacher')
     AND (
       OLD.applicant_id <> actor_id
       OR NEW.applicant_id <> actor_id
       OR old_status <> 'pending'
       OR new_status NOT IN ('pending', 'canceled')
     ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'user may only update or cancel own pending booking';
  END IF;

  IF new_status IN ('pending', 'approved')
     AND NOT EXISTS (
       SELECT 1 FROM classrooms AS c
       WHERE c.classroom_id = NEW.classroom_id
         AND c.is_active = TRUE
     ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'booking classroom must be active';
  END IF;

  IF new_status = 'approved' THEN
    IF EXISTS (
      SELECT 1
      FROM course_times AS fixed
      WHERE fixed.classroom_id = NEW.classroom_id
        AND fixed.day_of_week = WEEKDAY(NEW.booking_date) + 1
        AND NEW.start_section_id <= fixed.end_section_id
        AND NEW.end_section_id >= fixed.start_section_id
    ) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'booking overlaps classroom course schedule';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM bookings AS existing
      JOIN booking_statuses AS bs ON bs.status_id = existing.status_id
      WHERE existing.booking_id <> NEW.booking_id
        AND existing.classroom_id = NEW.classroom_id
        AND existing.booking_date = NEW.booking_date
        AND bs.status_code = 'approved'
        AND NEW.start_section_id <= existing.end_section_id
        AND NEW.end_section_id >= existing.start_section_id
    ) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'booking overlaps an approved booking';
    END IF;
  END IF;
END$$

-- booking_reviews.reviewer_id 必須對應 admin 角色。
CREATE TRIGGER trg_reviews_validate_insert
BEFORE INSERT ON booking_reviews
FOR EACH ROW
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM users AS u
    WHERE u.user_id = NEW.reviewer_id
      AND u.role = 'admin'
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'booking reviewer must reference an admin user';
  END IF;
END$$

CREATE TRIGGER trg_reviews_validate_update
BEFORE UPDATE ON booking_reviews
FOR EACH ROW
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM users AS u
    WHERE u.user_id = NEW.reviewer_id
      AND u.role = 'admin'
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'booking reviewer must reference an admin user';
  END IF;
END$$

DELIMITER ;

CREATE INDEX idx_bookings_classroom_date
  ON bookings(classroom_id, booking_date, start_section_id, end_section_id);

CREATE INDEX idx_bookings_applicant_date
  ON bookings(applicant_id, booking_date);

CREATE INDEX idx_course_times_classroom_weekday
  ON course_times(classroom_id, day_of_week, start_section_id, end_section_id);

CREATE INDEX idx_notifications_recipient_read
  ON notifications(recipient_id, is_read);

-- View 使用 USER() 取得登入 MariaDB 的帳號名稱。
-- 一般帳號名稱應與 users.user_id 相同，例如 '41243149'@'localhost'。
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_users AS
SELECT
  user_id, username, email, role, department
FROM users
WHERE user_id = SUBSTRING_INDEX(USER(), '@', 1)
   OR (
     SELECT CAST(account.role AS CHAR)
     FROM users AS account
     WHERE account.user_id = SUBSTRING_INDEX(USER(), '@', 1)
   ) = 'admin';

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_classrooms AS
SELECT
  classroom_id, classroom_name, capacity, is_active
FROM classrooms
WHERE is_active = TRUE
   OR (
     SELECT CAST(account.role AS CHAR)
     FROM users AS account
     WHERE account.user_id = SUBSTRING_INDEX(USER(), '@', 1)
   ) = 'admin'
WITH CASCADED CHECK OPTION;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_sections AS
SELECT
  section_id, section_name, start_time, end_time
FROM sections;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_booking_statuses AS
SELECT
  status_id, status_code, status_name
FROM booking_statuses;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_course_info AS
SELECT
  course_id, academic_year, semester, course_name, teacher_id
FROM course_info;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_course_times AS
SELECT
  course_time_id, course_id, classroom_id, day_of_week,
  start_section_id, end_section_id
FROM course_times;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_long_term_bookings AS
SELECT
  long_term_id, applicant_id, classroom_id, start_date, end_date,
  day_of_week, start_section_id, end_section_id, reason, status_id, created_at
FROM long_term_bookings
WHERE applicant_id = SUBSTRING_INDEX(USER(), '@', 1)
   OR (
     SELECT CAST(account.role AS CHAR)
     FROM users AS account
     WHERE account.user_id = SUBSTRING_INDEX(USER(), '@', 1)
   ) = 'admin'
WITH CASCADED CHECK OPTION;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_bookings AS
SELECT
  booking_id, applicant_id, classroom_id, long_term_id, course_time_id,
  booking_date, start_section_id, end_section_id, reason, status_id, created_at
FROM bookings
WHERE applicant_id = SUBSTRING_INDEX(USER(), '@', 1)
   OR (
     SELECT CAST(account.role AS CHAR)
     FROM users AS account
     WHERE account.user_id = SUBSTRING_INDEX(USER(), '@', 1)
   ) = 'admin'
WITH CASCADED CHECK OPTION;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_booking_reviews AS
SELECT
  review_id, booking_id, reviewer_id, status_id, comment, reviewed_at
FROM booking_reviews AS br
WHERE (
     SELECT CAST(account.role AS CHAR)
     FROM users AS account
     WHERE account.user_id = SUBSTRING_INDEX(USER(), '@', 1)
   ) = 'admin'
   OR br.reviewer_id = SUBSTRING_INDEX(USER(), '@', 1)
   OR EXISTS (
     SELECT 1
     FROM bookings AS b
     WHERE b.booking_id = br.booking_id
       AND b.applicant_id = SUBSTRING_INDEX(USER(), '@', 1)
   );

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW vw_notifications AS
SELECT
  notification_id, recipient_id, booking_id, message, is_read, created_at
FROM notifications
WHERE recipient_id = SUBSTRING_INDEX(USER(), '@', 1)
   OR (
     SELECT CAST(account.role AS CHAR)
     FROM users AS account
     WHERE account.user_id = SUBSTRING_INDEX(USER(), '@', 1)
   ) = 'admin'
WITH CASCADED CHECK OPTION;
