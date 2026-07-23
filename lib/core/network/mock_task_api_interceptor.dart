import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';

class MockTaskApiInterceptor extends Interceptor {
  // A static flag that can be toggled from the UI/Debug menu to simulate API failures.
  static bool shouldSimulateError = false;

  // Static in-memory database to persist tasks during the app execution session.
  static final List<Map<String, dynamic>> _inMemoryTasks = [];

  MockTaskApiInterceptor() {
    if (_inMemoryTasks.isEmpty) {
      _prepopulateTasks();
    }
  }

  // Pre-populates the in-memory list with 25+ realistic tasks.
  void _prepopulateTasks() {
    final now = DateTime.now();
    final random = Random();

    final titles = [
      'Set up Git repositories and branches',
      'Configure Firebase Project & Apps',
      'Design clean architecture structure',
      'Create custom login page UI',
      'Integrate email verification flow',
      'Set up database indexes for tasks',
      'Write authentication bloc tests',
      'Develop pagination logic for task lists',
      'Add pull-to-refresh to dashboard',
      'Implement local caching using SharedPreferences',
      'Create edit task form and validators',
      'Add search bar to dashboard',
      'Implement task status filter',
      'Implement priority filter',
      'Develop offline queue for sync',
      'Add dark mode color palette',
      'Configure CI/CD github actions pipeline',
      'Write task repository unit tests',
      'Conduct final manual testing on Android',
      'Prepare production build release',
      'Document design patterns in README.md',
      'Fix keyboard overflow in task details',
      'Optimize API request latency',
      'Configure SSL pinning for secure connections',
      'Conduct code review with team members',
      'Draft release notes for v1.0.0',
    ];

    final descriptions = [
      'Establish the main, dev, and feature branch structures, and enforce branch protection rules.',
      'Initialize Firebase project, download google-services.json for Android and GoogleService-Info.plist for iOS.',
      'Establish core, features, and theme folder structures under the lib directory following Clean Architecture.',
      'Develop the email & password inputs, login buttons, logos, and error text widgets.',
      'Send verification email upon new registration and prevent login until email is verified.',
      'Create compound indexes in Firestore on ownerId, status, priority, and due date.',
      'Write unit tests using bloc_test to verify all state transitions in AuthBloc.',
      'Implement pagination parameters on Dio requests and process lists in TaskListBloc.',
      'Support RefreshIndicator on Dashboard to reload the first page of tasks.',
      'Serialize tasks into a JSON string and store it locally using SharedPreferences.',
      'Build inputs for Title, Description, Priority dropdown, and Due Date picker with form keys.',
      'Allow live search by matching query against title and description strings.',
      'Filter dashboard tasks by Status (Pending, In Progress, Completed).',
      'Filter dashboard tasks by Priority (Low, Medium, High).',
      'Implement SQLite or SharedPreferences buffer to queue offline writes and sync when online.',
      'Define dark colors and typography, and toggle theme using ThemeMode.',
      'Set up a workflow that runs flutter test and builds apks on every push to main.',
      'Ensure the repository catches network exceptions and maps them to appropriate Failures.',
      'Run the application on an emulator and physical device to check responsive layout.',
      'Generate unsigned release APK and app bundle for Google Play Store upload.',
      'Write clean details explaining BLoC, Repository Pattern, and Dependency Injection details.',
      'Wrap task details content in a SingleChildScrollView to prevent layout overflows.',
      'Set up caching headers and minimize response payload size for fast load times.',
      'Add SSL certificate hashes to Dio SecurityContext for secure network communication.',
      'Go through the pull request line by line to verify clean code compliance and catch bugs.',
      'Outline bug fixes, new features, and changes included in this application release.',
    ];

    final priorities = ['Low', 'Medium', 'High'];
    final statuses = ['Pending', 'In Progress', 'Completed'];
    final users = [
      'Alice Smith',
      'Bob Jones',
      'Charlie Brown',
      'Diana Prince',
      'Evan Wright',
    ];

    for (int i = 0; i < titles.length; i++) {
      final daysDiff =
          random.nextInt(30) -
          10; // due dates between -10 and +20 days from now
      final dueDate = now.add(Duration(days: daysDiff));

      _inMemoryTasks.add({
        'id': 'task_id_${i + 1}',
        'title': titles[i],
        'description': descriptions[i],
        'priority': priorities[random.nextInt(priorities.length)],
        'dueDate': dueDate.toIso8601String(),
        'status': statuses[random.nextInt(statuses.length)],
        'assignedUser': users[random.nextInt(users.length)],
        'createdAt': now.subtract(Duration(days: i + 1)).toIso8601String(),
      });
    }
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Simulate network latency (between 400ms and 800ms)
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (shouldSimulateError) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 500,
            statusMessage: 'Internal Server Error (Simulated)',
          ),
          type: DioExceptionType.badResponse,
          error: 'Simulated API Failure',
        ),
      );
      return;
    }

    final path = options.path;

    // Handle GET /tasks
    if (path.endsWith('/tasks') && options.method == 'GET') {
      _handleGetTasks(options, handler);
      return;
    }

    // Handle POST /tasks
    if (path.endsWith('/tasks') && options.method == 'POST') {
      _handlePostTask(options, handler);
      return;
    }

    // Handle PUT /tasks/:id
    final putMatch = RegExp(r'/tasks/([^/]+)$').firstMatch(path);
    if (putMatch != null && options.method == 'PUT') {
      final taskId = putMatch.group(1);
      _handlePutTask(taskId!, options, handler);
      return;
    }

    // Pass through unhandled mock calls
    handler.next(options);
  }

  void _handleGetTasks(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final queryParams = options.queryParameters;

    // Parse query params
    final int page = int.tryParse(queryParams['page']?.toString() ?? '1') ?? 1;
    final int limit =
        int.tryParse(queryParams['limit']?.toString() ?? '10') ?? 10;
    final String search = queryParams['search']?.toString().toLowerCase() ?? '';
    final String status = queryParams['status']?.toString() ?? '';
    final String priority = queryParams['priority']?.toString() ?? '';
    final String startDateStr = queryParams['startDate']?.toString() ?? '';
    final String endDateStr = queryParams['endDate']?.toString() ?? '';

    // Apply filtering
    List<Map<String, dynamic>> filtered = List.from(_inMemoryTasks);

    // Search by title
    if (search.isNotEmpty) {
      filtered = filtered.where((t) {
        final title = t['title']?.toString().toLowerCase() ?? '';
        final desc = t['description']?.toString().toLowerCase() ?? '';
        return title.contains(search) || desc.contains(search);
      }).toList();
    }

    // Filter by status
    if (status.isNotEmpty && status != 'All') {
      filtered = filtered.where((t) => t['status'] == status).toList();
    }

    // Filter by priority
    if (priority.isNotEmpty && priority != 'All') {
      filtered = filtered.where((t) => t['priority'] == priority).toList();
    }

    // Filter by date (startDate/endDate)
    if (startDateStr.isNotEmpty && endDateStr.isNotEmpty) {
      final startDate = DateTime.tryParse(startDateStr);
      final endDate = DateTime.tryParse(endDateStr);

      if (startDate != null && endDate != null) {
        filtered = filtered.where((t) {
          final dueDate = DateTime.tryParse(t['dueDate'] ?? '');
          if (dueDate == null) return false;
          return dueDate.isAfter(
                startDate.subtract(const Duration(seconds: 1)),
              ) &&
              dueDate.isBefore(endDate.add(const Duration(seconds: 1)));
        }).toList();
      }
    }

    // Sort by createdAt descending (so new tasks appear first)
    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    // Paginate
    final int startIndex = (page - 1) * limit;
    final int endIndex = min(startIndex + limit, filtered.length);

    List<Map<String, dynamic>> pagedList = [];
    if (startIndex < filtered.length) {
      pagedList = filtered.sublist(startIndex, endIndex);
    }

    final hasMore = endIndex < filtered.length;

    final responseData = {
      'tasks': pagedList,
      'page': page,
      'limit': limit,
      'total': filtered.length,
      'hasMore': hasMore,
    };

    handler.resolve(
      Response(requestOptions: options, data: responseData, statusCode: 200),
    );
  }

  void _handlePostTask(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    try {
      final dynamic body = options.data;
      Map<String, dynamic> bodyMap = {};
      if (body is String) {
        bodyMap = jsonDecode(body) as Map<String, dynamic>;
      } else if (body is Map<String, dynamic>) {
        bodyMap = body;
      }

      final now = DateTime.now();
      final newTask = {
        'id': bodyMap['id'] ?? 'task_id_${_inMemoryTasks.length + 1}',
        'title': bodyMap['title'] ?? 'Untitled Task',
        'description': bodyMap['description'] ?? '',
        'priority': bodyMap['priority'] ?? 'Medium',
        'dueDate': bodyMap['dueDate'] ?? now.toIso8601String(),
        'status': bodyMap['status'] ?? 'Pending',
        'assignedUser': bodyMap['assignedUser'] ?? 'Unassigned',
        'createdAt': now.toIso8601String(),
      };

      _inMemoryTasks.insert(0, newTask); // Insert at beginning of memory list

      handler.resolve(
        Response(requestOptions: options, data: newTask, statusCode: 201),
      );
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Failed to parse task creation payload: $e',
          type: DioExceptionType.badResponse,
        ),
      );
    }
  }

  void _handlePutTask(
    String taskId,
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    try {
      final dynamic body = options.data;
      Map<String, dynamic> bodyMap = {};
      if (body is String) {
        bodyMap = jsonDecode(body) as Map<String, dynamic>;
      } else if (body is Map<String, dynamic>) {
        bodyMap = body;
      }

      final index = _inMemoryTasks.indexWhere((t) => t['id'] == taskId);
      if (index == -1) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 404,
              statusMessage: 'Task not found',
            ),
            type: DioExceptionType.badResponse,
            error: 'Task with ID $taskId not found',
          ),
        );
        return;
      }

      // Update fields
      final existingTask = _inMemoryTasks[index];
      final updatedTask = {
        ...existingTask,
        if (bodyMap.containsKey('title')) 'title': bodyMap['title'],
        if (bodyMap.containsKey('description'))
          'description': bodyMap['description'],
        if (bodyMap.containsKey('priority')) 'priority': bodyMap['priority'],
        if (bodyMap.containsKey('dueDate')) 'dueDate': bodyMap['dueDate'],
        if (bodyMap.containsKey('status')) 'status': bodyMap['status'],
        if (bodyMap.containsKey('assignedUser'))
          'assignedUser': bodyMap['assignedUser'],
      };

      _inMemoryTasks[index] = updatedTask;

      handler.resolve(
        Response(requestOptions: options, data: updatedTask, statusCode: 200),
      );
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Failed to parse task update payload: $e',
          type: DioExceptionType.badResponse,
        ),
      );
    }
  }
}
