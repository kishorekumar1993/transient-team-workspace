import '../../../../core/error/failures.dart';
import '../repositories/task_repository.dart';

class SyncOfflineTasksUseCase {
  final TaskRepository repository;

  SyncOfflineTasksUseCase(this.repository);

  Future<Result<void, Failure>> call() {
    return repository.syncOfflineTasks();
  }
}
