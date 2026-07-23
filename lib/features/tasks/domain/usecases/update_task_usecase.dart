import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class UpdateTaskUseCase {
  final TaskRepository repository;

  UpdateTaskUseCase(this.repository);

  Future<Result<TaskEntity, Failure>> call(TaskEntity task) {
    return repository.updateTask(task);
  }
}
