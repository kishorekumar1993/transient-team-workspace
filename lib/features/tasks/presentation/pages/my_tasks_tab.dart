import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../bloc/task_list_bloc.dart';
import '../bloc/task_list_event.dart';
import '../bloc/task_list_state.dart';
import 'create_edit_task_page.dart';
import 'task_details_page.dart';

class MyTasksTab extends StatefulWidget {
  const MyTasksTab({super.key});

  @override
  State<MyTasksTab> createState() => _MyTasksTabState();
}

class _MyTasksTabState extends State<MyTasksTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    context.read<TaskListBloc>().add(const LoadTasksList(reset: true));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'High': return const Color(0xFFEF4444);
      case 'Medium': return const Color(0xFFF59E0B);
      default: return const Color(0xFF3B82F6);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Completed': return const Color(0xFF10B981);
      case 'In Progress': return const Color(0xFF3B82F6);
      default: return const Color(0xFFF59E0B);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Completed': return Icons.check_circle_rounded;
      case 'In Progress': return Icons.sync_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String _tabStatus(int i) => ['Pending', 'In Progress', 'Completed'][i];

  Color _tabColor(int i) {
    switch (i) {
      case 0: return const Color(0xFFF59E0B);
      case 1: return const Color(0xFF3B82F6);
      case 2: return const Color(0xFF10B981);
      default: return AppTheme.primaryColor;
    }
  }

  IconData _tabIcon(int i) {
    switch (i) {
      case 0: return Icons.schedule_rounded;
      case 1: return Icons.sync_rounded;
      case 2: return Icons.check_circle_rounded;
      default: return Icons.list_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Tasks', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 22)),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEditTaskPage())),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Task'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 38),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            // Custom Tab Selector
            BlocBuilder<TaskListBloc, TaskListState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: List.generate(3, (i) {
                      final isSelected = _tabController.index == i;
                      final tabColor = _tabColor(i);
                      final count = state.tasks.where((t) => t.status == _tabStatus(i)).length;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _tabController.index = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? tabColor : (isDark ? AppTheme.darkSurface : Colors.white),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? tabColor : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: tabColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                                  : [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.0 : 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _tabIcon(i),
                                  size: 20,
                                  color: isSelected ? Colors.white : tabColor,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _tabStatus(i),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$count tasks',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white.withOpacity(0.8) : theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),

            // Task Cards List
            Expanded(
              child: BlocBuilder<TaskListBloc, TaskListState>(
                builder: (context, state) {
                  if (state is TaskListLoading && state.tasks.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2.5));
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: List.generate(3, (tabIdx) {
                      final tabFiltered = state.tasks.where((t) => t.status == _tabStatus(tabIdx)).toList();

                      if (tabFiltered.isEmpty) {
                        return Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(_tabIcon(tabIdx), size: 48, color: _tabColor(tabIdx).withOpacity(0.25)),
                            const SizedBox(height: 14),
                            Text(
                              'No ${_tabStatus(tabIdx)} Tasks',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tasks with this status will appear here.',
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                            ),
                          ]),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: tabFiltered.length,
                        itemBuilder: (_, i) => _taskCard(theme, isDark, tabFiltered[i]),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskCard(ThemeData theme, bool isDark, task) {
    final priorityColor = _priorityColor(task.priority);
    final statusColor = _statusColor(task.status);
    final isCompleted = task.status == 'Completed';
    final initials = _getInitials(task.assignedUser);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.0 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailsPage(task: task))),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Priority Badge + Status Pill
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task.priority.toUpperCase(),
                              style: TextStyle(color: priorityColor, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(_statusIcon(task.status), size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(task.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? theme.disabledColor : null,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Description
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.3),
                      ),
                      const SizedBox(height: 12),

                      // Assignee + Due Date
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                            child: Text(initials, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                          ),
                          const SizedBox(width: 6),
                          Text(task.assignedUser, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color)),
                          const Spacer(),
                          Icon(Icons.calendar_today_rounded, size: 12, color: theme.hintColor),
                          const SizedBox(width: 4),
                          Text(DateFormat('MMM dd, yyyy').format(task.dueDate), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.hintColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
