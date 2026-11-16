import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../viewmodels/student_view_model.dart';
import '../widgets/common.dart';
import 'student_portal_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<StudentViewModel>().load(search: ''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _openForm([Student? s]) async {
    final vm = context.read<StudentViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _StudentForm(
        student: s,
        onSubmit: (st) async => await vm.save(st) ? null : vm.error,
      ),
    );
    if (saved == true && mounted) showSnack(context, s == null ? 'Student added.' : 'Student updated.');
  }

  Future<void> _delete(Student s) async {
    final vm = context.read<StudentViewModel>();
    if (!await confirm(context, 'Delete student', 'Delete ${s.fullName} (${s.student_number})? This cannot be undone.')) {
      return;
    }
    final ok = await vm.remove(s.student_id!);
    if (mounted) reportResult(context, ok, vm.error, 'Student deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StudentViewModel>();
    return Scaffold(
      body: Column(
        children: [
          SearchField(
            hint: 'Search by name, number, email or course',
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () => vm.load(search: v));
            },
          ),
          Expanded(
            child: StateBody(
              loading: vm.loading,
              error: vm.error,
              isEmpty: vm.items.isEmpty,
              emptyText: vm.search.isEmpty ? 'No students yet. Tap "Add student" to create one.' : 'No students match "${vm.search}".',
              onRetry: () => vm.load(),
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: vm.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = vm.items[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(s.first_name.isEmpty ? '?' : s.first_name[0].toUpperCase())),
                    title: Text(s.fullName),
                    subtitle: Text('${s.student_number}  |  ${s.course}, year ${s.year_level}\n${s.email}'),
                    isThreeLine: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StudentPortalScreen(student: s)),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (a) {
                        if (a == 'edit') _openForm(s);
                        if (a == 'delete') _delete(s);
                        if (a == 'summary') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => StudentPortalScreen(student: s)));
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'summary', child: Text('Enrollment summary')),
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
        icon: const Icon(Icons.person_add),
        label: const Text('Add student'),
      ),
    );
  }
}

class _StudentForm extends StatefulWidget {
  const _StudentForm({required this.student, required this.onSubmit});
  final Student? student;
  final Future<String?> Function(Student) onSubmit;

  @override
  State<_StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<_StudentForm> {
  late final _number = TextEditingController(text: widget.student?.student_number);
  late final _first = TextEditingController(text: widget.student?.first_name);
  late final _last = TextEditingController(text: widget.student?.last_name);
  late final _email = TextEditingController(text: widget.student?.email);
  late final _course = TextEditingController(text: widget.student?.course);
  late final _contact = TextEditingController(text: widget.student?.contact_number);
  late int _year = widget.student?.year_level ?? 1;

  @override
  void dispose() {
    for (final c in [_number, _first, _last, _email, _course, _contact]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String?> _submit() => widget.onSubmit(Student(
        student_id: widget.student?.student_id,
        student_number: _number.text.trim(),
        first_name: _first.text.trim(),
        last_name: _last.text.trim(),
        email: _email.text.trim(),
        course: _course.text.trim(),
        year_level: _year,
        contact_number: emptyToNull(_contact.text),
      ));

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.student == null ? 'Add student' : 'Edit student',
      onSubmit: _submit,
      children: [
        TextFormField(
          controller: _number,
          maxLength: 20,
          decoration: const InputDecoration(labelText: 'Student number', border: OutlineInputBorder()),
          validator: (v) => requiredField(v, 'Student number'),
        ),
        TextFormField(
          controller: _first,
          maxLength: 50,
          decoration: const InputDecoration(labelText: 'First name', border: OutlineInputBorder()),
          validator: (v) => requiredField(v, 'First name'),
        ),
        TextFormField(
          controller: _last,
          maxLength: 50,
          decoration: const InputDecoration(labelText: 'Last name', border: OutlineInputBorder()),
          validator: (v) => requiredField(v, 'Last name'),
        ),
        TextFormField(
          controller: _email,
          maxLength: 100,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          validator: (v) {
            final r = requiredField(v, 'Email');
            if (r != null) return r;
            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim()) ? null : 'Enter a valid email address';
          },
        ),
        TextFormField(
          controller: _course,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder()),
          validator: (v) => requiredField(v, 'Course'),
        ),
        DropdownButtonFormField<int>(
          initialValue: _year,
          decoration: const InputDecoration(labelText: 'Year level', border: OutlineInputBorder()),
          items: [for (var y = 1; y <= 4; y++) DropdownMenuItem(value: y, child: Text('Year $y'))],
          onChanged: (v) => setState(() => _year = v ?? 1),
        ),
        TextFormField(
          controller: _contact,
          maxLength: 20,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Contact number (optional)', border: OutlineInputBorder()),
          validator: (v) => (v == null || v.trim().isEmpty || RegExp(r'^[0-9+\-\s()]{7,20}$').hasMatch(v.trim()))
              ? null
              : 'Enter a valid phone number',
        ),
      ],
    );
  }
}
