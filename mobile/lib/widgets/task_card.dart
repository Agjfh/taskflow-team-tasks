import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap, this.showTeam});

  final Task task;
  final VoidCallback? onTap;
  final String? showTeam;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: Priority.color(task.priority), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(task.priority.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(color: Priority.color(task.priority))),
                if (showTeam != null) ...[
                  const Spacer(),
                  Text(showTeam!, style: theme.textTheme.labelSmall),
                ],
              ]),
              const SizedBox(height: 6),
              Text(task.title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(children: [
                if (task.dueDate != null) ...[
                  Icon(Icons.event, size: 14, color: task.isOverdue ? theme.colorScheme.error : theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('d MMM').format(task.dueDate!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: task.isOverdue ? theme.colorScheme.error : null,
                      fontWeight: task.isOverdue ? FontWeight.bold : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (task.commentsCount > 0) ...[
                  Icon(Icons.chat_bubble_outline, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text('${task.commentsCount}', style: theme.textTheme.bodySmall),
                ],
                const Spacer(),
                if (task.assigneeName != null)
                  CircleAvatar(
                    radius: 12,
                    child: Text(task.assigneeName![0].toUpperCase(), style: const TextStyle(fontSize: 11)),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
