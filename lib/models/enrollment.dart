// ignore_for_file: non_constant_identifier_names
// Fields match the enrollment table.
import '../core/convert.dart';

const kStatusEnrolled = 'Enrolled';

class Enrollment {
  const Enrollment({
    this.enrollment_id,
    required this.student_id,
    required this.subject_id,
    required this.schedule_id,
    this.enrolled_at,
    this.status = kStatusEnrolled,
  });

  final int? enrollment_id; // PK
  final int student_id; // FK -> student
  final int subject_id; // FK -> subject   (student_id + subject_id is unique)
  final int schedule_id; // FK -> schedule
  final DateTime? enrolled_at;
  final String status; // Enrolled | Dropped

  factory Enrollment.fromMap(Map<String, dynamic> m) => Enrollment(
        enrollment_id: asIntOrNull(m['enrollment_id']),
        student_id: asInt(m['student_id']),
        subject_id: asInt(m['subject_id']),
        schedule_id: asInt(m['schedule_id']),
        enrolled_at: asDateTimeOrNull(m['enrolled_at']),
        status: asString(m['status']),
      );

  bool get isEnrolled => status == kStatusEnrolled;
}

// enrollment joined with student, subject, schedule and grade (read-only)
class EnrollmentDetail {
  const EnrollmentDetail({
    required this.enrollment,
    required this.student_number,
    required this.student_name,
    required this.subject_code,
    required this.subject_name,
    required this.units,
    required this.day_of_week,
    required this.start_time,
    required this.end_time,
    required this.room,
    this.grade_id,
    this.grade_value,
  });

  final Enrollment enrollment;
  final String student_number;
  final String student_name;
  final String subject_code;
  final String subject_name;
  final int units;
  final String day_of_week;
  final String start_time;
  final String end_time;
  final String room;
  final int? grade_id;
  final double? grade_value;

  String get timeRange => '${time12(start_time)} - ${time12(end_time)}';

  factory EnrollmentDetail.fromMap(Map<String, dynamic> m) => EnrollmentDetail(
        enrollment: Enrollment.fromMap(m),
        student_number: asString(m['student_number']),
        student_name: '${asString(m['first_name'])} ${asString(m['last_name'])}',
        subject_code: asString(m['subject_code']),
        subject_name: asString(m['subject_name']),
        units: asInt(m['units']),
        day_of_week: asString(m['day_of_week']),
        start_time: asString(m['start_time']),
        end_time: asString(m['end_time']),
        room: asString(m['room']),
        grade_id: asIntOrNull(m['grade_id']),
        grade_value: asDoubleOrNull(m['grade_value']),
      );
}
