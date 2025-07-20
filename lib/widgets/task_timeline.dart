import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';

class TaskTimeline extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;

  const TaskTimeline({super.key, required this.tasks, required this.onTaskTap});

  @override
  Widget build(BuildContext context) {
    final groupedTasks = <int, List<Task>>{};
    for (var task in tasks) {
      final startHour = task.startTime.hour;
      groupedTasks[startHour] = (groupedTasks[startHour] ?? [])..add(task);
    }

    return SingleChildScrollView(
      child: Column(
        children: List.generate(24, (hour) {
          final hourTasks = groupedTasks[hour] ?? [];
          if (hourTasks.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...hourTasks.map((task) => _buildTaskCard(context, task)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    return Dismissible(
      key: Key(task.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Task'),
              content: const Text('Are you sure you want to delete this task?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await Provider.of<DatabaseService>(
              context,
              listen: false,
            ).deleteTask(task.id);
          }
          return confirmed ?? false;
        } else {
          onTaskTap(task);
          return false;
        }
      },
      child: Card(
        child: ListTile(
          title: Text(task.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null) Text(task.description!),
              if (task.description != null) const SizedBox(height: 4),
              Text(
                '${task.formattedStartTime} - ${task.formattedEndTime}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (task.subtasks.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...task.subtasks.map((subtask) => Text('• $subtask')),
              ],
            ],
          ),
          trailing: Chip(label: Text(task.category)),
          onTap: () => onTaskTap(task),
        ),
      ),
    );
  }
}
