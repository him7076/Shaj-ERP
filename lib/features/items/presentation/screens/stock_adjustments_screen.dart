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
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class StockAdjustmentsScreen extends ConsumerStatefulWidget {
  const StockAdjustmentsScreen({Key? key}) : super(Key: key);

  @override
  ConsumerState<StockAdjustmentsScreen> createState() => _StockAdjustmentsScreenState();
}

class _StockAdjustmentsScreenState extends ConsumerState<StockAdjustmentsScreen> {
  bool _isLoading = false;
  List<StockAdjustment> _allAdjustments = [];
  String _searchQuery = '';
  String _typeFilter = 'All'; // 'All', 'Stock In', 'Stock Out'
  DateTimeRange? _dateRange;

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadAdjustments();
  }

  Future<void> _loadAdjustments() async {
    setState(() => _isLoading = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final list = await isar.collection<StockAdjustment>()
          .filter()
          .isDeletedEqualTo(false)
          .findAll();

      list.sort((a, b) => (b.adjustmentDate ?? b.createdAt).compareTo(a.adjustmentDate ?? a.createdAt));

      setState(() {
        _allAdjustments = list;
      });
    } catch (e) {
      logger.error('Failed to load stock adjustments', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<StockAdjustment> get _filteredAdjustments {
    return _allAdjustments.where((adj) {
      // 1. Search Query Filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final nameMatch = adj.itemName?.toLowerCase().contains(q) ?? false;
        final reasonMatch = adj.reason?.toLowerCase().contains(q) ?? false;
        final notesMatch = adj.notes?.toLowerCase().contains(q) ?? false;
        if (!nameMatch && !reasonMatch && !notesMatch) return false;
      }

      // 2. Type Filter
      final isAdd = adj.adjustmentType == 'Add' || adj.adjustmentType == 'Stock In';
      if (_typeFilter == 'Stock In' && !isAdd) return false;
      if (_typeFilter == 'Stock Out' && isAdd) return false;

      // 3. Date Range Filter
      if (_dateRange != null && adj.adjustmentDate != null) {
        final d = adj.adjustmentDate!;
        if (d.isBefore(_dateRange!.start.subtract(const Duration(days: 1))) ||
            d.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _deleteAdjustment(StockAdjustment adj) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stock Adjustment'),
        content: Text('Are you sure you want to delete adjustment for "${adj.itemName}"? Item stock will be recalculated.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final isar = ref.read(databaseServiceProvider).isar;
        await isar.writeTxn(() async {
          adj.isDeleted = true;
          adj.updatedAt = DateTime.now();
          adj.isSynced = false;
          await isar.collection<StockAdjustment>().put(adj);

          await isar.syncQueues.put(SyncQueue()
            ..uuid = const Uuid().v4()
            ..entityType = 'StockAdjustment'
            ..entityId = adj.id
            ..entityUuid = adj.uuid
            ..operation = 'Delete'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now());
        });

        try {
          ref.read(syncServiceProvider).syncPendingChangesQuietly();
        } catch (_) {}

        await ref.read(syncServiceProvider).recalculateAllItemStocksFromTransactions();
        ref.invalidate(filteredItemsProvider);
        ref.invalidate(lowStockAlertProvider);
        await _loadAdjustments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock adjustment deleted.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        logger.error('Failed to delete stock adjustment', e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showDetailModal(StockAdjustment adj) {
    final theme = Theme.of(context);
    final isAdd = adj.adjustmentType == 'Add' || adj.adjustmentType == 'Stock In';
    final dateStr = adj.adjustmentDate != null ? DateFormat('dd MMMM yyyy').format(adj.adjustmentDate!) : 'N/A';
    final rate = adj.ratePerUnit ?? 0.0;
    final totalVal = adj.totalValue ?? (adj.quantity ?? 0.0) * rate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAdd ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  color: isAdd ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Adjustment Details',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModalRow('Product Name', adj.itemName ?? 'N/A', theme),
                  _buildModalRow('Adjustment Type', isAdd ? 'Stock In (+)' : 'Stock Out (-)', theme, isColor: true, color: isAdd ? Colors.green : Colors.red),
                  _buildModalRow('Quantity & Unit', '${adj.quantity ?? 0.0} ${adj.unit ?? ""}', theme),
                  _buildModalRow('Rate per Unit', _currencyFormat.format(rate), theme),
                  _buildModalRow('Total Valuation Value', _currencyFormat.format(totalVal), theme, isBold: true),
                  _buildModalRow('Adjustment Date', dateStr, theme),
                  _buildModalRow('Reason', adj.reason ?? 'N/A', theme),
                  if (adj.notes != null && adj.notes!.isNotEmpty)
                    _buildModalRow('Notes', adj.notes!, theme),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
              onPressed: () async {
                Navigator.pop(dialogContext);
                _deleteAdjustment(adj);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Adjustment'),
              onPressed: () {
                Navigator.pop(dialogContext);
                _openAddEditDialog(existingAdjustment: adj);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildModalRow(String label, String value, ThemeData theme, {bool isBold = false, bool isColor = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isColor ? color : (isBold ? theme.colorScheme.primary : theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddEditDialog({StockAdjustment? existingAdjustment}) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => AddEditStockAdjustmentDialog(existingAdjustment: existingAdjustment),
    );

    if (success == true) {
      await _loadAdjustments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final filtered = _filteredAdjustments;

    // Aggregate Banner Metrics
    double stockInQty = 0.0;
    double stockOutQty = 0.0;
    double netValuation = 0.0;

    for (var adj in filtered) {
      final isAdd = adj.adjustmentType == 'Add' || adj.adjustmentType == 'Stock In';
      final qty = adj.quantity ?? 0.0;
      final val = adj.totalValue ?? (qty * (adj.ratePerUnit ?? 0.0));

      if (isAdd) {
        stockInQty += qty;
        netValuation += val;
      } else {
        stockOutQty += qty;
        netValuation -= val;
      }
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Stock Adjustments', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Adjustments',
            onPressed: _loadAdjustments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Stock Adjustment'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Bar Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search product name, reason...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (val) {
                              setState(() => _searchQuery = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(Icons.date_range_rounded, size: 18, color: _dateRange != null ? theme.colorScheme.primary : null),
                          label: Text(_dateRange == null ? 'Date' : '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}'),
                          onPressed: () async {
                            if (_dateRange != null) {
                              setState(() => _dateRange = null);
                            } else {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _dateRange = picked);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(value: 'All', label: Text('All Adjustments')),
                        ButtonSegment<String>(value: 'Stock In', label: Text('Stock In (+)')),
                        ButtonSegment<String>(value: 'Stock Out', label: Text('Stock Out (-)')),
                      ],
                      selected: {_typeFilter},
                      onSelectionChanged: (val) {
                        setState(() => _typeFilter = val.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Valuation & Summary Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme: theme,
                    title: 'Total Stock In Qty',
                    value: '+${stockInQty.toStringAsFixed(1)}',
                    icon: Icons.add_circle_outline,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    theme: theme,
                    title: 'Total Stock Out Qty',
                    value: '-${stockOutQty.toStringAsFixed(1)}',
                    icon: Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      theme: theme,
                      title: 'Net Valuation Change',
                      value: _currencyFormat.format(netValuation),
                      icon: Icons.account_balance_wallet_outlined,
                      color: netValuation >= 0 ? Colors.indigo : Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Adjustments Data List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(child: Text('No stock adjustments found.', style: theme.textTheme.titleMedium))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final adj = filtered[index];
                          final isAdd = adj.adjustmentType == 'Add' || adj.adjustmentType == 'Stock In';
                          final dateStr = adj.adjustmentDate != null ? DateFormat('dd MMM yyyy').format(adj.adjustmentDate!) : 'N/A';
                          final rate = adj.ratePerUnit ?? 0.0;
                          final totalVal = adj.totalValue ?? ((adj.quantity ?? 0.0) * rate);
                          final color = isAdd ? Colors.green : Colors.red;

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                            ),
                            child: ListTile(
                              onTap: () => _showDetailModal(adj),
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.12),
                                child: Icon(
                                  isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                  color: color,
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      adj.itemName ?? 'Unnamed Item',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${isAdd ? "+" : "-"}${adj.quantity ?? 0.0} ${adj.unit ?? ""}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Reason: ${adj.reason ?? "Manual Adjustment"}',
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                      Text(
                                        'Valuation: ${_currencyFormat.format(totalVal)}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Date: $dateStr | Rate: ${_currencyFormat.format(rate)}',
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant), maxLines: 1),
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddEditStockAdjustmentDialog extends ConsumerStatefulWidget {
  final StockAdjustment? existingAdjustment;

  const AddEditStockAdjustmentDialog({Key? key, this.existingAdjustment}) : super(key: key);

  @override
  ConsumerState<AddEditStockAdjustmentDialog> createState() => _AddEditStockAdjustmentDialogState();
}

class _AddEditStockAdjustmentDialogState extends ConsumerState<AddEditStockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _rateController = TextEditingController();
  final _reasonController = TextEditingController();

  Item? _selectedItem;
  bool _isStockIn = true;
  String _selectedUnit = 'PCS';
  DateTime _adjustmentDate = DateTime.now();
  bool _isSaving = false;

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    final adj = widget.existingAdjustment;
    if (adj != null) {
      _isStockIn = adj.adjustmentType == 'Add' || adj.adjustmentType == 'Stock In';
      _qtyController.text = adj.quantity?.toString() ?? '';
      _rateController.text = adj.ratePerUnit?.toString() ?? '';
      _reasonController.text = adj.reason ?? '';
      _selectedUnit = adj.unit ?? 'PCS';
      _adjustmentDate = adj.adjustmentDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _rateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  double get _calculatedTotal {
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    return qty * rate;
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
          Icon(isEditing ? Icons.edit_note_rounded : Icons.add_chart_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(isEditing ? 'Edit Stock Adjustment' : 'New Stock Adjustment'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Selector Dropdown
              itemsAsync.when(
                data: (itemsList) {
                  if (itemsList.isEmpty) {
                    return const Text('No products available. Add items first.');
                  }

                  if (_selectedItem == null && widget.existingAdjustment != null) {
                    final adjItemUuid = widget.existingAdjustment!.itemUuid;
                    _selectedItem = itemsList.firstWhere(
                      (i) => i.uuid == adjItemUuid || i.id == widget.existingAdjustment!.itemId,
                      orElse: () => itemsList.first,
                    );
                  }

                  return DropdownButtonFormField<Item>(
                    value: _selectedItem,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Product *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    items: itemsList.map((item) {
                      return DropdownMenuItem<Item>(
                        value: item,
                        child: Text('${item.itemName ?? "Unnamed"} (Code: ${item.itemCode ?? "N/A"})'),
                      );
                    }).toList(),
                    onChanged: (item) {
                      if (item != null) {
                        setState(() {
                          _selectedItem = item;
                          final buyRate = item.buyRate ?? 0.0;
                          _rateController.text = buyRate > 0 ? buyRate.toString() : '';
                          _selectedUnit = item.primaryUnitName ?? item.unit.value?.shortName ?? 'PCS';
                        });
                      }
                    },
                    validator: (v) => v == null ? 'Please select a product' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Error loading products: $err'),
              ),
              const SizedBox(height: 16),

              // Stock In / Stock Out Toggle
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

              // Quantity & Unit
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

              // Rate per Unit & Live Total Valuation
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

              // Reason Input
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Adjustment *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Audit, Damage, Manual Addition...',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a reason' : null,
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
        ElevatedButton(
          onPressed: _isSaving ? null : _saveStockAdjustment,
          child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEditing ? 'Save Changes' : 'Apply Adjustment'),
        ),
      ],
    );
  }

  Future<void> _saveStockAdjustment() async {
    if (!_formKey.currentState!.validate() || _selectedItem == null) return;

    setState(() => _isSaving = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final qty = double.parse(_qtyController.text);
      final rate = double.tryParse(_rateController.text) ?? 0.0;
      final reason = _reasonController.text.trim();
      final isEditing = widget.existingAdjustment != null;

      final adj = widget.existingAdjustment ?? StockAdjustment();
      adj.uuid ??= const Uuid().v4();
      adj.itemUuid = _selectedItem!.uuid;
      adj.itemId = _selectedItem!.id;
      adj.itemName = _selectedItem!.itemName;
      adj.adjustmentType = _isStockIn ? 'Add' : 'Reduce';
      adj.quantity = qty;
      adj.unit = _selectedUnit;
      adj.ratePerUnit = rate;
      adj.totalValue = qty * rate;
      adj.adjustmentDate = _adjustmentDate;
      adj.reason = reason;
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
            content: Text(isEditing ? 'Stock adjustment updated successfully!' : 'Stock adjustment applied successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.error('Failed saving stock adjustment', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed saving adjustment: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
