import '../core/db/db_service.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  ScheduleRepository(this._db);
  final DbService _db;

  static const _detailSelect = '''
SELECT sc.schedule_id, sc.subject_id, sc.day_of_week,
       sc.start_time::text AS start_time, sc.end_time::text AS end_time,
       sc.room, sc.slot_capacity, sb.subject_code, sb.subject_name,
       (SELECT count(*) FROM enrollment e
         WHERE e.schedule_id = sc.schedule_id AND e.status = 'Enrolled')::int AS enrolled_count
  FROM schedule sc
  JOIN subject sb ON sb.subject_id = sc.subject_id''';

  static const _order = '''
 ORDER BY sb.subject_code,
          array_position(ARRAY['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'], sc.day_of_week),
          sc.start_time''';

  Future<List<ScheduleDetail>> list({int? subjectId}) async {
    final rows = subjectId == null
        ? await _db.query('$_detailSelect$_order')
        : await _db.query('$_detailSelect WHERE sc.subject_id = \$1::int$_order', [subjectId]);
    return rows.map(ScheduleDetail.fromMap).toList();
  }

  // times are "HH:mm"
  Future<void> create(Schedule s) async {
    await _db.query(
      r'INSERT INTO schedule (subject_id, day_of_week, start_time, end_time, room, slot_capacity) '
      r'VALUES ($1::int, $2, $3::text::time, $4::text::time, $5, $6::int)',
      [s.subject_id, s.day_of_week, s.start_time, s.end_time, s.room, s.slot_capacity],
    );
  }

  Future<void> update(Schedule s) async {
    final rows = await _db.query(
      r'UPDATE schedule SET subject_id = $1::int, day_of_week = $2, start_time = $3::text::time, '
      r'end_time = $4::text::time, room = $5, slot_capacity = $6::int '
      r'WHERE schedule_id = $7::int RETURNING schedule_id',
      [s.subject_id, s.day_of_week, s.start_time, s.end_time, s.room, s.slot_capacity, s.schedule_id],
    );
    if (rows.isEmpty) throw DbException('This schedule no longer exists.');
  }

  Future<void> delete(int id) async {
    await _db.query(r'DELETE FROM schedule WHERE schedule_id = $1::int', [id]);
  }
}
