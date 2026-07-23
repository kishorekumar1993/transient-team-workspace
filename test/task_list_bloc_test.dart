import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transient/core/error/failures.dart';
import 'package:transient/features/tasks/domain/entities/task_entity.dart';
import 'package:transient/features/tasks/domain/repositories/task_repository.dart';
import 'package:transient/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:transient/features/tasks/domain/usecases/sync_offline_tasks_usecase.dart';
import 'package:transient/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient/features/tasks/presentation/bloc/task_list_event.dart';
import 'package:transient/features/tasks/presentation/bloc/task_list_state.dart';

class MockTaskRepository implements TaskRepository {
  List<TaskEntity> tasks = [];
  bool hasMoreValue = false;
  bool shouldFail = false;
  String errorMsg = 'API Failure';

  @override
  Future<Result<PaginatedTasks, Failure>> getTasks({
    required int page,
    required int limit,
    required String search,
    required String status,
    required String priority,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (shouldFail) return Error(ServerFailure(errorMsg));
    return Success(PaginatedTasks(tasks: tasks, hasMore: hasMoreValue));
  }

  @override
  Future<Result<TaskEntity, Failure>> createTask(TaskEntity task) async {
    if (shouldFail) return Error(ServerFailure(errorMsg));
    tasks.add(task);
    return Success(task);
  }

  @override
  Future<Result<TaskEntity, Failure>> updateTask(TaskEntity task) async {
    if (shouldFail) return Error(ServerFailure(errorMsg));
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
    }
    return Success(task);
  }

  @override
  Future<Result<void, Failure>> syncOfflineTasks() async {
    if (shouldFail) return Error(ServerFailure(errorMsg));
    return const Success(null);
  }
}

void main() {
  late MockTaskRepository mockRepository;
  late GetTasksUseCase getTasksUseCase;
  late SyncOfflineTasksUseCase syncOfflineTasksUseCase;
  late TaskListBloc taskListBloc;

  final tTask = TaskEntity(
    id: '1',
    title: 'Test Task',
    description: 'Test Desc',
    priority: 'Medium',
    status: 'Pending',
    assignedUser: 'John',
    dueDate: DateTime.now(),
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockRepository = MockTaskRepository();
    getTasksUseCase = GetTasksUseCase(mockRepository);
    syncOfflineTasksUseCase = SyncOfflineTasksUseCase(mockRepository);
    taskListBloc = TaskListBloc(
      getTasksUseCase: getTasksUseCase,
      syncOfflineTasksUseCase: syncOfflineTasksUseCase,
    );
  });

  tearDown(() {
    taskListBloc.close();
  });

  test('initial state should be TaskListInitial', () {
    expect(taskListBloc.state, isA<TaskListInitial>());
  });

  group('LoadTasksList', () {
    blocTest<TaskListBloc, TaskListState>(
      'emits [TaskListLoading, TaskListLoaded] when tasks load successfully',
      build: () {
        mockRepository.tasks = [tTask];
        return taskListBloc;
      },
      act: (bloc) => bloc.add(const LoadTasksList()),
      expect: () => [
        isA<TaskListLoading>(),
        isA<TaskListLoaded>().having(
          (state) => state.tasks.length,
          'length',
          1,
        ),
      ],
    );

    blocTest<TaskListBloc, TaskListState>(
      'emits [TaskListLoading, TaskListError] when tasks load fails',
      build: () {
        mockRepository.shouldFail = true;
        return taskListBloc;
      },
      act: (bloc) => bloc.add(const LoadTasksList()),
      expect: () => [
        isA<TaskListLoading>(),
        isA<TaskListError>().having(
          (state) => state.errorMessage,
          'errorMessage',
          'API Failure',
        ),
      ],
    );
  });

  group('Local sync queue updates', () {
    blocTest<TaskListBloc, TaskListState>(
      'instantly adds newly created local tasks to presentation state lists',
      build: () => taskListBloc,
      act: (bloc) => bloc.add(LocalTaskCreated(tTask)),
      expect: () => [
        isA<TaskListLoaded>().having(
          (state) => state.tasks.first.title,
          'first title',
          'Test Task',
        ),
      ],
    );

    blocTest<TaskListBloc, TaskListState>(
      'instantly replaces updated tasks inside presentation lists',
      build: () {
        taskListBloc.emit(
          TaskListLoaded(
            tasks: [tTask],
            page: 1,
            hasMore: false,
            searchQuery: '',
            statusFilter: 'All',
            priorityFilter: 'All',
            isSyncing: false,
            dateFilterType: 'All',
            customStartDate: null,
            customEndDate: null,
          ),
        );
        return taskListBloc;
      },
      act: (bloc) =>
          bloc.add(LocalTaskUpdated(tTask.copyWith(status: 'Completed'))),
      expect: () => [
        isA<TaskListLoaded>().having(
          (state) => state.tasks.first.status,
          'status',
          'Completed',
        ),
      ],
    );
  });
}
