// ignore_for_file: non_constant_identifier_names
// Fields match the subject table.
import '../core/convert.dart';

class Subject {
  const Subject({
    this.subject_id,
    required this.subject_code,
    required this.subject_name,
    required this.units,
    this.description,
  });

  final int? subject_id; // PK
  final String subject_code; // UK
  final String subject_name;
  final int units; // 1-6
  final String? description;

  factory Subject.fromMap(Map<String, dynamic> m) => Subject(
        subject_id: asIntOrNull(m['subject_id']),
        subject_code: asString(m['subject_code']),
        subject_name: asString(m['subject_name']),
        units: asInt(m['units']),
        description: asStringOrNull(m['description']),
      );

  String get label => '$subject_code - $subject_name';
}
