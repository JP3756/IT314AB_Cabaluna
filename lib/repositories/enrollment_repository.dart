import '../core/db/db_service.dart';
import '../models/enrollment.dart';

class EnrollmentRepository {
  EnrollmentRepository(this._db);
  final DbService _db;

  static const _detailSelect = '''
SELECT e.enrollment_id, e.student_id, e.subject_id, e.schedule_id,
       e.enrolled_at::text AS enrolled_at, e.status,
       st.student_number, st.first_name, st.last_name,
       sb.subject_code, sb.subject_name, sb.units,
       sc.day_of_week, sc.start_time::text AS start_time, sc.end_time::text AS end_time, sc.room,
       g.grade_id, g.grade_value::float8 AS grade_value
  FROM enrollment e
  JOIN student  st ON st.student_id  = e.student_id
  JOIN subject  sb ON sb.subject_id  = e.subject_id
  JOIN schedule sc ON sc.schedule_id = e.schedule_id
  LEFT JOIN grades g ON g.enrollment_id = e.enrollment_id''';

  static const _order = '''
 ORDER BY st.last_name, st.first_name, e.status DESC, sb.subject_code''';

  // all enrollments, optionally for one student and/or status
  Future<List<EnrollmentDetail>> list({int? studentId, String? status}) async {
    final where = <String>[];
    final params = <Object?>[];
    if (studentId != null) {
      params.add(studentId);
      where.add('e.student_id = \$${params.length}::int');
    }
    if (status != null) {
      params.add(status);
      where.add('e.status = \$${params.length}');
    }
    final clause = where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}';
    final rows = await _db.query('$_detailSelect$clause$_order', params);
    return rows.map(EnrollmentDetail.fromMap).toList();
  }

  // A dropped subject is re-activated on the same row because (student_id, subject_id) is unique.
  // The database rejects duplicates, schedule conflicts and full classes.
  Future<void> enroll({required int studentId, required int subjectId, required int scheduleId}) async {
    final existing = await _db.query(
      r'SELECT enrollment_id, status FROM enrollment WHERE student_id = $1::int AND subject_id = $2::int',
      [studentId, subjectId],
    );
    if (existing.isNotEmpty) {
      if (existing.first['status'] == kStatusEnrolled) {
        throw DbException('DUPLICATE_ENROLLMENT: already enrolled', code: '23505', constraint: 'uq_enrollment_student_subject');
      }
      await _db.query(
        r"UPDATE enrollment SET status = 'Enrolled', schedule_id = $1::int, enrolled_at = CURRENT_TIMESTAMP "
        r'WHERE enrollment_id = $2::int',
        [scheduleId, existing.first['enrollment_id']],
      );
      return;
    }
    await _db.query(
      r'INSERT INTO enrollment (student_id, subject_id, schedule_id) VALUES ($1::int, $2::int, $3::int)',
      [studentId, subjectId, scheduleId],
    );
  }

  // Moves an enrollment to another schedule of the same subject.
  // The database rejects full classes and schedule conflicts.
  Future<void> changeSchedule({required int enrollmentId, required int scheduleId}) async {
    final rows = await _db.query(
      r'UPDATE enrollment e SET schedule_id = $1::int '
      r"WHERE e.enrollment_id = $2::int AND e.status = 'Enrolled' "
      r'AND EXISTS (SELECT 1 FROM schedule s WHERE s.schedule_id = $1::int AND s.subject_id = e.subject_id) '
      r'RETURNING e.enrollment_id',
      [scheduleId, enrollmentId],
    );
    if (rows.isEmpty) throw DbException('That schedule does not belong to this subject, or the enrollment is not active.');
  }

  // drop = status 'Dropped'; the row stays
  Future<void> drop(int enrollmentId) async {
    final rows = await _db.query(
      r"UPDATE enrollment SET status = 'Dropped' WHERE enrollment_id = $1::int RETURNING enrollment_id",
      [enrollmentId],
    );
    if (rows.isEmpty) throw DbException('This enrollment no longer exists.');
  }
}
