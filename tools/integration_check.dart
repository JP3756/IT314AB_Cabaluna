// ignore_for_file: avoid_print
// Runs the repositories against the LOCAL database and cleans up after itself.
//   dart run tools/integration_check.dart native   (direct connection)
//   dart run tools/integration_check.dart http     (needs tools/local_bridge.dart running)
import 'dart:io';

import 'package:student_directory/core/db/db_service.dart';
import 'package:student_directory/core/db/http_db_service.dart';
import 'package:student_directory/core/db/postgres_db_service.dart';
import 'package:student_directory/models/grades.dart';
import 'package:student_directory/models/schedule.dart';
import 'package:student_directory/models/student.dart';
import 'package:student_directory/models/subject.dart';
import 'package:student_directory/repositories/enrollment_repository.dart';
import 'package:student_directory/repositories/grades_repository.dart';
import 'package:student_directory/repositories/schedule_repository.dart';
import 'package:student_directory/repositories/student_repository.dart';
import 'package:student_directory/repositories/subject_repository.dart';

int failures = 0;

void check(String name, bool ok, [Object? detail]) {
  print('${ok ? 'PASS' : 'FAIL'}  $name${ok ? '' : '  -> $detail'}');
  if (!ok) failures++;
}

Future<void> rejects(String name, Future<void> Function() action, String code) async {
  try {
    await action();
    check(name, false, 'no error');
  } on DbException catch (e) {
    check(name, e.code == code, 'got ${e.code}: ${e.message}');
  }
}

Future<void> main(List<String> args) async {
  final mode = args.isEmpty ? 'native' : args.first;
  final env = <String, String>{};
  for (final l in File('.env.app').readAsLinesSync()) {
    final i = l.indexOf('=');
    if (i > 0) env[l.substring(0, i)] = l.substring(i + 1).trim();
  }
  final db = mode == 'http'
      ? HttpDbService(endpoint: Uri.parse('http://localhost:4000/sql'), description: 'bridge')
      : PostgresDbService(connectionString: env['LOCAL_DATABASE_URL']!, description: 'local');
  print('Mode: $mode');

  final students = StudentRepository(db);
  final subjects = SubjectRepository(db);
  final schedules = ScheduleRepository(db);
  final enrollments = EnrollmentRepository(db);
  final grades = GradesRepository(db);

  // remove leftovers from earlier runs
  Future<void> cleanup() async {
    await db.query("DELETE FROM grades WHERE enrollment_id IN (SELECT enrollment_id FROM enrollment WHERE student_id IN (SELECT student_id FROM student WHERE student_number LIKE 'ZT-%'))");
    await db.query("DELETE FROM enrollment WHERE student_id IN (SELECT student_id FROM student WHERE student_number LIKE 'ZT-%')");
    await db.query("DELETE FROM schedule WHERE subject_id IN (SELECT subject_id FROM subject WHERE subject_code LIKE 'ZT-%')");
    await db.query("DELETE FROM subject WHERE subject_code LIKE 'ZT-%'");
    await db.query("DELETE FROM student WHERE student_number LIKE 'ZT-%'");
  }

  try {
    await cleanup();

    final a = await students.create(const Student(
        student_number: 'ZT-1', first_name: 'Ana', last_name: 'Zed', email: 'zt1@test.com', course: 'BSIT', year_level: 3));
    final b = await students.create(const Student(
        student_number: 'ZT-2', first_name: 'Ben', last_name: 'Zed', email: 'zt2@test.com', course: 'BSIT', year_level: 2, contact_number: '09171234567'));
    check('student create returns id + created_at', a.student_id != null && a.created_at != null, a);
    check('student contact_number optional round-trip', a.contact_number == null && b.contact_number == '09171234567');
    final upd = await students.update(Student(
        student_id: a.student_id, student_number: 'ZT-1', first_name: 'Anna', last_name: 'Zed', email: 'zt1@test.com', course: 'BSIT', year_level: 4));
    check('student update', upd.first_name == 'Anna' && upd.year_level == 4);
    check('student search', (await students.list(search: 'zt-')).length == 2);
    await rejects('student duplicate number rejected', () async => await students.create(const Student(
        student_number: 'ZT-1', first_name: 'x', last_name: 'x', email: 'other@test.com', course: 'c', year_level: 1)), '23505');
    await rejects('student year_level 5 rejected', () async => await students.create(const Student(
        student_number: 'ZT-9', first_name: 'x', last_name: 'x', email: 'n9@test.com', course: 'c', year_level: 5)), '23514');

    final s1 = await subjects.create(const Subject(subject_code: 'ZT-A', subject_name: 'Alpha', units: 3));
    final s2 = await subjects.create(const Subject(subject_code: 'ZT-B', subject_name: 'Beta', units: 2, description: 'second'));
    check('subject create + description', s2.description == 'second' && s1.units == 3);
    await rejects('subject units 9 rejected', () async => await subjects.create(const Subject(subject_code: 'ZT-C', subject_name: 'c', units: 9)), '23514');

    Schedule sch(int subjectId, String day, String start, String end, String room, int cap) =>
        Schedule(subject_id: subjectId, day_of_week: day, start_time: start, end_time: end, room: room, slot_capacity: cap);
    await schedules.create(sch(s1.subject_id!, 'Monday', '08:00', '10:00', 'ZT-R1', 1));
    await schedules.create(sch(s2.subject_id!, 'Monday', '09:00', '11:00', 'ZT-R2', 5));
    final listed = await schedules.list();
    final c1 = listed.firstWhere((d) => d.subject_code == 'ZT-A');
    final c2 = listed.firstWhere((d) => d.subject_code == 'ZT-B');
    check('schedule list: time as HH:mm:ss text + enrolled_count', c1.schedule.start_time.startsWith('08:00') && c1.enrolled_count == 0, c1.schedule.start_time);
    await rejects('schedule end before start rejected', () async => await schedules.create(sch(s1.subject_id!, 'Friday', '10:00', '09:00', 'ZT-R9', 5)), '23514');
    await rejects('schedule capacity 0 rejected', () async => await schedules.create(sch(s1.subject_id!, 'Friday', '09:00', '10:00', 'ZT-R9', 0)), '23514');
    await rejects('room double-booking rejected', () async => await schedules.create(sch(s2.subject_id!, 'Monday', '09:30', '10:30', 'ZT-R1', 5)), '23P01');

    await enrollments.enroll(studentId: a.student_id!, subjectId: s1.subject_id!, scheduleId: c1.schedule.schedule_id!);
    check('enroll creates Enrolled row', (await enrollments.list(studentId: a.student_id)).single.enrollment.isEnrolled);
    await rejects('duplicate enrollment rejected', () => enrollments.enroll(studentId: a.student_id!, subjectId: s1.subject_id!, scheduleId: c1.schedule.schedule_id!), '23505');
    await rejects('slot capacity enforced', () => enrollments.enroll(studentId: b.student_id!, subjectId: s1.subject_id!, scheduleId: c1.schedule.schedule_id!), 'EN002');
    await rejects('schedule conflict enforced', () => enrollments.enroll(studentId: a.student_id!, subjectId: s2.subject_id!, scheduleId: c2.schedule.schedule_id!), 'EN001');
    await enrollments.enroll(studentId: b.student_id!, subjectId: s2.subject_id!, scheduleId: c2.schedule.schedule_id!);
    final bEnr = (await enrollments.list(studentId: b.student_id)).single;

    await grades.add(Grades(enrollment_id: bEnr.enrollment.enrollment_id!, grade_value: 88.5, remarks: 'good'));
    var gl = await grades.list(studentId: b.student_id);
    check('grade add + read as double', gl.single.grade.grade_value == 88.5 && gl.single.grade.remarks == 'good', gl);
    check('grade date_recorded present', gl.single.grade.date_recorded != null);
    await rejects('second grade for enrollment rejected', () => grades.add(Grades(enrollment_id: bEnr.enrollment.enrollment_id!, grade_value: 70)), '23505');
    final aEnrollmentId = (await enrollments.list(studentId: a.student_id)).single.enrollment.enrollment_id!;
    await rejects('grade 101 rejected', () => grades.add(Grades(enrollment_id: aEnrollmentId, grade_value: 101)), '23514');
    await grades.update(Grades(grade_id: gl.single.grade.grade_id, enrollment_id: bEnr.enrollment.enrollment_id!, grade_value: 91, remarks: null));
    gl = await grades.list(studentId: b.student_id);
    check('grade update', gl.single.grade.grade_value == 91 && gl.single.grade.remarks == null);
    await rejects('drop blocked while graded', () => enrollments.drop(bEnr.enrollment.enrollment_id!), 'EN004');
    check('enrollment detail shows grade', (await enrollments.list(studentId: b.student_id)).single.grade_value == 91);
    await grades.delete(gl.single.grade.grade_id!);

    await enrollments.drop(bEnr.enrollment.enrollment_id!);
    check('drop sets Dropped', !(await enrollments.list(studentId: b.student_id)).single.enrollment.isEnrolled);
    await enrollments.drop(aEnrollmentId);
    await enrollments.enroll(studentId: b.student_id!, subjectId: s1.subject_id!, scheduleId: c1.schedule.schedule_id!);
    check('freed seat can be taken', (await enrollments.list(studentId: b.student_id, status: 'Enrolled')).length == 1);
    await rejects('student with enrollments cannot be deleted', () => students.delete(b.student_id!), '23001');
  } finally {
    await cleanup();
    final left = await db.query("SELECT count(*)::int AS n FROM student WHERE student_number LIKE 'ZT-%'");
    check('test rows cleaned up', left.first['n'].toString() == '0');
    await db.close();
  }
  print(failures == 0 ? '\nALL CHECKS PASSED' : '\n$failures CHECK(S) FAILED');
  exit(failures == 0 ? 0 : 1);
}
