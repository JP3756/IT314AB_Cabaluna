// ignore_for_file: non_constant_identifier_names
// Fields match the schedule table.
import '../core/convert.dart';

const kDaysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

class Schedule {
  const Schedule({
    this.schedule_id,
    required this.subject_id,
    required this.day_of_week,
    required this.start_time,
    required this.end_time,
    required this.room,
    required this.slot_capacity,
  });

  final int? schedule_id; // PK
  final int subject_id; // FK -> subject
  final String day_of_week;
  final String start_time; // "HH:mm:ss"
  final String end_time; // "HH:mm:ss", later than start_time
  final String room;
  final int slot_capacity; // > 0

  factory Schedule.fromMap(Map<String, dynamic> m) => Schedule(
        schedule_id: asIntOrNull(m['schedule_id']),
        subject_id: asInt(m['subject_id']),
        day_of_week: asString(m['day_of_week']),
        start_time: asString(m['start_time']),
        end_time: asString(m['end_time']),
        room: asString(m['room']),
        slot_capacity: asInt(m['slot_capacity']),
      );

  String get timeRange => '${time12(start_time)} - ${time12(end_time)}';
}

// schedule with its subject and seats taken (read-only)
class ScheduleDetail {
  const ScheduleDetail({
    required this.schedule,
    required this.subject_code,
    required this.subject_name,
    required this.enrolled_count,
  });

  final Schedule schedule;
  final String subject_code;
  final String subject_name;
  final int enrolled_count;

  int get slotsLeft => schedule.slot_capacity - enrolled_count;

  factory ScheduleDetail.fromMap(Map<String, dynamic> m) => ScheduleDetail(
        schedule: Schedule.fromMap(m),
        subject_code: asString(m['subject_code']),
        subject_name: asString(m['subject_name']),
        enrolled_count: asInt(m['enrolled_count']),
      );
}
