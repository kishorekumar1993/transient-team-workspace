import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

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
    final isOnline = await networkInfo.isConnected;

    if (isOnline) {
      try {
        final remoteResponse = await remoteDataSource.getTasks(
          page: page,
          limit: limit,
          search: search,
          status: status,
          priority: priority,
          startDate: startDate,
          endDate: endDate,
        );

        // Cache the first page of results to show offline later
        if (page == 1 &&
            search.isEmpty &&
            (status == 'All' || status.isEmpty) &&
            (priority == 'All' || priority.isEmpty) &&
            startDate == null &&
            endDate == null) {
          await localDataSource.cacheTasks(remoteResponse.tasks);
        }

        return Success(
          PaginatedTasks(
            tasks: remoteResponse.tasks,
            hasMore: remoteResponse.hasMore,
          ),
        );
      } on ServerException catch (e) {
        // If remote fails, fallback to local cache ONLY on first page
        if (page == 1) {
          return await _getLocalCachedTasksResult(
            search,
            status,
            priority,
            startDate,
            endDate,
          );
        }
        return Error(ServerFailure(e.message));
      } catch (e) {
        if (page == 1) {
          return await _getLocalCachedTasksResult(
            search,
            status,
            priority,
            startDate,
            endDate,
          );
        }
        return Error(ServerFailure(e.toString()));
      }
    } else {
      // Offline mode: load from cache
      if (page == 1) {
        return await _getLocalCachedTasksResult(
          search,
          status,
          priority,
          startDate,
          endDate,
        );
      }
      return const Error(
        NetworkFailure('No internet connection to load more pages'),
      );
    }
  }

  Future<Result<PaginatedTasks, Failure>> _getLocalCachedTasksResult(
    String search,
    String status,
    String priority,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final cachedList = await localDataSource.getCachedTasks();

      // Perform offline search & filtering locally so that search/filter functionality still works when offline!
      List<TaskModel> filtered = List.from(cachedList);

      if (search.isNotEmpty) {
        final query = search.toLowerCase();
        filtered = filtered.where((t) {
          return t.title.toLowerCase().contains(query) ||
              t.description.toLowerCase().contains(query);
        }).toList();
      }

      if (status.isNotEmpty && status != 'All') {
        filtered = filtered.where((t) => t.status == status).toList();
      }

      if (priority.isNotEmpty && priority != 'All') {
        filtered = filtered.where((t) => t.priority == priority).toList();
      }

      // Apply date range filter
      if (startDate != null && endDate != null) {
        filtered = filtered.where((t) {
          // Ensure dueDate is between startDate and endDate
          return t.dueDate.isAfter(
                startDate.subtract(const Duration(seconds: 1)),
              ) &&
              t.dueDate.isBefore(endDate.add(const Duration(seconds: 1)));
        }).toList();
      }

      // Sort by createdAt descending
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Success(
        PaginatedTasks(
          tasks: filtered,
          hasMore:
              false, // In offline mode we don't have pagination pages, we return the entire matching local set
        ),
      );
    } on CacheException catch (e) {
      return Error(CacheFailure(e.message));
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<TaskEntity, Failure>> createTask(TaskEntity task) async {
    final taskModel = TaskModel.fromEntity(task);
    final isOnline = await networkInfo.isConnected;

    if (isOnline) {
      try {
        final createdTask = await remoteDataSource.createTask(taskModel);

        // Update local cache by inserting the new task at the top
        await _insertTaskIntoLocalCache(createdTask);

        return Success(createdTask);
      } catch (e) {
        // If remote call fails, queue offline and return local success
        return await _queueOfflineCreate(taskModel);
      }
    } else {
      // Device is offline, queue local creation
      return await _queueOfflineCreate(taskModel);
    }
  }

  Future<Result<TaskEntity, Failure>> _queueOfflineCreate(
    TaskModel taskModel,
  ) async {
    try {
      await localDataSource.queueOfflineAction('CREATE', taskModel);
      await _insertTaskIntoLocalCache(taskModel);
      return Success(
        taskModel,
      ); // Return success so that it reflects immediately in the UI
    } on CacheException catch (e) {
      return Error(CacheFailure(e.message));
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  Future<void> _insertTaskIntoLocalCache(TaskModel task) async {
    try {
      final cached = await localDataSource.getCachedTasks();
      cached.insert(0, task); // insert at top
      await localDataSource.cacheTasks(cached);
    } catch (_) {}
  }

  @override
  Future<Result<TaskEntity, Failure>> updateTask(TaskEntity task) async {
    final taskModel = TaskModel.fromEntity(task);
    final isOnline = await networkInfo.isConnected;

    if (isOnline) {
      try {
        final updatedTask = await remoteDataSource.updateTask(taskModel);

        // Update local cache
        await _updateTaskInLocalCache(updatedTask);

        return Success(updatedTask);
      } catch (e) {
        // Queue update action locally
        return await _queueOfflineUpdate(taskModel);
      }
    } else {
      // Device is offline, queue local update
      return await _queueOfflineUpdate(taskModel);
    }
  }

  Future<Result<TaskEntity, Failure>> _queueOfflineUpdate(
    TaskModel taskModel,
  ) async {
    try {
      await localDataSource.queueOfflineAction('UPDATE', taskModel);
      await _updateTaskInLocalCache(taskModel);
      return Success(taskModel); // Reflects immediately in the UI
    } on CacheException catch (e) {
      return Error(CacheFailure(e.message));
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  Future<void> _updateTaskInLocalCache(TaskModel task) async {
    try {
      final cached = await localDataSource.getCachedTasks();
      final index = cached.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        cached[index] = task;
        await localDataSource.cacheTasks(cached);
      }
    } catch (_) {}
  }

  @override
  Future<Result<void, Failure>> syncOfflineTasks() async {
    final isOnline = await networkInfo.isConnected;
    if (!isOnline) {
      return const Error(
        NetworkFailure('Device is offline. Cannot sync tasks.'),
      );
    }

    try {
      final queue = await localDataSource.getOfflineQueue();
      if (queue.isEmpty) {
        return const Success(null);
      }

      // Synchronize each queued action
      for (final action in queue) {
        if (action.actionType == 'CREATE') {
          await remoteDataSource.createTask(action.task);
        } else if (action.actionType == 'UPDATE') {
          await remoteDataSource.updateTask(action.task);
        }
      }

      // If all operations successfully replayed, clear queue
      await localDataSource.clearOfflineQueue();
      return const Success(null);
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Error(CacheFailure(e.message));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}
