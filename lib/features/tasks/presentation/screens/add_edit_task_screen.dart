import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/task_collection.dart';
import 'package:business_sahaj_erp/features/tasks/presentation/providers/task_providers.dart';
import 'package:business_sahaj_erp/core/widgets/custom_app_bar.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final int? taskId;

  const AddEditTaskScreen({Key? key, this.taskId}) : super(key: key);

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _status = 'Todo';
  String _priority = 'Medium';
  DateTime? _dueDate;
  
  Task? _existingTask;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    if (widget.taskId != null) {
      final repository = ref.read(taskRepositoryProvider);
      final task = await repository.getById(widget.taskId!);
      if (task != null) {
        _existingTask = task;
        _titleController.text = task.title ?? '';
        _descriptionController.text = task.description ?? '';
        _status = task.status ?? 'Todo';
        _priority = task.priority ?? 'Medium';
        _dueDate = task.dueDate;
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    Task task;
    if (_existingTask != null) {
      task = _existingTask!
        ..title = title
        ..description = description
        ..status = _status
        ..priority = _priority
        ..dueDate = _dueDate;
      
      if (_status == 'Done' && task.completedAt == null) {
        task.completedAt = DateTime.now();
      } else if (_status != 'Done') {
        task.completedAt = null;
      }
      
      await ref.read(taskNotifierProvider.notifier).updateTask(task);
    } else {
      task = Task()
        ..title = title
        ..description = description
        ..status = _status
        ..priority = _priority
        ..dueDate = _dueDate;
        
      if (_status == 'Done') {
        task.completedAt = DateTime.now();
      }

      await ref.read(taskNotifierProvider.notifier).addTask(task);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_existingTask == null ? 'Task Created' : 'Task Updated'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isEdit = _existingTask != null;

    return Scaffold(
      appBar: CustomAppBar(title: isEdit ? 'Edit Task' : 'New Task'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Todo', 'In Progress', 'Done'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Low', 'Medium', 'High'].map((p) {
                        return DropdownMenuItem(value: p, child: Text(p));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _priority = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due Date'),
                subtitle: Text(_dueDate == null ? 'No due date set' : DateFormat('EEE, MMM dd, yyyy').format(_dueDate!)),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Select Date'),
                  onPressed: _pickDueDate,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveTask,
                  child: Text(isEdit ? 'Update Task' : 'Create Task', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
