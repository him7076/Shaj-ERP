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
import 'package:business_sahaj_erp/data/local/collections/stock_adjustment_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_edit_item_screen.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/invoice_detail_screen.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/screens/add_edit_purchase_screen.dart';
import 'package:business_sahaj_erp/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/stock_adjustments_screen.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class _ItemTransaction {
  final String type; // 'Sale', 'Purchase', 'Order', 'Adjustment'
  final DateTime date;
  final String title;
  final String partyName;
  final double quantity;
  final String unit;
  final double rate;
  final double totalAmount;
  final String targetUuid;
  final StockAdjustment? rawAdjustment;

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
    this.rawAdjustment,
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
        final itemUuid = fetchedItem.uuid;

        // 1. Indexed query for Sales Invoices
        final matchedInvItems = await isar.invoiceItems
            .filter()
            .isDeletedEqualTo(false)
            .and()
            .group((q) {
              var builder = q.itemIdEqualTo(fetchedItem.id);
              if (fetchedItem.itemName != null && fetchedItem.itemName!.isNotEmpty) {
                builder = builder.or().itemNameEqualTo(fetchedItem.itemName!);
              }
              return builder;
            })
            .findAll();

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
              totalAmount: ii.taxableAmount ?? (ii.quantity ?? 1.0) * (ii.rate ?? 0.0) - (ii.discount ?? 0.0),
              targetUuid: inv.uuid ?? inv.id.toString(),
            ));
          }
        }

        // 2. Indexed query for Purchase Bills
        final matchedPurItems = await isar.purchaseItems
            .filter()
            .isDeletedEqualTo(false)
            .and()
            .group((q) {
              var builder = q.itemIdEqualTo(fetchedItem.id);
              if (fetchedItem.itemName != null && fetchedItem.itemName!.isNotEmpty) {
                builder = builder.or().itemNameEqualTo(fetchedItem.itemName!);
              }
              return builder;
            })
            .findAll();

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
              totalAmount: pi.taxableAmount ?? (pi.quantity ?? 1.0) * (pi.rate ?? 0.0) - (pi.discount ?? 0.0),
              targetUuid: pur.uuid ?? pur.id.toString(),
            ));
          }
        }

        // 3. Indexed query for Orders
        final matchedOrdItems = await isar.orderItems
            .filter()
            .isDeletedEqualTo(false)
            .and()
            .group((q) {
              var builder = q.itemIdEqualTo(fetchedItem.id);
              if (fetchedItem.itemName != null && fetchedItem.itemName!.isNotEmpty) {
                builder = builder.or().itemNameEqualTo(fetchedItem.itemName!);
              }
              return builder;
            })
            .findAll();

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
              totalAmount: oi.taxableAmount ?? (oi.quantity ?? 1.0) * (oi.rate ?? 0.0) - (oi.discount ?? 0.0),
              targetUuid: ord.uuid ?? ord.id.toString(),
            ));
          }
        }

        // 4. Indexed query for Stock Adjustments
        final adjustments = await isar.collection<StockAdjustment>()
            .filter()
            .isDeletedEqualTo(false)
            .and()
            .group((q) {
              var builder = q.itemIdEqualTo(fetchedItem.id);
              if (itemUuid != null && itemUuid.isNotEmpty) {
                builder = builder.or().itemUuidEqualTo(itemUuid);
              }
              if (fetchedItem.itemName != null && fetchedItem.itemName!.isNotEmpty) {
                builder = builder.or().itemNameEqualTo(fetchedItem.itemName!);
              }
              return builder;
            })
            .findAll();

        for (var adj in adjustments) {
          final isAdd = adj.adjustmentType == 'Add' || adj.adjustmentType == 'Stock In';
          final adjRate = adj.ratePerUnit ?? fetchedItem.buyRate ?? 0.0;
          final adjQty = adj.quantity ?? 0.0;
          final adjTotalVal = adj.totalValue ?? (adjQty * adjRate);
          txs.add(_ItemTransaction(
            type: 'Adjustment',
            date: adj.adjustmentDate ?? adj.createdAt,
            title: 'Stock Adjustment (${isAdd ? "Stock In +" : "Stock Out -"})',
            partyName: adj.reason ?? (isAdd ? 'Stock Added' : 'Stock Reduced'),
            quantity: adjQty,
            unit: adj.unit ?? (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? 'PCS'),
            rate: adjRate,
            totalAmount: adjTotalVal,
            targetUuid: adj.uuid ?? adj.id.toString(),
            rawAdjustment: adj,
          ));
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
    } else if (tx.type == 'Adjustment' && tx.rawAdjustment != null) {
      _showAdjustmentDetailModal(tx.rawAdjustment!);
    }
  }

  Future<void> _adjustStockDialog({StockAdjustment? existingAdjustment}) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => AddEditStockAdjustmentDialog(existingAdjustment: existingAdjustment),
    );

    if (success == true) {
      await _loadItem();
    }
  }

  void _showAdjustmentDetailModal(StockAdjustment adj) {
    final theme = Theme.of(context);
    final isAdd = adj.adjustmentType == 'Add' || adj.adjustmentType == 'Stock In';
    final dateStr = adj.adjustmentDate != null ? DateFormat('dd MMMM yyyy').format(adj.adjustmentDate!) : 'N/A';

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
              Text(
                'Stock Adjustment Details',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailTable([
                _DetailRow('Product Name', adj.itemName ?? 'N/A'),
                _DetailRow('Adjustment Type', isAdd ? 'Stock In (+)' : 'Stock Out (-)'),
                _DetailRow('Quantity & Unit', '${adj.quantity ?? 0.0} ${adj.unit ?? ''}'),
                _DetailRow('Rate per Unit', _currencyFormat.format(adj.ratePerUnit ?? _item?.buyRate ?? 0.0)),
                _DetailRow('Total Value', _currencyFormat.format(adj.totalValue ?? ((adj.quantity ?? 0.0) * (adj.ratePerUnit ?? _item?.buyRate ?? 0.0))), isBold: true),
                _DetailRow('Adjustment Date', dateStr),
                _DetailRow('Reason', adj.reason ?? 'N/A'),
                if (adj.notes != null && adj.notes!.isNotEmpty)
                  _DetailRow('Notes', adj.notes!),
              ], theme),
            ],
          ),
          actions: [
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete'),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Adjustment'),
                    content: const Text('Are you sure you want to delete this stock adjustment? Item stock will be recalculated.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
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
                    await _loadItem();
                    ref.invalidate(filteredItemsProvider);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stock adjustment deleted.')),
                      );
                    }
                  } catch (e) {
                    logger.error('Failed to delete adjustment', e);
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
              onPressed: () {
                Navigator.pop(dialogContext);
                _adjustStockDialog(existingAdjustment: adj);
              },
            ),
          ],
        );
      },
    );
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
    final double rawCurrent = item.currentStock ?? 0.0;
    final double rawOpening = item.openingStock ?? 0.0;
    final double primaryStock = (rawCurrent <= 0.0 && rawOpening > 0.0) ? rawOpening : rawCurrent;
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
                                const SizedBox(height: 4),
                                () {
                                  double costRate = (item.buyRate != null && item.buyRate! > 0) ? item.buyRate! : 0.0;
                                  if (costRate <= 0 && item.sellRate != null && item.sellRate! > 0) {
                                    final double gstPct = item.gstApplicable ? (item.gstRate ?? 0.0) : 0.0;
                                    costRate = item.sellRate! / (1.0 + (gstPct / 100.0));
                                  }
                                  final double stockValAmt = primaryStock <= 0 ? 0.0 : primaryStock * costRate;
                                  return Text(
                                    'Total Stock Value: ${_currencyFormat.format(stockValAmt)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  );
                                }(),
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
                            } else if (tx.type == 'Adjustment') {
                              final isAdd = tx.rawAdjustment?.adjustmentType == 'Add' || tx.rawAdjustment?.adjustmentType == 'Stock In';
                              badgeColor = isAdd ? Colors.green : Colors.red;
                              badgeIcon = isAdd ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded;
                            }

                            final isAdj = tx.type == 'Adjustment';
                            final isAddAdj = isAdj && (tx.rawAdjustment?.adjustmentType == 'Add' || tx.rawAdjustment?.adjustmentType == 'Stock In');

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
                                      isAdj
                                          ? '${isAddAdj ? "+" : "-"}${tx.quantity} ${tx.unit} (${_currencyFormat.format(tx.totalAmount)})'
                                          : _currencyFormat.format(tx.totalAmount),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor, fontSize: 13),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          isAdj
                                              ? 'Reason: ${tx.partyName}  •  Rate: ${_currencyFormat.format(tx.rate)}  •  $dateStr'
                                              : 'Party: ${tx.partyName}  •  $dateStr',
                                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${tx.quantity} ${tx.unit}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isAdj ? badgeColor : null),
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
      return const SizedBox.shrink();
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
