import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';
import 'task_form_event.dart';
import 'task_form_state.dart';

class TaskFormBloc extends Bloc<TaskFormEvent, TaskFormState> {
  final CreateTaskUseCase createTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;
  final Uuid uuid = const Uuid();

  TaskFormBloc({
    required this.createTaskUseCase,
    required this.updateTaskUseCase,
  }) : super(TaskFormInitial()) {
    on<TaskFormSubmitted>(_onTaskFormSubmitted);
  }

  Future<void> _onTaskFormSubmitted(
    TaskFormSubmitted event,
    Emitter<TaskFormState> emit,
  ) async {
    emit(TaskFormSubmitting());

    final isEdit = event.id != null;
    final task = TaskEntity(
      id: event.id ?? uuid.v4(),
      title: event.title,
      description: event.description,
      priority: event.priority,
      dueDate: event.dueDate,
      status: event.status,
      assignedUser: event.assignedUser.isEmpty ? 'Unassigned' : event.assignedUser,
      createdAt: DateTime.now(),
    );

    final result = isEdit 
        ? await updateTaskUseCase(task) 
        : await createTaskUseCase(task);

    result.fold(
      (savedTask) => emit(TaskFormSuccess(savedTask, isEdit: isEdit)),
      (failure) => emit(TaskFormError(failure.message)),
    );
  }
}
