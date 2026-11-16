// ignore_for_file: non_constant_identifier_names
// Fields match the grades table.
import '../core/convert.dart';

class Grades {
  const Grades({
    this.grade_id,
    required this.enrollment_id,
    required this.grade_value,
    this.remarks,
    this.date_recorded,
  });

  final int? grade_id; // PK
  final int enrollment_id; // FK -> enrollment, unique (one grade per enrollment)
  final double grade_value; // 0-100
  final String? remarks;
  final DateTime? date_recorded;

  factory Grades.fromMap(Map<String, dynamic> m) => Grades(
        grade_id: asIntOrNull(m['grade_id']),
        enrollment_id: asInt(m['enrollment_id']),
        grade_value: asDouble(m['grade_value']),
        remarks: asStringOrNull(m['remarks']),
        date_recorded: asDateTimeOrNull(m['date_recorded']),
      );
}

// grade joined with student and subject (read-only)
class GradeDetail {
  const GradeDetail({
    required this.grade,
    required this.student_id,
    required this.student_number,
    required this.student_name,
    required this.subject_code,
    required this.subject_name,
    required this.units,
  });

  final Grades grade;
  final int student_id;
  final String student_number;
  final String student_name;
  final String subject_code;
  final String subject_name;
  final int units;

  factory GradeDetail.fromMap(Map<String, dynamic> m) => GradeDetail(
        grade: Grades.fromMap(m),
        student_id: asInt(m['student_id']),
        student_number: asString(m['student_number']),
        student_name: '${asString(m['first_name'])} ${asString(m['last_name'])}',
        subject_code: asString(m['subject_code']),
        subject_name: asString(m['subject_name']),
        units: asInt(m['units']),
      );
}
