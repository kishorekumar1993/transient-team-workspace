import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/task_list_bloc.dart';
import '../bloc/task_list_event.dart';
import '../bloc/task_list_state.dart';
import 'create_edit_task_page.dart';
import 'task_details_page.dart';

class DashboardHomeTab extends StatefulWidget {
  const DashboardHomeTab({super.key});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _debounceTimer;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<TaskListBloc>().add(const LoadTasksList());

    final networkInfo = sl<NetworkInfo>();
    networkInfo.isConnected.then((v) {
      if (mounted) setState(() => _isOnline = v);
    });

    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((
      online,
    ) {
      if (mounted) {
        final wasOffline = !_isOnline;
        setState(() => _isOnline = online);
        if (online && wasOffline) {
          context.read<TaskListBloc>().add(SyncQueueTriggered());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.cloud_done_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Connection restored. Syncing changes...'),
                ],
              ),
              backgroundColor: AppTheme.priorityLow,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.offset >=
            _scrollController.position.maxScrollExtent * 0.9) {
      context.read<TaskListBloc>().add(LoadNextTasksPage());
    }
  }

  void _onSearchChanged(String q) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 400),
      () => context.read<TaskListBloc>().add(UpdateSearchQuery(q)),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(theme, isDark, isWide),
            if (!_isOnline) _buildOfflineBanner(),
            Expanded(
              child: BlocBuilder<TaskListBloc, TaskListState>(
                builder: (ctx, state) {
                  return Column(
                    children: [
                      // Modern Minimalist Header Section
                      _buildHeaderSection(theme, isDark, state, isWide),

                      // Filter & Search Toolbar
                      _buildFilterToolbar(theme, isDark, state, isWide),

                      // Clean Task Cards List
                      Expanded(child: _buildTaskList(theme, isDark, state)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ─────────── MODERN APP BAR ────────────
  Widget _buildAppBar(ThemeData theme, bool isDark, bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transient',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Task Workspace',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),
            ],
          ),
          const Spacer(),

          // Dark/Light Theme Toggle Icon
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              size: 20,
              color: isDark ? const Color(0xFFF59E0B) : theme.hintColor,
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),

          // Notification Bell
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: const Icon(Icons.notifications_none_rounded, size: 20),
              ),
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // User Avatar
          GestureDetector(
            onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: AppTheme.primaryColor,
              child: const Text(
                'KK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      color: AppTheme.priorityHigh.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 12),
          SizedBox(width: 8),
          Text(
            'Offline Mode – Changes will sync on reconnect',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── MODERN MINIMALIST HEADER ────────────
  Widget _buildHeaderSection(
    ThemeData theme,
    bool isDark,
    TaskListState state,
    bool isWide,
  ) {
    final tasks = state.tasks;
    final total = tasks.length;
    final pending = tasks.where((t) => t.status == 'Pending').length;
    final inProgress = tasks.where((t) => t.status == 'In Progress').length;
    final completed = tasks.where((t) => t.status == 'Completed').length;
    final pct = total > 0 ? (completed / total * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning, Kishore 👋',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Here is your workspace summary for today',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pct% Done',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 Modern Sleek Stat Cards (20px Rounded, Soft Shadow)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _minimalStatCard(
                  isDark: isDark,
                  theme: theme,
                  icon: Icons.hourglass_empty_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  count: pending,
                  label: 'Pending',
                ),
                const SizedBox(width: 12),
                _minimalStatCard(
                  isDark: isDark,
                  theme: theme,
                  icon: Icons.sync_rounded,
                  iconBg: const Color(0xFFDBEAFE),
                  iconColor: const Color(0xFF2563EB),
                  count: inProgress,
                  label: 'In Progress',
                ),
                const SizedBox(width: 12),
                _minimalStatCard(
                  isDark: isDark,
                  theme: theme,
                  icon: Icons.check_circle_rounded,
                  iconBg: const Color(0xFFD1FAE5),
                  iconColor: const Color(0xFF059669),
                  count: completed,
                  label: 'Completed',
                ),
                const SizedBox(width: 12),
                _minimalStatCard(
                  isDark: isDark,
                  theme: theme,
                  icon: Icons.layers_rounded,
                  iconBg: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF9333EA),
                  count: total,
                  label: 'Total Tasks',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Rounded Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              minHeight: 6,
              backgroundColor: isDark
                  ? AppTheme.darkBorder
                  : const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _minimalStatCard({
    required bool isDark,
    required ThemeData theme,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required int count,
    required String label,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── SEARCH & FILTER TOOLBAR ────────────
  Widget _buildFilterToolbar(
    ThemeData theme,
    bool isDark,
    TaskListState state,
    bool isWide,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Search Input
            Container(
              width: isWide ? 320 : 210,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: theme.hintColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        hintStyle: TextStyle(
                          color: theme.hintColor,
                          fontSize: 12.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        context.read<TaskListBloc>().add(
                          const UpdateSearchQuery(''),
                        );
                      },
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: theme.hintColor,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status Filter Dropdown
            _minimalFilterChip(
              theme: theme,
              isDark: isDark,
              label: 'Status',
              value: state.statusFilter,
              isActive: state.statusFilter != 'All',
              items: const ['All', 'Pending', 'In Progress', 'Completed'],
              onChanged: (v) =>
                  context.read<TaskListBloc>().add(UpdateStatusFilter(v)),
            ),
            const SizedBox(width: 8),

            // Priority Filter Dropdown
            _minimalFilterChip(
              theme: theme,
              isDark: isDark,
              label: 'Priority',
              value: state.priorityFilter,
              isActive: state.priorityFilter != 'All',
              items: const ['All', 'Low', 'Medium', 'High'],
              onChanged: (v) =>
                  context.read<TaskListBloc>().add(UpdatePriorityFilter(v)),
            ),
            const SizedBox(width: 8),

            // Reset Button
            if (state.statusFilter != 'All' ||
                state.priorityFilter != 'All' ||
                state.dateFilterType != 'All')
              GestureDetector(
                onTap: () {
                  context.read<TaskListBloc>()
                    ..add(UpdateStatusFilter('All'))
                    ..add(UpdatePriorityFilter('All'))
                    ..add(UpdateDateFilterType('All'));
                  _searchController.clear();
                  context.read<TaskListBloc>().add(const UpdateSearchQuery(''));
                },
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.priorityHigh.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.priorityHigh.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: AppTheme.priorityHigh,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Reset',
                        style: TextStyle(
                          color: AppTheme.priorityHigh,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _minimalFilterChip({
    required ThemeData theme,
    required bool isDark,
    required String label,
    required String value,
    required bool isActive,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      elevation: 6,
      itemBuilder: (_) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontWeight: item == value ? FontWeight.w800 : FontWeight.w500,
                  color: item == value ? AppTheme.primaryColor : null,
                  fontSize: 13,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor
              : (isDark ? AppTheme.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isActive ? '$label: $value' : '$label ▼',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? Colors.white
                    : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────── CLEAN TASK CARDS LIST WITH COLORED LEFT BORDER ────────────
  Widget _buildTaskList(ThemeData theme, bool isDark, TaskListState state) {
    if (state is TaskListLoading && state.tasks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppTheme.primaryColor,
        ),
      );
    }
    if (state is TaskListError && state.tasks.isEmpty) {
      return _errorState(theme, state.errorMessage);
    }
    if (state.tasks.isEmpty) {
      return _emptyState(theme, isDark);
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            final c = Completer<void>();
            context.read<TaskListBloc>().add(const LoadTasksList(reset: true));
            late StreamSubscription sub;
            sub = context.read<TaskListBloc>().stream.listen((s) {
              if (s is! TaskListLoading) {
                c.complete();
                sub.cancel();
              }
            });
            return c.future;
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: state.tasks.length + (state.hasMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == state.tasks.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              }
              return _cleanTaskCardItem(theme, isDark, state.tasks[i]);
            },
          ),
        ),
        if (state.isSyncing)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Syncing offline changes...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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

  // Modern Minimalist Task Card (20px rounded corners, soft shadow, colored left border)
  Widget _cleanTaskCardItem(ThemeData theme, bool isDark, task) {
    final priorityColor = _priorityColor(task.priority);
    final statusColor = _statusColor(task.status);
    final isCompleted = task.status == 'Completed';
    final initials = _getInitials(task.assignedUser);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored Left Border Indicator Strip (5px wide)
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailsPage(task: task),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Priority Badge | Status Chip | Menu (⋮)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task.priority.toUpperCase(),
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _statusIcon(task.status),
                                  size: 12,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),

                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: theme.hintColor,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (val) {
                              if (val == 'details') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TaskDetailsPage(task: task),
                                  ),
                                );
                              } else if (val == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CreateEditTaskPage(task: task),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'details',
                                child: Text('View Details'),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit Task'),
                              ),
                            ],
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
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted ? theme.disabledColor : null,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Description
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Bottom Row: Avatar Initials + Name | Due Date
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppTheme.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            task.assignedUser,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: theme.hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(task.dueDate),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.hintColor,
                            ),
                          ),
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

  Widget _emptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(
            'No Tasks Found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try creating a new task or clearing search filters.',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateEditTaskPage()),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Task'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(140, 42)),
          ),
        ],
      ),
    );
  }

  Widget _errorState(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 44,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load tasks',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<TaskListBloc>().add(
              const LoadTasksList(reset: true),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateEditTaskPage()),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text(
          'New Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
