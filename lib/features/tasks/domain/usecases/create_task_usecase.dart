import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  final TaskRepository repository;

  CreateTaskUseCase(this.repository);

  Future<Result<TaskEntity, Failure>> call(TaskEntity task) {
    return repository.createTask(task);
  }
}
