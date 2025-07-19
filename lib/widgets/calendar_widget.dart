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
  bool _showYearPicker = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCurrentDate();
    });
  }

  void _centerCurrentDate() {
    if (_isExpanded || !_weekScrollController.hasClients) return;

    // Calculate position to center the selected date
    final dateWidth = 56.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final visibleDates = (screenWidth / dateWidth).floor();
    final centerOffset =
        (widget.selectedDate.weekday - 1) * dateWidth -
        (screenWidth / 2) +
        (dateWidth / 2);

    _weekScrollController.jumpTo(
      centerOffset.clamp(0.0, _weekScrollController.position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _isExpanded ? 350 : 100,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _isExpanded ? _buildMonthView() : _buildWeekView()),
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
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_isExpanded) _centerCurrentDate();
                });
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final firstDayOfWeek = widget.selectedDate.subtract(
      Duration(days: widget.selectedDate.weekday - 1),
    );

    return SizedBox(
      height: 80,
      child: ListView.builder(
        controller: _weekScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 21, // 3 weeks worth of days
        itemBuilder: (context, index) {
          final date = firstDayOfWeek.add(
            Duration(days: index - 7),
          ); // Center current week
          final isSelected =
              date.day == widget.selectedDate.day &&
              date.month == widget.selectedDate.month &&
              date.year == widget.selectedDate.year;

          return GestureDetector(
            onTap: () {
              widget.onDateSelected(date);
              setState(
                () => _currentMonth = DateTime(date.year, date.month, 1),
              );
            },
            child: Container(
              width: 56,
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
            ),
          );
        },
      ),
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
                              date.month == widget.selectedDate.month &&
                              date.year == widget.selectedDate.year;

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

  void _navigateMonths(int offset) {
    if (_showYearPicker) return;

    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + offset,
        1,
      );
    });
  }

  @override
  void dispose() {
    _weekScrollController.dispose();
    _monthPageController.dispose();
    super.dispose();
  }
}
