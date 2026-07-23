import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/update_task_usecase.dart';
import '../bloc/task_list_bloc.dart';
import '../bloc/task_list_event.dart';
import 'create_edit_task_page.dart';

class TaskDetailsPage extends StatefulWidget {
  final TaskEntity task;

  const TaskDetailsPage({super.key, required this.task});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late TaskEntity _currentTask;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Completed':
        return const Color(0xFF10B981);
      case 'In Progress':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Completed':
        return Icons.check_circle_rounded;
      case 'In Progress':
        return Icons.sync_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  void _toggleStatus() async {
    setState(() => _isSubmitting = true);

    final newStatus = _currentTask.status == 'Completed'
        ? 'In Progress'
        : 'Completed';
    final updated = _currentTask.copyWith(status: newStatus);
    final result = await sl<UpdateTaskUseCase>().call(updated);

    if (mounted) {
      setState(() => _isSubmitting = false);
      result.fold(
        (savedTask) {
          setState(() => _currentTask = savedTask);
          context.read<TaskListBloc>().add(LocalTaskUpdated(savedTask));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    newStatus == 'Completed'
                        ? 'Task marked as Completed'
                        : 'Task reopened',
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update: ${failure.message}'),
              backgroundColor: AppTheme.priorityHigh,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = _currentTask.status == 'Completed';
    final priorityColor = _priorityColor(_currentTask.priority);
    final statusColor = _statusColor(_currentTask.status);
    final initials = _getInitials(_currentTask.assignedUser);
    final isOverdue =
        _currentTask.dueDate.isBefore(DateTime.now()) && !isCompleted;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Task Details',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
            tooltip: 'Edit Task',
            onPressed: () async {
              final result = await Navigator.push<TaskEntity>(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateEditTaskPage(task: _currentTask),
                ),
              );
              if (result != null && mounted) {
                setState(() => _currentTask = result);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── HERO CARD: Title, Status, Priority ───
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _badge(
                            statusColor,
                            _statusIcon(_currentTask.status),
                            _currentTask.status,
                          ),
                          _badge(
                            priorityColor,
                            Icons.flag_rounded,
                            '${_currentTask.priority} Priority',
                          ),
                          if (isOverdue)
                            _badge(
                              const Color(0xFFEF4444),
                              Icons.warning_amber_rounded,
                              'Overdue',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        _currentTask.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          height: 1.2,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted ? theme.disabledColor : null,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Created At
                      Text(
                        'Created ${DateFormat('MMM dd, yyyy').format(_currentTask.createdAt)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ─── METADATA CARD: Assignee, Due Date ───
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Assignee Row
                      _metadataRow(
                        theme: theme,
                        isDark: isDark,
                        icon: Icons.person_outline_rounded,
                        iconColor: AppTheme.primaryColor,
                        label: 'Assigned To',
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.primaryColor
                                  .withOpacity(0.15),
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentTask.assignedUser,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Team Member',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 11,
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 24,
                        color: isDark
                            ? AppTheme.darkBorder
                            : AppTheme.lightBorder,
                      ),

                      // Due Date Row
                      _metadataRow(
                        theme: theme,
                        isDark: isDark,
                        icon: Icons.calendar_today_rounded,
                        iconColor: isOverdue
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF3B82F6),
                        label: 'Due Date',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'EEEE, MMMM dd, yyyy',
                              ).format(_currentTask.dueDate),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: isOverdue
                                    ? const Color(0xFFEF4444)
                                    : null,
                              ),
                            ),
                            Text(
                              _daysUntilDue(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 11,
                                color: isOverdue
                                    ? const Color(0xFFEF4444)
                                    : theme.hintColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 24,
                        color: isDark
                            ? AppTheme.darkBorder
                            : AppTheme.lightBorder,
                      ),

                      // Status Row
                      _metadataRow(
                        theme: theme,
                        isDark: isDark,
                        icon: _statusIcon(_currentTask.status),
                        iconColor: statusColor,
                        label: 'Current Status',
                        child: Text(
                          _currentTask.status,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: statusColor,
                          ),
                        ),
                      ),
                      Divider(
                        height: 24,
                        color: isDark
                            ? AppTheme.darkBorder
                            : AppTheme.lightBorder,
                      ),

                      // Priority Row
                      _metadataRow(
                        theme: theme,
                        isDark: isDark,
                        icon: Icons.flag_rounded,
                        iconColor: priorityColor,
                        label: 'Priority Level',
                        child: Text(
                          _currentTask.priority,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: priorityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ─── DESCRIPTION CARD ───
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Description',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentTask.description.isEmpty
                            ? 'No description provided.'
                            : _currentTask.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          fontSize: 14,
                          color: isCompleted ? theme.disabledColor : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // ─── ACTION BUTTONS INLINE (NO FIXED FOOTER ON WIDE DESKTOP) ───
                _isSubmitting
                    ? const SizedBox(
                        height: 52,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push<TaskEntity>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CreateEditTaskPage(task: _currentTask),
                                  ),
                                );
                                if (result != null && mounted)
                                  setState(() => _currentTask = result);
                              },
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit Task'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                side: BorderSide(color: AppTheme.primaryColor),
                                foregroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: isCompleted
                                    ? null
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFF10B981),
                                          Color(0xFF059669),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                color: isCompleted ? Colors.transparent : null,
                                border: isCompleted
                                    ? Border.all(
                                        color: AppTheme.primaryColor,
                                        width: 1.5,
                                      )
                                    : null,
                                boxShadow: isCompleted
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF10B981,
                                          ).withOpacity(0.35),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _toggleStatus,
                                icon: Icon(
                                  isCompleted
                                      ? Icons.refresh_rounded
                                      : Icons.check_circle_outline_rounded,
                                  color: isCompleted
                                      ? AppTheme.primaryColor
                                      : Colors.white,
                                  size: 20,
                                ),
                                label: Text(
                                  isCompleted ? 'Reopen Task' : 'Mark Complete',
                                  style: TextStyle(
                                    color: isCompleted
                                        ? AppTheme.primaryColor
                                        : Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metadataRow({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: theme.hintColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              child,
            ],
          ),
        ),
      ],
    );
  }

  String _daysUntilDue() {
    final now = DateTime.now();
    final due = _currentTask.dueDate;
    final diff = due.difference(DateTime(now.year, now.month, now.day)).inDays;

    if (diff < 0) return '${-diff} day${-diff != 1 ? 's' : ''} overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days';
  }
}
