import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ui.dart';
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';
import '../widgets/task_card.dart';
import 'board_screen.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Dashboard? _dashboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final teams = context.read<TeamProvider>();
    try {
      final results = await Future.wait([teams.dashboard(), teams.loadTeams()]);
      if (mounted) setState(() => _dashboard = results.first as Dashboard);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createTeam() async {
    final name = TextEditingController();
    final description = TextEditingController();
    const colors = ['#4F46E5', '#059669', '#DC2626', '#D97706', '#0891B2', '#7C3AED'];
    var color = colors.first;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New team'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Team name')),
            const SizedBox(height: 12),
            TextField(controller: description, decoration: const InputDecoration(labelText: 'Description (optional)')),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final c in colors)
                  GestureDetector(
                    onTap: () => setLocal(() => color = c),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(int.parse(c.substring(1), radix: 16) + 0xFF000000),
                      child: color == c ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  ),
              ],
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );

    if (created == true && name.text.trim().isNotEmpty && mounted) {
      try {
        await context.read<TeamProvider>().createTeam(
              name.text.trim(),
              description.text.trim().isEmpty ? null : description.text.trim(),
              color,
            );
      } catch (e) {
        if (mounted) showError(context, e);
      }
    }
    name.dispose();
    description.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teams = context.watch<TeamProvider>().teams;
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);
    final d = _dashboard;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${user?.name.split(' ').first ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTeam,
        icon: const Icon(Icons.group_add),
        label: const Text('New team'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  if (d != null)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.1,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        _Stat('Open tasks', d.assignedOpen, Icons.inbox_outlined, theme.colorScheme.primary),
                        _Stat('Overdue', d.overdue, Icons.warning_amber, theme.colorScheme.error),
                        _Stat('Due this week', d.dueThisWeek, Icons.event_outlined, Colors.orange),
                        _Stat('Done this week', d.completedThisWeek, Icons.check_circle_outline, Colors.green),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Text('Your teams', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (teams.isEmpty)
                    const Card(child: ListTile(title: Text('No teams yet'), subtitle: Text('Create one to start planning.'))),
                  for (final t in teams)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: t.colorValue,
                          child: Text(t.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(t.name),
                        subtitle: Text('${t.membersCount ?? 0} members · ${t.openTasksCount ?? 0} open tasks'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => BoardScreen(team: t)));
                          _refresh();
                        },
                      ),
                    ),
                  if (d != null && d.upcoming.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Assigned to you', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final task in d.upcoming)
                      TaskCard(
                        task: task,
                        showTeam: teams.where((t) => t.id == task.teamId).map((t) => t.name).firstOrNull,
                        onTap: () async {
                          await Navigator.push(
                              context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)));
                          _refresh();
                        },
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ]),
      ),
    );
  }
}
