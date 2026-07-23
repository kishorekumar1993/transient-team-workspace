import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';

class PaginatedTasks {
  final List<TaskEntity> tasks;
  final bool hasMore;

  PaginatedTasks({required this.tasks, required this.hasMore});
}

abstract class TaskRepository {
  Future<Result<PaginatedTasks, Failure>> getTasks({
    required int page,
    required int limit,
    required String search,
    required String status,
    required String priority,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Result<TaskEntity, Failure>> createTask(TaskEntity task);

  Future<Result<TaskEntity, Failure>> updateTask(TaskEntity task);

  Future<Result<void, Failure>> syncOfflineTasks();
}
