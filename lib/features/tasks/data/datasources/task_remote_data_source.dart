import 'package:dio/dio.dart';
import 'package:transient/core/config/app_config.dart';
import '../../../../core/error/exceptions.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<RemoteTasksResponse> getTasks({
    required int page,
    required int limit,
    required String search,
    required String status,
    required String priority,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<TaskModel> createTask(TaskModel task);

  Future<TaskModel> updateTask(TaskModel task);
}

class RemoteTasksResponse {
  final List<TaskModel> tasks;
  final bool hasMore;

  RemoteTasksResponse({required this.tasks, required this.hasMore});
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final Dio dio;
  String get _tasksUrl => AppConfig.instance.apiBaseUrl;

  TaskRemoteDataSourceImpl({required this.dio});

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
    try {
      final response = await dio.get(
        _tasksUrl,
        queryParameters: {
          'page': page,
          'limit': limit,
          'search': search,
          'status': status,
          'priority': priority,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final tasksList = (data['tasks'] as List)
            .map((task) => TaskModel.fromJson(task as Map<String, dynamic>))
            .toList();
        final hasMore = data['hasMore'] as bool? ?? false;
        return RemoteTasksResponse(tasks: tasksList, hasMore: hasMore);
      } else {
        throw ServerException(
          'Failed to load tasks: Code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Dio server exception occurred');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final response = await dio.post(_tasksUrl, data: task.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        return TaskModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          'Failed to create task: Code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Dio server exception occurred');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final response = await dio.put(
        '$_tasksUrl/${task.id}',
        data: task.toJson(),
      );
      if (response.statusCode == 200) {
        return TaskModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          'Failed to update task: Code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Dio server exception occurred');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
