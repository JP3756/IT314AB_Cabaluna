import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/convert.dart';
import '../core/db/db_service.dart';
import '../models/enrollment.dart';
import '../models/grades.dart';
import '../repositories/enrollment_repository.dart';
import '../viewmodels/grades_view_model.dart';
import '../viewmodels/student_view_model.dart';
import '../widgets/common.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentViewModel>().load(search: '');
      context.read<GradesViewModel>().load();
    });
  }

  Future<void> _openForm({GradeDetail? existing}) async {
    final vm = context.read<GradesViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _GradeForm(
        existing: existing,
        initialStudentId: vm.studentFilter,
        onSubmit: (g) async => await vm.save(g) ? null : vm.error,
      ),
    );
    if (saved == true && mounted) showSnack(context, existing == null ? 'Grade recorded.' : 'Grade updated.');
  }

  Future<void> _delete(GradeDetail g) async {
    final vm = context.read<GradesViewModel>();
    if (!await confirm(context, 'Delete grade', 'Delete the grade of ${g.student_name} in ${g.subject_code}?')) return;
    final ok = await vm.remove(g.grade.grade_id!);
    if (mounted) reportResult(context, ok, vm.error, 'Grade deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GradesViewModel>();
    final students = context.watch<StudentViewModel>().items;
    final avg = vm.weightedAverage;
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
          if (vm.studentFilter != null && avg != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Weighted average: ${avg.toStringAsFixed(2)}', style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
          Expanded(
            child: StateBody(
              loading: vm.loading,
              error: vm.error,
              isEmpty: vm.items.isEmpty,
              emptyText: 'No grades recorded yet. Tap "Record grade" to add one.',
              onRetry: () => vm.load(keepFilter: true),
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: vm.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final g = vm.items[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(g.grade.grade_value.toStringAsFixed(0))),
                    title: Text('${g.student_name}  -  ${g.subject_code}'),
                    subtitle: Text(
                      '${g.subject_name}\nGrade ${g.grade.grade_value.toStringAsFixed(2)}  |  ${dateOnly(g.grade.date_recorded)}'
                      '${(g.grade.remarks ?? '').isEmpty ? '' : '  |  ${g.grade.remarks}'}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (a) => a == 'edit' ? _openForm(existing: g) : _delete(g),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.grade),
        label: const Text('Record grade'),
      ),
    );
  }
}

class _GradeForm extends StatefulWidget {
  const _GradeForm({required this.existing, required this.initialStudentId, required this.onSubmit});
  final GradeDetail? existing;
  final int? initialStudentId;
  final Future<String?> Function(Grades) onSubmit;

  @override
  State<_GradeForm> createState() => _GradeFormState();
}

class _GradeFormState extends State<_GradeForm> {
  late final _value = TextEditingController(text: widget.existing?.grade.grade_value.toString());
  late final _remarks = TextEditingController(text: widget.existing?.grade.remarks);
  List<EnrollmentDetail> _options = [];
  int? _enrollmentId;
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.existing == null) _loadOptions();
  }

  @override
  void dispose() {
    _value.dispose();
    _remarks.dispose();
    super.dispose();
  }

  // only Enrolled, ungraded enrollments can get a grade
  Future<void> _loadOptions() async {
    setState(() => _loading = true);
    try {
      final all = await context.read<EnrollmentRepository>().list(studentId: widget.initialStudentId, status: kStatusEnrolled);
      if (!mounted) return;
      setState(() {
        _options = all.where((e) => e.grade_id == null).toList();
        _loading = false;
      });
    } on DbException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = friendlyDbMessage(e);
      });
    }
  }

  Future<String?> _submit() => widget.onSubmit(Grades(
        grade_id: widget.existing?.grade.grade_id,
        enrollment_id: widget.existing?.grade.enrollment_id ?? _enrollmentId!,
        grade_value: double.parse(_value.text.trim()),
        remarks: emptyToNull(_remarks.text),
      ));

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return FormDialog(
      title: existing == null ? 'Record grade' : 'Edit grade',
      onSubmit: _submit,
      children: [
        if (existing != null)
          Text('${existing.student_name}  -  ${existing.subject_code} ${existing.subject_name}', style: Theme.of(context).textTheme.titleSmall)
        else if (_loading)
          const LinearProgressIndicator()
        else if (_loadError != null)
          Text(_loadError!, style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (_options.isEmpty)
          const Text('No ungraded enrollments. A student must be enrolled in a subject before a grade can be recorded.')
        else
          DropdownButtonFormField<int?>(
            initialValue: _enrollmentId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Student and subject', border: OutlineInputBorder()),
            items: [
              for (final e in _options)
                DropdownMenuItem<int?>(
                  value: e.enrollment.enrollment_id,
                  child: Text('${e.student_name}  -  ${e.subject_code}', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _enrollmentId = v),
            validator: (v) => v == null ? 'Choose an enrollment' : null,
          ),
        TextFormField(
          controller: _value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Grade (0 - 100)', border: OutlineInputBorder()),
          validator: (v) {
            final n = double.tryParse((v ?? '').trim());
            if (n == null) return 'Enter a number';
            if (n < 0 || n > 100) return 'Grade must be between 0 and 100';
            return null;
          },
        ),
        TextFormField(
          controller: _remarks,
          maxLength: 255,
          decoration: const InputDecoration(labelText: 'Remarks (optional)', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}
