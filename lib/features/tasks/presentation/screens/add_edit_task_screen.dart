import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:business_sahaj_erp/data/local/collections/task_collection.dart';
import 'package:business_sahaj_erp/features/tasks/presentation/providers/task_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/vault/presentation/providers/vault_provider.dart';

class SubtaskItem {
  String title;
  bool isCompleted;
  SubtaskItem({required this.title, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
    'title': title,
    'isCompleted': isCompleted,
  };

  factory SubtaskItem.fromJson(Map<String, dynamic> json) => SubtaskItem(
    title: json['title'] ?? '',
    isCompleted: json['isCompleted'] ?? false,
  );
}

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
  final _estimatedTimeController = TextEditingController();
  
  String _status = 'Todo';
  String _priority = 'Medium';
  DateTime? _dueDate;
  
  List<SubtaskItem> _subtasks = [];
  List<Item> _linkedItems = [];
  
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
        
        if (task.estimatedTimeMinutes != null) {
          _estimatedTimeController.text = task.estimatedTimeMinutes.toString();
        }

        if (task.subtasksJson != null && task.subtasksJson!.isNotEmpty) {
          try {
            final List<dynamic> decoded = jsonDecode(task.subtasksJson!);
            _subtasks = decoded.map((e) => SubtaskItem.fromJson(e)).toList();
          } catch (_) {}
        }

        if (task.linkedItemUuids != null && task.linkedItemUuids!.isNotEmpty) {
          final allItems = await ref.read(itemsListProvider.future);
          _linkedItems = allItems.where((i) => i.uuid != null && task.linkedItemUuids!.contains(i.uuid)).toList();
        }
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
    _estimatedTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final estimatedTime = int.tryParse(_estimatedTimeController.text.trim());

    Task task;
    if (_existingTask != null) {
      task = _existingTask!
        ..title = title
        ..description = description
        ..status = _status
        ..priority = _priority
        ..dueDate = _dueDate
        ..estimatedTimeMinutes = estimatedTime
        ..subtasksJson = jsonEncode(_subtasks.map((e) => e.toJson()).toList())
        ..linkedItemUuids = _linkedItems.map((e) => e.uuid!).toList();
      
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
        ..dueDate = _dueDate
        ..estimatedTimeMinutes = estimatedTime
        ..subtasksJson = jsonEncode(_subtasks.map((e) => e.toJson()).toList())
        ..linkedItemUuids = _linkedItems.map((e) => e.uuid!).toList();
        
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

  void _addSubtask() {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subtask'),
        content: TextField(
          controller: tc,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Subtask title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (tc.text.trim().isNotEmpty) {
                setState(() {
                  _subtasks.add(SubtaskItem(title: tc.text.trim()));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  Future<void> _pickItems() async {
    final allItems = await ref.read(itemsListProvider.future);
    if (!mounted) return;

    List<Item> tempSelected = List.from(_linkedItems);
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    AppBar(
                      title: const Text('Link Items/Bundles'),
                      leading: const CloseButton(),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: allItems.length,
                        itemBuilder: (context, index) {
                          final item = allItems[index];
                          final isSelected = tempSelected.any((e) => e.uuid == item.uuid);
                          return CheckboxListTile(
                            title: Text(item.itemName ?? ''),
                            subtitle: Text(item.isBundle ? 'Bundle' : 'Item'),
                            value: isSelected,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  tempSelected.add(item);
                                } else {
                                  tempSelected.removeWhere((e) => e.uuid == item.uuid);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done'),
                        ),
                      ),
                    )
                  ],
                );
              },
            );
          },
        );
      },
    );

    setState(() {
      _linkedItems = tempSelected;
    });
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
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Task' : 'New Task'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _estimatedTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Est. Time (mins)',
                        
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
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
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _dueDate == null ? 'Due Date' : DateFormat('MMM dd, yyyy').format(_dueDate!),
                                style: TextStyle(color: _dueDate == null ? Colors.grey.shade600 : null),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Subtasks Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _addSubtask,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (_subtasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('No subtasks added.', style: TextStyle(color: Colors.grey)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _subtasks.length,
                  itemBuilder: (context, index) {
                    final sub = _subtasks[index];
                    return CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        sub.title,
                        style: TextStyle(
                          decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                          color: sub.isCompleted ? Colors.grey : null,
                        ),
                      ),
                      value: sub.isCompleted,
                      onChanged: (val) {
                        setState(() {
                          sub.isCompleted = val ?? false;
                        });
                      },
                      secondary: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _subtasks.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              
              const SizedBox(height: 16),

              if (ref.read(vaultModeProvider) == VaultMode.business) ...[
                // Linked Items Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Linked Items & Bundles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _pickItems,
                      icon: const Icon(Icons.link),
                      label: const Text('Link Items'),
                    ),
                  ],
                ),
                if (_linkedItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('No items linked.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _linkedItems.map((item) {
                      return Chip(
                        label: Text(item.itemName ?? ''),
                        onDeleted: () {
                          setState(() {
                            _linkedItems.remove(item);
                          });
                        },
                      );
                    }).toList(),
                  ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveTask,
                  child: Text(isEdit ? 'Update Task' : 'Create Task', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
