import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/convert.dart';
import '../models/schedule.dart';
import '../models/subject.dart';
import '../viewmodels/schedule_view_model.dart';
import '../viewmodels/subject_view_model.dart';
import '../widgets/common.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubjectViewModel>().load(search: '');
      context.read<ScheduleViewModel>().load();
    });
  }

  Future<void> _openForm([Schedule? s]) async {
    final vm = context.read<ScheduleViewModel>();
    final subjects = context.read<SubjectViewModel>().items;
    if (subjects.isEmpty) {
      showSnack(context, 'Add a subject first. A schedule belongs to a subject.', error: true);
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ScheduleForm(
        schedule: s,
        subjects: subjects,
        initialSubjectId: vm.subjectFilter,
        onSubmit: (x) async => await vm.save(x) ? null : vm.error,
      ),
    );
    if (saved == true && mounted) showSnack(context, s == null ? 'Schedule added.' : 'Schedule updated.');
  }

  Future<void> _delete(ScheduleDetail d) async {
    final vm = context.read<ScheduleViewModel>();
    if (!await confirm(
      context,
      'Delete schedule',
      'Delete ${d.subject_code} ${d.schedule.day_of_week} ${d.schedule.timeRange}? Enrollments using it must be removed first.',
    )) {
      return;
    }
    final ok = await vm.remove(d.schedule.schedule_id!);
    if (mounted) reportResult(context, ok, vm.error, 'Schedule deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScheduleViewModel>();
    final subjects = context.watch<SubjectViewModel>().items;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DropdownButtonFormField<int?>(
              initialValue: vm.subjectFilter,
              decoration: const InputDecoration(labelText: 'Filter by subject', border: OutlineInputBorder(), isDense: true),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('All subjects')),
                for (final s in subjects) DropdownMenuItem<int?>(value: s.subject_id, child: Text(s.label, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => vm.load(subjectId: v),
            ),
          ),
          Expanded(
            child: StateBody(
              loading: vm.loading,
              error: vm.error,
              isEmpty: vm.items.isEmpty,
              emptyText: 'No schedules yet. Tap "Add schedule" to assign a day, time and room to a subject.',
              onRetry: () => vm.load(keepFilter: true),
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: vm.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final d = vm.items[i];
                  final s = d.schedule;
                  return ListTile(
                    leading: CircleAvatar(child: Text(s.day_of_week.substring(0, 3))),
                    title: Text('${d.subject_code} - ${d.subject_name}'),
                    subtitle: Text('${s.day_of_week}  ${s.timeRange}\nRoom ${s.room}  |  ${d.enrolled_count}/${s.slot_capacity} slots taken'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (a) => a == 'edit' ? _openForm(s) : _delete(d),
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
        icon: const Icon(Icons.add),
        label: const Text('Add schedule'),
      ),
    );
  }
}

class _ScheduleForm extends StatefulWidget {
  const _ScheduleForm({required this.schedule, required this.subjects, required this.initialSubjectId, required this.onSubmit});
  final Schedule? schedule;
  final List<Subject> subjects;
  final int? initialSubjectId;
  final Future<String?> Function(Schedule) onSubmit;

  @override
  State<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<_ScheduleForm> {
  late final _room = TextEditingController(text: widget.schedule?.room);
  late final _capacity = TextEditingController(text: '${widget.schedule?.slot_capacity ?? 40}');
  late int? _subjectId = widget.schedule?.subject_id ?? widget.initialSubjectId ?? widget.subjects.first.subject_id;
  late String _day = widget.schedule?.day_of_week ?? 'Monday';
  late TimeOfDay? _start = _parse(widget.schedule?.start_time);
  late TimeOfDay? _end = _parse(widget.schedule?.end_time);
  String? _timeError;

  static TimeOfDay? _parse(String? t) {
    if (t == null || t.length < 5) return null;
    return TimeOfDay(hour: int.parse(t.substring(0, 2)), minute: int.parse(t.substring(3, 5)));
  }

  static String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _room.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final t = await showTimePicker(context: context, initialTime: (start ? _start : _end) ?? const TimeOfDay(hour: 8, minute: 0));
    if (t != null) setState(() => start ? _start = t : _end = t);
  }

  Future<String?> _submit() {
    final s = _start, e = _end;
    if (s == null || e == null) {
      setState(() => _timeError = 'Choose a start and end time');
      return Future.value('Choose a start and end time.');
    }
    if (e.hour * 60 + e.minute <= s.hour * 60 + s.minute) {
      setState(() => _timeError = 'End time must be later than start time');
      return Future.value('End time must be later than start time.');
    }
    setState(() => _timeError = null);
    return widget.onSubmit(Schedule(
      schedule_id: widget.schedule?.schedule_id,
      subject_id: _subjectId!,
      day_of_week: _day,
      start_time: _fmt(s),
      end_time: _fmt(e),
      room: _room.text.trim(),
      slot_capacity: int.parse(_capacity.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.schedule == null ? 'Add schedule' : 'Edit schedule',
      onSubmit: _submit,
      children: [
        DropdownButtonFormField<int?>(
          initialValue: _subjectId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
          items: [for (final s in widget.subjects) DropdownMenuItem<int?>(value: s.subject_id, child: Text(s.label, overflow: TextOverflow.ellipsis))],
          onChanged: (v) => setState(() => _subjectId = v),
          validator: (v) => v == null ? 'Choose a subject' : null,
        ),
        DropdownButtonFormField<String>(
          initialValue: _day,
          decoration: const InputDecoration(labelText: 'Day', border: OutlineInputBorder()),
          items: [for (final d in kDaysOfWeek) DropdownMenuItem(value: d, child: Text(d))],
          onChanged: (v) => setState(() => _day = v ?? 'Monday'),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(true),
                icon: const Icon(Icons.schedule),
                label: Text(_start == null ? 'Start time' : time12(_fmt(_start!))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(false),
                icon: const Icon(Icons.schedule),
                label: Text(_end == null ? 'End time' : time12(_fmt(_end!))),
              ),
            ),
          ],
        ),
        if (_timeError != null)
          Text(_timeError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
        TextFormField(
          controller: _room,
          maxLength: 30,
          decoration: const InputDecoration(labelText: 'Room', border: OutlineInputBorder()),
          validator: (v) => requiredField(v, 'Room'),
        ),
        TextFormField(
          controller: _capacity,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Slot capacity', border: OutlineInputBorder()),
          validator: (v) {
            final n = int.tryParse((v ?? '').trim());
            if (n == null) return 'Enter a whole number';
            if (n < 1) return 'Capacity must be greater than 0';
            if (n > 1000) return 'Capacity is too large';
            return null;
          },
        ),
      ],
    );
  }
}
