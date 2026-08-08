import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_edit_item_screen.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/invoice_detail_screen.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/screens/add_edit_purchase_screen.dart';
import 'package:business_sahaj_erp/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class _ItemTransaction {
  final String type; // 'Sale', 'Purchase', 'Order'
  final DateTime date;
  final String title;
  final String partyName;
  final double quantity;
  final String unit;
  final double rate;
  final double totalAmount;
  final String targetUuid;

  _ItemTransaction({
    required this.type,
    required this.date,
    required this.title,
    required this.partyName,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.totalAmount,
    required this.targetUuid,
  });
}

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemUuid;

  const ItemDetailScreen({Key? key, required this.itemUuid}) : super(key: key);

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _isLoading = false;
  Item? _item;
  List<_ItemTransaction> _itemTransactions = [];

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      final isar = ref.read(databaseServiceProvider).isar;
      final fetchedItem = await repo.getByUuid(widget.itemUuid);

      if (fetchedItem != null) {
        try { await fetchedItem.category.load(); } catch (_) {}
        try { await fetchedItem.brand.load(); } catch (_) {}
        try { await fetchedItem.unit.load(); } catch (_) {}

        final List<_ItemTransaction> txs = [];
        final itemName = fetchedItem.itemName?.trim().toLowerCase() ?? '';
        final itemId = fetchedItem.id;

        // 1. Fetch Sales Invoices for this item
        final allInvItems = await isar.invoiceItems.filter().isDeletedEqualTo(false).findAll();
        final matchedInvItems = allInvItems.where((ii) => ii.itemId == itemId || (ii.itemName != null && ii.itemName!.trim().toLowerCase() == itemName)).toList();

        for (var ii in matchedInvItems) {
          Invoice? inv;
          try { await ii.invoice.load(); inv = ii.invoice.value; } catch (_) {}
          inv ??= ii.parentInvoiceId != null ? await isar.invoices.get(ii.parentInvoiceId!) : null;

          if (inv != null && !inv.isDeleted) {
            txs.add(_ItemTransaction(
              type: 'Sale',
              date: inv.invoiceDate ?? inv.createdAt,
              title: 'Sales Invoice #${inv.invoiceNumber}',
              partyName: inv.partyName ?? 'Customer',
              quantity: ii.quantity ?? 1.0,
              unit: (ii.unit != null && ii.unit!.isNotEmpty && ii.unit != 'PCS')
                  ? ii.unit!
                  : (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? ii.unit ?? 'PCS'),
              rate: ii.rate ?? 0.0,
              totalAmount: ii.totalAmount ?? (ii.quantity ?? 1.0) * (ii.rate ?? 0.0),
              targetUuid: inv.uuid ?? inv.id.toString(),
            ));
          }
        }

        // 2. Fetch Purchase Bills for this item
        final allPurItems = await isar.purchaseItems.filter().isDeletedEqualTo(false).findAll();
        final matchedPurItems = allPurItems.where((pi) => pi.itemId == itemId || (pi.itemName != null && pi.itemName!.trim().toLowerCase() == itemName)).toList();

        for (var pi in matchedPurItems) {
          Purchase? pur;
          try { await pi.purchase.load(); pur = pi.purchase.value; } catch (_) {}
          pur ??= pi.purchaseId != null ? await isar.purchases.get(pi.purchaseId!) : null;

          if (pur != null && !pur.isDeleted) {
            txs.add(_ItemTransaction(
              type: 'Purchase',
              date: pur.purchaseDate ?? pur.createdAt,
              title: 'Purchase Bill #${pur.purchaseNumber}${pur.supplierInvoiceNumber != null && pur.supplierInvoiceNumber!.isNotEmpty ? " (Supp: ${pur.supplierInvoiceNumber})" : ""}',
              partyName: pur.partyName ?? 'Supplier',
              quantity: pi.quantity ?? 1.0,
              unit: (pi.unit != null && pi.unit!.isNotEmpty && pi.unit != 'PCS')
                  ? pi.unit!
                  : (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? pi.unit ?? 'PCS'),
              rate: pi.rate ?? 0.0,
              totalAmount: pi.totalAmount ?? (pi.quantity ?? 1.0) * (pi.rate ?? 0.0),
              targetUuid: pur.uuid ?? pur.id.toString(),
            ));
          }
        }

        // 3. Fetch Orders for this item
        final allOrdItems = await isar.orderItems.filter().isDeletedEqualTo(false).findAll();
        final matchedOrdItems = allOrdItems.where((oi) => oi.itemId == itemId || (oi.itemName != null && oi.itemName!.trim().toLowerCase() == itemName)).toList();

        for (var oi in matchedOrdItems) {
          Order? ord;
          try { await oi.order.load(); ord = oi.order.value; } catch (_) {}

          if (ord != null && !ord.isDeleted) {
            txs.add(_ItemTransaction(
              type: 'Order',
              date: ord.orderDate ?? ord.createdAt,
              title: 'Sales Order #${ord.orderNumber}',
              partyName: ord.partyName ?? 'Customer',
              quantity: oi.quantity ?? 1.0,
              unit: (oi.unit != null && oi.unit!.isNotEmpty && oi.unit != 'PCS')
                  ? oi.unit!
                  : (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? oi.unit ?? 'PCS'),
              rate: oi.rate ?? 0.0,
              totalAmount: oi.totalAmount ?? (oi.quantity ?? 1.0) * (oi.rate ?? 0.0),
              targetUuid: ord.uuid ?? ord.id.toString(),
            ));
          }
        }

        // Sort descending by date
        txs.sort((a, b) => b.date.compareTo(a.date));

        setState(() {
          _item = fetchedItem;
          _itemTransactions = txs;
        });
      }
    } catch (e) {
      logger.error('Failed to load item detail', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${_item?.itemName}"? This can be undone later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && _item != null) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(itemRepositoryProvider);
        await repo.delete(_item!.id);
        ref.invalidate(filteredItemsProvider);
        ref.invalidate(lowStockAlertProvider);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product "${_item?.itemName}" deleted.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        logger.error('Failed to delete item', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete product: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _adjustStockDialog() async {
    final qtyController = TextEditingController();
    final reasonController = TextEditingController();
    var isStockIn = true;
    final formKey = GlobalKey<FormState>();

    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adjust Inventory Stock'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Stock In (+)'),
                            icon: Icon(Icons.add),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Stock Out (-)'),
                            icon: Icon(Icons.remove),
                          ),
                        ],
                        selected: {isStockIn},
                        onSelectionChanged: (val) {
                          setDialogState(() => isStockIn = val.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null || val <= 0) return 'Enter value > 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Adjustment',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. Purchase, Damage, Audit...',
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (success == true && _item != null) {
      setState(() => _isLoading = true);
      try {
        final stockService = ref.read(stockServiceProvider);
        final adjustment = double.parse(qtyController.text);
        final finalQty = isStockIn ? adjustment : -adjustment;
        
        await stockService.adjustStock(
          _item!,
          finalQty,
          reasonController.text.trim(),
        );

        await _loadItem();
        ref.invalidate(filteredItemsProvider);
        ref.invalidate(lowStockAlertProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock levels adjusted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        logger.error('Failed to adjust stock', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Adjustment failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _openTransactionDetail(_ItemTransaction tx) {
    if (tx.type == 'Sale') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceDetailScreen(invoiceUuid: tx.targetUuid),
        ),
      ).then((_) => _loadItem());
    } else if (tx.type == 'Purchase') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditPurchaseScreen(purchaseUuid: tx.targetUuid),
        ),
      ).then((_) => _loadItem());
    } else if (tx.type == 'Order') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(orderUuid: tx.targetUuid),
        ),
      ).then((_) => _loadItem());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockService = ref.watch(stockServiceProvider);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Product not found.')),
      );
    }

    final item = _item!;
    final isLow = stockService.isLowStock(item);
    final isOut = stockService.isOutOfStock(item);

    // Calculate Primary vs Secondary stock breakdown
    final double primaryStock = item.currentStock ?? 0.0;
    final String primaryUnitName = item.primaryUnitName ?? item.unit.value?.shortName ?? item.unit.value?.unitName ?? 'PCS';
    final String? secUnitName = item.secondaryUnit;
    final double? convFactor = item.conversionFactor;

    String stockBreakdownText = '$primaryStock $primaryUnitName';
    if (secUnitName != null && secUnitName.isNotEmpty && convFactor != null && convFactor > 1.0) {
      final double secStock = primaryStock * convFactor;
      stockBreakdownText = '$primaryStock $primaryUnitName  (${secStock.toStringAsFixed(1)} $secUnitName)';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(item.itemName ?? 'Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditItemScreen(itemUuid: item.uuid),
                ),
              );
              _loadItem();
            },
            tooltip: 'Edit Product',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _deleteItem,
            tooltip: 'Delete Product',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageHeader(item, theme),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName ?? '',
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Code: ${item.itemCode ?? "N/A"} | HSN: ${item.hsnCode ?? "N/A"}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      _buildStockBadge(isOut, isLow, theme, item),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stock Level Card with Dual Unit Conversion
                  Card(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2, color: theme.colorScheme.primary, size: 36),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Stock Level:',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stockBreakdownText,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reorder Level: ${item.reorderLevel ?? 0.0} | Min: ${item.minimumStock ?? 0.0}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.swap_vert, size: 18),
                            label: const Text('Adjust'),
                            onPressed: _adjustStockDialog,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pricing Info Table
                  _buildSectionTitle('Pricing & Taxation', theme),
                  const SizedBox(height: 12),
                  _buildDetailTable([
                    _DetailRow('Selling Price (Retail)', _currencyFormat.format(item.sellRate ?? 0.0), isBold: true),
                    _DetailRow('Wholesale Price', _currencyFormat.format(item.wholesaleRate ?? 0.0)),
                    _DetailRow('Min Selling Price', _currencyFormat.format(item.minimumSellingPrice ?? 0.0)),
                    _DetailRow('MRP', _currencyFormat.format(item.mrp ?? 0.0)),
                    _DetailRow('Buy/Purchase Price', _currencyFormat.format(item.buyRate ?? 0.0)),
                    _DetailRow('GST Status', item.gstApplicable ? 'Applicable (${item.gstRate ?? 0.0}%)' : 'Exempt / Non-GST'),
                    _DetailRow('HSN Code', item.hsnCode ?? 'N/A'),
                  ], theme),
                  const SizedBox(height: 24),

                  // Units & Conversion Specs
                  _buildSectionTitle('Units & Unit Conversion', theme),
                  const SizedBox(height: 12),
                  _buildDetailTable([
                    _DetailRow('Category', item.category.value?.categoryName ?? 'N/A'),
                    _DetailRow('Brand', item.brand.value?.brandName ?? 'N/A'),
                    _DetailRow('Primary Unit', item.primaryUnitName ?? item.unit.value?.unitName ?? item.unit.value?.shortName ?? 'N/A'),
                    _DetailRow('Secondary Unit', item.secondaryUnit != null && item.secondaryUnit!.isNotEmpty ? item.secondaryUnit! : 'None'),
                    _DetailRow('Conversion Factor', (item.conversionFactor != null && item.conversionFactor! > 1.0) ? '1 ${item.primaryUnitName ?? item.unit.value?.shortName ?? "Box"} = ${item.conversionFactor} ${item.secondaryUnit}' : '1 : 1'),
                  ], theme),
                  const SizedBox(height: 24),

                  // CLICKABLE ITEM TRANSACTIONS SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Item Transactions (${_itemTransactions.length})', theme),
                      Text('Click to View Detail', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _itemTransactions.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('No sales, purchases, or orders recorded for this item yet.'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _itemTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = _itemTransactions[index];
                            final dateStr = DateFormat('dd MMM yyyy').format(tx.date);

                            Color badgeColor = Colors.green;
                            IconData badgeIcon = Icons.call_made_rounded;

                            if (tx.type == 'Purchase') {
                              badgeColor = Colors.blue;
                              badgeIcon = Icons.call_received_rounded;
                            } else if (tx.type == 'Order') {
                              badgeColor = Colors.orange;
                              badgeIcon = Icons.shopping_bag_outlined;
                            }

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                              ),
                              child: ListTile(
                                onTap: () => _openTransactionDetail(tx),
                                leading: CircleAvatar(
                                  backgroundColor: badgeColor.withOpacity(0.12),
                                  child: Icon(badgeIcon, color: badgeColor, size: 20),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tx.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _currencyFormat.format(tx.totalAmount),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor, fontSize: 14),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Party: ${tx.partyName}  •  $dateStr',
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                      Text(
                                        '${tx.quantity} ${tx.unit}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader(Item item, ThemeData theme) {
    final images = item.imagePaths ?? [];
    if (images.isEmpty) {
      return Container(
        height: 180,
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          final file = File(images[index]);
          return FutureBuilder<bool>(
            future: file.exists(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return Image.file(file, fit: BoxFit.contain);
              } else {
                return Container(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  child: const Center(child: Text('Image file not found locally.')),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildStockBadge(bool isOut, bool isLow, ThemeData theme, Item item) {
    Color color = Colors.green;
    String label = 'In Stock';
    if (isOut) {
      color = Colors.red;
      label = 'Out of Stock';
    } else if (isLow) {
      color = Colors.orange;
      label = 'Low Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildDetailTable(List<_DetailRow> rows, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  row.label,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  row.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: row.isBold ? FontWeight.bold : FontWeight.normal,
                    color: row.isBold ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  final bool isBold;
  _DetailRow(this.label, this.value, {this.isBold = false});
}
