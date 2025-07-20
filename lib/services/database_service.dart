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
    await Hive.openBox<Map<String, dynamic>>(_profileBoxName);

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

    final profileBox = Hive.box<Map<String, dynamic>>(_profileBoxName);
    if (profileBox.isEmpty) {
      await profileBox.put('profile', {'name': 'User', 'imagePath': null});
    }
  }

  Box<Task> get tasksBox => Hive.box<Task>(_taskBoxName);
  Box<String> get categoryBox => Hive.box<String>(_categoryBoxName);
  Box<Map<String, dynamic>> get profileBox =>
      Hive.box<Map<String, dynamic>>(_profileBoxName);

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
        .where((task) =>
            task.date.year == date.year &&
            task.date.month == date.month &&
            task.date.day == date.day)
        .toList();
  }

  Future<void> addCategory(String category) async {
    await categoryBox.add(category);
  }

  Future<void> deleteCategory(int index) async {
    await categoryBox.deleteAt(index);
  }

  List<String> getCategories() {
    return categoryBox.values.toList();
  }

  Future<void> updateProfile(Map<String, dynamic> profile) async {
    await profileBox.put('profile', profile);
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final profile = profileBox.get('profile');
      if (profile != null) {
        return Map<String, dynamic>.from(profile);
      }
      return {'name': 'User', 'imagePath': null};
    } catch (e) {
      return {'name': 'User', 'imagePath': null};
    }
  }

  Future<void> close() async {
    await Hive.close();
  }
}
