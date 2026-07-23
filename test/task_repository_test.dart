import 'package:flutter_test/flutter_test.dart';
import 'package:transient/core/error/exceptions.dart';
import 'package:transient/core/error/failures.dart';
import 'package:transient/core/network/network_info.dart';
import 'package:transient/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:transient/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:transient/features/tasks/data/models/task_model.dart';
import 'package:transient/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:transient/features/tasks/domain/entities/task_entity.dart';

class MockRemoteDataSource implements TaskRemoteDataSource {
  List<TaskModel> tasks = [];
  bool hasMore = false;
  bool shouldThrow = false;

  @override
  Future<RemoteTasksResponse> getTasks({
    required int page,
    required int limit,
    required String search,
    required String status,
    required String priority,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (shouldThrow) throw const ServerException('Remote Error');
    return RemoteTasksResponse(tasks: tasks, hasMore: hasMore);
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    if (shouldThrow) throw const ServerException('Remote Error');
    tasks.add(task);
    return task;
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    if (shouldThrow) throw const ServerException('Remote Error');
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
    }
    return task;
  }
}

class MockLocalDataSource implements TaskLocalDataSource {
  List<TaskModel> cachedTasks = [];
  List<OfflineAction> offlineQueue = [];

  @override
  Future<List<TaskModel>> getCachedTasks() async => cachedTasks;

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    cachedTasks = tasks;
  }

  @override
  Future<void> queueOfflineAction(String actionType, TaskModel task) async {
    offlineQueue.add(OfflineAction(actionType: actionType, task: task));
  }

  @override
  Future<List<OfflineAction>> getOfflineQueue() async => offlineQueue;

  @override
  Future<void> clearOfflineQueue() async {
    offlineQueue.clear();
  }
}

class MockNetworkInfo implements NetworkInfo {
  bool isConnectedValue = true;

  @override
  Future<bool> get isConnected async => isConnectedValue;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(isConnectedValue);
}

void main() {
  late MockRemoteDataSource remoteDataSource;
  late MockLocalDataSource localDataSource;
  late MockNetworkInfo networkInfo;
  late TaskRepositoryImpl repository;

  final tTask = TaskEntity(
    id: 'task_1',
    title: 'Test Title',
    description: 'Test Desc',
    priority: 'Low',
    status: 'Pending',
    assignedUser: 'Bob',
    dueDate: DateTime.now(),
    createdAt: DateTime.now(),
  );

  setUp(() {
    remoteDataSource = MockRemoteDataSource();
    localDataSource = MockLocalDataSource();
    networkInfo = MockNetworkInfo();
    repository = TaskRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      networkInfo: networkInfo,
    );
  });

  group('getTasks', () {
    test('should fetch remote tasks and cache them locally when online', () async {
      networkInfo.isConnectedValue = true;
      final taskModel = TaskModel.fromEntity(tTask);
      remoteDataSource.tasks = [taskModel];

      final result = await repository.getTasks(
        page: 1,
        limit: 10,
        search: '',
        status: '',
        priority: '',
      );

      expect(result.isSuccess, true);
      expect(localDataSource.cachedTasks.length, 1);
    });

    test('should return local cached tasks when offline', () async {
      networkInfo.isConnectedValue = false;
      final taskModel = TaskModel.fromEntity(tTask);
      localDataSource.cachedTasks = [taskModel];

      final result = await repository.getTasks(
        page: 1,
        limit: 10,
        search: '',
        status: '',
        priority: '',
      );

      expect(result.isSuccess, true);
      expect(remoteDataSource.tasks.isEmpty, true);
    });
  });

  group('syncOfflineTasks', () {
    test('should execute queued actions and clear queue when online sync is invoked', () async {
      networkInfo.isConnectedValue = true;
      final taskModel = TaskModel.fromEntity(tTask);
      localDataSource.offlineQueue = [
        OfflineAction(actionType: 'CREATE', task: taskModel),
      ];

      final result = await repository.syncOfflineTasks();

      expect(result.isSuccess, true);
      expect(remoteDataSource.tasks.length, 1);
      expect(localDataSource.offlineQueue.isEmpty, true);
    });
  });
}
