import sys

content = open(r'd:\Backend\transient\transient\lib\features\tasks\presentation\bloc\task_list_bloc.dart', 'r', encoding='utf-8').read()

content = content.replace('dateFilter: state.dateFilter,', '''dateFilterType: state.dateFilterType,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,''')

content = content.replace('on<UpdateDateFilter>(_onUpdateDateFilter);', '''on<UpdateDateFilterType>(_onUpdateDateFilterType);
    on<UpdateCustomDateRange>(_onUpdateCustomDateRange);''')

old_handler = '''void _onUpdateDateFilter(UpdateDateFilter event, Emitter<TaskListState> emit) {
    emit(TaskListInitial(
      tasks: state.tasks,
      page: state.page,
      hasMore: state.hasMore,
      searchQuery: state.searchQuery,
      statusFilter: state.statusFilter,
      priorityFilter: state.priorityFilter,
      dateFilter: event.date,
      isSyncing: state.isSyncing,
    ));
    add(const LoadTasksList(reset: true));
  }'''

new_handler = '''void _onUpdateDateFilterType(UpdateDateFilterType event, Emitter<TaskListState> emit) {
    emit(TaskListInitial(
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
    ));
    add(const LoadTasksList(reset: true));
  }

  void _onUpdateCustomDateRange(UpdateCustomDateRange event, Emitter<TaskListState> emit) {
    emit(TaskListInitial(
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
    ));
    add(const LoadTasksList(reset: true));
  }'''

content = content.replace(old_handler, new_handler)

# The getTasksUseCase calls will have:
#       dateFilterType: state.dateFilterType,
#         customStartDate: state.customStartDate,
#         customEndDate: state.customEndDate,
# But we need them to be:
#       startDate: _getStartDate(state),
#       endDate: _getEndDate(state),

# So let's replace that specific block in the getTasksUseCase call:
call_old = '''      priority: state.priorityFilter,
      dateFilterType: state.dateFilterType,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
    );'''

call_new = '''      priority: state.priorityFilter,
      startDate: _getStartDate(state),
      endDate: _getEndDate(state),
    );'''
content = content.replace(call_old, call_new)

call_old2 = '''      priority: state.priorityFilter,
      dateFilterType: state.dateFilterType,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
      isSyncing: state.isSyncing,
    );'''
# wait, getTasksUseCase doesn't have isSyncing. It ends with `);`

# Add the helper methods
helpers = '''
  DateTime? _getStartDate(TaskListState state) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (state.dateFilterType) {
      case 'Today': return today;
      case 'Last 3 Days': return today.subtract(const Duration(days: 3));
      case '1 Week': return today.subtract(const Duration(days: 7));
      case '2 Weeks': return today.subtract(const Duration(days: 14));
      case '1 Month': return DateTime(now.year, now.month - 1, now.day);
      case '3 Months': return DateTime(now.year, now.month - 3, now.day);
      case '6 Months': return DateTime(now.year, now.month - 6, now.day);
      case '1 Year': return DateTime(now.year - 1, now.month, now.day);
      case 'Custom Range': return state.customStartDate;
      case 'All':
      default: return null;
    }
  }

  DateTime? _getEndDate(TaskListState state) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    if (state.dateFilterType == 'Custom Range') {
      return state.customEndDate != null 
          ? DateTime(state.customEndDate!.year, state.customEndDate!.month, state.customEndDate!.day, 23, 59, 59)
          : null;
    } else if (state.dateFilterType != 'All') {
      return endOfToday;
    }
    return null;
  }
}'''

content = content.replace('}\n', helpers)

open(r'd:\Backend\transient\transient\lib\features\tasks\presentation\bloc\task_list_bloc.dart', 'w', encoding='utf-8').write(content)
