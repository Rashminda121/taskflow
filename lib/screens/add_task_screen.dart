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
  final Task? taskToEdit;

  const AddTaskScreen({
    super.key,
    required this.selectedDate,
    this.taskToEdit,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final _subtaskController = TextEditingController();
  final _categoryController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _category;
  List<String> _subtasks = [];
  Color _taskColor = Colors.blue;
  bool _showSubtasks = false;
  bool _showDescription = false;

  @override
  void initState() {
    super.initState();

    if (widget.taskToEdit != null) {
      _titleController = TextEditingController(text: widget.taskToEdit!.title);
      _descriptionController =
          TextEditingController(text: widget.taskToEdit!.description ?? '');
      _selectedDate = widget.taskToEdit!.date;
      _startTime = widget.taskToEdit!.startTime;
      _endTime = widget.taskToEdit!.endTime;
      _category = widget.taskToEdit!.category;
      _subtasks = List.from(widget.taskToEdit!.subtasks ?? []);
      _taskColor = widget.taskToEdit!.color;
      _showSubtasks = widget.taskToEdit!.subtasks?.isNotEmpty ?? false;
      _showDescription = widget.taskToEdit!.description?.isNotEmpty ?? false;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedDate = widget.selectedDate;
      _startTime = TimeOfDay.now();
      _endTime =
          TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);
      _category = 'Personal';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    if (_subtaskController.text.isNotEmpty) {
      setState(() {
        _subtasks.add(_subtaskController.text);
        _subtaskController.clear();
        _showSubtasks = true;
      });
    }
  }

  Future<void> _addNewCategory(DatabaseService database) async {
    if (_categoryController.text.isNotEmpty) {
      await database.addCategory(_categoryController.text);
      setState(() {
        _category = _categoryController.text;
        _categoryController.clear();
      });
    }
  }

  Future<void> _scheduleNotification(Task task) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    tz.initializeTimeZones();

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

  Widget _buildColorOption(Color color) {
    final theme = Theme.of(context);
    final isSelected = _taskColor.value == color.value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _taskColor = color;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: isSelected ? 42 : 36,
          height: isSelected ? 42 : 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    width: 1.5,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<DatabaseService>(context);
    final categories = database.getCategories();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit != null ? 'Edit Task' : 'New Task'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.normal, // Ensures it's not bold
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Date Section
              const Text('Date',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 20, color: theme.iconTheme.color),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEE, MMM d, y').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time Section
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('From Time',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 20, color: theme.iconTheme.color),
                                const SizedBox(width: 12),
                                Text(
                                  _startTime.format(context),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('To Time',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 20, color: theme.iconTheme.color),
                                const SizedBox(width: 12),
                                Text(
                                  _endTime.format(context),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category Section
              const Text('Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                      ),
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
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showAddCategoryDialog(database),
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Color Section
              const Text('Color',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildColorOption(Colors.red),
                    _buildColorOption(Colors.orange),
                    _buildColorOption(Colors.yellow),
                    _buildColorOption(Colors.green),
                    _buildColorOption(Colors.blue),
                    _buildColorOption(Colors.indigo),
                    _buildColorOption(Colors.purple),
                    _buildColorOption(Colors.pink),
                    _buildColorOption(Colors.teal),
                    _buildColorOption(Colors.cyan),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Subtasks Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtasks',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notes,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showSubtasks = !_showSubtasks;
                      });
                    },
                  ),
                ],
              ),

              if (_showSubtasks) ...[
                if (_subtasks.isNotEmpty)
                  Column(
                    children: _subtasks
                        .map((subtask) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.circle_outlined,
                                      size: 18, color: theme.iconTheme.color),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(subtask)),
                                  IconButton(
                                    icon: Icon(Icons.close,
                                        size: 18, color: theme.iconTheme.color),
                                    onPressed: () {
                                      setState(() {
                                        _subtasks.remove(subtask);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _subtaskController,
                        decoration: InputDecoration(
                          hintText: 'Add a subtask...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onFieldSubmitted: (_) => _addSubtask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _addSubtask,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Description Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notes,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showDescription = !_showDescription;
                      });
                    },
                  ),
                ],
              ),

              if (_showDescription)
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Enter description...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_titleController.text.isEmpty) {
                      final theme = Theme.of(context);
                      final isDark = theme.brightness == Brightness.dark;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please enter a task title',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: isDark
                              ? Colors
                                  .grey[850] // custom dark-friendly background
                              : Colors.grey[200], // light-friendly background
                          action: SnackBarAction(
                            label: 'Dismiss',
                            onPressed: () {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                            },
                            textColor: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    } else {
                      _saveTask();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    widget.taskToEdit != null ? 'UPDATE TASK' : 'CREATE TASK',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(DatabaseService database) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              hintText: 'Enter category name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                _addNewCategory(database);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.taskToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        date: _selectedDate,
        startTime: _startTime,
        endTime: _endTime,
        category: _category,
        subtasks: _subtasks,
        color: _taskColor,
        isCompleted: widget.taskToEdit?.isCompleted ?? false,
      );

      final database = Provider.of<DatabaseService>(context, listen: false);
      if (widget.taskToEdit != null) {
        await database.updateTask(task);
      } else {
        await database.addTask(task);
      }

      await _scheduleNotification(task);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }
}
