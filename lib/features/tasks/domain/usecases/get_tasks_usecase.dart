import '../../../../core/error/failures.dart';
import '../repositories/task_repository.dart';

class GetTasksUseCase {
  final TaskRepository repository;

  GetTasksUseCase(this.repository);

  Future<Result<PaginatedTasks, Failure>> call({
    required int page,
    required int limit,
    required String search,
    required String status,
    required String priority,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await repository.getTasks(
      page: page,
      limit: limit,
      search: search,
      status: status,
      priority: priority,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
