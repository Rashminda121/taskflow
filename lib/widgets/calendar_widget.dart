import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CompactCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const CompactCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<CompactCalendar> createState() => _CompactCalendarState();
}

class _CompactCalendarState extends State<CompactCalendar> {
  bool _isExpanded = false;
  late DateTime _currentMonth;
  final ScrollController _weekScrollController = ScrollController();
  final PageController _monthPageController = PageController(initialPage: 12);
  late PageController _yearPageController;
  bool _showYearPicker = false;
  late List<int> _years;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );
    _years = List.generate(20, (index) => DateTime.now().year - 10 + index);
    _yearPageController = PageController(
      initialPage: DateTime.now().year - _years.first,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedWeek(center: true);
      _centerOnCurrentMonth();
    });
  }

  @override
  void didUpdateWidget(CompactCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _currentMonth = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        1,
      );
      _scrollToSelectedWeek(center: true);
      _centerOnCurrentMonth();
    }
  }

  void _scrollToSelectedWeek({bool center = false}) {
    if (_isExpanded || !_weekScrollController.hasClients) return;

    final firstDayOfWeek = widget.selectedDate.subtract(
      Duration(days: widget.selectedDate.weekday - 1),
    );
    final daysDifference = widget.selectedDate
        .difference(firstDayOfWeek)
        .inDays;
    final scrollOffset = daysDifference * 56.0;

    if (center) {
      // Calculate position to center the selected date
      final viewportWidth =
          MediaQuery.of(context).size.width - 32; // Account for padding
      final centerOffset =
          scrollOffset - (viewportWidth / 2) + 24; // 24 is half day width
      _weekScrollController.jumpTo(
        centerOffset.clamp(0.0, _weekScrollController.position.maxScrollExtent),
      );
    } else {
      _weekScrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _centerOnCurrentMonth() {
    if (!_isExpanded || !_monthPageController.hasClients) return;
    _monthPageController.animateToPage(
      12,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: _isExpanded ? (_showYearPicker ? 300 : 350) : 100,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          if (!_isExpanded) Expanded(child: _buildWeekView()),
          if (_isExpanded && !_showYearPicker)
            Expanded(child: _buildMonthView()),
          if (_isExpanded && _showYearPicker)
            Expanded(child: _buildYearPicker()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _navigateMonths(-1),
              ),
              GestureDetector(
                onTap: () => setState(() => _showYearPicker = !_showYearPicker),
                child: Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _navigateMonths(1),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
                _showYearPicker = false;
                if (_isExpanded) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _centerOnCurrentMonth(),
                  );
                } else {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToSelectedWeek(center: true),
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    final days = ['Mo', 'Tu', 'Wed', 'Th', 'Fr', 'Sa', 'Su'];
    final firstDayOfWeek = widget.selectedDate.subtract(
      Duration(days: widget.selectedDate.weekday - 1),
    );

    return ListView.builder(
      controller: _weekScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: 21, // 3 weeks
      itemBuilder: (context, index) {
        final date = firstDayOfWeek.add(Duration(days: index - 7));
        final isSelected =
            date.day == widget.selectedDate.day &&
            date.month == widget.selectedDate.month;

        return Container(
          width: 48,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                days[date.weekday - 1],
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthView() {
    return PageView.builder(
      controller: _monthPageController,
      itemCount: 24,
      onPageChanged: (index) {
        final newMonth = DateTime(
          _currentMonth.year,
          _currentMonth.month + (index - 12),
          1,
        );
        setState(() => _currentMonth = newMonth);
      },
      itemBuilder: (context, pageIndex) {
        final displayMonth = DateTime(
          _currentMonth.year,
          _currentMonth.month + (pageIndex - 12),
          1,
        );
        return _buildSingleMonthView(displayMonth);
      },
    );
  }

  Widget _buildSingleMonthView(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysBefore = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (day) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Table(
            children: [
              for (int i = 0; i < ((daysBefore + daysInMonth) / 7).ceil(); i++)
                TableRow(
                  children: [
                    for (int j = 0; j < 7; j++)
                      Builder(
                        builder: (context) {
                          final dayIndex = i * 7 + j;
                          final date = firstDayOfMonth.add(
                            Duration(days: dayIndex - daysBefore),
                          );
                          final isCurrentMonth =
                              dayIndex >= daysBefore &&
                              dayIndex < daysBefore + daysInMonth;
                          final isSelected =
                              isCurrentMonth &&
                              date.day == widget.selectedDate.day &&
                              date.month == widget.selectedDate.month;

                          return GestureDetector(
                            onTap: isCurrentMonth
                                ? () {
                                    widget.onDateSelected(date);
                                    setState(() => _isExpanded = false);
                                  }
                                : null,
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue
                                    : isCurrentMonth
                                    ? Colors.transparent
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : isCurrentMonth
                                        ? Colors.black
                                        : Colors.grey,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearPicker() {
    return PageView.builder(
      controller: _yearPageController,
      itemCount: _years.length,
      onPageChanged: (index) {
        setState(
          () => _currentMonth = DateTime(_years[index], _currentMonth.month, 1),
        );
      },
      itemBuilder: (context, index) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
          ),
          itemCount: 12,
          itemBuilder: (context, monthIndex) {
            return InkWell(
              onTap: () {
                setState(() {
                  _currentMonth = DateTime(_years[index], monthIndex + 1, 1);
                  _showYearPicker = false;
                });
              },
              child: Card(
                color:
                    _currentMonth.year == _years[index] &&
                        _currentMonth.month == monthIndex + 1
                    ? Colors.blue.withOpacity(0.2)
                    : null,
                child: Center(
                  child: Text(
                    DateFormat('MMM').format(DateTime(0, monthIndex + 1)),
                    style: TextStyle(
                      fontWeight:
                          _currentMonth.year == _years[index] &&
                              _currentMonth.month == monthIndex + 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _navigateMonths(int offset) {
    if (_showYearPicker) return;

    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + offset,
        1,
      );
      if (_isExpanded) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _centerOnCurrentMonth(),
        );
      } else {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToSelectedWeek(center: true),
        );
      }
    });
  }

  @override
  void dispose() {
    _weekScrollController.dispose();
    _monthPageController.dispose();
    _yearPageController.dispose();
    super.dispose();
  }
}
