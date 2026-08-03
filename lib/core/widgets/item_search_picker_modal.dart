import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_item_sheet.dart';

class ItemSearchPickerModal extends ConsumerStatefulWidget {
  final bool isPurchase;
  const ItemSearchPickerModal({Key? key, this.isPurchase = false}) : super(key: key);

  static Future<Item?> show(BuildContext context, {bool isPurchase = false}) {
    return showDialog<Item>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 550,
          height: 600,
          child: ItemSearchPickerModal(isPurchase: isPurchase),
        ),
      ),
    );
  }

  @override
  ConsumerState<ItemSearchPickerModal> createState() => _ItemSearchPickerModalState();
}

class _ItemSearchPickerModalState extends ConsumerState<ItemSearchPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(filteredItemsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.isPurchase ? 'Select Product for Purchase' : 'Select Product for Sales'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Field & Quick Add Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search product name, code, barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Items Catalog List
          Expanded(
            child: itemsAsync.when(
              data: (allItems) {
                final filteredList = allItems.where((item) {
                  if (_searchQuery.isEmpty) return true;
                  final name = item.itemName?.toLowerCase() ?? '';
                  final code = item.itemCode?.toLowerCase() ?? '';
                  final barcode = item.barcode?.toLowerCase() ?? '';
                  return name.contains(_searchQuery) || code.contains(_searchQuery) || barcode.contains(_searchQuery);
                }).toList();

                final bool exactMatchExists = allItems.any((i) => i.itemName?.trim().toLowerCase() == _searchQuery);

                return Column(
                  children: [
                    // Create New Item Banner (Shown if query is typed or no exact match)
                    if (_searchQuery.isNotEmpty && !exactMatchExists)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Material(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary,
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                            title: Text(
                              'Create New Product: "${_searchController.text.trim()}"',
                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                            subtitle: const Text('Not in catalog? Click here to quick create and select it.'),
                            onTap: () async {
                              final created = await AddItemSheet.show(context, initialName: _searchController.text.trim());
                              if (created != null && mounted) {
                                Navigator.pop(context, created);
                              }
                            },
                          ),
                        ),
                      ),

                    if (filteredList.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 56, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text('No products matching "${_searchController.text}"', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: Text('Create "${_searchController.text.trim()}"'),
                                onPressed: () async {
                                  final created = await AddItemSheet.show(context, initialName: _searchController.text.trim());
                                  if (created != null && mounted) {
                                    Navigator.pop(context, created);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: filteredList.length + 1,
                          itemBuilder: (context, index) {
                            if (index == filteredList.length) {
                              // Always present "Create New Product" at the bottom of the catalog list
                              return Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 20),
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('Create Another New Product'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () async {
                                    final created = await AddItemSheet.show(context, initialName: _searchController.text.trim());
                                    if (created != null && mounted) {
                                      Navigator.pop(context, created);
                                    }
                                  },
                                ),
                              );
                            }

                            final item = filteredList[index];
                            final rate = widget.isPurchase ? (item.buyRate ?? item.sellRate ?? 0.0) : (item.sellRate ?? 0.0);

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                                  child: Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary, size: 18),
                                ),
                                title: Text(
                                  item.itemName ?? 'Unnamed Item',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  'Code: ${item.itemCode ?? "N/A"} | Price: ₹${rate.toStringAsFixed(2)} | Stock: ${item.currentStock?.toInt() ?? 0}',
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  child: const Text('Select'),
                                  onPressed: () {
                                    Navigator.pop(context, item);
                                  },
                                ),
                                onTap: () {
                                  Navigator.pop(context, item);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load items: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}
