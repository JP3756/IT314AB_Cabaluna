import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/db/db_service.dart';
import '../models/enrollment.dart';
import '../models/schedule.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../repositories/schedule_repository.dart';
import '../viewmodels/enrollment_view_model.dart';
import '../viewmodels/student_view_model.dart';
import '../viewmodels/subject_view_model.dart';
import '../widgets/common.dart';

class EnrollmentsScreen extends StatefulWidget {
  const EnrollmentsScreen({super.key});

  @override
  State<EnrollmentsScreen> createState() => _EnrollmentsScreenState();
}

class _EnrollmentsScreenState extends State<EnrollmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentViewModel>().load(search: '');
      context.read<SubjectViewModel>().load(search: '');
      context.read<EnrollmentViewModel>().load();
    });
  }

  Future<void> _openEnroll({int? studentId, int? subjectId}) async {
    final vm = context.read<EnrollmentViewModel>();
    final students = context.read<StudentViewModel>().items;
    final subjects = context.read<SubjectViewModel>().items;
    if (students.isEmpty || subjects.isEmpty) {
      showSnack(context, 'Add at least one student and one subject first.', error: true);
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EnrollForm(
        students: students,
        subjects: subjects,
        initialStudentId: studentId ?? vm.studentFilter,
        initialSubjectId: subjectId,
        onSubmit: (st, sb, sc) async =>
            await vm.enroll(studentId: st, subjectId: sb, scheduleId: sc) ? null : vm.error,
      ),
    );
    if (saved == true && mounted) showSnack(context, 'Student enrolled.');
  }

  Future<void> _drop(EnrollmentDetail e) async {
    final vm = context.read<EnrollmentViewModel>();
    if (!await confirm(context, 'Drop enrollment', 'Drop ${e.student_name} from ${e.subject_code}? The seat is freed.', action: 'Drop')) {
      return;
    }
    final ok = await vm.drop(e.enrollment.enrollment_id!);
    if (mounted) reportResult(context, ok, vm.error, 'Enrollment dropped.');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EnrollmentViewModel>();
    final students = context.watch<StudentViewModel>().items;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DropdownButtonFormField<int?>(
              initialValue: vm.studentFilter,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Filter by student', border: OutlineInputBorder(), isDense: true),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('All students')),
                for (final s in students)
                  DropdownMenuItem<int?>(value: s.student_id, child: Text('${s.fullName} (${s.student_number})', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => vm.load(studentId: v),
            ),
          ),
          if (vm.studentFilter != null && vm.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Enrolled: ${vm.active.length} subject(s), ${vm.totalUnits} unit(s)', style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
          Expanded(
            child: StateBody(
              loading: vm.loading,
              error: vm.error,
              isEmpty: vm.items.isEmpty,
              emptyText: 'No enrollments yet. Tap "Enroll student" to add one.',
              onRetry: () => vm.load(keepFilter: true),
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: vm.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final e = vm.items[i];
                  final enrolled = e.enrollment.isEnrolled;
                  return ListTile(
                    title: Text('${e.student_name}  -  ${e.subject_code}'),
                    subtitle: Text('${e.subject_name}\n${e.day_of_week} ${e.timeRange}, Room ${e.room}'
                        '${e.grade_value == null ? '' : '  |  Grade ${e.grade_value!.toStringAsFixed(2)}'}'),
                    isThreeLine: true,
                    leading: StatusChip(label: e.enrollment.status, good: enrolled),
                    trailing: enrolled
                        ? IconButton(tooltip: 'Drop', icon: const Icon(Icons.person_remove_outlined), onPressed: () => _drop(e))
                        : IconButton(
                            tooltip: 'Re-enroll',
                            icon: const Icon(Icons.replay),
                            onPressed: () => _openEnroll(studentId: e.enrollment.student_id, subjectId: e.enrollment.subject_id),
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEnroll(),
        icon: const Icon(Icons.how_to_reg),
        label: const Text('Enroll student'),
      ),
    );
  }
}

class _EnrollForm extends StatefulWidget {
  const _EnrollForm({
    required this.students,
    required this.subjects,
    required this.initialStudentId,
    required this.initialSubjectId,
    required this.onSubmit,
  });
  final List<Student> students;
  final List<Subject> subjects;
  final int? initialStudentId;
  final int? initialSubjectId;
  final Future<String?> Function(int studentId, int subjectId, int scheduleId) onSubmit;

  @override
  State<_EnrollForm> createState() => _EnrollFormState();
}

class _EnrollFormState extends State<_EnrollForm> {
  late int? _student = widget.initialStudentId;
  late int? _subject = widget.initialSubjectId;
  int? _schedule;
  List<ScheduleDetail> _schedules = [];
  bool _loadingSchedules = false;
  String? _scheduleError;

  @override
  void initState() {
    super.initState();
    if (_subject != null) _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _loadingSchedules = true;
      _schedule = null;
      _scheduleError = null;
    });
    try {
      final list = await context.read<ScheduleRepository>().list(subjectId: _subject);
      if (!mounted) return;
      setState(() {
        _schedules = list;
        _loadingSchedules = false;
      });
    } on DbException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSchedules = false;
        _scheduleError = friendlyDbMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Enroll student',
      submitLabel: 'Enroll',
      onSubmit: () => widget.onSubmit(_student!, _subject!, _schedule!),
      children: [
        DropdownButtonFormField<int?>(
          initialValue: _student,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '1. Student', border: OutlineInputBorder()),
          items: [
            for (final s in widget.students)
              DropdownMenuItem<int?>(value: s.student_id, child: Text('${s.fullName} (${s.student_number})', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => _student = v),
          validator: (v) => v == null ? 'Choose a student' : null,
        ),
        DropdownButtonFormField<int?>(
          initialValue: _subject,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '2. Subject', border: OutlineInputBorder()),
          items: [for (final s in widget.subjects) DropdownMenuItem<int?>(value: s.subject_id, child: Text(s.label, overflow: TextOverflow.ellipsis))],
          onChanged: (v) {
            setState(() => _subject = v);
            _loadSchedules();
          },
          validator: (v) => v == null ? 'Choose a subject' : null,
        ),
        if (_loadingSchedules)
          const LinearProgressIndicator()
        else if (_scheduleError != null)
          Text(_scheduleError!, style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (_subject != null && _schedules.isEmpty)
          const Text('This subject has no schedule yet. Add one under Schedules first.')
        else
          DropdownButtonFormField<int?>(
            key: ValueKey('schedule-$_subject-${_schedules.length}'),
            initialValue: _schedule,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '3. Schedule', border: OutlineInputBorder()),
            items: [
              for (final d in _schedules)
                DropdownMenuItem<int?>(
                  value: d.schedule.schedule_id,
                  enabled: d.slotsLeft > 0,
                  child: Text(
                    '${d.schedule.day_of_week.substring(0, 3)} ${d.schedule.timeRange}, ${d.schedule.room}  '
                    '(${d.slotsLeft > 0 ? '${d.slotsLeft} slots left' : 'FULL'})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _schedule = v),
            validator: (v) => v == null ? 'Choose a schedule' : null,
          ),
      ],
    );
  }
}
