import '../../domain/entities/task_entity.dart';

abstract class TaskListState {
  final List<TaskEntity> tasks;
  final int page;
  final bool hasMore;
  final String searchQuery;
  final String statusFilter;
  final String priorityFilter;
  final String dateFilterType;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final bool isSyncing;

  const TaskListState({
    this.tasks = const [],
    this.page = 1,
    this.hasMore = true,
    this.searchQuery = '',
    this.statusFilter = 'All',
    this.priorityFilter = 'All',
    this.dateFilterType = 'All',
    this.customStartDate,
    this.customEndDate,
    this.isSyncing = false,
  });
}

class TaskListInitial extends TaskListState {
  const TaskListInitial({
    super.tasks,
    super.page,
    super.hasMore,
    super.searchQuery,
    super.statusFilter,
    super.priorityFilter,
    super.dateFilterType,
    super.customStartDate,
    super.customEndDate,
    super.isSyncing,
  });
}

class TaskListLoading extends TaskListState {
  const TaskListLoading({
    required super.tasks,
    required super.page,
    required super.hasMore,
    required super.searchQuery,
    required super.statusFilter,
    required super.priorityFilter,
    required super.dateFilterType,
    required super.customStartDate,
    required super.customEndDate,
    required super.isSyncing,
  });
}

class TaskListLoaded extends TaskListState {
  const TaskListLoaded({
    required super.tasks,
    required super.page,
    required super.hasMore,
    required super.searchQuery,
    required super.statusFilter,
    required super.priorityFilter,
    required super.dateFilterType,
    required super.customStartDate,
    required super.customEndDate,
    required super.isSyncing,
  });
}

class TaskListError extends TaskListState {
  final String errorMessage;

  const TaskListError({
    required this.errorMessage,
    required super.tasks,
    required super.page,
    required super.hasMore,
    required super.searchQuery,
    required super.statusFilter,
    required super.priorityFilter,
    required super.dateFilterType,
    required super.customStartDate,
    required super.customEndDate,
    required super.isSyncing,
  });
}
