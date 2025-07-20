import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/database_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _subtaskController;
  late String _selectedCategory;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late List<String> _subtasks;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _subtaskController = TextEditingController();
    _selectedCategory = widget.task.category;
    _startTime = widget.task.startTime;
    _endTime = widget.task.endTime;
    _subtasks = List.from(widget.task.subtasks);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    if (_subtaskController.text.isNotEmpty) {
      setState(() {
        _subtasks.add(_subtaskController.text);
        _subtaskController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<DatabaseService>(context);
    final categories = database.getCategories();

    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d').format(widget.task.date),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${_startTime.format(context)} - ${_endTime.format(context)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 16),
                Chip(label: Text(_selectedCategory)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text('Category'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedCategory,
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
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
              onEditingComplete: _addSubtask,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeField('From', _startTime, (time) {
                    setState(() {
                      _startTime = time;
                      if (_endTime.hour < time.hour ||
                          (_endTime.hour == time.hour &&
                              _endTime.minute <= time.minute)) {
                        _endTime = TimeOfDay(
                          hour: time.hour + 1,
                          minute: time.minute,
                        );
                      }
                    });
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeField('To', _endTime, (time) {
                    setState(() {
                      _endTime = time;
                    });
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _updateTask,
              child: const Text('Update Task'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return InkWell(
      onTap: () async {
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (selectedTime != null) {
          onTimeSelected(selectedTime);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(time.format(context), style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _updateTask() async {
    final updatedTask = Task(
      id: widget.task.id,
      title: _titleController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      date: widget.task.date,
      startTime: _startTime,
      endTime: _endTime,
      category: _selectedCategory,
      isCompleted: widget.task.isCompleted,
      subtasks: _subtasks,
    );

    await Provider.of<DatabaseService>(
      context,
      listen: false,
    ).updateTask(updatedTask);
    if (!mounted) return;
    Navigator.pop(context, updatedTask);
  }
}
