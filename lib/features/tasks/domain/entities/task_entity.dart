class TaskEntity {
  final String id;
  final String title;
  final String description;
  final String priority;
  final DateTime dueDate;
  final String status;
  final String assignedUser;
  final DateTime createdAt;

  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.status,
    required this.assignedUser,
    required this.createdAt,
  });

  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    DateTime? dueDate,
    String? status,
    String? assignedUser,
    DateTime? createdAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      assignedUser: assignedUser ?? this.assignedUser,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
