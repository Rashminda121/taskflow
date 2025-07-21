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

    final dateWidth = 52.0;
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final selectedColor = theme.primaryColor;
    final borderColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;

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
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: textColor,
                    ),
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
                              right: BorderSide(color: borderColor),
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
                                          ? selectedColor
                                          : textColor,
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
                                  backgroundColor: month == _currentMonth.month
                                      ? selectedColor.withOpacity(0.1)
                                      : null,
                                  side: BorderSide(
                                    color: month == _currentMonth.month
                                        ? selectedColor
                                        : borderColor,
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
                                    color: month == _currentMonth.month
                                        ? selectedColor
                                        : textColor,
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
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: textColor),
                        ),
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final selectedDateBgColor = isDarkMode ? Colors.white : theme.primaryColor;
    final selectedDateTextColor = isDarkMode ? Colors.black : Colors.white;
    final currentDateBgColor = isDarkMode
        ? Colors.blueGrey.withOpacity(0.3)
        : Colors.blue.withOpacity(0.1);
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(isDarkMode, textColor),
          if (_isExpanded)
            SizedBox(
              height: 300, // Fixed height for expanded view
              child: _buildMonthView(
                selectedDateBgColor,
                selectedDateTextColor,
                currentDateBgColor,
                textColor,
              ),
            )
          else
            SizedBox(
              height: 72, // Fixed height for compact view
              child: _buildWeekView(
                selectedDateBgColor,
                selectedDateTextColor,
                currentDateBgColor,
                textColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (_isExpanded)
                IconButton(
                  icon: Icon(Icons.chevron_left, color: textColor),
                  onPressed: () => _navigateMonths(-1),
                ),
              InkWell(
                onTap: _isExpanded
                    ? _showYearMonthPickerDialog
                    : () => setState(() => _isExpanded = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              if (_isExpanded)
                IconButton(
                  icon: Icon(Icons.chevron_right, color: textColor),
                  onPressed: () => _navigateMonths(1),
                ),
            ],
          ),
          Row(
            children: [
              if (_isExpanded)
                IconButton(
                  icon: Icon(Icons.today, color: textColor),
                  tooltip: 'Go to today',
                  onPressed: _resetToCurrentDate,
                ),
              IconButton(
                icon: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: textColor,
                ),
                onPressed: () {
                  setState(() => _isExpanded = !_isExpanded);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_isExpanded) _centerSelectedDate();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(
    Color selectedDateBgColor,
    Color selectedDateTextColor,
    Color currentDateBgColor,
    Color textColor,
  ) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weeksToShow = 3;
    final firstDayToShow = widget.selectedDate.subtract(
      Duration(days: widget.selectedDate.weekday - 1 + 7),
    );

    return ListView.builder(
      controller: _weekScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: days.length * weeksToShow,
      itemBuilder: (context, index) {
        final date = firstDayToShow.add(Duration(days: index));
        final isSelected = date.day == widget.selectedDate.day &&
            date.month == widget.selectedDate.month &&
            date.year == widget.selectedDate.year;
        final isCurrentDate = date.day == _currentDate.day &&
            date.month == _currentDate.month &&
            date.year == _currentDate.year;

        return SizedBox(
          width: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedDateBgColor
                    : isCurrentDate
                        ? currentDateBgColor
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isCurrentDate && !isSelected
                    ? Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.5))
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    widget.onDateSelected(date);
                    setState(() =>
                        _currentMonth = DateTime(date.year, date.month, 1));
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _centerSelectedDate());
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
                            fontSize: 14,
                            color:
                                isSelected ? selectedDateTextColor : textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          days[date.weekday - 1],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? selectedDateTextColor
                                : textColor
                                    .withOpacity(isCurrentDate ? 1 : 0.7),
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
      },
    );
  }

  Widget _buildMonthView(
    Color selectedDateBgColor,
    Color selectedDateTextColor,
    Color currentDateBgColor,
    Color textColor,
  ) {
    return PageView.builder(
      controller: _monthPageController,
      itemCount: 24,
      onPageChanged: (index) {
        setState(() {
          _currentMonth = DateTime(
            _currentMonth.year,
            _currentMonth.month + (index - 12),
            1,
          );
        });
      },
      itemBuilder: (context, pageIndex) {
        final displayMonth = DateTime(
          _currentMonth.year,
          _currentMonth.month + (pageIndex - 12),
          1,
        );
        return _buildSingleMonthView(
          displayMonth,
          selectedDateBgColor,
          selectedDateTextColor,
          currentDateBgColor,
          textColor,
        );
      },
    );
  }

  Widget _buildSingleMonthView(
    DateTime month,
    Color selectedDateBgColor,
    Color selectedDateTextColor,
    Color currentDateBgColor,
    Color textColor,
  ) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysBefore = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((day) => SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: textColor,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: List.generate(
              ((daysBefore + daysInMonth) / 7).ceil(),
              (i) => TableRow(
                children: List.generate(
                  7,
                  (j) {
                    final dayIndex = i * 7 + j;
                    final date = firstDayOfMonth
                        .add(Duration(days: dayIndex - daysBefore));
                    final isCurrentMonth = dayIndex >= daysBefore &&
                        dayIndex < daysBefore + daysInMonth;
                    final isSelected = isCurrentMonth &&
                        date.day == widget.selectedDate.day &&
                        date.month == widget.selectedDate.month &&
                        date.year == widget.selectedDate.year;
                    final isCurrentDate = isCurrentMonth &&
                        date.day == _currentDate.day &&
                        date.month == _currentDate.month &&
                        date.year == _currentDate.year;

                    return Container(
                      height: 32,
                      margin: const EdgeInsets.all(1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedDateBgColor
                              : isCurrentDate
                                  ? currentDateBgColor
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: isCurrentDate && !isSelected
                              ? Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5))
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: isCurrentMonth
                                ? () {
                                    widget.onDateSelected(date);
                                    setState(() {
                                      _currentMonth =
                                          DateTime(date.year, date.month, 1);
                                      _isExpanded = false;
                                    });
                                    WidgetsBinding.instance
                                        .addPostFrameCallback(
                                            (_) => _centerSelectedDate());
                                  }
                                : null,
                            child: Center(
                              child: Text(
                                date.day.toString(),
                                style: TextStyle(
                                  color: isSelected
                                      ? selectedDateTextColor
                                      : isCurrentDate
                                          ? textColor
                                          : isCurrentMonth
                                              ? textColor
                                              : textColor.withOpacity(0.5),
                                  fontWeight: isSelected || isCurrentDate
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
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
