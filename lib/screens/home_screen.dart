import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../widgets/theme_provider.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';
import 'category_management_screen.dart';
import 'profile_screen.dart';
import '../models/task.dart';
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
  bool _showCategorySelector = false;
  bool _showCompletedTasks = false;
  final Map<int, bool> _expandedHours = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Initialize all hours as expanded
    for (int i = 0; i < 24; i++) {
      _expandedHours[i] = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  String _formatHour(int hour) {
    final time = TimeOfDay(hour: hour, minute: 0);
    return time.format(context);
  }

  void _toggleCategorySelector() {
    setState(() {
      _showCategorySelector = !_showCategorySelector;
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _showCategorySelector = false;
    });
  }

  void _toggleCompletedTasks() {
    setState(() {
      _showCompletedTasks = !_showCompletedTasks;
    });
  }

  void _toggleHourExpansion(int hour) {
    setState(() {
      _expandedHours[hour] = !(_expandedHours[hour] ?? true);
    });
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final database = Provider.of<DatabaseService>(context, listen: false);
    await database.updateTask(task.copyWith(isCompleted: !task.isCompleted));
    setState(() {});
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
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
      final database = Provider.of<DatabaseService>(context, listen: false);
      await database.deleteTask(task.id);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task "${task.title}" deleted')),
        );
      }
    }
  }

  Future<void> _editTask(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          selectedDate: task.date,
          taskToEdit: task,
        ),
      ),
    );
    setState(() {});
  }

  DateTime _timeOfDayToDateTime(TimeOfDay timeOfDay, DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final database = Provider.of<DatabaseService>(context);
    final allTasks = database.getTasksForDate(_selectedDate);

    // Filter tasks based on category and completion status
    final pendingTasks = allTasks.where((task) {
      final categoryMatch =
          _selectedCategory == 'All' || task.category == _selectedCategory;
      return categoryMatch && !task.isCompleted;
    }).toList()
      ..sort((a, b) => _timeOfDayToDateTime(a.startTime, a.date)
          .compareTo(_timeOfDayToDateTime(b.startTime, b.date)));

    final completedTasks = allTasks.where((task) {
      final categoryMatch =
          _selectedCategory == 'All' || task.category == _selectedCategory;
      return categoryMatch && task.isCompleted;
    }).toList()
      ..sort((a, b) => _timeOfDayToDateTime(a.startTime, a.date)
          .compareTo(_timeOfDayToDateTime(b.startTime, b.date)));

    // Group tasks by hour
    final Map<int, List<Task>> tasksByHour = {};
    for (final task in pendingTasks) {
      final hour = task.startTime.hour;
      tasksByHour.putIfAbsent(hour, () => []);
      tasksByHour[hour]!.add(task);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snapshot) {
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.secondary,
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
                              color: theme.colorScheme.onSecondary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 20,
                          color: theme.colorScheme.onSecondary,
                        ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getGreeting(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'User'
                            : snapshot.data?['name'] ?? 'User',
                        style: theme.textTheme.titleMedium?.copyWith(
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
          IconButton(
            icon: Icon(theme.brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () => Provider.of<ThemeProvider>(context, listen: false)
                .toggleTheme(),
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CategoryManagementScreen()),
            ).then((_) => setState(() {})),
            tooltip: 'Manage categories',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Calendar Section
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CompactCalendar(
                      selectedDate: _selectedDate,
                      onDateSelected: (date) =>
                          setState(() => _selectedDate = date),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Header Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Schedule',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        DateFormat('MMM d').format(_selectedDate),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter and Completed Tasks Toggle Row
              if (allTasks.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Filter Chip
                      GestureDetector(
                        onTap: _toggleCategorySelector,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_alt_outlined,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedCategory,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Completed Tasks Toggle
                      if (completedTasks.isNotEmpty)
                        GestureDetector(
                          onTap: _toggleCompletedTasks,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _showCompletedTasks
                                  ? theme.colorScheme.primary.withOpacity(0.1)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showCompletedTasks
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Completed',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1),
              ),
              const SizedBox(height: 8),

              // Task Timeline
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      // Show message if no tasks in selected category
                      if (pendingTasks.isEmpty && completedTasks.isEmpty)
                        _buildNoTasksInCategory(),

                      // Pending Tasks by Hour
                      if (pendingTasks.isNotEmpty)
                        ...List.generate(24, (index) {
                          final hour = index;
                          final tasks = tasksByHour[hour] ?? [];
                          final hasTasks = tasks.isNotEmpty;

                          if (!hasTasks) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            children: [
                              // Hour Header
                              GestureDetector(
                                onTap: () => _toggleHourExpansion(hour),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  color: theme.colorScheme.surface,
                                  child: Row(
                                    children: [
                                      Text(
                                        _formatHour(hour),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        _expandedHours[hour] ?? true
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Tasks for this hour
                              if (_expandedHours[hour] ?? true)
                                ...tasks
                                    .map((task) => _buildTaskCard(task, false)),
                            ],
                          );
                        }),

                      // Completed Tasks Section
                      if (_showCompletedTasks && completedTasks.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                'Completed Tasks',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  completedTasks.length.toString(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...completedTasks
                            .map((task) => _buildTaskCard(task, true)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Category Selector Bottom Sheet
          if (_showCategorySelector) _buildCategorySelector(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddTaskScreen(selectedDate: _selectedDate)),
        ).then((_) => setState(() {})),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                ).then((_) {
                  setState(() {
                    _currentIndex = 0;
                    _loadProfile();
                  });
                });
              }
            },
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 0
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.task,
                    size: 24,
                  ),
                ),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _currentIndex == 1
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 24,
                  ),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoTasksInCategory() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCategory == 'All'
                ? 'No tasks for this day'
                : 'No tasks in "$_selectedCategory" category',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedCategory != 'All')
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'All';
                });
              },
              child: Text(
                'View all tasks',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a new task',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, bool isCompleted) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a');
    final startTime =
        timeFormat.format(_timeOfDayToDateTime(task.startTime, task.date));
    final endTime =
        timeFormat.format(_timeOfDayToDateTime(task.endTime, task.date));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.horizontal,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await _deleteTask(task);
            return false;
          } else if (direction == DismissDirection.endToStart) {
            await _editTask(task);
            return false;
          }
          return null;
        },
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _toggleTaskCompletion(task),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Category Indicator
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: task.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Task Title
                      Expanded(
                        child: Text(
                          task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: isCompleted
                                ? theme.colorScheme.onSurface.withOpacity(0.5)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Complete/Incomplete Button
                      IconButton(
                        icon: Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        onPressed: () => _toggleTaskCompletion(task),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$startTime - $endTime',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ...[
                        Icon(
                          Icons.category,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final theme = Theme.of(context);
    final database = Provider.of<DatabaseService>(context);
    final categories = ['All', ...database.getCategories()];

    return Positioned.fill(
      child: GestureDetector(
        onTap: _toggleCategorySelector,
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              elevation: 8,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Draggable Handle
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Category',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            onPressed: _toggleCategorySelector,
                          ),
                        ],
                      ),
                    ),

                    // Categories List
                    Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        shrinkWrap: true,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            title: Text(
                              category,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: _selectedCategory == category
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: _selectedCategory == category
                                ? Icon(
                                    Icons.check,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  )
                                : null,
                            onTap: () => _selectCategory(category),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
