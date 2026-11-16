import '../core/db/db_service.dart';
import '../models/student.dart';

class StudentRepository {
  StudentRepository(this._db);
  final DbService _db;

  static const _cols = 'student_id, student_number, first_name, last_name, email, course, '
      'year_level, contact_number, created_at::text AS created_at';

  Future<List<Student>> list({String search = ''}) async {
    final term = search.trim();
    final rows = term.isEmpty
        ? await _db.query('SELECT $_cols FROM student ORDER BY last_name, first_name')
        : await _db.query(
            'SELECT $_cols FROM student '
            r"WHERE student_number ILIKE $1 OR first_name ILIKE $1 OR last_name ILIKE $1 "
            r"OR email ILIKE $1 OR course ILIKE $1 "
            'ORDER BY last_name, first_name',
            ['%$term%'],
          );
    return rows.map(Student.fromMap).toList();
  }

  Future<Student> create(Student s) async {
    final rows = await _db.query(
      'INSERT INTO student (student_number, first_name, last_name, email, course, year_level, contact_number) '
      r'VALUES ($1, $2, $3, $4, $5, $6::int, $7) '
      'RETURNING $_cols',
      [s.student_number, s.first_name, s.last_name, s.email, s.course, s.year_level, s.contact_number],
    );
    return Student.fromMap(rows.first);
  }

  Future<Student> update(Student s) async {
    final rows = await _db.query(
      r'UPDATE student SET student_number = $1, first_name = $2, last_name = $3, email = $4, '
      r'course = $5, year_level = $6::int, contact_number = $7 WHERE student_id = $8::int '
      'RETURNING $_cols',
      [s.student_number, s.first_name, s.last_name, s.email, s.course, s.year_level, s.contact_number, s.student_id],
    );
    if (rows.isEmpty) throw DbException('This student no longer exists.');
    return Student.fromMap(rows.first);
  }

  Future<void> delete(int id) async {
    await _db.query(r'DELETE FROM student WHERE student_id = $1::int', [id]);
  }
}
