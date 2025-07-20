import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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
  final DateTime _currentDate = DateTime.now();
  final ScrollController _yearScrollController = ScrollController();
  final ScrollController _monthScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerSelectedDate();
      _centerCurrentYearMonth();
    });
  }

  void _centerSelectedDate() {
    if (_isExpanded || !_weekScrollController.hasClients) return;

    final dateWidth = 56.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final daysBefore = 7;
    final selectedDateOffset =
        (widget.selectedDate.weekday - 1 + daysBefore) * dateWidth;
    final centerOffset =
        selectedDateOffset - (screenWidth / 2) + (dateWidth / 2);

    _weekScrollController.animateTo(
      centerOffset.clamp(0.0, _weekScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _centerCurrentYearMonth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_yearScrollController.hasClients) {
        final yearItemHeight = 48.0;
        final currentYearOffset =
            (_currentMonth.year - _currentDate.year + 10) * yearItemHeight;
        final viewportHeight = _yearScrollController.position.viewportDimension;
        final centerOffset =
            currentYearOffset - (viewportHeight / 2) + (yearItemHeight / 2);

        _yearScrollController.animateTo(
          centerOffset.clamp(
            0.0,
            _yearScrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      if (_monthScrollController.hasClients) {
        final monthItemHeight = 56.0;
        final currentMonthOffset = (_currentMonth.month - 1) * monthItemHeight;
        final viewportHeight =
            _monthScrollController.position.viewportDimension;
        final centerOffset =
            currentMonthOffset - (viewportHeight / 2) + (monthItemHeight / 2);

        _monthScrollController.animateTo(
          centerOffset.clamp(
            0.0,
            _monthScrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void didUpdateWidget(CompactCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      setState(() {
        _currentMonth = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          1,
        );
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerSelectedDate();
      });
    }
  }

  void _resetToCurrentDate() {
    widget.onDateSelected(_currentDate);
    setState(() {
      _currentMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    });
    if (!_isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerSelectedDate();
        _centerCurrentYearMonth();
      });
    }
  }

  void _showYearMonthPickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              minWidth: 300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select Year and Month',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: ListView.builder(
                            controller: _yearScrollController,
                            itemCount: 30,
                            itemExtent: 48.0,
                            itemBuilder: (context, index) {
                              final year = _currentDate.year - 10 + index;
                              return ListTile(
                                title: Center(
                                  child: Text(
                                    year.toString(),
                                    style: TextStyle(
                                      fontWeight: year == _currentMonth.year
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: year == _currentMonth.year
                                          ? Theme.of(context).primaryColor
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _currentMonth = DateTime(
                                      year,
                                      _currentMonth.month,
                                      1,
                                    );
                                    _centerCurrentYearMonth();
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ListView.builder(
                          controller: _monthScrollController,
                          itemCount: 12,
                          itemExtent: 56.0,
                          itemBuilder: (context, index) {
                            final month = index + 1;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor:
                                      month == _currentMonth.month &&
                                          _currentMonth.year ==
                                              _currentMonth.year
                                      ? Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.1)
                                      : null,
                                  side: BorderSide(
                                    color:
                                        month == _currentMonth.month &&
                                            _currentMonth.year ==
                                                _currentMonth.year
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _currentMonth = DateTime(
                                      _currentMonth.year,
                                      month,
                                      1,
                                    );
                                    Navigator.pop(context);
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          _centerSelectedDate();
                                        });
                                  });
                                },
                                child: Text(
                                  DateFormat('MMMM').format(DateTime(0, month)),
                                  style: TextStyle(
                                    color:
                                        month == _currentMonth.month &&
                                            _currentMonth.year ==
                                                _currentMonth.year
                                        ? Theme.of(context).primaryColor
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _centerCurrentYearMonth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _isExpanded ? 450 : 110,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _isExpanded ? _buildMonthView() : _buildWeekView()),
          if (_isExpanded) const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (_isExpanded)
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _navigateMonths(-1),
                ),
              InkWell(
                onTap: _isExpanded
                    ? _showYearMonthPickerDialog
                    : () {
                        setState(() {
                          _isExpanded = true;
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                  ),
                  child: Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (_isExpanded)
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _navigateMonths(1),
                ),
            ],
          ),
          Row(
            children: [
              if (_isExpanded)
                IconButton(
                  icon: const Icon(Icons.today),
                  tooltip: 'Go to today',
                  onPressed: _resetToCurrentDate,
                ),
              IconButton(
                icon: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_isExpanded) _centerSelectedDate();
                    });
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weeksToShow = 3;
    final firstDayToShow = widget.selectedDate.subtract(
      Duration(days: widget.selectedDate.weekday - 1 + 7),
    );

    return SizedBox(
      height: 110,
      child: ListView.builder(
        controller: _weekScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: days.length * weeksToShow,
        itemBuilder: (context, index) {
          final date = firstDayToShow.add(Duration(days: index));
          final isSelected =
              date.day == widget.selectedDate.day &&
              date.month == widget.selectedDate.month &&
              date.year == widget.selectedDate.year;
          final isCurrentDate =
              date.day == _currentDate.day &&
              date.month == _currentDate.month &&
              date.year == _currentDate.year;

          return SizedBox(
            width: 56,
            height: 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Material(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : isCurrentDate
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    widget.onDateSelected(date);
                    setState(() {
                      _currentMonth = DateTime(date.year, date.month, 1);
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _centerSelectedDate();
                    });
                  },
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 1.2,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          days[date.weekday - 1],
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            color: isSelected
                                ? Colors.white
                                : isCurrentDate
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
        setState(() {
          _currentMonth = newMonth;
        });
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                children: List.generate(
                  ((daysBefore + daysInMonth) / 7).ceil(),
                  (i) => TableRow(
                    children: List.generate(7, (j) {
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
                      final isCurrentDate =
                          isCurrentMonth &&
                          date.day == _currentDate.day &&
                          date.month == _currentDate.month &&
                          date.year == _currentDate.year;

                      return Container(
                        height: 44,
                        margin: const EdgeInsets.all(2),
                        child: Material(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : isCurrentDate
                              ? Colors.grey.withOpacity(0.2)
                              : isCurrentMonth
                              ? Colors.transparent
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: isCurrentMonth
                                ? () {
                                    widget.onDateSelected(date);
                                    setState(() {
                                      _currentMonth = DateTime(
                                        date.year,
                                        date.month,
                                        1,
                                      );
                                      _isExpanded = false;
                                    });
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          _centerSelectedDate();
                                        });
                                  }
                                : null,
                            child: Center(
                              child: Text(
                                date.day.toString(),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : isCurrentDate
                                      ? Colors.black
                                      : isCurrentMonth
                                      ? Colors.black
                                      : Colors.grey,
                                  fontWeight: isSelected || isCurrentDate
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateMonths(int offset) {
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
    _yearScrollController.dispose();
    _monthScrollController.dispose();
    super.dispose();
  }
}
