import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/time_of_day_adapter.dart';

class DatabaseService {
  static const String _taskBoxName = 'tasks';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TimeOfDayAdapter());
    await Hive.openBox<Task>(_taskBoxName);
  }

  Box<Task> get tasksBox => Hive.box<Task>(_taskBoxName);

  Future<void> addTask(Task task) async {
    await tasksBox.put(task.id, task);
  }

  Future<void> updateTask(Task task) async {
    await tasksBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    await tasksBox.delete(id);
  }

  List<Task> getTasksForDate(DateTime date) {
    return tasksBox.values
        .where(
          (task) =>
              task.date.year == date.year &&
              task.date.month == date.month &&
              task.date.day == date.day,
        )
        .toList();
  }
}
