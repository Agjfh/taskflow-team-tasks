import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/ui.dart';
import '../models/task.dart';
import '../models/team.dart';
import '../providers/team_provider.dart';
import 'task_form_sheet.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final int taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Task? _task;
  Team? _team;
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final provider = context.read<TeamProvider>();
    try {
      final task = await provider.task(widget.taskId);
      final team = await provider.team(task.teamId);
      if (mounted) {
        setState(() {
          _task = task;
          _team = team;
        });
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _setStatus(String status) async {
    try {
      await context.read<TeamProvider>().moveTask(_task!.id, status);
      await _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _send() async {
    final body = _comment.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    try {
      final task = await context.read<TeamProvider>().comment(_task!.id, body);
      _comment.clear();
      if (mounted) setState(() => _task = task);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<TeamProvider>().deleteTask(_task!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          if (task != null && _team != null)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final saved = await showTaskForm(context, team: _team!, existing: task);
                if (saved != null) _load();
              },
            ),
          if (task != null)
            IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: task == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(task.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: [
                          for (final s in TaskStatus.all)
                            ButtonSegment(value: s, label: Text(TaskStatus.label(s), style: const TextStyle(fontSize: 12))),
                        ],
                        selected: {task.status},
                        onSelectionChanged: (s) => _setStatus(s.first),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Column(children: [
                          ListTile(
                            leading: Icon(Icons.flag, color: Priority.color(task.priority)),
                            title: const Text('Priority'),
                            trailing: Text(task.priority.toUpperCase()),
                          ),
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('Assignee'),
                            trailing: Text(task.assigneeName ?? 'Unassigned'),
                          ),
                          ListTile(
                            leading: Icon(Icons.event, color: task.isOverdue ? theme.colorScheme.error : null),
                            title: const Text('Due'),
                            trailing: Text(
                              task.dueDate == null ? '—' : DateFormat('d MMM yyyy').format(task.dueDate!),
                              style: TextStyle(color: task.isOverdue ? theme.colorScheme.error : null),
                            ),
                          ),
                        ]),
                      ),
                      if (task.description != null) ...[
                        const SizedBox(height: 12),
                        Text(task.description!, style: theme.textTheme.bodyLarge),
                      ],
                      const SizedBox(height: 20),
                      Text('Comments (${task.comments.length})', style: theme.textTheme.titleMedium),
                      for (final c in task.comments)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(child: Text(c.userName[0].toUpperCase())),
                          title: Text(c.userName, style: theme.textTheme.labelLarge),
                          subtitle: Text(c.body),
                          trailing: Text(DateFormat('d MMM').format(c.createdAt), style: theme.textTheme.bodySmall),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _comment,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(hintText: 'Write a comment...', isDense: true),
                        ),
                      ),
                      IconButton(onPressed: _sending ? null : _send, icon: const Icon(Icons.send)),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}
