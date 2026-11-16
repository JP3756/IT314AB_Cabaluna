import '../core/db/db_service.dart';
import '../models/subject.dart';

class SubjectRepository {
  SubjectRepository(this._db);
  final DbService _db;

  static const _cols = 'subject_id, subject_code, subject_name, units, description';

  Future<List<Subject>> list({String search = ''}) async {
    final term = search.trim();
    final rows = term.isEmpty
        ? await _db.query('SELECT $_cols FROM subject ORDER BY subject_code')
        : await _db.query(
            'SELECT $_cols FROM subject '
            r'WHERE subject_code ILIKE $1 OR subject_name ILIKE $1 '
            'ORDER BY subject_code',
            ['%$term%'],
          );
    return rows.map(Subject.fromMap).toList();
  }

  Future<Subject> create(Subject s) async {
    final rows = await _db.query(
      r'INSERT INTO subject (subject_code, subject_name, units, description) VALUES ($1, $2, $3::int, $4) '
      'RETURNING $_cols',
      [s.subject_code, s.subject_name, s.units, s.description],
    );
    return Subject.fromMap(rows.first);
  }

  Future<Subject> update(Subject s) async {
    final rows = await _db.query(
      r'UPDATE subject SET subject_code = $1, subject_name = $2, units = $3::int, description = $4 '
      r'WHERE subject_id = $5::int '
      'RETURNING $_cols',
      [s.subject_code, s.subject_name, s.units, s.description, s.subject_id],
    );
    if (rows.isEmpty) throw DbException('This subject no longer exists.');
    return Subject.fromMap(rows.first);
  }

  Future<void> delete(int id) async {
    await _db.query(r'DELETE FROM subject WHERE subject_id = $1::int', [id]);
  }
}
