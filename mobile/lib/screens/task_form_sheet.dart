import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/ui.dart';
import '../models/task.dart';
import '../models/team.dart';
import '../providers/team_provider.dart';

/// Opens a bottom sheet to create a task, or edit [existing]. Returns the saved task.
Future<Task?> showTaskForm(BuildContext context, {required Team team, Task? existing, String initialStatus = 'todo'}) {
  return showModalBottomSheet<Task>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: _TaskForm(team: team, existing: existing, initialStatus: initialStatus),
    ),
  );
}

class _TaskForm extends StatefulWidget {
  const _TaskForm({required this.team, this.existing, required this.initialStatus});

  final Team team;
  final Task? existing;
  final String initialStatus;

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _description = TextEditingController(text: widget.existing?.description);
  late String _priority = widget.existing?.priority ?? 'medium';
  late String _status = widget.existing?.status ?? widget.initialStatus;
  late int? _assigneeId = widget.existing?.assigneeId;
  late DateTime? _due = widget.existing?.dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = {
      'title': _title.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'priority': _priority,
      'status': _status,
      'assignee_id': _assigneeId,
      'due_date': TeamProvider.formatDate(_due),
    };
    final provider = context.read<TeamProvider>();
    try {
      final task = widget.existing == null
          ? await provider.createTask(widget.team.id, body)
          : await provider.updateTask(widget.existing!.id, body);
      if (mounted) Navigator.pop(context, task);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Text(widget.existing == null ? 'New task' : 'Edit task', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _title,
            autofocus: widget.existing == null,
            decoration: const InputDecoration(labelText: 'Title'),
            validator: requiredField,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  for (final s in TaskStatus.all) DropdownMenuItem(value: s, child: Text(TaskStatus.label(s))),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: [
                  for (final p in Priority.all)
                    DropdownMenuItem(value: p, child: Text(p[0].toUpperCase() + p.substring(1))),
                ],
                onChanged: (v) => setState(() => _priority = v!),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: _assigneeId,
            decoration: const InputDecoration(labelText: 'Assignee'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Unassigned')),
              for (final m in widget.team.members) DropdownMenuItem<int?>(value: m.id, child: Text(m.name)),
            ],
            onChanged: (v) => setState(() => _assigneeId = v),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _due ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) setState(() => _due = picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Due date',
                suffixIcon: _due == null
                    ? const Icon(Icons.event)
                    : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _due = null)),
              ),
              child: Text(_due == null ? 'No due date' : DateFormat('EEE, d MMM yyyy').format(_due!)),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text(_saving ? 'Saving...' : 'Save task'),
          ),
        ],
      ),
    );
  }
}
