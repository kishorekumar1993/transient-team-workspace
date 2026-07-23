abstract class TaskFormEvent {
  const TaskFormEvent();
}

class TaskFormSubmitted extends TaskFormEvent {
  final String? id; // Null means creating a new task, otherwise editing
  final String title;
  final String description;
  final String priority;
  final DateTime dueDate;
  final String status;
  final String assignedUser;

  const TaskFormSubmitted({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.status,
    required this.assignedUser,
  });
}
