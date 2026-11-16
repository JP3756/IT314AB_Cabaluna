"""Apply db/migrations/001 and run the rule tests.

  python tools/run_migration.py            dry run (rolled back)
  python tools/run_migration.py --apply    keep the schema, remove the test rows
  --local uses LOCAL_DATABASE_URL instead of NEON_DATABASE_URL
"""
import sys
import psycopg
from psycopg import errors

apply = "--apply" in sys.argv
KEY = "LOCAL_DATABASE_URL" if "--local" in sys.argv else "NEON_DATABASE_URL"
url = next(l.split("=", 1)[1].strip() for l in open(".env") if l.startswith(KEY + "="))
print("TARGET:", "local Postgres" if "--local" in sys.argv else "Neon")
sql = open("db/migrations/001_create_enrollment_schema.sql", encoding="utf-8-sig").read()
# own transaction instead of the file's BEGIN/COMMIT
sql = sql.replace("\nBEGIN;", "\n", 1).rsplit("COMMIT;", 1)[0]

results = []


def expect(cur, name, stmt, params=(), sqlstate=None):
    """Run stmt in a savepoint. sqlstate=None means it must succeed."""
    cur.execute("SAVEPOINT t")
    try:
        cur.execute(stmt, params)
        ok = sqlstate is None
        got = "ok"
    except psycopg.Error as e:
        ok = sqlstate is not None and e.sqlstate == sqlstate
        got = e.sqlstate
    cur.execute("ROLLBACK TO SAVEPOINT t")
    results.append((ok, name, got))


with psycopg.connect(url, connect_timeout=20, autocommit=False) as c:
    cur = c.cursor()
    cur.execute("select count(*) from information_schema.tables where table_schema='public'")
    if cur.fetchone()[0] != 0:
        sys.exit("public schema is not empty; aborting")
    cur.execute(sql)

    # test data
    cur.execute("insert into student(student_number,first_name,last_name,email,course,year_level) values "
                "('S1','A','A','a@x.com','BSIT',1),('S2','B','B','b@x.com','BSIT',2) returning student_id")
    s1, s2 = [r[0] for r in cur.fetchall()]
    cur.execute("insert into subject(subject_code,subject_name,units) values ('IT1','One',3),('IT2','Two',3),('IT3','Three',3) returning subject_id")
    j1, j2, j3 = [r[0] for r in cur.fetchall()]
    cur.execute("insert into schedule(subject_id,day_of_week,start_time,end_time,room,slot_capacity) values "
                "(%s,'Monday','08:00','10:00','R1',1),(%s,'Monday','09:00','11:00','R2',5),(%s,'Tuesday','08:00','10:00','R1',5) returning schedule_id",
                (j1, j2, j3))
    c1, c2, c3 = [r[0] for r in cur.fetchall()]

    E = "insert into enrollment(student_id,subject_id,schedule_id) values (%s,%s,%s)"
    expect(cur, "bad year_level 5", "insert into student(student_number,first_name,last_name,email,course,year_level) values ('S9','x','x','z@x.com','c',5)", sqlstate="23514")
    expect(cur, "duplicate student_number", "insert into student(student_number,first_name,last_name,email,course,year_level) values ('S1','x','x','q@x.com','c',1)", sqlstate="23505")
    expect(cur, "units 0", "insert into subject(subject_code,subject_name,units) values ('Z','z',0)", sqlstate="23514")
    expect(cur, "end before start", "insert into schedule(subject_id,day_of_week,start_time,end_time,room,slot_capacity) values (%s,'Friday','10:00','09:00','R9',5)", (j1,), "23514")
    expect(cur, "capacity 0", "insert into schedule(subject_id,day_of_week,start_time,end_time,room,slot_capacity) values (%s,'Friday','09:00','10:00','R9',0)", (j1,), "23514")
    expect(cur, "bad day name", "insert into schedule(subject_id,day_of_week,start_time,end_time,room,slot_capacity) values (%s,'Funday','09:00','10:00','R9',5)", (j1,), "23514")
    expect(cur, "room double-booked", "insert into schedule(subject_id,day_of_week,start_time,end_time,room,slot_capacity) values (%s,'Monday','09:00','09:30','R1',5)", (j2,), "23P01")
    expect(cur, "schedule not of subject", E, (s1, j2, c1), "23503")

    cur.execute(E + " returning enrollment_id", (s1, j1, c1))
    e1 = cur.fetchone()[0]
    expect(cur, "duplicate enrollment", E, (s1, j1, c1), "23505")
    expect(cur, "slot capacity full", E, (s2, j1, c1), "EN002")
    expect(cur, "schedule conflict", E, (s1, j2, c2), "EN001")
    expect(cur, "non-conflicting enroll", E, (s1, j3, c3))
    expect(cur, "bad status", "update enrollment set status='Pending' where enrollment_id=%s", (e1,), "23514")

    expect(cur, "grade 101", "insert into grades(enrollment_id,grade_value) values (%s,101)", (e1,), "23514")
    expect(cur, "grade for unknown enrollment", "insert into grades(enrollment_id,grade_value) values (999999,90)", sqlstate="EN003")
    cur.execute("insert into grades(enrollment_id,grade_value) values (%s,90)", (e1,))
    expect(cur, "second grade for same enrollment", "insert into grades(enrollment_id,grade_value) values (%s,80)", (e1,), "23505")
    expect(cur, "drop blocked when graded", "update enrollment set status='Dropped' where enrollment_id=%s", (e1,), "EN004")
    expect(cur, "delete student with enrollment", "delete from student where student_id=%s", (s1,), "23001")

    cur.execute("delete from grades where enrollment_id=%s", (e1,))
    cur.execute("update enrollment set status='Dropped' where enrollment_id=%s", (e1,))
    expect(cur, "dropped frees seat", E, (s2, j1, c1))
    expect(cur, "grade on dropped enrollment", "insert into grades(enrollment_id,grade_value) values (%s,90)", (e1,), "EN003")
    expect(cur, "re-enroll after drop", "update enrollment set status='Enrolled' where enrollment_id=%s", (e1,))
    cur.execute(E, (s1, j3, c3))   # c3 now has s1 and s2 enrolled
    cur.execute(E, (s2, j3, c3))
    cur.execute(E, (s2, j2, c2))   # s2 also has Monday 09:00-11:00
    expect(cur, "capacity below enrolled count", "update schedule set slot_capacity=1 where schedule_id=%s", (c3,), "EN002")
    expect(cur, "move schedule into a student's other class", "update schedule set day_of_week='Monday', start_time='09:00', end_time='10:00', room='R7' where schedule_id=%s", (c3,), "EN001")

    for ok, name, got in results:
        print(("PASS " if ok else "FAIL ") + name + "  [" + str(got) + "]")
    failed = [r for r in results if not r[0]]

    if failed or not apply:
        c.rollback()
        print("\nROLLED BACK.", "Failures: %d" % len(failed) if failed else "Dry run OK, nothing changed.")
        sys.exit(1 if failed else 0)

    # remove test rows, keep the schema
    cur.execute("truncate grades, enrollment, schedule, subject, student restart identity")
    c.commit()
    print("\nCOMMITTED. Schema created, test rows removed.")
