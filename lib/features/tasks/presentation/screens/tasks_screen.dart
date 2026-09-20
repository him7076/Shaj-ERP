import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/core/theme/app_decorations.dart';
import 'package:business_sahaj_erp/core/widgets/custom_app_bar.dart';
import 'package:business_sahaj_erp/features/tasks/presentation/providers/task_providers.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Tasks'),
      backgroundColor: theme.colorScheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/add'),
        child: const Icon(Icons.add),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No tasks found.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.push('/tasks/add'),
                    child: const Text('Create New Task'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    task.title ?? 'Untitled Task',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildChip(theme, task.status ?? 'Todo', _getStatusColor(task.status)),
                          const SizedBox(width: 8),
                          _buildChip(theme, task.priority ?? 'Medium', _getPriorityColor(task.priority)),
                          const Spacer(),
                          if (task.dueDate != null)
                            Text(
                              'Due: ${DateFormat('dd MMM').format(task.dueDate!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: task.dueDate!.isBefore(DateTime.now()) && task.status != 'Done' ? Colors.red : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => context.push('/tasks/edit/${task.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChip(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Done':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'Todo':
      default:
        return Colors.orange;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.purple;
      case 'Low':
      default:
        return Colors.grey;
    }
  }
}
