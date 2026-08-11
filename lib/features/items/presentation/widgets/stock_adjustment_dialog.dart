import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/data/local/collections/stock_adjustment_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class StockAdjustmentDialog extends ConsumerStatefulWidget {
  final Item? initialItem;
  final StockAdjustment? existingAdjustment;

  const StockAdjustmentDialog({
    Key? key,
    this.initialItem,
    this.existingAdjustment,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context, {
    Item? initialItem,
    StockAdjustment? existingAdjustment,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => StockAdjustmentDialog(
        initialItem: initialItem,
        existingAdjustment: existingAdjustment,
      ),
    );
  }

  @override
  ConsumerState<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _rateController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  Item? _selectedItem;
  bool _isStockIn = true;
  String _selectedUnit = 'PCS';
  DateTime _adjustmentDate = DateTime.now();
  bool _isSaving = false;

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initialItem;

    final adj = widget.existingAdjustment;
    if (adj != null) {
      _isStockIn = adj.adjustmentType == 'Add' || adj.adjustmentType == 'Stock In';
      _qtyController.text = adj.quantity?.toString() ?? '';
      _rateController.text = adj.ratePerUnit?.toString() ?? '';
      _reasonController.text = adj.reason ?? '';
      _notesController.text = adj.notes ?? '';
      _selectedUnit = adj.unit ?? 'PCS';
      _adjustmentDate = adj.adjustmentDate ?? DateTime.now();
    } else if (widget.initialItem != null) {
      final buyRate = widget.initialItem!.buyRate ?? 0.0;
      if (buyRate > 0) {
        _rateController.text = buyRate.toString();
      }
      _selectedUnit = widget.initialItem!.primaryUnitName ?? widget.initialItem!.unit.value?.shortName ?? 'PCS';
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _rateController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _calculatedTotal {
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    return qty * rate;
  }

  Future<void> _saveAdjustment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product first.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final qty = double.parse(_qtyController.text);
      final rate = double.tryParse(_rateController.text) ?? (_selectedItem?.buyRate ?? 0.0);
      final reason = _reasonController.text.trim();
      final notes = _notesController.text.trim();
      final adjType = _isStockIn ? 'Stock In' : 'Stock Out';
      final isEditing = widget.existingAdjustment != null;

      final adj = widget.existingAdjustment ?? StockAdjustment();
      adj.uuid ??= const Uuid().v4();
      adj.itemUuid = _selectedItem!.uuid;
      adj.itemId = _selectedItem!.id;
      adj.itemName = _selectedItem!.itemName;
      adj.adjustmentType = adjType;
      adj.quantity = qty;
      adj.unit = _selectedUnit;
      adj.ratePerUnit = rate;
      adj.totalValue = qty * rate;
      adj.adjustmentDate = _adjustmentDate;
      adj.reason = reason;
      adj.notes = notes.isNotEmpty ? notes : null;
      adj.updatedAt = DateTime.now();
      adj.createdAt = isEditing ? adj.createdAt : DateTime.now();
      adj.isDeleted = false;
      adj.isSynced = false;

      await isar.writeTxn(() async {
        final id = await isar.collection<StockAdjustment>().put(adj);
        adj.id = id;

        await isar.syncQueues.put(SyncQueue()
          ..uuid = const Uuid().v4()
          ..entityType = 'StockAdjustment'
          ..entityId = id
          ..entityUuid = adj.uuid
          ..operation = isEditing ? 'Update' : 'Insert'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now());
      });

      try {
        ref.read(syncServiceProvider).syncPendingChangesQuietly();
      } catch (_) {}

      await ref.read(syncServiceProvider).recalculateAllItemStocksFromTransactions();
      ref.invalidate(filteredItemsProvider);
      ref.invalidate(lowStockAlertProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Stock adjustment updated.' : 'Stock adjustment saved successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.error('Failed to save stock adjustment', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save adjustment: $e'),
            backgroundColor: Colors.red,
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
    final isEditing = widget.existingAdjustment != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEditing ? Icons.edit_note_rounded : Icons.swap_vert_circle_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Edit Stock Adjustment' : 'Stock Adjustment',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _selectedItem?.itemName ?? 'Adjust inventory stock & valuation',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Searchable Product Autocomplete Field
              itemsAsync.when(
                data: (itemsList) {
                  if (itemsList.isEmpty) {
                    return const Text('No products available.');
                  }

                  if (_selectedItem == null) {
                    if (widget.existingAdjustment != null) {
                      final adjUuid = widget.existingAdjustment!.itemUuid;
                      final adjId = widget.existingAdjustment!.itemId;
                      _selectedItem = itemsList.firstWhere(
                        (i) => i.uuid == adjUuid || i.id == adjId,
                        orElse: () => itemsList.first,
                      );
                    } else if (widget.initialItem != null) {
                      _selectedItem = itemsList.firstWhere(
                        (i) => i.uuid == widget.initialItem!.uuid || i.id == widget.initialItem!.id,
                        orElse: () => itemsList.first,
                      );
                    } else {
                      _selectedItem = itemsList.first;
                    }
                  }

                  return RawAutocomplete<Item>(
                    initialValue: TextEditingValue(text: _selectedItem?.itemName ?? ''),
                    displayStringForOption: (item) => '${item.itemName ?? "Unnamed"} (${item.itemCode ?? "No Code"})',
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final q = textEditingValue.text.trim().toLowerCase();
                      if (q.isEmpty) return itemsList;
                      return itemsList.where((i) {
                        final name = i.itemName?.toLowerCase() ?? '';
                        final code = i.itemCode?.toLowerCase() ?? '';
                        return name.contains(q) || code.contains(q);
                      });
                    },
                    onSelected: (item) {
                      setState(() {
                        _selectedItem = item;
                        final buyRate = item.buyRate ?? 0.0;
                        if (_rateController.text.isEmpty || _rateController.text == '0' || _rateController.text == '0.0') {
                          _rateController.text = buyRate > 0 ? buyRate.toString() : '';
                        }
                        _selectedUnit = item.primaryUnitName ?? item.unit.value?.shortName ?? 'PCS';
                      });
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 320),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final item = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  title: Text(item.itemName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Code: ${item.itemCode ?? "N/A"} | Stock: ${item.currentStock?.toInt() ?? 0}'),
                                  onTap: () => onSelected(item),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Select Product *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                          suffixIcon: controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    controller.clear();
                                    setState(() => _selectedItem = null);
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Error loading products: $err'),
              ),
              const SizedBox(height: 16),

              // Stock In / Stock Out Segmented Button
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Stock In (+)'),
                    icon: Icon(Icons.add_circle_outline, color: Colors.green),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Stock Out (-)'),
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                  ),
                ],
                selected: {_isStockIn},
                onSelectionChanged: (val) {
                  setState(() => _isStockIn = val.first);
                },
              ),
              const SizedBox(height: 16),

              // Quantity & Unit Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final numVal = double.tryParse(v);
                        if (numVal == null || numVal <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Builder(
                      builder: (context) {
                        final pUnit = _selectedItem?.primaryUnitName ?? _selectedItem?.unit.value?.shortName ?? 'PCS';
                        final sUnit = _selectedItem?.secondaryUnit;

                        final unitOptions = [pUnit];
                        if (sUnit != null && sUnit.isNotEmpty && sUnit != pUnit) {
                          unitOptions.add(sUnit);
                        }

                        if (!unitOptions.contains(_selectedUnit)) {
                          _selectedUnit = pUnit;
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit *',
                            border: OutlineInputBorder(),
                          ),
                          items: unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedUnit = val);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rate per Unit & Live Total Valuation Card
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Rate per Unit (₹)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Value:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(
                            _currencyFormat.format(_calculatedTotal),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Adjustment Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _adjustmentDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _adjustmentDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Adjustment Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(DateFormat('dd MMMM yyyy').format(_adjustmentDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Reason
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Adjustment *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Audit, Damage, Manual Addition...',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Reason is required' : null,
              ),
              const SizedBox(height: 16),

              // Additional Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Internal Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveAdjustment,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_rounded),
          label: Text(isEditing ? 'Save Changes' : 'Apply Adjustment'),
        ),
      ],
    );
  }
}
