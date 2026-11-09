import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/models/task.dart';
import 'package:taskflow/models/team.dart';

void main() {
  test('Task parses assignee and overdue flag', () {
    final task = Task.fromJson({
      'id': 3,
      'team_id': 1,
      'title': 'Push notifications',
      'status': 'in_progress',
      'priority': 'high',
      'due_date': '2026-01-10',
      'is_overdue': true,
      'assignee': {'id': 7, 'name': 'Sara Ali'},
      'comments_count': 2,
    });

    expect(task.assigneeName, 'Sara Ali');
    expect(task.isOverdue, isTrue);
    expect(TaskStatus.label(task.status), 'In progress');
  });

  test('Member initials', () {
    expect(Member(id: 1, name: 'Omar Khaled', email: '').initials, 'OK');
  });
}
