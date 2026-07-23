import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../bloc/task_list_bloc.dart';
import '../bloc/task_list_state.dart';
import 'create_edit_task_page.dart';
import 'task_details_page.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime get _firstDayOfMonth =>
      DateTime(_focusedMonth.year, _focusedMonth.month, 1);
  int get _daysInMonth =>
      DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

  List<DateTime> get _calendarDays {
    final firstWeekday = _firstDayOfMonth.weekday % 7; // 0=Sun
    final days = <DateTime>[];
    for (int i = firstWeekday - 1; i >= 0; i--) {
      days.add(_firstDayOfMonth.subtract(Duration(days: i + 1)));
    }
    for (int d = 1; d <= _daysInMonth; d++) {
      days.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }
    while (days.length % 7 != 0) {
      days.add(days.last.add(const Duration(days: 1)));
    }
    return days;
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'High':
        return AppTheme.priorityHigh;
      case 'Medium':
        return AppTheme.priorityMedium;
      default:
        return AppTheme.priorityLow;
    }
  }

  String _statusEmoji(String s) {
    switch (s) {
      case 'Completed':
        return '✔';
      case 'In Progress':
        return '🚀';
      default:
        return '⏳';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isWide ? 'Calendar Workspace' : 'Calendar',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
          ],
        ),
        actions: [
          if (isWide)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEditTaskPage()),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Task'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(110, 38),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: BlocBuilder<TaskListBloc, TaskListState>(
        builder: (context, state) {
          final tasks = state.tasks;

          final Map<String, List<dynamic>> tasksByDate = {};
          for (final task in tasks) {
            final key = DateFormat('yyyy-MM-dd').format(task.dueDate);
            tasksByDate.putIfAbsent(key, () => []).add(task);
          }

          final selectedDayKey = DateFormat('yyyy-MM-dd').format(_selectedDay);
          final selectedDayTasks = tasksByDate[selectedDayKey] ?? [];

          if (isWide) {
            return _buildWebCalendarLayout(
              theme,
              isDark,
              tasksByDate,
              selectedDayTasks,
            );
          } else {
            return _buildMobileCalendarLayout(
              theme,
              isDark,
              tasksByDate,
              selectedDayTasks,
            );
          }
        },
      ),
    );
  }

  // ─────────── WEB DESKTOP CALENDAR LAYOUT (2 Columns) ────────────
  Widget _buildWebCalendarLayout(
    ThemeData theme,
    bool isDark,
    Map<String, List<dynamic>> tasksByDate,
    List<dynamic> selectedDayTasks,
  ) {
    final today = DateTime.now();

    return Row(
      children: [
        // Left Column: Full Desktop Calendar Month View (Grid with Embedded Task Chips)
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:isDark ? 0.0 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Month Controls Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_focusedMonth),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => setState(() {
                                _focusedMonth = DateTime.now();
                                _selectedDay = DateTime.now();
                              }),
                              icon: const Icon(Icons.today_rounded, size: 16),
                              label: const Text('Today'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(80, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded),
                              onPressed: () => setState(() {
                                _focusedMonth = DateTime(
                                  _focusedMonth.year,
                                  _focusedMonth.month - 1,
                                  1,
                                );
                              }),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded),
                              onPressed: () => setState(() {
                                _focusedMonth = DateTime(
                                  _focusedMonth.year,
                                  _focusedMonth.month + 1,
                                  1,
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Day Headers (Sun - Sat)
                  Container(
                    color: isDark
                        ? AppTheme.darkBg.withValues(alpha:0.5)
                        : AppTheme.lightBg,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children:
                          [
                                'Sunday',
                                'Monday',
                                'Tuesday',
                                'Wednesday',
                                'Thursday',
                                'Friday',
                                'Saturday',
                              ]
                              .map(
                                (d) => Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: theme.hintColor,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),

                  // Expanded Desktop Calendar Grid
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 7,
                      childAspectRatio: 1.2,
                      children: _calendarDays.map((day) {
                        final isCurrentMonth = day.month == _focusedMonth.month;
                        final isToday =
                            DateFormat('yyyy-MM-dd').format(day) ==
                            DateFormat('yyyy-MM-dd').format(today);
                        final dayKey = DateFormat('yyyy-MM-dd').format(day);
                        final isSelected =
                            dayKey ==
                            DateFormat('yyyy-MM-dd').format(_selectedDay);
                        final dayTasks = tasksByDate[dayKey] ?? [];

                        return InkWell(
                          onTap: () => setState(() => _selectedDay = day),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withValues(alpha:0.08)
                                  : isDark
                                  ? AppTheme.darkSurface
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : (isDark
                                          ? AppTheme.darkBorder.withValues(alpha:0.5)
                                          : AppTheme.lightBorder),
                                width: isSelected ? 1.5 : 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isToday
                                            ? AppTheme.primaryColor
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${day.day}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isToday
                                                ? FontWeight.w900
                                                : FontWeight.w600,
                                            color: isToday
                                                ? Colors.white
                                                : !isCurrentMonth
                                                ? theme.hintColor.withValues(alpha:
                                                    0.3,
                                                  )
                                                : theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (dayTasks.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha:0.12),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '${dayTasks.length}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: dayTasks
                                        .take(2)
                                        .map(
                                          (t) => Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 3,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _priorityColor(
                                                t.priority,
                                              ).withValues(alpha:0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border(
                                                left: BorderSide(
                                                  color: _priorityColor(
                                                    t.priority,
                                                  ),
                                                  width: 3,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              t.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppTheme.lightTextPrimary,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right Column: Agenda Side Panel for Selected Day Tasks
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:isDark ? 0.0 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day Agenda',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'EEEE, MMM d, yyyy',
                            ).format(_selectedDay),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha:0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${selectedDayTasks.length} task${selectedDayTasks.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Agenda task cards
                  Expanded(
                    child: selectedDayTasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '📋',
                                  style: TextStyle(fontSize: 40),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No tasks on this day',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Select another day or add a task.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: selectedDayTasks.length,
                            itemBuilder: (_, i) {
                              final task = selectedDayTasks[i];
                              final priorityColor = _priorityColor(
                                task.priority,
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.darkBg
                                      : AppTheme.lightBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark
                                        ? AppTheme.darkBorder
                                        : AppTheme.lightBorder,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TaskDetailsPage(task: task),
                                    ),
                                  ),
                                  leading: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: priorityColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  title: Text(
                                    task.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    task.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: priorityColor.withValues(alpha:0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_statusEmoji(task.status)} ${task.status}',
                                      style: TextStyle(
                                        color: priorityColor,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
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
          ),
        ),
      ],
    );
  }

  // ─────────── MOBILE CALENDAR LAYOUT ────────────
  Widget _buildMobileCalendarLayout(
    ThemeData theme,
    bool isDark,
    Map<String, List<dynamic>> tasksByDate,
    List<dynamic> selectedDayTasks,
  ) {
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedMonth),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month - 1,
                            1,
                          );
                        }),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month + 1,
                            1,
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.15,
                children: _calendarDays.map((day) {
                  final isCurrentMonth = day.month == _focusedMonth.month;
                  final isToday =
                      DateFormat('yyyy-MM-dd').format(day) ==
                      DateFormat('yyyy-MM-dd').format(today);
                  final dayKey = DateFormat('yyyy-MM-dd').format(day);
                  final isSelected =
                      dayKey == DateFormat('yyyy-MM-dd').format(_selectedDay);
                  final hasTasks = tasksByDate.containsKey(dayKey);
                  final dayTasks = tasksByDate[dayKey] ?? [];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : isToday
                                ? AppTheme.primaryColor.withValues(alpha:0.15)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isToday || isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : !isCurrentMonth
                                    ? theme.hintColor.withValues(alpha:0.3)
                                    : isToday
                                    ? AppTheme.primaryColor
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ),
                        if (hasTasks) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dayTasks
                                .take(3)
                                .map(
                                  (t) => Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _priorityColor(t.priority),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Row(
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(_selectedDay),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${selectedDayTasks.length} task${selectedDayTasks.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: selectedDayTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 10),
                      Text(
                        'No tasks scheduled for this day',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: selectedDayTasks.length,
                  itemBuilder: (_, i) {
                    final task = selectedDayTasks[i];
                    final priorityColor = _priorityColor(task.priority);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBorder
                              : AppTheme.lightBorder,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailsPage(task: task),
                          ),
                        ),
                        leading: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: priorityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          task.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          task.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha:0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_statusEmoji(task.status)} ${task.status}',
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
