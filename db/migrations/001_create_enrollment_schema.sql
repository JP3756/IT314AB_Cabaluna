-- Enrollment System schema (IT313AB). Run once on the existing Neon database, in one transaction.
-- Field names follow the PDF. Business rules live here (keys, CHECKs, triggers), not only in the app.
BEGIN;

CREATE EXTENSION IF NOT EXISTS btree_gist;   -- needed only for the room double-booking rule

-- master tables
CREATE TABLE student (
    student_id      SERIAL       PRIMARY KEY,
    student_number  VARCHAR(20)  NOT NULL,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    email           VARCHAR(100) NOT NULL,
    course          VARCHAR(100) NOT NULL,
    year_level      SMALLINT     NOT NULL,
    contact_number  VARCHAR(20),
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_student_student_number UNIQUE (student_number),
    CONSTRAINT uq_student_email          UNIQUE (email),
    CONSTRAINT ck_student_year_level     CHECK (year_level BETWEEN 1 AND 4),
    CONSTRAINT ck_student_email_format   CHECK (email LIKE '%_@_%._%')
);

CREATE TABLE subject (
    subject_id    SERIAL       PRIMARY KEY,
    subject_code  VARCHAR(20)  NOT NULL,
    subject_name  VARCHAR(150) NOT NULL,
    units         SMALLINT     NOT NULL,
    description   TEXT,
    CONSTRAINT uq_subject_subject_code UNIQUE (subject_code),
    CONSTRAINT ck_subject_units        CHECK (units BETWEEN 1 AND 6)   -- ASSUMPTION: range not confirmed
);

CREATE TABLE schedule (
    schedule_id    SERIAL      PRIMARY KEY,
    subject_id     INTEGER     NOT NULL REFERENCES subject (subject_id)
                               ON UPDATE RESTRICT ON DELETE RESTRICT,
    day_of_week    VARCHAR(9)  NOT NULL,
    start_time     TIME        NOT NULL,
    end_time       TIME        NOT NULL,
    room           VARCHAR(30) NOT NULL,
    slot_capacity  SMALLINT    NOT NULL,
    CONSTRAINT ck_schedule_day_of_week   CHECK (day_of_week IN
        ('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')),
    CONSTRAINT ck_schedule_time_order    CHECK (end_time > start_time),
    CONSTRAINT ck_schedule_slot_capacity CHECK (slot_capacity > 0),
    -- lets enrollment check that its schedule belongs to its subject
    CONSTRAINT uq_schedule_id_subject    UNIQUE (schedule_id, subject_id),
    -- no overlapping bookings for the same room and day
    CONSTRAINT ex_schedule_room_overlap  EXCLUDE USING gist (
        room        WITH =,
        day_of_week WITH =,
        tsrange(DATE '2000-01-01' + start_time, DATE '2000-01-01' + end_time) WITH &&
    )
);

-- transactional tables
CREATE TABLE enrollment (
    enrollment_id  SERIAL      PRIMARY KEY,
    student_id     INTEGER     NOT NULL REFERENCES student  (student_id)
                               ON UPDATE RESTRICT ON DELETE RESTRICT,
    subject_id     INTEGER     NOT NULL REFERENCES subject  (subject_id)
                               ON UPDATE RESTRICT ON DELETE RESTRICT,
    schedule_id    INTEGER     NOT NULL REFERENCES schedule (schedule_id)
                               ON UPDATE RESTRICT ON DELETE RESTRICT,
    enrolled_at    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status         VARCHAR(10) NOT NULL DEFAULT 'Enrolled',
    CONSTRAINT ck_enrollment_status  CHECK (status IN ('Enrolled','Dropped')),
    -- no duplicate enrollment (a drop is a status change; re-enrolling flips it back)
    CONSTRAINT uq_enrollment_student_subject UNIQUE (student_id, subject_id),
    -- the chosen schedule must belong to the chosen subject
    CONSTRAINT fk_enrollment_schedule_subject FOREIGN KEY (schedule_id, subject_id)
        REFERENCES schedule (schedule_id, subject_id)
);
CREATE INDEX ix_enrollment_schedule_status ON enrollment (schedule_id, status);
CREATE INDEX ix_enrollment_student_status  ON enrollment (student_id, status);

CREATE TABLE grades (
    grade_id       SERIAL        PRIMARY KEY,
    enrollment_id  INTEGER       NOT NULL REFERENCES enrollment (enrollment_id)
                                 ON UPDATE RESTRICT ON DELETE RESTRICT,
    grade_value    NUMERIC(5,2)  NOT NULL,
    remarks        VARCHAR(255),
    date_recorded  DATE          NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT uq_grades_enrollment_id UNIQUE (enrollment_id),         -- at most one grade per enrollment
    CONSTRAINT ck_grades_grade_value   CHECK (grade_value BETWEEN 0 AND 100)
);

-- enrollment rules: slot capacity and schedule conflicts.
-- Advisory locks (student, then schedule) keep concurrent enrollments safe.
-- Error codes: EN001 schedule conflict, EN002 no free slots, EN003 grade needs Enrolled, EN004 drop blocked by a grade
CREATE FUNCTION fn_enrollment_check() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_cap   SMALLINT;
    v_day   VARCHAR(9);
    v_start TIME;
    v_end   TIME;
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.status = 'Enrolled' AND NEW.status = 'Dropped' THEN
        IF EXISTS (SELECT 1 FROM grades WHERE enrollment_id = OLD.enrollment_id) THEN
            RAISE EXCEPTION 'DROP_BLOCKED_HAS_GRADE: enrollment % already has a grade', OLD.enrollment_id
                USING ERRCODE = 'EN004';
        END IF;
    END IF;

    IF TG_OP = 'INSERT' AND EXISTS (SELECT 1 FROM enrollment
         WHERE student_id = NEW.student_id AND subject_id = NEW.subject_id) THEN
        RAISE EXCEPTION 'DUPLICATE_ENROLLMENT: student % is already enrolled in subject %', NEW.student_id, NEW.subject_id
            USING ERRCODE = '23505';
    END IF;

    IF NEW.status <> 'Enrolled' THEN
        RETURN NEW;                          -- Dropped rows consume no seat and no time slot
    END IF;

    PERFORM pg_advisory_xact_lock(1, NEW.student_id);
    PERFORM pg_advisory_xact_lock(2, NEW.schedule_id);

    SELECT slot_capacity, day_of_week, start_time, end_time
      INTO v_cap, v_day, v_start, v_end
      FROM schedule WHERE schedule_id = NEW.schedule_id;

    IF (SELECT count(*) FROM enrollment e
         WHERE e.schedule_id = NEW.schedule_id AND e.status = 'Enrolled'
           AND e.enrollment_id IS DISTINCT FROM NEW.enrollment_id) >= v_cap THEN
        RAISE EXCEPTION 'SLOT_CAPACITY_FULL: schedule % has no free slots', NEW.schedule_id
            USING ERRCODE = 'EN002';
    END IF;

    IF EXISTS (SELECT 1
                 FROM enrollment e JOIN schedule s ON s.schedule_id = e.schedule_id
                WHERE e.student_id = NEW.student_id AND e.status = 'Enrolled'
                  AND e.enrollment_id IS DISTINCT FROM NEW.enrollment_id
                  AND s.day_of_week = v_day
                  AND s.start_time < v_end AND s.end_time > v_start) THEN
        RAISE EXCEPTION 'SCHEDULE_CONFLICT: student % already has a class overlapping this schedule', NEW.student_id
            USING ERRCODE = 'EN001';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_enrollment_check
    BEFORE INSERT OR UPDATE OF student_id, schedule_id, status ON enrollment
    FOR EACH ROW EXECUTE FUNCTION fn_enrollment_check();

-- editing a schedule must not break students who are already enrolled
CREATE FUNCTION fn_schedule_update_check() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    PERFORM pg_advisory_xact_lock(2, NEW.schedule_id);

    IF (SELECT count(*) FROM enrollment
         WHERE schedule_id = NEW.schedule_id AND status = 'Enrolled') > NEW.slot_capacity THEN
        RAISE EXCEPTION 'SLOT_CAPACITY_FULL: new capacity is below the number of enrolled students'
            USING ERRCODE = 'EN002';
    END IF;

    IF NEW.day_of_week <> OLD.day_of_week OR NEW.start_time <> OLD.start_time OR NEW.end_time <> OLD.end_time THEN
        IF EXISTS (SELECT 1
                     FROM enrollment e1
                     JOIN enrollment e2 ON e2.student_id = e1.student_id
                                       AND e2.enrollment_id <> e1.enrollment_id
                                       AND e2.status = 'Enrolled'
                     JOIN schedule s2 ON s2.schedule_id = e2.schedule_id
                    WHERE e1.schedule_id = NEW.schedule_id AND e1.status = 'Enrolled'
                      AND s2.day_of_week = NEW.day_of_week
                      AND s2.start_time < NEW.end_time AND s2.end_time > NEW.start_time) THEN
            RAISE EXCEPTION 'SCHEDULE_CONFLICT: the new time overlaps another class of an enrolled student'
                USING ERRCODE = 'EN001';
        END IF;
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_schedule_update_check
    BEFORE UPDATE OF day_of_week, start_time, end_time, slot_capacity ON schedule
    FOR EACH ROW EXECUTE FUNCTION fn_schedule_update_check();

-- grades only for an existing, Enrolled enrollment (FOR SHARE blocks a concurrent drop)
CREATE FUNCTION fn_grades_check() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_status VARCHAR(10);
BEGIN
    SELECT status INTO v_status FROM enrollment
     WHERE enrollment_id = NEW.enrollment_id FOR SHARE;
    IF v_status IS DISTINCT FROM 'Enrolled' THEN
        RAISE EXCEPTION 'GRADE_REQUIRES_ENROLLED: enrollment % is not in Enrolled status', NEW.enrollment_id
            USING ERRCODE = 'EN003';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_grades_check
    BEFORE INSERT OR UPDATE OF enrollment_id ON grades
    FOR EACH ROW EXECUTE FUNCTION fn_grades_check();

COMMIT;
