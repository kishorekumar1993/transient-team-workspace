import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import '../../domain/usecases/sync_offline_tasks_usecase.dart';
import 'task_list_event.dart';
import 'task_list_state.dart';

class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  final GetTasksUseCase getTasksUseCase;
  final SyncOfflineTasksUseCase syncOfflineTasksUseCase;

  TaskListBloc({
    required this.getTasksUseCase,
    required this.syncOfflineTasksUseCase,
  }) : super(const TaskListInitial()) {
    on<LoadTasksList>(_onLoadTasksList);
    on<LoadNextTasksPage>(_onLoadNextTasksPage);
    on<UpdateSearchQuery>(_onUpdateSearchQuery);
    on<UpdateStatusFilter>(_onUpdateStatusFilter);
    on<UpdatePriorityFilter>(_onUpdatePriorityFilter);
    on<UpdateDateFilterType>(_onUpdateDateFilterType);
    on<UpdateCustomDateRange>(_onUpdateCustomDateRange);
    on<LocalTaskCreated>(_onLocalTaskCreated);
    on<LocalTaskUpdated>(_onLocalTaskUpdated);
    on<SyncQueueTriggered>(_onSyncQueueTriggered);
  }

  Future<void> _onLoadTasksList(
    LoadTasksList event,
    Emitter<TaskListState> emit,
  ) async {
    if (event.reset) {
      emit(
        TaskListLoading(
          tasks: const [],
          page: 1,
          hasMore: true,
          searchQuery: state.searchQuery,
          statusFilter: state.statusFilter,
          priorityFilter: state.priorityFilter,
          dateFilterType: state.dateFilterType,
          customStartDate: state.customStartDate,
          customEndDate: state.customEndDate,
          isSyncing: state.isSyncing,
        ),
      );
    } else if (state is TaskListInitial) {
      emit(
        TaskListLoading(
          tasks: state.tasks,
          page: state.page,
          hasMore: state.hasMore,
          searchQuery: state.searchQuery,
          statusFilter: state.statusFilter,
          priorityFilter: state.priorityFilter,
          dateFilterType: state.dateFilterType,
          customStartDate: state.customStartDate,
          customEndDate: state.customEndDate,
          isSyncing: state.isSyncing,
        ),
      );
    }

    final result = await getTasksUseCase(
      page: 1,
      limit: 10,
      search: state.searchQuery,
      status: state.statusFilter,
      priority: state.priorityFilter,
      startDate: _getStartDate(state),
      endDate: _getEndDate(state),
    );

    result.fold(
      (paginated) {
        emit(
          TaskListLoaded(
            tasks: paginated.tasks,
            page: 1,
            hasMore: paginated.hasMore,
            searchQuery: state.searchQuery,
            statusFilter: state.statusFilter,
            priorityFilter: state.priorityFilter,
            dateFilterType: state.dateFilterType,
            customStartDate: state.customStartDate,
            customEndDate: state.customEndDate,
            isSyncing: state.isSyncing,
          ),
        );
      },
      (failure) {
        emit(
          TaskListError(
            errorMessage: failure.message,
            tasks: state.tasks,
            page: state.page,
            hasMore: state.hasMore,
            searchQuery: state.searchQuery,
            statusFilter: state.statusFilter,
            priorityFilter: state.priorityFilter,
            dateFilterType: state.dateFilterType,
            customStartDate: state.customStartDate,
            customEndDate: state.customEndDate,
            isSyncing: state.isSyncing,
          ),
        );
      },
    );
  }

  Future<void> _onLoadNextTasksPage(
    LoadNextTasksPage event,
    Emitter<TaskListState> emit,
  ) async {
    if (state is TaskListLoading || !state.hasMore) return;

    final nextPage = state.page + 1;

    // Show inline loading or keep current state
    emit(
      TaskListLoading(
        tasks: state.tasks,
        page: state.page,
        hasMore: state.hasMore,
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        priorityFilter: state.priorityFilter,
        dateFilterType: state.dateFilterType,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
        isSyncing: state.isSyncing,
      ),
    );

    final result = await getTasksUseCase(
      page: nextPage,
      limit: 10,
      search: state.searchQuery,
      status: state.statusFilter,
      priority: state.priorityFilter,
      startDate: _getStartDate(state),
      endDate: _getEndDate(state),
    );

    result.fold(
      (paginated) {
        emit(
          TaskListLoaded(
            tasks: [...state.tasks, ...paginated.tasks],
            page: nextPage,
            hasMore: paginated.hasMore,
            searchQuery: state.searchQuery,
            statusFilter: state.statusFilter,
            priorityFilter: state.priorityFilter,
            dateFilterType: state.dateFilterType,
            customStartDate: state.customStartDate,
            customEndDate: state.customEndDate,
            isSyncing: state.isSyncing,
          ),
        );
      },
      (failure) {
        emit(
          TaskListError(
            errorMessage: failure.message,
            tasks: state.tasks,
            page: state.page,
            hasMore: state.hasMore,
            searchQuery: state.searchQuery,
            statusFilter: state.statusFilter,
            priorityFilter: state.priorityFilter,
            dateFilterType: state.dateFilterType,
            customStartDate: state.customStartDate,
            customEndDate: state.customEndDate,
            isSyncing: state.isSyncing,
          ),
        );
      },
    );
  }

  void _onUpdateSearchQuery(
    UpdateSearchQuery event,
    Emitter<TaskListState> emit,
  ) {
    emit(
      TaskListInitial(
        tasks: state.tasks,
        page: state.page,
        hasMore: state.hasMore,
        searchQuery: event.query,
        statusFilter: state.statusFilter,
        priorityFilter: state.priorityFilter,
        dateFilterType: state.dateFilterType,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
        isSyncing: state.isSyncing,
      ),
    );
    add(const LoadTasksList(reset: true));
  }

  void _onUpdateStatusFilter(
    UpdateStatusFilter event,
    Emitter<TaskListState> emit,
  ) {
    emit(
      TaskListInitial(
        tasks: state.tasks,
        page: state.page,
        hasMore: state.hasMore,
        searchQuery: state.searchQuery,
        statusFilter: event.status,
        priorityFilter: state.priorityFilter,
        dateFilterType: state.dateFilterType,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
        isSyncing: state.isSyncing,
      ),
    );
    add(const LoadTasksList(reset: true));
  }

  void _onUpdatePriorityFilter(
    UpdatePriorityFilter event,
    Emitter<TaskListState> emit,
  ) {
    emit(
      TaskListInitial(
        tasks: state.tasks,
        page: state.page,
        hasMore: state.hasMore,
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        priorityFilter: event.priority,
        dateFilterType: state.dateFilterType,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
        isSyncing: state.isSyncing,
      ),
    );
    add(const LoadTasksList(reset: true));
  }

  void _onUpdateDateFilterType(
    UpdateDateFilterType event,
    Emitter<TaskListState> emit,
  ) {
    emit(
      TaskListInitial(
        tasks: state.tasks,
        page: state.page,
        hasMore: state.hasMore,
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        priorityFilter: state.priorityFilter,
        dateFilterType: event.dateFilterType,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
        isSyncing: state.isSyncing,
      ),
    );
    add(const LoadTasksList(reset: true));
  }

  void _onUpdateCustomDateRange(
    UpdateCustomDateRange event,
    Emitter<TaskListState> emit,
  ) {
    emit(
      TaskListInitial(
        tasks: state.tasks,
        page: state.page,
        hasMore: state.hasMore,
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        priorityFilter: state.priorityFilter,
        dateFilterType: 'Custom Range',
        customStartDate: event.startDate,
        customEndDate: event.endDate,
        isSyncing: state.isSyncing,
      ),
    );
    add(const LoadTasksList(reset: true));
  }

  void _onLocalTaskCreated(
    LocalTaskCreated event,
    Emitter<TaskListState> emit,
  ) {
    final updatedList = List<Object>.from(state.tasks).cast<dynamic>();

    // Check if task already exists (e.g. from sync reload)
    final exists = updatedList.any((t) => t.id == event.task.id);
    if (!exists) {
      updatedList.insert(0, event.task);
    }

    emit(
      TaskListLoaded(
        tasks: updatedList.cast(),
        page: state.page,
        hasMore: state.hasMore,
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        priorityFilter: state.priorityFilter,
        dateFilterType: state.dateFilterType,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
        isSyncing: state.isSyncing,
      ),
    );
  }

  void _onLocalTaskUpdated(
    LocalTaskUpdated event,
    Emitter<TaskListState> emit,
  ) {
    final updatedList = List<Object>.from(state.tasks).cast<dynamic>();
    final index = updatedList.indexWhere((t) => t.id == event.task.id);
    if (index != -1) {
      updatedList[index] = event.task;
    }

    emit(
      TaskListLoaded(
        tasks: updatedList.cast(),
        page: state.page,
        hasMore: state.hasMore,
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        priorityFilter: state.priorityFilter,
        dateFilterType: state.dateFilterType,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
        isSyncing: state.isSyncing,
      ),
    );
  }

  Future<void> _onSyncQueueTriggered(
    SyncQueueTriggered event,
    Emitter<TaskListState> emit,
  ) async {
    emit(
      TaskListLoaded(
        tasks: state.tasks,
        page: state.page,
        hasMore: state.hasMore,
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        priorityFilter: state.priorityFilter,
        dateFilterType: state.dateFilterType,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
        isSyncing: true,
      ),
    );

    final result = await syncOfflineTasksUseCase();

    result.fold(
      (_) {
        // Reload tasks list after successful sync to fetch updated remote IDs and order
        add(const LoadTasksList(reset: true));
      },
      (failure) {
        emit(
          TaskListError(
            errorMessage: 'Sync failed: ${failure.message}',
            tasks: state.tasks,
            page: state.page,
            hasMore: state.hasMore,
            searchQuery: state.searchQuery,
            statusFilter: state.statusFilter,
            priorityFilter: state.priorityFilter,
            dateFilterType: state.dateFilterType,
            customStartDate: state.customStartDate,
            customEndDate: state.customEndDate,
            isSyncing: false,
          ),
        );
      },
    );
  }

  DateTime? _getStartDate(TaskListState state) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (state.dateFilterType) {
      case 'Today':
        return today;
      case 'Last 3 Days':
        return today.subtract(const Duration(days: 3));
      case '1 Week':
        return today.subtract(const Duration(days: 7));
      case '2 Weeks':
        return today.subtract(const Duration(days: 14));
      case '1 Month':
        return DateTime(now.year, now.month - 1, now.day);
      case '3 Months':
        return DateTime(now.year, now.month - 3, now.day);
      case '6 Months':
        return DateTime(now.year, now.month - 6, now.day);
      case '1 Year':
        return DateTime(now.year - 1, now.month, now.day);
      case 'Custom Range':
        return state.customStartDate;
      case 'All':
      default:
        return null;
    }
  }

  DateTime? _getEndDate(TaskListState state) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (state.dateFilterType == 'Custom Range') {
      return state.customEndDate != null
          ? DateTime(
              state.customEndDate!.year,
              state.customEndDate!.month,
              state.customEndDate!.day,
              23,
              59,
              59,
            )
          : null;
    } else if (state.dateFilterType != 'All') {
      return endOfToday;
    }
    return null;
  }
}
