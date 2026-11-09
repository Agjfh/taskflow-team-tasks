import 'package:flutter/material.dart';

class TaskStatus {
  static const all = ['todo', 'in_progress', 'review', 'done'];

  static String label(String status) => const {
        'todo': 'To do',
        'in_progress': 'In progress',
        'review': 'Review',
        'done': 'Done',
      }[status]!;
}

class Priority {
  static const all = ['low', 'medium', 'high', 'urgent'];

  static Color color(String priority) => const {
        'low': Colors.blueGrey,
        'medium': Colors.blue,
        'high': Colors.orange,
        'urgent': Colors.red,
      }[priority]!;
}

class Comment {
  Comment({required this.id, required this.body, required this.userName, required this.createdAt});

  final int id;
  final String body;
  final String userName;
  final DateTime createdAt;

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as int,
        body: json['body'] as String,
        userName: (json['user'] as Map<String, dynamic>)['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

class Task {
  Task({
    required this.id,
    required this.teamId,
    required this.title,
    required this.status,
    required this.priority,
    required this.isOverdue,
    this.description,
    this.dueDate,
    this.assigneeId,
    this.assigneeName,
    this.creatorName,
    this.commentsCount = 0,
    this.comments = const [],
  });

  final int id;
  final int teamId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final bool isOverdue;
  final int? assigneeId;
  final String? assigneeName;
  final String? creatorName;
  final int commentsCount;
  final List<Comment> comments;

  factory Task.fromJson(Map<String, dynamic> json) {
    final assignee = json['assignee'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;
    final comments = (json['comments'] as List? ?? [])
        .map((c) => Comment.fromJson(c as Map<String, dynamic>))
        .toList();
    return Task(
      id: json['id'] as int,
      teamId: json['team_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      dueDate: json['due_date'] == null ? null : DateTime.parse(json['due_date'] as String),
      isOverdue: json['is_overdue'] as bool? ?? false,
      assigneeId: assignee?['id'] as int?,
      assigneeName: assignee?['name'] as String?,
      creatorName: creator?['name'] as String?,
      commentsCount: json['comments_count'] as int? ?? comments.length,
      comments: comments,
    );
  }
}
