import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/task.dart';
import '../models/team.dart';

class Dashboard {
  Dashboard(this.assignedOpen, this.overdue, this.dueThisWeek, this.completedThisWeek, this.upcoming);

  final int assignedOpen;
  final int overdue;
  final int dueThisWeek;
  final int completedThisWeek;
  final List<Task> upcoming;
}

class TeamProvider extends ChangeNotifier {
  TeamProvider(this.api);

  final ApiClient api;
  List<Team> teams = [];

  Future<void> loadTeams() async {
    final data = await api.get('/teams') as List;
    teams = data.map((t) => Team.fromJson(t as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  Future<Team> createTeam(String name, String? description, String color) async {
    final team = Team.fromJson(await api.post('/teams', {
      'name': name,
      'description': description,
      'color': color,
    }) as Map<String, dynamic>);
    await loadTeams();
    return team;
  }

  Future<Team> team(int id) async => Team.fromJson(await api.get('/teams/$id') as Map<String, dynamic>);

  Future<void> addMember(int teamId, String email, String role) =>
      api.post('/teams/$teamId/members', {'email': email, 'role': role});

  Future<void> removeMember(int teamId, int userId) => api.delete('/teams/$teamId/members/$userId');

  Future<Dashboard> dashboard() async {
    final d = await api.get('/dashboard') as Map<String, dynamic>;
    return Dashboard(
      d['assigned_open'] as int,
      d['overdue'] as int,
      d['due_this_week'] as int,
      d['completed_this_week'] as int,
      (d['upcoming'] as List).map((t) => Task.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }

  Future<List<Task>> tasks(int teamId, {bool onlyMine = false}) async {
    final data = await api.get('/teams/$teamId/tasks', query: {if (onlyMine) 'assignee': 'me'}) as List;
    return data.map((t) => Task.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<Task> task(int id) async => Task.fromJson(await api.get('/tasks/$id') as Map<String, dynamic>);

  Future<Task> createTask(int teamId, Map<String, dynamic> body) async =>
      Task.fromJson(await api.post('/teams/$teamId/tasks', body) as Map<String, dynamic>);

  Future<Task> updateTask(int id, Map<String, dynamic> body) async =>
      Task.fromJson(await api.patch('/tasks/$id', body) as Map<String, dynamic>);

  Future<Task> moveTask(int id, String status) async =>
      Task.fromJson(await api.patch('/tasks/$id/move', {'status': status}) as Map<String, dynamic>);

  Future<void> deleteTask(int id) => api.delete('/tasks/$id');

  Future<Task> comment(int taskId, String body) async =>
      Task.fromJson(await api.post('/tasks/$taskId/comments', {'body': body}) as Map<String, dynamic>);

  static String? formatDate(DateTime? d) => d == null ? null : DateFormat('yyyy-MM-dd').format(d);
}
