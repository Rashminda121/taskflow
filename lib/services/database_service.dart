import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/time_of_day_adapter.dart';

class DatabaseService {
  static const String _taskBoxName = 'tasks';
  static const String _categoryBoxName = 'categories';
  static const String _profileBoxName = 'profile';

  static const List<String> _defaultCategories = [
    'Work',
    'Personal',
    'Study',
    'Health',
    'Other',
  ];

  late Box<Task> _taskBox;
  late Box<String> _categoryBox;
  late Box<Map<String, dynamic>> _profileBox;

  Future<void> init() async {
    try {
      await Hive.initFlutter();

      if (!Hive.isAdapterRegistered(TaskAdapter().typeId)) {
        Hive.registerAdapter(TaskAdapter());
      }
      if (!Hive.isAdapterRegistered(TimeOfDayAdapter().typeId)) {
        Hive.registerAdapter(TimeOfDayAdapter());
      }

      _taskBox = await _openBoxWithRecovery<Task>(_taskBoxName);
      _categoryBox = await _openBoxWithRecovery<String>(_categoryBoxName);
      _profileBox =
          await _openBoxWithRecovery<Map<String, dynamic>>(_profileBoxName);

      await _initializeDefaultData();
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<Box<T>> _openBoxWithRecovery<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (e) {
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox<T>(name);
    }
  }

  Future<void> _initializeDefaultData() async {
    for (final category in _defaultCategories) {
      if (!_categoryBox.values.contains(category)) {
        await _categoryBox.add(category);
      }
    }

    if (!_profileBox.containsKey('profile')) {
      await _profileBox.put('profile', {
        'name': 'User',
        'imagePath': null,
        'email': '',
        'phone': '',
        'themeMode': 'system',
      });
    }
  }

  // Task operations
  Future<void> addTask(Task task) async => await _taskBox.put(task.id, task);
  Future<void> updateTask(Task task) async => await _taskBox.put(task.id, task);
  Future<void> deleteTask(String id) async => await _taskBox.delete(id);
  Future<void> clearAllTasks() async => await _taskBox.clear();

  List<Task> getTasksForDate(DateTime date) {
    return _taskBox.values
        .where((task) =>
            task.date.year == date.year &&
            task.date.month == date.month &&
            task.date.day == date.day)
        .toList();
  }

  // Category operations
  List<String> getCategories() => _categoryBox.values.toList();

  Future<void> addCategory(String category) async {
    if (!_categoryBox.values.contains(category)) {
      await _categoryBox.add(category);
    }
  }

  Future<void> deleteCategory(int index) async {
    final category = _categoryBox.getAt(index);
    if (category != null && !_defaultCategories.contains(category)) {
      await _categoryBox.deleteAt(index);
    }
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final categories = _categoryBox.values.toList();
    if (oldIndex < newIndex) newIndex -= 1;
    final item = categories.removeAt(oldIndex);
    categories.insert(newIndex, item);
    await _categoryBox.clear();
    await _categoryBox.addAll(categories);
  }

  bool isDefaultCategory(String category) =>
      _defaultCategories.contains(category);

  // Profile operations
  Future<Map<String, dynamic>> getProfile() async {
    return _profileBox.get('profile') ??
        {
          'name': 'User',
          'imagePath': null,
          'email': '',
          'phone': '',
          'themeMode': 'system',
        };
  }

  Future<void> updateProfile(Map<String, dynamic> profile) async {
    await _profileBox.put('profile', profile);
  }

  Future<void> clearDatabase() async {
    await _taskBox.clear();
    await _categoryBox.clear();
    await _profileBox.clear();
    await _initializeDefaultData();
  }

  Future<void> close() async => await Hive.close();

  Box<Task> get tasksBox => _taskBox;
  Box<String> get categoryBox => _categoryBox;
  Box<Map<String, dynamic>> get profileBox => _profileBox;
}
