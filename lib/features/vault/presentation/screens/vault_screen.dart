import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/features/vault/domain/models/vault_item.dart';
import 'package:business_sahaj_erp/features/vault/presentation/providers/vault_provider.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  void _showAddEditDialog([VaultItem? item]) {
    final titleController = TextEditingController(text: item?.title);
    final contentController = TextEditingController(text: item?.content);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? 'Add Vault Note' : 'Edit Vault Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Secret Content / Note',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                
                final newItem = VaultItem(
                  id: item?.id,
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  createdAt: item?.createdAt,
                  updatedAt: item?.updatedAt,
                );
                
                ref.read(vaultItemsProvider.notifier).saveItem(newItem);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(vaultItemsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Vault'),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Your Personal Vault is Empty',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 8),
                  const Text('Store your secret notes and information securely here.'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddEditDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Secret Note'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    leading: const Icon(Icons.lock, color: Colors.blueGrey),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(item.content),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            onPressed: () => _showAddEditDialog(item),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            label: const Text('Delete', style: TextStyle(color: Colors.red)),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Note'),
                                  content: const Text('Are you sure you want to delete this secret note?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true), 
                                      child: const Text('Delete', style: TextStyle(color: Colors.red))
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                ref.read(vaultItemsProvider.notifier).deleteItem(item.id);
                              }
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: items.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddEditDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
