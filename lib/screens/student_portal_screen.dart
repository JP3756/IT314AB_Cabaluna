import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enrollment.dart';
import '../models/schedule.dart';
import '../models/student.dart';
import '../viewmodels/enrollment_view_model.dart';
import '../viewmodels/student_view_model.dart';
import '../widgets/common.dart';

// Subjects, schedule and grades of one student. Also used as the admin's enrollment summary.
class StudentPortalScreen extends StatefulWidget {
  const StudentPortalScreen({super.key, this.student});

  // null: ask who the student is
  final Student? student;

  @override
  State<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends State<StudentPortalScreen> {
  late Student? _student = widget.student;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_student != null) {
        context.read<EnrollmentViewModel>().load(studentId: _student!.student_id);
      } else {
        context.read<StudentViewModel>().load(search: '');
      }
    });
  }

  void _select(Student? s) {
    setState(() => _student = s);
    context.read<EnrollmentViewModel>().load(studentId: s?.student_id);
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentViewModel>();
    final vm = context.watch<EnrollmentViewModel>();
    final picking = widget.student == null;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_student == null ? 'Student view' : _student!.fullName),
          bottom: _student == null
              ? null
              : const TabBar(tabs: [
                  Tab(icon: Icon(Icons.menu_book), text: 'Subjects'),
                  Tab(icon: Icon(Icons.calendar_month), text: 'Schedule'),
                  Tab(icon: Icon(Icons.grade), text: 'Grades'),
                ]),
        ),
        body: Column(
          children: [
            if (picking)
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<Student>(
                  initialValue: _student,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Who are you?', border: OutlineInputBorder()),
                  items: [
                    for (final s in students.items)
                      DropdownMenuItem(value: s, child: Text('${s.fullName} (${s.student_number})', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: _select,
                ),
              ),
            Expanded(
              child: _student == null
                  ? StateBody(
                      loading: students.loading,
                      error: students.error,
                      isEmpty: students.items.isEmpty,
                      emptyText: 'No students found.',
                      onRetry: () => students.load(),
                      child: const Center(child: Text('Choose your name to see your enrollment.')),
                    )
                  : TabBarView(children: [
                      _SubjectsTab(vm: vm),
                      _ScheduleTab(vm: vm),
                      _GradesTab(vm: vm),
                    ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectsTab extends StatelessWidget {
  const _SubjectsTab({required this.vm});
  final EnrollmentViewModel vm;

  @override
  Widget build(BuildContext context) {
    return StateBody(
      loading: vm.loading,
      error: vm.error,
      isEmpty: vm.items.isEmpty,
      emptyText: 'Not enrolled in any subject yet.',
      onRetry: () => vm.load(keepFilter: true),
      child: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.summarize),
              title: Text('${vm.active.length} subject(s) enrolled'),
              subtitle: Text('Total units: ${vm.totalUnits}'),
            ),
          ),
          for (final e in vm.items)
            ListTile(
              title: Text('${e.subject_code} - ${e.subject_name}'),
              subtitle: Text('${e.units} unit(s)  |  ${e.day_of_week} ${e.timeRange}, Room ${e.room}'),
              trailing: StatusChip(label: e.enrollment.status, good: e.enrollment.isEnrolled),
            ),
        ],
      ),
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab({required this.vm});
  final EnrollmentViewModel vm;

  @override
  Widget build(BuildContext context) {
    final active = vm.active;
    return StateBody(
      loading: vm.loading,
      error: vm.error,
      isEmpty: active.isEmpty,
      emptyText: 'No classes scheduled. Enrolled subjects will appear here.',
      onRetry: () => vm.load(keepFilter: true),
      child: ListView(
        children: [
          for (final day in kDaysOfWeek)
            if (active.any((e) => e.day_of_week == day)) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(day, style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final e in (active.where((e) => e.day_of_week == day).toList()..sort((a, b) => a.start_time.compareTo(b.start_time))))
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('${e.subject_code} - ${e.subject_name}'),
                  subtitle: Text('${e.timeRange}  |  Room ${e.room}'),
                ),
            ],
        ],
      ),
    );
  }
}

class _GradesTab extends StatelessWidget {
  const _GradesTab({required this.vm});
  final EnrollmentViewModel vm;

  @override
  Widget build(BuildContext context) {
    final active = vm.active;
    final graded = active.where((e) => e.grade_value != null).toList();
    final units = graded.fold<int>(0, (s, e) => s + e.units);
    final avg = units == 0 ? null : graded.fold<double>(0, (s, e) => s + e.grade_value! * e.units) / units;
    return StateBody(
      loading: vm.loading,
      error: vm.error,
      isEmpty: active.isEmpty,
      emptyText: 'No grades yet. Grades appear for subjects you are enrolled in.',
      onRetry: () => vm.load(keepFilter: true),
      child: ListView(
        children: [
          if (avg != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: ListTile(
                leading: const Icon(Icons.analytics),
                title: Text('Weighted average: ${avg.toStringAsFixed(2)}'),
                subtitle: Text('${graded.length} graded subject(s)'),
              ),
            ),
          for (final EnrollmentDetail e in active)
            ListTile(
              title: Text('${e.subject_code} - ${e.subject_name}'),
              subtitle: Text('${e.units} unit(s)'),
              trailing: Text(
                e.grade_value == null ? 'No grade yet' : e.grade_value!.toStringAsFixed(2),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
        ],
      ),
    );
  }
}
