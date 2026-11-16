import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../viewmodels/subject_view_model.dart';
import '../widgets/common.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SubjectViewModel>().load(search: ''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _openForm([Subject? s]) async {
    final vm = context.read<SubjectViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _SubjectForm(subject: s, onSubmit: (x) async => await vm.save(x) ? null : vm.error),
    );
    if (saved == true && mounted) showSnack(context, s == null ? 'Subject added.' : 'Subject updated.');
  }

  Future<void> _delete(Subject s) async {
    final vm = context.read<SubjectViewModel>();
    if (!await confirm(context, 'Delete subject', 'Delete ${s.label}? Its schedules must be removed first.')) return;
    final ok = await vm.remove(s.subject_id!);
    if (mounted) reportResult(context, ok, vm.error, 'Subject deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SubjectViewModel>();
    return Scaffold(
      body: Column(
        children: [
          SearchField(
            hint: 'Search by code or name',
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
              emptyText: vm.search.isEmpty ? 'No subjects yet. Tap "Add subject" to create one.' : 'No subjects match "${vm.search}".',
              onRetry: () => vm.load(),
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: vm.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = vm.items[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${s.units}')),
                    title: Text(s.label),
                    subtitle: Text(
                      '${s.units} unit${s.units == 1 ? '' : 's'}'
                      '${(s.description ?? '').isEmpty ? '' : '\n${s.description}'}',
                    ),
                    isThreeLine: (s.description ?? '').isNotEmpty,
                    trailing: PopupMenuButton<String>(
                      onSelected: (a) => a == 'edit' ? _openForm(s) : _delete(s),
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
        label: const Text('Add subject'),
      ),
    );
  }
}

class _SubjectForm extends StatefulWidget {
  const _SubjectForm({required this.subject, required this.onSubmit});
  final Subject? subject;
  final Future<String?> Function(Subject) onSubmit;

  @override
  State<_SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends State<_SubjectForm> {
  late final _code = TextEditingController(text: widget.subject?.subject_code);
  late final _name = TextEditingController(text: widget.subject?.subject_name);
  late final _desc = TextEditingController(text: widget.subject?.description);
  late int _units = widget.subject?.units ?? 3;

  @override
  void dispose() {
    for (final c in [_code, _name, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String?> _submit() => widget.onSubmit(Subject(
        subject_id: widget.subject?.subject_id,
        subject_code: _code.text.trim(),
        subject_name: _name.text.trim(),
        units: _units,
        description: emptyToNull(_desc.text),
      ));

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.subject == null ? 'Add subject' : 'Edit subject',
      onSubmit: _submit,
      children: [
        TextFormField(
          controller: _code,
          maxLength: 20,
          decoration: const InputDecoration(labelText: 'Subject code', border: OutlineInputBorder()),
          validator: (v) => requiredField(v, 'Subject code'),
        ),
        TextFormField(
          controller: _name,
          maxLength: 150,
          decoration: const InputDecoration(labelText: 'Subject name', border: OutlineInputBorder()),
          validator: (v) => requiredField(v, 'Subject name'),
        ),
        DropdownButtonFormField<int>(
          initialValue: _units,
          decoration: const InputDecoration(labelText: 'Units', border: OutlineInputBorder()),
          items: [for (var u = 1; u <= 6; u++) DropdownMenuItem(value: u, child: Text('$u'))],
          onChanged: (v) => setState(() => _units = v ?? 3),
        ),
        TextFormField(
          controller: _desc,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}
