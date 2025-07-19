import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/database_service.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onChanged;

  const TaskCard({super.key, required this.task, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description),
            const SizedBox(height: 4),
            Text(
              '${task.formattedStartTime} - ${task.formattedEndTime}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        secondary: Chip(label: Text(task.category)),
        value: task.isCompleted,
        onChanged: (value) async {
          task.isCompleted = value!;
          await Provider.of<DatabaseService>(
            context,
            listen: false,
          ).updateTask(task);
          onChanged();
        },
      ),
    );
  }
}
