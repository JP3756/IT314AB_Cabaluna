import 'package:flutter_test/flutter_test.dart';
import 'package:student_directory/config/app_config.dart';
import 'package:student_directory/core/db/db_service.dart';
import 'package:student_directory/main.dart';
import 'package:student_directory/models/student.dart';

// fake db, so tests never touch a real database
class FakeDb implements DbService {
  FakeDb({this.rows = const [], this.failWith});

  final List<Map<String, dynamic>> rows;
  final DbException? failWith;

  @override
  String get description => 'Fake database';

  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<Object?> params = const []]) async {
    if (failWith != null) throw failWith!;
    return sql.contains('FROM student') && !sql.contains('JOIN') ? rows : [];
  }

  @override
  Future<void> close() async {}
}

const _config = AppConfig(target: DbTarget.neon, neonUrl: 'postgresql://u:p@h/db', localUrl: '', bridgeUrl: '');

Future<void> _open(WidgetTester t, FakeDb db) async {
  await t.pumpWidget(EnrollmentApp(config: _config, db: db));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('home shows connection status and both roles', (t) async {
    await _open(t, FakeDb());
    expect(find.text('Enrollment System'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Registrar / Admin'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
  });

  testWidgets('home explains a database failure', (t) async {
    await _open(t, FakeDb(failWith: DbException('boom', code: 'connection')));
    expect(find.text('Database not reachable'), findsOneWidget);
    expect(find.textContaining('Cannot reach the database'), findsOneWidget);
  });

  testWidgets('admin students tab shows empty state and validates the form', (t) async {
    await _open(t, FakeDb());
    await t.tap(find.text('Registrar / Admin'));
    await t.pumpAndSettle();
    expect(find.textContaining('No students yet'), findsOneWidget);

    await t.tap(find.text('Add student'));
    await t.pumpAndSettle();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('Student number is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('admin students tab lists rows from the database', (t) async {
    await _open(
      t,
      FakeDb(rows: [
        {
          'student_id': 1,
          'student_number': '2024-001',
          'first_name': 'Ana',
          'last_name': 'Cruz',
          'email': 'ana@x.com',
          'course': 'BSIT',
          'year_level': '3', // the HTTP path returns numbers as text
          'contact_number': null,
          'created_at': '2026-11-16 08:00:00',
        }
      ]),
    );
    await t.tap(find.text('Registrar / Admin'));
    await t.pumpAndSettle();
    expect(find.text('Ana Cruz'), findsOneWidget);
    expect(find.textContaining('year 3'), findsOneWidget);
  });

  test('Student model keeps the exact table field names', () {
    final s = Student.fromMap({
      'student_id': 7,
      'student_number': 'S1',
      'first_name': 'A',
      'last_name': 'B',
      'email': 'a@b.co',
      'course': 'C',
      'year_level': 2,
    });
    expect([s.student_id, s.student_number, s.first_name, s.last_name, s.email, s.course, s.year_level, s.contact_number],
        [7, 'S1', 'A', 'B', 'a@b.co', 'C', 2, null]);
  });

  test('database errors become readable messages', () {
    expect(friendlyDbMessage(DbException('x', code: 'EN001')), contains('Schedule conflict'));
    expect(friendlyDbMessage(DbException('x', code: 'EN002')), contains('No slots left'));
    expect(
      friendlyDbMessage(DbException('duplicate key value violates unique constraint "uq_student_email"', code: '23505')),
      contains('email'),
    );
    expect(friendlyDbMessage(DbException('x', code: 'connection')), contains('Cannot reach'));
  });
}
