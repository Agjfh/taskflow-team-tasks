import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ui.dart';
import '../models/team.dart';
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key, required this.team});

  final Team team;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  late Team _team = widget.team;

  Future<void> _reload() async {
    final team = await context.read<TeamProvider>().team(_team.id);
    if (mounted) setState(() => _team = team);
  }

  Future<void> _invite() async {
    final email = TextEditingController();
    var role = 'member';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add member'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email of a registered user'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'member', label: Text('Member')),
                ButtonSegment(value: 'admin', label: Text('Admin')),
              ],
              selected: {role},
              onSelectionChanged: (s) => setLocal(() => role = s.first),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      try {
        await context.read<TeamProvider>().addMember(_team.id, email.text.trim(), role);
        await _reload();
      } catch (e) {
        if (mounted) showError(context, e);
      }
    }
    email.dispose();
  }

  Future<void> _remove(Member m) async {
    try {
      await context.read<TeamProvider>().removeMember(_team.id, m.id);
      await _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: Text('${_team.name} · Members')),
      floatingActionButton: _team.canManage
          ? FloatingActionButton.extended(onPressed: _invite, icon: const Icon(Icons.person_add), label: const Text('Add'))
          : null,
      body: ListView(
        children: [
          for (final m in _team.members)
            ListTile(
              leading: CircleAvatar(child: Text(m.initials)),
              title: Text(m.id == me?.id ? '${m.name} (you)' : m.name),
              subtitle: Text(m.email),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Chip(label: Text(m.role ?? 'member')),
                if (_team.canManage && m.role != 'owner')
                  IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _remove(m)),
              ]),
            ),
        ],
      ),
    );
  }
}
