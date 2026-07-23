import '../../domain/entities/task_entity.dart';

abstract class TaskFormState {
  const TaskFormState();
}

class TaskFormInitial extends TaskFormState {}

class TaskFormSubmitting extends TaskFormState {}

class TaskFormSuccess extends TaskFormState {
  final TaskEntity task;
  final bool isEdit;
  const TaskFormSuccess(this.task, {required this.isEdit});
}

class TaskFormError extends TaskFormState {
  final String message;
  const TaskFormError(this.message);
}
