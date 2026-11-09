import 'package:flutter/material.dart';

class Member {
  Member({required this.id, required this.name, required this.email, this.role});

  final int id;
  final String name;
  final String email;
  final String? role;

  String get initials => name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String? ?? '',
        role: json['role'] as String?,
      );
}

class Team {
  Team({
    required this.id,
    required this.name,
    required this.color,
    required this.ownerId,
    this.description,
    this.myRole,
    this.membersCount,
    this.openTasksCount,
    this.members = const [],
  });

  final int id;
  final String name;
  final String? description;
  final String color;
  final int ownerId;
  final String? myRole;
  final int? membersCount;
  final int? openTasksCount;
  final List<Member> members;

  bool get canManage => myRole == 'owner' || myRole == 'admin';

  Color get colorValue => Color(int.parse(color.substring(1), radix: 16) + 0xFF000000);

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        color: json['color'] as String,
        ownerId: json['owner_id'] as int,
        myRole: json['my_role'] as String?,
        membersCount: json['members_count'] as int?,
        openTasksCount: json['open_tasks_count'] as int?,
        members: (json['members'] as List? ?? [])
            .map((m) => Member.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}
