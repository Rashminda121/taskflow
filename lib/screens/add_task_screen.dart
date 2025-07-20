import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../models/task.dart';
import '../services/database_service.dart';

class AddTaskScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddTaskScreen({super.key, required this.selectedDate});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subtaskController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  String _category = 'Meeting';
  List<String> _subtasks = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);
  }

  void _addSubtask() {
    if (_subtaskController.text.isNotEmpty) {
      setState(() {
        _subtasks.add(_subtaskController.text);
        _subtaskController.clear();
      });
    }
  }

  Future<void> _scheduleNotification(Task task) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Convert to TZDateTime
    final scheduledTime = tz.TZDateTime.from(
      DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.startTime.hour,
        task.startTime.minute,
      ),
      tz.local,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      task.id.hashCode,
      task.title,
      task.description ?? 'Task starting now',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daydo_channel',
          'DayDo Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<DatabaseService>(context);
    final categories = database.getCategories();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(_startTime.format(context)),
                onTap: () => _selectTime(context, true),
              ),
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(_endTime.format(context)),
                onTap: () => _selectTime(context, false),
              ),
              const SizedBox(height: 16),
              const Text('Category'),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _category,
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _category = value!;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addCategory(context, database),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Subtasks'),
              ..._subtasks.map(
                (subtask) => ListTile(
                  title: Text(subtask),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _subtasks.remove(subtask);
                      });
                    },
                  ),
                ),
              ),
              TextFormField(
                controller: _subtaskController,
                decoration: const InputDecoration(labelText: 'Add Subtask'),
                onFieldSubmitted: (_) => _addSubtask(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTask,
                child: const Text('Save Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          if (_endTime.hour < picked.hour ||
              (_endTime.hour == picked.hour &&
                  _endTime.minute <= picked.minute)) {
            _endTime = TimeOfDay(hour: picked.hour + 1, minute: picked.minute);
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _addCategory(
    BuildContext context,
    DatabaseService database,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await database.addCategory(result);
      setState(() {
        _category = result;
      });
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        date: _selectedDate,
        startTime: _startTime,
        endTime: _endTime,
        category: _category,
        subtasks: _subtasks,
      );

      await Provider.of<DatabaseService>(context, listen: false).addTask(task);
      await _scheduleNotification(task);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }
}
