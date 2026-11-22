// Runs SQL with $1, $2 placeholders. Direct connection on Android/desktop, HTTP on web.
abstract class DbService {
  // shown on the home screen
  String get description;

  Future<List<Map<String, dynamic>>> query(String sql, [List<Object?> params = const []]);

  Future<void> close();
}

// Runs a test query. Throws DbException if the database cannot be reached.
extension DbConnectionTest on DbService {
  Future<void> testConnection() async {
    await query('SELECT 1 AS ok');
  }
}

// A database failure. [code] is the SQLSTATE, or 'connection' if the server can't be reached.
class DbException implements Exception {
  DbException(this.message, {this.code, this.constraint});

  final String message;
  final String? code;
  final String? constraint;

  @override
  String toString() => 'DbException($code): $message';
}

// Turns a database error into a message the user can act on.
String friendlyDbMessage(Object error) {
  if (error is! DbException) return 'Something went wrong. Please try again.';
  final msg = error.message;
  final constraint = error.constraint ?? RegExp(r'constraint "([^"]+)"').firstMatch(msg)?.group(1) ?? '';

  switch (error.code) {
    case 'connection':
      return 'Cannot reach the database. Check your connection, or that Postgres / the local bridge is running.';
    case 'EN001':
      return 'Schedule conflict: the student already has a class that overlaps this time.';
    case 'EN002':
      return 'No slots left for this schedule (or the capacity is lower than the number of enrolled students).';
    case 'EN003':
      return 'A grade can only be recorded for a subject the student is currently enrolled in.';
    case 'EN004':
      return 'This enrollment already has a grade, so it cannot be dropped. Delete the grade first.';
    case '23505':
      if (msg.contains('DUPLICATE_ENROLLMENT') || constraint == 'uq_enrollment_student_subject') {
        return 'The student is already enrolled in this subject.';
      }
      return const {
            'uq_student_student_number': 'That student number already exists.',
            'uq_student_email': 'That email address is already used by another student.',
            'uq_subject_subject_code': 'That subject code already exists.',
            'uq_grades_enrollment_id': 'This enrollment already has a grade. Edit the existing grade instead.',
          }[constraint] ??
          'That value already exists.';
    case '23514':
      return const {
            'ck_student_year_level': 'Year level must be between 1 and 4.',
            'ck_student_email_format': 'Enter a valid email address.',
            'ck_subject_units': 'Units must be between 1 and 6.',
            'ck_schedule_day_of_week': 'Choose a valid day of the week.',
            'ck_schedule_time_order': 'End time must be later than start time.',
            'ck_schedule_slot_capacity': 'Slot capacity must be greater than 0.',
            'ck_enrollment_status': 'Status must be Enrolled or Dropped.',
            'ck_grades_grade_value': 'Grade must be between 0 and 100.',
          }[constraint] ??
          'A value is outside the allowed range.';
    case '23P01':
      return 'That room is already booked at an overlapping time on this day.';
    case '23503':
      return msg.contains('update or delete')
          ? 'This record is still used by other records, so it cannot be deleted.'
          : 'The selected record does not exist or does not match (invalid reference).';
    case '23001':
      return 'This record is still used by other records (for example enrollments), so it cannot be deleted.';
    case '22P02':
    case '22007':
    case '22008':
    case '22003':
      return 'One of the values is not in a valid format.';
    case '23502':
      return 'A required field is missing.';
  }
  return msg;
}
