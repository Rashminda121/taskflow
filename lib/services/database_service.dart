import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/time_of_day_adapter.dart';

class DatabaseService {
  static const String _taskBoxName = 'tasks';
  static const String _categoryBoxName = 'categories';
  static const String _profileBoxName = 'profile';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TimeOfDayAdapter());
    await Hive.openBox<Task>(_taskBoxName);
    await Hive.openBox<String>(_categoryBoxName);
    await Hive.openBox(_profileBoxName);

    final categoryBox = Hive.box<String>(_categoryBoxName);
    if (categoryBox.isEmpty) {
      await categoryBox.addAll([
        'Meeting',
        'Hangout',
        'Cooking',
        'Other',
        'Weekend',
      ]);
    }

    final profileBox = Hive.box(_profileBoxName);
    if (profileBox.isEmpty) {
      await profileBox.put('profile', {'name': 'User', 'imagePath': null});
    }
  }

  Box<Task> get tasksBox => Hive.box<Task>(_taskBoxName);
  Box<String> get categoryBox => Hive.box<String>(_categoryBoxName);
  Box get profileBox => Hive.box(_profileBoxName);

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

  Future<void> addCategory(String category) async {
    await categoryBox.add(category);
  }

  Future<void> deleteCategory(String category) async {
    final index = categoryBox.values.toList().indexOf(category);
    if (index != -1) {
      await categoryBox.deleteAt(index);
    }
  }

  List<String> getCategories() {
    return categoryBox.values.toList();
  }

  Future<void> updateProfile(Map<String, dynamic> profile) async {
    await profileBox.put('profile', profile);
  }

  Map<String, dynamic> getProfile() {
    return profileBox.get('profile') ?? {'name': 'User', 'imagePath': null};
  }
}
