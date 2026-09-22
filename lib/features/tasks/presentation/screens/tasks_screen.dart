import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/core/theme/app_decorations.dart';
import 'package:business_sahaj_erp/core/widgets/custom_app_bar.dart';
import 'package:business_sahaj_erp/features/tasks/presentation/providers/task_providers.dart';

import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/data/local/collections/task_collection.dart';
import 'package:business_sahaj_erp/features/vault/presentation/providers/vault_provider.dart';
import 'package:business_sahaj_erp/features/tasks/presentation/widgets/machinery_list_tab.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _enableMachineryManagement = false;

  @override
  void initState() {
    super.initState();
    final isPersonal = ref.read(vaultModeProvider) == VaultMode.personal;
    final prefs = ref.read(sharedPreferencesProvider);
    _enableMachineryManagement = isPersonal ? false : (prefs.getBool('enable_machinery_management') ?? false);
    _tabController = TabController(length: _enableMachineryManagement ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (ref.watch(vaultModeProvider) == VaultMode.personal)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.brightness == Brightness.dark 
                      ? Colors.white.withOpacity(0.15)
                      : Colors.indigo.withOpacity(0.1),
                  foregroundColor: theme.brightness == Brightness.dark 
                      ? Colors.white
                      : Colors.indigo.shade900,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.business_rounded, size: 18),
                label: const Text('Switch to Business', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () {
                  ref.read(vaultModeProvider.notifier).setMode(VaultMode.business);
                  context.go('/dashboard');
                },
              ),
            ),
        ],
        bottom: _enableMachineryManagement
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Tasks'),
                  Tab(text: 'Machinery'),
                ],
              )
            : null,
      ),
      backgroundColor: theme.colorScheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_enableMachineryManagement && _tabController.index == 1) {
            context.push('/machinery/add');
          } else {
            context.push('/tasks/add');
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _enableMachineryManagement
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildTasksList(tasksAsync, theme),
                const MachineryListTab(),
              ],
            )
          : _buildTasksList(tasksAsync, theme),
    );
  }

  Widget _buildTasksList(AsyncValue<List<Task>> tasksAsync, ThemeData theme) {
    return tasksAsync.when(
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
