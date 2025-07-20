import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../widgets/theme_provider.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';
import 'category_management_screen.dart';
import 'profile_screen.dart';
import '../widgets/task_timeline.dart';
import '../widgets/calendar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'All';
  int _currentIndex = 0;
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final database = Provider.of<DatabaseService>(context, listen: false);
    _profileFuture = database.getProfile();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<DatabaseService>(context);
    final categories = ['All', ...database.getCategories()];
    final tasks = database.getTasksForDate(_selectedDate)
      ..sort((a, b) =>
          a.startTime.hour * 60 +
          a.startTime.minute -
          (b.startTime.hour * 60 + b.startTime.minute));

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snapshot) {
            return Row(
              children: [
                // Profile icon
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: snapshot.hasData && snapshot.data?['photoUrl'] != null
                      ? ClipOval(
                          child: Image.network(
                            snapshot.data!['photoUrl'],
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                ),
                const SizedBox(width: 12),
                // Greeting and name with constrained width
                SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.5, // Limits width to 50% of screen
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getGreeting(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.8),
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'User'
                            : snapshot.data?['name'] ?? 'User',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () => Provider.of<ThemeProvider>(context, listen: false)
                .toggleTheme(),
            tooltip: 'Toggle theme',
          ),
          // Categories button
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CategoryManagementScreen()),
            ).then((_) => setState(() {})),
            tooltip: 'Manage categories',
          ),
          // Add some spacing if needed
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          CompactCalendar(
            selectedDate: _selectedDate,
            onDateSelected: (date) => setState(() => _selectedDate = date),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedCategory,
              items: categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Schedule Today',
                    style: Theme.of(context).textTheme.titleLarge),
                Text(DateFormat('EEEE, MMMM d').format(_selectedDate),
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          Expanded(
            child: TaskTimeline(
              tasks: _selectedCategory == 'All'
                  ? tasks
                  : tasks
                      .where((task) => task.category == _selectedCategory)
                      .toList(),
              onTaskTap: (task) => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TaskDetailScreen(task: task)),
              ).then((_) => setState(() {})),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddTaskScreen(selectedDate: _selectedDate)),
        ).then((_) => setState(() {})),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ).then((_) {
              setState(() {
                _currentIndex = 0;
                _loadProfile();
              });
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
