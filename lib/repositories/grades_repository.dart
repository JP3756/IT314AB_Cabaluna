import '../core/db/db_service.dart';
import '../models/grades.dart';

class GradesRepository {
  GradesRepository(this._db);
  final DbService _db;

  static const _detailSelect = '''
SELECT g.grade_id, g.enrollment_id, g.grade_value::float8 AS grade_value, g.remarks,
       g.date_recorded::text AS date_recorded,
       e.student_id, st.student_number, st.first_name, st.last_name,
       sb.subject_code, sb.subject_name, sb.units
  FROM grades g
  JOIN enrollment e ON e.enrollment_id = g.enrollment_id
  JOIN student st   ON st.student_id   = e.student_id
  JOIN subject sb   ON sb.subject_id   = e.subject_id''';

  Future<List<GradeDetail>> list({int? studentId}) async {
    const order = ' ORDER BY st.last_name, st.first_name, sb.subject_code';
    final rows = studentId == null
        ? await _db.query('$_detailSelect$order')
        : await _db.query('$_detailSelect WHERE e.student_id = \$1::int$order', [studentId]);
    return rows.map(GradeDetail.fromMap).toList();
  }

  Future<void> add(Grades g) async {
    await _db.query(
      r'INSERT INTO grades (enrollment_id, grade_value, remarks) VALUES ($1::int, $2::text::numeric, $3)',
      [g.enrollment_id, g.grade_value.toString(), g.remarks],
    );
  }

  Future<void> update(Grades g) async {
    final rows = await _db.query(
      r'UPDATE grades SET grade_value = $1::text::numeric, remarks = $2, date_recorded = CURRENT_DATE '
      r'WHERE grade_id = $3::int RETURNING grade_id',
      [g.grade_value.toString(), g.remarks, g.grade_id],
    );
    if (rows.isEmpty) throw DbException('This grade no longer exists.');
  }

  Future<void> delete(int gradeId) async {
    await _db.query(r'DELETE FROM grades WHERE grade_id = $1::int', [gradeId]);
  }
}
