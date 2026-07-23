import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/task_model.dart';

class OfflineAction {
  final String actionType; // "CREATE" or "UPDATE"
  final TaskModel task;

  OfflineAction({required this.actionType, required this.task});

  Map<String, dynamic> toJson() {
    return {'actionType': actionType, 'task': task.toJson()};
  }

  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      actionType: json['actionType'] as String,
      task: TaskModel.fromJson(json['task'] as Map<String, dynamic>),
    );
  }
}

abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getCachedTasks();
  Future<void> cacheTasks(List<TaskModel> tasks);
  Future<void> queueOfflineAction(String actionType, TaskModel task);
  Future<List<OfflineAction>> getOfflineQueue();
  Future<void> clearOfflineQueue();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const _cachedTasksKey = 'cached_tasks_list';
  static const _offlineQueueKey = 'offline_sync_queue';

  TaskLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<TaskModel>> getCachedTasks() async {
    final raw = sharedPreferences.getString(_cachedTasksKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const CacheException('Failed to parse cached tasks');
    }
  }

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    final rawList = tasks.map((t) => t.toJson()).toList();
    final success = await sharedPreferences.setString(
      _cachedTasksKey,
      jsonEncode(rawList),
    );
    if (!success) {
      throw const CacheException('Failed to write tasks to cache');
    }
  }

  @override
  Future<void> queueOfflineAction(String actionType, TaskModel task) async {
    try {
      final queue = await getOfflineQueue();

      // If there is an existing update/create action for this task in the queue, we can update it or merge it
      final index = queue.indexWhere((action) => action.task.id == task.id);
      if (index != -1) {
        // Keep the original actionType (if it was CREATE, keep it as CREATE)
        final originalActionType = queue[index].actionType;
        queue[index] = OfflineAction(
          actionType: originalActionType,
          task: task,
        );
      } else {
        queue.add(OfflineAction(actionType: actionType, task: task));
      }

      final rawList = queue.map((action) => action.toJson()).toList();
      final success = await sharedPreferences.setString(
        _offlineQueueKey,
        jsonEncode(rawList),
      );
      if (!success) {
        throw const CacheException('Failed to save action to offline queue');
      }
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<List<OfflineAction>> getOfflineQueue() async {
    final raw = sharedPreferences.getString(_offlineQueueKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((item) => OfflineAction.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> clearOfflineQueue() async {
    final success = await sharedPreferences.remove(_offlineQueueKey);
    if (!success) {
      throw const CacheException('Failed to clear offline queue');
    }
  }
}
