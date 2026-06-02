-- 教室租用系統：完整資料庫 Schema
-- Target DBMS: SQLite 3
-- 使用方式：sqlite3 classroom_rental.db < Part2_schema.sql

PRAGMA foreign_keys = ON;

DROP TRIGGER IF EXISTS trg_bookings_prevent_overlap_update;
DROP TRIGGER IF EXISTS trg_bookings_prevent_overlap_insert;
DROP TRIGGER IF EXISTS trg_course_times_prevent_overlap_update;
DROP TRIGGER IF EXISTS trg_course_times_prevent_overlap_insert;

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
  username    VARCHAR(30) NOT NULL,
  email       VARCHAR(100) NOT NULL UNIQUE,
  role        VARCHAR(10) NOT NULL
              CONSTRAINT chk_users_role
              CHECK (role IN ('student', 'teacher', 'admin')),
  department  VARCHAR(50)
);

CREATE TABLE classrooms (
  classroom_id    VARCHAR(10) PRIMARY KEY,
  classroom_name  VARCHAR(50) NOT NULL,
  capacity        INTEGER NOT NULL
                  CONSTRAINT chk_classrooms_capacity CHECK (capacity > 0),
  is_active       INTEGER NOT NULL DEFAULT 1
                  CONSTRAINT chk_classrooms_active CHECK (is_active IN (0, 1))
);

CREATE TABLE sections (
  section_id    INTEGER PRIMARY KEY,
  section_name  VARCHAR(20) NOT NULL UNIQUE,
  start_time    CHAR(5) NOT NULL,
  end_time      CHAR(5) NOT NULL,
  CONSTRAINT chk_sections_range CHECK (start_time < end_time)
);

CREATE TABLE booking_statuses (
  status_id    INTEGER PRIMARY KEY,
  status_code  VARCHAR(10) NOT NULL UNIQUE
               CONSTRAINT chk_statuses_code
               CHECK (status_code IN ('pending', 'approved', 'rejected', 'canceled')),
  status_name  VARCHAR(20) NOT NULL
);

CREATE TABLE course_info (
  course_id       VARCHAR(20) PRIMARY KEY,
  academic_year   INTEGER NOT NULL,
  semester        INTEGER NOT NULL
                  CONSTRAINT chk_course_info_semester CHECK (semester IN (1, 2)),
  course_name     VARCHAR(100) NOT NULL,
  teacher_id      CHAR(8) NOT NULL,
  CONSTRAINT fk_course_info_teacher
    FOREIGN KEY (teacher_id) REFERENCES users(user_id)
);

CREATE TABLE course_times (
  course_time_id    INTEGER PRIMARY KEY AUTOINCREMENT,
  course_id         VARCHAR(20) NOT NULL,
  classroom_id      VARCHAR(10) NOT NULL,
  day_of_week       INTEGER NOT NULL
                    CONSTRAINT chk_course_times_weekday CHECK (day_of_week BETWEEN 1 AND 7),
  start_section_id  INTEGER NOT NULL,
  end_section_id    INTEGER NOT NULL,
  CONSTRAINT chk_course_times_section_range CHECK (start_section_id <= end_section_id),
  CONSTRAINT fk_course_times_course
    FOREIGN KEY (course_id) REFERENCES course_info(course_id),
  CONSTRAINT fk_course_times_classroom
    FOREIGN KEY (classroom_id) REFERENCES classrooms(classroom_id),
  CONSTRAINT fk_course_times_start_section
    FOREIGN KEY (start_section_id) REFERENCES sections(section_id),
  CONSTRAINT fk_course_times_end_section
    FOREIGN KEY (end_section_id) REFERENCES sections(section_id)
);

CREATE TABLE long_term_bookings (
  long_term_id       INTEGER PRIMARY KEY AUTOINCREMENT,
  applicant_id       CHAR(8) NOT NULL,
  classroom_id       VARCHAR(10) NOT NULL,
  start_date         DATE NOT NULL,
  end_date           DATE NOT NULL,
  day_of_week        INTEGER NOT NULL
                     CONSTRAINT chk_long_term_weekday CHECK (day_of_week BETWEEN 1 AND 7),
  start_section_id   INTEGER NOT NULL,
  end_section_id     INTEGER NOT NULL,
  reason             VARCHAR(200) NOT NULL,
  status_id          INTEGER NOT NULL,
  created_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_long_term_date_range CHECK (start_date <= end_date),
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
);

CREATE TABLE bookings (
  booking_id         INTEGER PRIMARY KEY AUTOINCREMENT,
  applicant_id       CHAR(8) NOT NULL,
  classroom_id       VARCHAR(10) NOT NULL,
  long_term_id       INTEGER,
  course_time_id     INTEGER,
  booking_date       DATE NOT NULL,
  start_section_id   INTEGER NOT NULL,
  end_section_id     INTEGER NOT NULL,
  reason             VARCHAR(200) NOT NULL,
  status_id          INTEGER NOT NULL,
  created_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
);

CREATE TABLE booking_reviews (
  review_id    INTEGER PRIMARY KEY AUTOINCREMENT,
  booking_id   INTEGER NOT NULL,
  reviewer_id  CHAR(8) NOT NULL,
  status_id    INTEGER NOT NULL,
  comment      VARCHAR(300),
  reviewed_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reviews_booking
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
  CONSTRAINT fk_reviews_reviewer
    FOREIGN KEY (reviewer_id) REFERENCES users(user_id),
  CONSTRAINT fk_reviews_status
    FOREIGN KEY (status_id) REFERENCES booking_statuses(status_id)
);

CREATE TABLE notifications (
  notification_id  INTEGER PRIMARY KEY AUTOINCREMENT,
  recipient_id     CHAR(8) NOT NULL,
  booking_id       INTEGER,
  message          VARCHAR(300) NOT NULL,
  is_read          INTEGER NOT NULL DEFAULT 0
                   CONSTRAINT chk_notifications_read CHECK (is_read IN (0, 1)),
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notifications_recipient
    FOREIGN KEY (recipient_id) REFERENCES users(user_id),
  CONSTRAINT fk_notifications_booking
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

-- 固定課表：同一教室、同一星期不可出現節次重疊。
CREATE TRIGGER trg_course_times_prevent_overlap_insert
BEFORE INSERT ON course_times
BEGIN
  SELECT CASE WHEN EXISTS (
    SELECT 1
    FROM course_times existing
    WHERE existing.classroom_id = NEW.classroom_id
      AND existing.day_of_week = NEW.day_of_week
      AND NEW.start_section_id <= existing.end_section_id
      AND NEW.end_section_id >= existing.start_section_id
  ) THEN RAISE(ABORT, 'course time overlaps an existing classroom schedule') END;
  SELECT CASE WHEN EXISTS (
    SELECT 1
    FROM bookings existing
    JOIN booking_statuses status ON status.status_id = existing.status_id
    WHERE existing.classroom_id = NEW.classroom_id
      AND (
        CASE CAST(strftime('%w', existing.booking_date) AS INTEGER)
          WHEN 0 THEN 7
          ELSE CAST(strftime('%w', existing.booking_date) AS INTEGER)
        END
      ) = NEW.day_of_week
      AND status.status_code = 'approved'
      AND NEW.start_section_id <= existing.end_section_id
      AND NEW.end_section_id >= existing.start_section_id
  ) THEN RAISE(ABORT, 'course time overlaps an approved booking') END;
END;

CREATE TRIGGER trg_course_times_prevent_overlap_update
BEFORE UPDATE ON course_times
BEGIN
  SELECT CASE WHEN EXISTS (
    SELECT 1
    FROM course_times existing
    WHERE existing.course_time_id <> NEW.course_time_id
      AND existing.classroom_id = NEW.classroom_id
      AND existing.day_of_week = NEW.day_of_week
      AND NEW.start_section_id <= existing.end_section_id
      AND NEW.end_section_id >= existing.start_section_id
  ) THEN RAISE(ABORT, 'course time overlaps an existing classroom schedule') END;
  SELECT CASE WHEN EXISTS (
    SELECT 1
    FROM bookings existing
    JOIN booking_statuses status ON status.status_id = existing.status_id
    WHERE existing.classroom_id = NEW.classroom_id
      AND (
        CASE CAST(strftime('%w', existing.booking_date) AS INTEGER)
          WHEN 0 THEN 7
          ELSE CAST(strftime('%w', existing.booking_date) AS INTEGER)
        END
      ) = NEW.day_of_week
      AND status.status_code = 'approved'
      AND NEW.start_section_id <= existing.end_section_id
      AND NEW.end_section_id >= existing.start_section_id
  ) THEN RAISE(ABORT, 'course time overlaps an approved booking') END;
END;

-- 單次預約：只有 approved 狀態會占用教室，待審核案件可先並存。
CREATE TRIGGER trg_bookings_prevent_overlap_insert
BEFORE INSERT ON bookings
WHEN (SELECT status_code FROM booking_statuses WHERE status_id = NEW.status_id) = 'approved'
BEGIN
  SELECT CASE WHEN EXISTS (
    SELECT 1
    FROM course_times fixed
    WHERE fixed.classroom_id = NEW.classroom_id
      AND fixed.day_of_week = (
        CASE CAST(strftime('%w', NEW.booking_date) AS INTEGER)
          WHEN 0 THEN 7
          ELSE CAST(strftime('%w', NEW.booking_date) AS INTEGER)
        END
      )
      AND NEW.start_section_id <= fixed.end_section_id
      AND NEW.end_section_id >= fixed.start_section_id
  ) THEN RAISE(ABORT, 'booking overlaps classroom course schedule') END;
  SELECT CASE WHEN EXISTS (
    SELECT 1
    FROM bookings existing
    JOIN booking_statuses status ON status.status_id = existing.status_id
    WHERE existing.classroom_id = NEW.classroom_id
      AND existing.booking_date = NEW.booking_date
      AND status.status_code = 'approved'
      AND NEW.start_section_id <= existing.end_section_id
      AND NEW.end_section_id >= existing.start_section_id
  ) THEN RAISE(ABORT, 'booking overlaps an approved booking') END;
END;

CREATE TRIGGER trg_bookings_prevent_overlap_update
BEFORE UPDATE ON bookings
WHEN (SELECT status_code FROM booking_statuses WHERE status_id = NEW.status_id) = 'approved'
BEGIN
  SELECT CASE WHEN EXISTS (
    SELECT 1
    FROM course_times fixed
    WHERE fixed.classroom_id = NEW.classroom_id
      AND fixed.day_of_week = (
        CASE CAST(strftime('%w', NEW.booking_date) AS INTEGER)
          WHEN 0 THEN 7
          ELSE CAST(strftime('%w', NEW.booking_date) AS INTEGER)
        END
      )
      AND NEW.start_section_id <= fixed.end_section_id
      AND NEW.end_section_id >= fixed.start_section_id
  ) THEN RAISE(ABORT, 'booking overlaps classroom course schedule') END;
  SELECT CASE WHEN EXISTS (
    SELECT 1
    FROM bookings existing
    JOIN booking_statuses status ON status.status_id = existing.status_id
    WHERE existing.booking_id <> NEW.booking_id
      AND existing.classroom_id = NEW.classroom_id
      AND existing.booking_date = NEW.booking_date
      AND status.status_code = 'approved'
      AND NEW.start_section_id <= existing.end_section_id
      AND NEW.end_section_id >= existing.start_section_id
  ) THEN RAISE(ABORT, 'booking overlaps an approved booking') END;
END;

CREATE INDEX idx_bookings_classroom_date
  ON bookings(classroom_id, booking_date, start_section_id, end_section_id);

CREATE INDEX idx_bookings_applicant_date
  ON bookings(applicant_id, booking_date);

CREATE INDEX idx_course_times_classroom_weekday
  ON course_times(classroom_id, day_of_week, start_section_id, end_section_id);

CREATE INDEX idx_notifications_recipient_read
  ON notifications(recipient_id, is_read);
