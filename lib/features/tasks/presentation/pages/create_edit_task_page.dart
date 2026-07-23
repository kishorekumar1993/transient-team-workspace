import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_form_bloc.dart';
import '../bloc/task_form_event.dart';
import '../bloc/task_form_state.dart';
import '../bloc/task_list_bloc.dart';
import '../bloc/task_list_event.dart';

class CreateEditTaskPage extends StatefulWidget {
  final TaskEntity? task;

  const CreateEditTaskPage({super.key, this.task});

  @override
  State<CreateEditTaskPage> createState() => _CreateEditTaskPageState();
}

class _CreateEditTaskPageState extends State<CreateEditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _assigneeController;

  late String _priority;
  late String _status;
  late DateTime _dueDate;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _assigneeController = TextEditingController(text: widget.task?.assignedUser ?? '');

    _priority = widget.task?.priority ?? 'Medium';
    _status = widget.task?.status ?? 'Pending';
    _dueDate = widget.task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() => _dueDate = picked);
    }
  }

  void _submitForm(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<TaskFormBloc>().add(
            TaskFormSubmitted(
              id: widget.task?.id,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              priority: _priority,
              dueDate: _dueDate,
              status: _status,
              assignedUser: _assigneeController.text.trim(),
            ),
          );
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'High': return const Color(0xFFEF4444);
      case 'Medium': return const Color(0xFFF59E0B);
      default: return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => sl<TaskFormBloc>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: theme.iconTheme.color),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isEdit ? Icons.edit_rounded : Icons.add_task_rounded,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isEdit ? 'Edit Task' : 'New Task',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
            ),
            body: BlocListener<TaskFormBloc, TaskFormState>(
              listener: (context, state) {
                if (state is TaskFormSuccess) {
                  if (state.isEdit) {
                    context.read<TaskListBloc>().add(LocalTaskUpdated(state.task));
                  } else {
                    context.read<TaskListBloc>().add(LocalTaskCreated(state.task));
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(_isEdit ? 'Task updated successfully' : 'Task created successfully'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  Navigator.pop(context, state.task);
                } else if (state is TaskFormError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(state.message)),
                        ],
                      ),
                      backgroundColor: AppTheme.priorityHigh,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Form Card Container
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.edit_note_rounded, size: 18, color: AppTheme.primaryColor),
                                    ),
                                    const SizedBox(width: 10),
                                    Text('Task Information', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // Title Field
                                _fieldLabel(theme, 'Task Title', Icons.title_rounded),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _titleController,
                                  textInputAction: TextInputAction.next,
                                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14.5),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'Task title is required';
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Set up Git repositories and branches',
                                    prefixIcon: Icon(Icons.task_alt_rounded, size: 20, color: theme.hintColor),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Description Field
                                _fieldLabel(theme, 'Description', Icons.description_outlined),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 4,
                                  textInputAction: TextInputAction.next,
                                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14.5),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'Task description is required';
                                    return null;
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Describe what needs to be done, expected outcomes, and any context...',
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, left: 4),
                                  child: Text('Provide enough context for the assignee to understand the task.', style: TextStyle(fontSize: 11, color: theme.hintColor)),
                                ),
                                const SizedBox(height: 20),

                                // Assignee Field
                                _fieldLabel(theme, 'Assigned User', Icons.person_outline_rounded),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _assigneeController,
                                  textInputAction: TextInputAction.done,
                                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14.5),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Kishore Kumar (Optional)',
                                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: theme.hintColor),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Priority & Status Row
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C3AED).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF7C3AED)),
                                    ),
                                    const SizedBox(width: 10),
                                    Text('Options & Scheduling', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // Priority Selection Chips
                                _fieldLabel(theme, 'Priority', Icons.flag_rounded),
                                const SizedBox(height: 10),
                                Row(
                                  children: ['Low', 'Medium', 'High'].map((p) {
                                    final isSelected = _priority == p;
                                    final color = _priorityColor(p);

                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _priority = p),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          margin: EdgeInsets.only(right: p != 'High' ? 8 : 0),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: isSelected ? color : (isDark ? AppTheme.darkBg : AppTheme.lightBg),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected ? color : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                            boxShadow: isSelected
                                                ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]
                                                : [],
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(Icons.flag_rounded, size: 18, color: isSelected ? Colors.white : color),
                                              const SizedBox(height: 4),
                                              Text(
                                                p,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),

                                // Status Selection Chips (for edit mode)
                                if (_isEdit) ...[
                                  _fieldLabel(theme, 'Status', Icons.checklist_rounded),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: ['Pending', 'In Progress', 'Completed'].map((s) {
                                      final isSelected = _status == s;
                                      final color = s == 'Completed'
                                          ? const Color(0xFF10B981)
                                          : s == 'In Progress'
                                              ? const Color(0xFF3B82F6)
                                              : const Color(0xFFF59E0B);

                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _status = s),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            margin: EdgeInsets.only(right: s != 'Completed' ? 8 : 0),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isSelected ? color : (isDark ? AppTheme.darkBg : AppTheme.lightBg),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected ? color : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                                width: isSelected ? 1.5 : 1,
                                              ),
                                              boxShadow: isSelected
                                                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]
                                                  : [],
                                            ),
                                            child: Center(
                                              child: Text(
                                                s == 'In Progress' ? 'Progress' : s,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Due Date Selector
                                _fieldLabel(theme, 'Due Date', Icons.calendar_today_rounded),
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: () => _selectDueDate(context),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryColor),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat('EEEE').format(_dueDate),
                                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              DateFormat('MMMM dd, yyyy').format(_dueDate),
                                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Icon(Icons.edit_calendar_rounded, size: 18, color: theme.hintColor),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          BlocBuilder<TaskFormBloc, TaskFormState>(
                            builder: (context, state) {
                              final isLoading = state is TaskFormSubmitting;
                              return Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primaryColor, Color(0xFF7C3AED)],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: AppTheme.primaryColor.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: isLoading ? null : () => _submitForm(context),
                                  icon: isLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : Icon(_isEdit ? Icons.save_rounded : Icons.add_task_rounded, color: Colors.white, size: 20),
                                  label: Text(
                                    _isEdit ? 'Save Changes' : 'Create Task',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fieldLabel(ThemeData theme, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 13)),
      ],
    );
  }
}
