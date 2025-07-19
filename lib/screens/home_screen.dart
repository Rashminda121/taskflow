import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import 'add_task_screen.dart';
import '../widgets/task_card.dart';
import '../widgets/calendar_widget.dart'; // Import your CompactCalendar

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  late final DatabaseService _database;

  @override
  void initState() {
    super.initState();
    _database = Provider.of<DatabaseService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _database.getTasksForDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Good Morning, Rdev')),
      body: Column(
        children: [
          // Use your CompactCalendar widget here
          CompactCalendar(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(),
          ),

          // Schedule Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Schedule Today',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  DateFormat('EEEE, MMMM d').format(_selectedDate),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),

          // Tasks List
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('No tasks for today'))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) => TaskCard(
                      task: tasks[index],
                      onChanged: () => setState(() {}),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTask(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(selectedDate: _selectedDate),
      ),
    );
    setState(() {});
  }
}
