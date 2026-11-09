import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ui.dart';
import '../models/task.dart';
import '../models/team.dart';
import '../providers/team_provider.dart';
import '../widgets/task_card.dart';
import 'members_screen.dart';
import 'task_detail_screen.dart';
import 'task_form_sheet.dart';

/// Kanban board: one column per status. Long-press and drag a card to move it.
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.team});

  final Team team;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late Team _team = widget.team;
  List<Task> _tasks = [];
  bool _loading = true;
  bool _onlyMine = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<TeamProvider>();
    try {
      final results = await Future.wait([
        provider.team(_team.id),
        provider.tasks(_team.id, onlyMine: _onlyMine),
      ]);
      if (!mounted) return;
      setState(() {
        _team = results[0] as Team;
        _tasks = results[1] as List<Task>;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _move(Task task, String status) async {
    if (task.status == status) return;
    try {
      final updated = await context.read<TeamProvider>().moveTask(task.id, status);
      setState(() {
        _tasks = [for (final t in _tasks) t.id == task.id ? updated : t];
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _newTask(String status) async {
    final created = await showTaskForm(context, team: _team, initialStatus: status);
    if (created != null) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_team.name),
        actions: [
          FilterChip(
            label: const Text('Mine'),
            selected: _onlyMine,
            onSelected: (v) {
              _onlyMine = v;
              _load();
            },
          ),
          IconButton(
            tooltip: 'Members',
            icon: const Icon(Icons.group_outlined),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => MembersScreen(team: _team)));
              _load();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _newTask('todo'),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                children: [
                  for (final status in TaskStatus.all)
                    _Column(
                      status: status,
                      tasks: _tasks.where((t) => t.status == status).toList(),
                      onDrop: (task) => _move(task, status),
                      onAdd: () => _newTask(status),
                      onOpen: (task) async {
                        await Navigator.push(
                            context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)));
                        _load();
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.status,
    required this.tasks,
    required this.onDrop,
    required this.onAdd,
    required this.onOpen,
  });

  final String status;
  final List<Task> tasks;
  final ValueChanged<Task> onDrop;
  final VoidCallback onAdd;
  final ValueChanged<Task> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, _) => Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text(TaskStatus.label(status), style: theme.textTheme.titleSmall),
              const SizedBox(width: 6),
              Text('${tasks.length}', style: theme.textTheme.bodySmall),
              const Spacer(),
              IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.add), onPressed: onAdd),
            ]),
            Expanded(
              child: ListView(
                children: [
                  for (final task in tasks)
                    LongPressDraggable<Task>(
                      data: task,
                      feedback: SizedBox(width: 264, child: Material(elevation: 6, borderRadius: BorderRadius.circular(12), child: TaskCard(task: task))),
                      childWhenDragging: Opacity(opacity: 0.3, child: TaskCard(task: task)),
                      child: TaskCard(task: task, onTap: () => onOpen(task)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
