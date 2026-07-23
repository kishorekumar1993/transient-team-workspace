import '../../domain/entities/task_entity.dart';

abstract class TaskListEvent {
  const TaskListEvent();
}

class LoadTasksList extends TaskListEvent {
  final bool reset;
  const LoadTasksList({this.reset = false});
}

class LoadNextTasksPage extends TaskListEvent {}

class UpdateSearchQuery extends TaskListEvent {
  final String query;
  const UpdateSearchQuery(this.query);
}

class UpdateStatusFilter extends TaskListEvent {
  final String status;
  const UpdateStatusFilter(this.status);
}

class UpdatePriorityFilter extends TaskListEvent {
  final String priority;
  const UpdatePriorityFilter(this.priority);
}

class UpdateDateFilterType extends TaskListEvent {
  final String dateFilterType;
  const UpdateDateFilterType(this.dateFilterType);
}

class UpdateCustomDateRange extends TaskListEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  const UpdateCustomDateRange(this.startDate, this.endDate);
}

class LocalTaskUpdated extends TaskListEvent {
  final TaskEntity task;
  const LocalTaskUpdated(this.task);
}

class LocalTaskCreated extends TaskListEvent {
  final TaskEntity task;
  const LocalTaskCreated(this.task);
}

class SyncQueueTriggered extends TaskListEvent {}
