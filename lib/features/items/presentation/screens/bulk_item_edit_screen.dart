import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:isar/isar.dart';

class BulkItemEditScreen extends ConsumerStatefulWidget {
  const BulkItemEditScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BulkItemEditScreen> createState() => _BulkItemEditScreenState();
}

class _BulkItemEditScreenState extends ConsumerState<BulkItemEditScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, Map<String, dynamic>> _editedItemsMap = {};
  bool _isSaving = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFieldChanged(Item item, String fieldName, dynamic val) {
    if (!_editedItemsMap.containsKey(item.id)) {
      _editedItemsMap[item.id] = {
        'id': item.id,
        'uuid': item.uuid,
        'item': item,
      };
    }
    _editedItemsMap[item.id]![fieldName] = val;
    setState(() {});
  }

  Future<void> _saveAllBulkChanges() async {
    if (_editedItemsMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No item edits to save.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      int updatedCount = 0;

      await isar.writeTxn(() async {
        for (var entry in _editedItemsMap.values) {
          final Item originalItem = entry['item'] as Item;
          final itemToSave = await isar.items.get(originalItem.id) ?? originalItem;

          if (entry.containsKey('itemName')) itemToSave.itemName = entry['itemName'] as String;
          if (entry.containsKey('primaryUnitName')) {
            final pUnit = (entry['primaryUnitName'] as String).trim();
            itemToSave.primaryUnitName = pUnit;
            if (pUnit.isNotEmpty) {
              final unitRepo = ref.read(unitRepositoryProvider);
              final allUnits = await unitRepo.getAll();
              var matched = allUnits.where((u) => u.shortName?.trim().toLowerCase() == pUnit.toLowerCase() || u.unitName?.trim().toLowerCase() == pUnit.toLowerCase()).firstOrNull;
              if (matched == null) {
                matched = Unit()
                  ..uuid = const Uuid().v4()
                  ..unitName = pUnit
                  ..shortName = pUnit
                  ..createdAt = DateTime.now()
                  ..updatedAt = DateTime.now();
                matched.id = await isar.units.put(matched);
              }
              itemToSave.unit.value = matched;
            }
          }
          if (entry.containsKey('secondaryUnit')) {
            itemToSave.secondaryUnit = (entry['secondaryUnit'] as String).trim();
          }
          if (entry.containsKey('conversionFactor')) {
            itemToSave.conversionFactor = double.tryParse(entry['conversionFactor'].toString()) ?? 1.0;
          }
          if (entry.containsKey('sellRate')) itemToSave.sellRate = double.tryParse(entry['sellRate'].toString());
          if (entry.containsKey('wholesaleRate')) itemToSave.wholesaleRate = double.tryParse(entry['wholesaleRate'].toString());
          if (entry.containsKey('mrp')) itemToSave.mrp = double.tryParse(entry['mrp'].toString());
          if (entry.containsKey('buyRate')) itemToSave.buyRate = double.tryParse(entry['buyRate'].toString());
          if (entry.containsKey('gstRate')) itemToSave.gstRate = double.tryParse(entry['gstRate'].toString());
          if (entry.containsKey('hsnCode')) itemToSave.hsnCode = entry['hsnCode'] as String;
          if (entry.containsKey('currentStock')) itemToSave.currentStock = double.tryParse(entry['currentStock'].toString());

          itemToSave.updatedAt = DateTime.now();
          itemToSave.isSynced = false;
          itemToSave.version += 1;

          await isar.items.put(itemToSave);
          updatedCount++;
        }
      });

      _editedItemsMap.clear();
      ref.invalidate(filteredItemsProvider);

      // Lightweight non-blocking quiet background sync
      try {
        ref.read(syncServiceProvider).syncPendingChangesQuietly();
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Bulk updated $updatedCount items successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      logger.error('Failed to bulk save items', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save bulk edits: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(filteredItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Item Editor'),
        actions: [
          if (_editedItemsMap.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: Chip(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  label: Text(
                    '${_editedItemsMap.length} Edited',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAllBulkChanges,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save Bulk Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : itemsAsync.when(
              data: (items) {
                final filtered = _searchQuery.isEmpty
                    ? items
                    : items.where((i) {
                        final name = i.itemName?.toLowerCase() ?? '';
                        final code = i.itemCode?.toLowerCase() ?? '';
                        final hsn = i.hsnCode?.toLowerCase() ?? '';
                        final q = _searchQuery.toLowerCase();
                        return name.contains(q) || code.contains(q) || hsn.contains(q);
                      }).toList();

                return Column(
                  children: [
                    // Search & Helper Header Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search items by name, code or HSN to bulk edit...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _editedItemsMap.isEmpty ? null : _saveAllBulkChanges,
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text('Save (${_editedItemsMap.length})'),
                          ),
                        ],
                      ),
                    ),

                    // Spreadsheet Style Editable Table List
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No items match search filter.'))
                          : SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 16,
                                  dataRowMaxHeight: 65,
                                  headingRowColor: MaterialStateProperty.all(
                                    theme.colorScheme.primaryContainer.withOpacity(0.4),
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Primary Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Secondary Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Conversion Factor', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Selling Rate (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Wholesale (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('MRP (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Buy Rate (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('GST %', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('HSN Code', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Stock Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: filtered.map((item) {
                                    final isEdited = _editedItemsMap.containsKey(item.id);
                                    return DataRow(
                                      color: isEdited
                                          ? MaterialStateProperty.all(Colors.amber.withOpacity(0.12))
                                          : null,
                                      cells: [
                                        DataCell(
                                          SizedBox(
                                            width: 160,
                                            child: TextFormField(
                                              initialValue: item.itemName ?? '',
                                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                              onChanged: (v) => _onFieldChanged(item, 'itemName', v),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 100,
                                            child: TextFormField(
                                              initialValue: item.primaryUnitName ?? item.unit.value?.shortName ?? 'PCS',
                                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                              onChanged: (v) => _onFieldChanged(item, 'primaryUnitName', v),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 100,
                                            child: TextFormField(
                                              initialValue: item.secondaryUnit ?? '',
                                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'None'),
                                              onChanged: (v) => _onFieldChanged(item, 'secondaryUnit', v),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 90,
                                            child: TextFormField(
                                              initialValue: (item.conversionFactor ?? 1.0).toString(),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                              onChanged: (v) => _onFieldChanged(item, 'conversionFactor', v),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 90,
                                            child: TextFormField(
                                              initialValue: (item.sellRate ?? 0.0).toString(),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                              onChanged: (v) => _onFieldChanged(item, 'sellRate', v),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 90,
                                            child: TextFormField(
                                              initialValue: (item.wholesaleRate ?? 0.0).toString(),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                              onChanged: (v) => _onFieldChanged(item, 'wholesaleRate', v),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 90,
                                            child: TextFormField(
                                              initialValue: (item.mrp ?? 0.0).toString(),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                              onChanged: (v) => _onFieldChanged(item, 'mrp', v),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 90,
                                            child: TextFormField(
                                              initialValue: (item.buyRate ?? 0.0).toString(),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                              onChanged: (v) => _onFieldChanged(item, 'buyRate', v),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 70,
                                            child: TextFormField(
                                              initialValue: (item.gstRate ?? 18.0).toString(),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                              onChanged: (v) => _onFieldChanged(item, 'gstRate', v),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 100,
                                            child: TextFormField(
                                              initialValue: item.hsnCode ?? '',
                                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                              onChanged: (v) => _onFieldChanged(item, 'hsnCode', v),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 80,
                                            child: TextFormField(
                                              initialValue: (item.currentStock ?? 0.0).toString(),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                              onChanged: (v) => _onFieldChanged(item, 'currentStock', v),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading items: $e')),
            ),
    );
  }
}
