// ignore_for_file: non_constant_identifier_names
// Fields match the student table.
import '../core/convert.dart';

class Student {
  const Student({
    this.student_id,
    required this.student_number,
    required this.first_name,
    required this.last_name,
    required this.email,
    required this.course,
    required this.year_level,
    this.contact_number,
    this.created_at,
  });

  final int? student_id; // PK
  final String student_number; // UK
  final String first_name;
  final String last_name;
  final String email; // UK
  final String course;
  final int year_level; // 1-4
  final String? contact_number;
  final DateTime? created_at;

  factory Student.fromMap(Map<String, dynamic> m) => Student(
        student_id: asIntOrNull(m['student_id']),
        student_number: asString(m['student_number']),
        first_name: asString(m['first_name']),
        last_name: asString(m['last_name']),
        email: asString(m['email']),
        course: asString(m['course']),
        year_level: asInt(m['year_level']),
        contact_number: asStringOrNull(m['contact_number']),
        created_at: asDateTimeOrNull(m['created_at']),
      );

  String get fullName => '$first_name $last_name';
}
