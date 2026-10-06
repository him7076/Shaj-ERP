import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:business_sahaj_erp/core/utils/excel_download_helper.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/stock_adjustment_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_edit_item_screen.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/invoice_detail_screen.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/screens/add_edit_purchase_screen.dart';
import 'package:business_sahaj_erp/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_credit_note_screen.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_debit_note_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/stock_adjustments_screen.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/features/items/presentation/widgets/stock_adjustment_dialog.dart';

class _ItemTransaction {
  final String type; // 'Sale', 'Purchase', 'Order', 'Adjustment', 'Credit Note', 'Debit Note'
  final DateTime date;
  final String title;
  final String voucherNumber;
  final String partyName;
  final double quantity;
  final String unit;
  final double rate;
  final double totalAmount;
  final String targetUuid;
  final String? paymentStatus;
  final StockAdjustment? rawAdjustment;
  final String? hsnCode;
  final double? gstRate;
  final double? discount;
  final double? taxableAmount;
  final double? subtotal;
  final double? purchaseRate;
  final bool isTaxInclusive;

  _ItemTransaction({
    required this.type,
    required this.date,
    required this.title,
    required this.voucherNumber,
    required this.partyName,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.totalAmount,
    required this.targetUuid,
    this.paymentStatus,
    this.rawAdjustment,
    this.hsnCode,
    this.gstRate,
    this.discount,
    this.taxableAmount,
    this.subtotal,
    this.purchaseRate,
    this.isTaxInclusive = false,
  });
}

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String? itemUuid;
  final Item? item;

  const ItemDetailScreen({Key? key, this.itemUuid, this.item}) : super(key: key);

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
      final fetchedItem = widget.item ?? (widget.itemUuid != null ? await repo.getByUuid(widget.itemUuid!) : null);

      if (fetchedItem != null) {
        try { await fetchedItem.category.load(); } catch (_) {}
        try { await fetchedItem.brand.load(); } catch (_) {}
        try { await fetchedItem.unit.load(); } catch (_) {}

        final List<_ItemTransaction> txs = [];
        final itemName = fetchedItem.itemName?.trim().toLowerCase() ?? '';
        final itemUuid = fetchedItem.uuid;

        // 1. Sales Invoices
        final allInvItems = await isar.invoiceItems.filter().isDeletedEqualTo(false).findAll();
        final matchedInvItems = allInvItems.where((ii) {
          if (ii.itemId == fetchedItem.id) return true;
          if (itemName.isNotEmpty && ii.itemId == null && (ii.itemName?.trim().toLowerCase() ?? '') == itemName) return true;
          return false;
        }).toList();

        final invIds = matchedInvItems.map((ii) => ii.parentInvoiceId).where((id) => id != null).cast<int>().toSet().toList();
        final invoicesBatch = await isar.invoices.getAll(invIds);
        final invoicesMap = { for (var inv in invoicesBatch) if (inv != null) inv.id: inv };

        final invUuids = matchedInvItems.map((ii) => ii.parentInvoiceUuid).where((u) => u != null && u.isNotEmpty).cast<String>().toSet().toList();
        final allInvoices = invUuids.isNotEmpty ? await isar.invoices.filter().isDeletedEqualTo(false).findAll() : <Invoice>[];
        final invoicesUuidMap = { for (var inv in allInvoices) if (inv.uuid != null && invUuids.contains(inv.uuid)) inv.uuid!: inv };

        for (var ii in matchedInvItems) {
          Invoice? inv;
          if (ii.parentInvoiceId != null) inv = invoicesMap[ii.parentInvoiceId];
          if (inv == null && ii.parentInvoiceUuid != null) inv = invoicesUuidMap[ii.parentInvoiceUuid];
          
          if (inv == null) {
            try { 
              await ii.invoice.load();
              inv = ii.invoice.value; 
            } catch (_) {}
          }

          if (inv != null && !inv.isDeleted) {
            txs.add(_ItemTransaction(
              type: 'Sale',
              date: inv.invoiceDate ?? inv.createdAt,
              title: 'Sales Invoice #${inv.invoiceNumber}',
              voucherNumber: inv.invoiceNumber ?? 'INV',
              partyName: inv.partyName ?? 'Customer',
              quantity: ii.quantity ?? 1.0,
              unit: (ii.unit != null && ii.unit!.isNotEmpty && ii.unit != 'PCS')
                  ? ii.unit!
                  : (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? ii.unit ?? 'PCS'),
              rate: ii.rate ?? 0.0,
              totalAmount: ii.taxableAmount ?? (ii.quantity ?? 1.0) * (ii.rate ?? 0.0) - (ii.discount ?? 0.0),
              targetUuid: inv.uuid ?? inv.id.toString(),
              paymentStatus: inv.paymentStatus,
              hsnCode: ii.hsnCode ?? fetchedItem.hsnCode,
              gstRate: ii.gstRate ?? fetchedItem.gstRate,
              discount: ii.discount ?? 0.0,
              taxableAmount: ii.taxableAmount,
              subtotal: (ii.quantity ?? 1.0) * (ii.rate ?? 0.0),
              purchaseRate: fetchedItem.buyRate ?? 0.0,
              isTaxInclusive: false,
            ));
          }
        }

        // 2. Purchase Bills
        final allPurItems = await isar.purchaseItems.filter().isDeletedEqualTo(false).findAll();
        final matchedPurItems = allPurItems.where((pi) {
          if (pi.itemId == fetchedItem.id) return true;
          if (itemName.isNotEmpty && pi.itemId == null && (pi.itemName?.trim().toLowerCase() ?? '') == itemName) return true;
          return false;
        }).toList();

        final purIds = matchedPurItems.map((pi) => pi.purchaseId).where((id) => id != null).cast<int>().toSet().toList();
        final purchasesBatch = await isar.collection<Purchase>().getAll(purIds);
        final purchasesMap = { for (var pur in purchasesBatch) if (pur != null) pur.id: pur };

        final purUuids = matchedPurItems.map((pi) => pi.purchaseUuid).where((u) => u != null && u.isNotEmpty).cast<String>().toSet().toList();
        final allPurchases = purUuids.isNotEmpty ? await isar.collection<Purchase>().filter().isDeletedEqualTo(false).findAll() : <Purchase>[];
        final purchasesUuidMap = { for (var pur in allPurchases) if (pur.uuid != null && purUuids.contains(pur.uuid)) pur.uuid!: pur };

        for (var pi in matchedPurItems) {
          Purchase? pur;
          if (pi.purchaseId != null) pur = purchasesMap[pi.purchaseId];
          if (pur == null && pi.purchaseUuid != null) pur = purchasesUuidMap[pi.purchaseUuid];

          if (pur == null) {
            try {
              await pi.purchase.load();
              pur = pi.purchase.value;
            } catch (_) {}
          }

          if (pur != null && !pur.isDeleted) {
            txs.add(_ItemTransaction(
              type: 'Purchase',
              date: pur.purchaseDate ?? pur.createdAt,
              title: 'Purchase Bill #${pur.purchaseNumber}${pur.supplierInvoiceNumber != null && pur.supplierInvoiceNumber!.isNotEmpty ? " (Supp: ${pur.supplierInvoiceNumber})" : ""}',
              voucherNumber: pur.purchaseNumber ?? 'PUR',
              partyName: pur.partyName ?? 'Supplier',
              quantity: pi.quantity ?? 1.0,
              unit: (pi.unit != null && pi.unit!.isNotEmpty && pi.unit != 'PCS')
                  ? pi.unit!
                  : (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? pi.unit ?? 'PCS'),
              rate: pi.rate ?? 0.0,
              totalAmount: pi.taxableAmount ?? (pi.quantity ?? 1.0) * (pi.rate ?? 0.0) - (pi.discount ?? 0.0),
              targetUuid: pur.uuid ?? pur.id.toString(),
              paymentStatus: pur.paymentStatus,
              hsnCode: pi.hsnCode ?? fetchedItem.hsnCode,
              gstRate: pi.gstRate ?? fetchedItem.gstRate,
              discount: pi.discount ?? 0.0,
              taxableAmount: pi.taxableAmount,
              subtotal: (pi.quantity ?? 1.0) * (pi.rate ?? 0.0),
              purchaseRate: pi.rate ?? fetchedItem.buyRate ?? 0.0,
            ));
          }
        }

        // 3. Orders
        final allOrdItems = await isar.orderItems.filter().isDeletedEqualTo(false).findAll();
        final matchedOrdItems = allOrdItems.where((oi) {
          if (oi.itemId == fetchedItem.id) return true;
          if (itemName.isNotEmpty && oi.itemId == null && (oi.itemName?.trim().toLowerCase() ?? '') == itemName) return true;
          return false;
        }).toList();

        final ordIds = matchedOrdItems.map((oi) => oi.orderId).where((id) => id != null).cast<int>().toSet().toList();
        final ordersBatch = await isar.orders.getAll(ordIds);
        final ordersMap = { for (var ord in ordersBatch) if (ord != null) ord.id: ord };

        for (var oi in matchedOrdItems) {
          Order? ord = oi.orderId != null ? ordersMap[oi.orderId] : null;
          if (ord == null && oi.order.value != null) ord = oi.order.value;

          if (ord != null && !ord.isDeleted) {
            txs.add(_ItemTransaction(
              type: 'Order',
              date: ord.orderDate ?? ord.createdAt,
              title: 'Sales Order #${ord.orderNumber}',
              voucherNumber: ord.orderNumber ?? 'ORD',
              partyName: ord.partyName ?? 'Customer',
              quantity: oi.quantity ?? 1.0,
              unit: (oi.unit != null && oi.unit!.isNotEmpty && oi.unit != 'PCS')
                  ? oi.unit!
                  : (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? oi.unit ?? 'PCS'),
              rate: oi.rate ?? 0.0,
              totalAmount: oi.taxableAmount ?? (oi.quantity ?? 1.0) * (oi.rate ?? 0.0) - (oi.discountAmount ?? 0.0),
              targetUuid: ord.uuid ?? ord.id.toString(),
              paymentStatus: ord.status,
            ));
          }
        }

        // 4. Credit Notes (Sales Returns: +Stock)
        final allCNItems = await isar.creditNoteItems.filter().isDeletedEqualTo(false).findAll();
        final matchedCNItems = allCNItems.where((cni) {
          if (cni.itemId == fetchedItem.id) return true;
          if (itemName.isNotEmpty && cni.itemId == null && (cni.itemName?.trim().toLowerCase() ?? '') == itemName) return true;
          return false;
        }).toList();

        final cnIds = matchedCNItems.map((cni) => cni.parentCreditNoteId).where((id) => id != null).cast<int>().toSet().toList();
        final creditNotesBatch = await isar.creditNotes.getAll(cnIds);
        final creditNotesMap = { for (var cn in creditNotesBatch) if (cn != null) cn.id: cn };

        for (var cni in matchedCNItems) {
          CreditNote? cn = cni.parentCreditNoteId != null ? creditNotesMap[cni.parentCreditNoteId] : null;
          if (cn == null && cni.creditNote.value != null) cn = cni.creditNote.value;

          if (cn != null && !cn.isDeleted && cn.paymentMode != 'Cancelled' && !(cn.remarks?.contains('[CANCELLED]') ?? false)) {
            txs.add(_ItemTransaction(
              type: 'Credit Note',
              date: cn.creditNoteDate ?? cn.createdAt,
              title: 'Credit Note #${cn.creditNoteNumber}',
              voucherNumber: cn.creditNoteNumber ?? 'CN',
              partyName: cn.partyName ?? 'Customer',
              quantity: cni.quantity ?? 1.0,
              unit: (cni.unit != null && cni.unit!.isNotEmpty && cni.unit != 'PCS')
                  ? cni.unit!
                  : (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? cni.unit ?? 'PCS'),
              rate: cni.rate ?? 0.0,
              totalAmount: cni.taxableAmount ?? (cni.quantity ?? 1.0) * (cni.rate ?? 0.0) - (cni.discount ?? 0.0),
              targetUuid: cn.uuid ?? cn.id.toString(),
              paymentStatus: 'Return In (+)',
            ));
          }
        }

        // 5. Debit Notes (Purchase Returns: -Stock)
        final allDNItems = await isar.debitNoteItems.filter().isDeletedEqualTo(false).findAll();
        final matchedDNItems = allDNItems.where((dni) {
          if (dni.itemId == fetchedItem.id) return true;
          if (itemName.isNotEmpty && dni.itemId == null && (dni.itemName?.trim().toLowerCase() ?? '') == itemName) return true;
          return false;
        }).toList();

        final dnIds = matchedDNItems.map((dni) => dni.parentDebitNoteId).where((id) => id != null).cast<int>().toSet().toList();
        final debitNotesBatch = await isar.debitNotes.getAll(dnIds);
        final debitNotesMap = { for (var dn in debitNotesBatch) if (dn != null) dn.id: dn };

        for (var dni in matchedDNItems) {
          DebitNote? dn = dni.parentDebitNoteId != null ? debitNotesMap[dni.parentDebitNoteId] : null;
          if (dn == null && dni.debitNote.value != null) dn = dni.debitNote.value;

          if (dn != null && !dn.isDeleted && dn.paymentMode != 'Cancelled' && !(dn.remarks?.contains('[CANCELLED]') ?? false)) {
            txs.add(_ItemTransaction(
              type: 'Debit Note',
              date: dn.debitNoteDate ?? dn.createdAt,
              title: 'Debit Note #${dn.debitNoteNumber}',
              voucherNumber: dn.debitNoteNumber ?? 'DN',
              partyName: dn.partyName ?? 'Supplier',
              quantity: dni.quantity ?? 1.0,
              unit: (dni.unit != null && dni.unit!.isNotEmpty && dni.unit != 'PCS')
                  ? dni.unit!
                  : (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? dni.unit ?? 'PCS'),
              rate: dni.rate ?? 0.0,
              totalAmount: dni.taxableAmount ?? (dni.quantity ?? 1.0) * (dni.rate ?? 0.0) - (dni.discount ?? 0.0),
              targetUuid: dn.uuid ?? dn.id.toString(),
              paymentStatus: 'Return Out (-)',
            ));
          }
        }

        // 6. Stock Adjustments
        final allAdjustments = await isar.collection<StockAdjustment>().filter().isDeletedEqualTo(false).findAll();
        final adjustments = allAdjustments.where((adj) {
          if (adj.itemId == fetchedItem.id) return true;
          if (itemUuid != null && itemUuid.isNotEmpty && adj.itemUuid == itemUuid) return true;
          if (itemName.isNotEmpty && adj.itemId == null && (adj.itemName?.trim().toLowerCase() ?? '') == itemName) return true;
          return false;
        }).toList();

        for (var adj in adjustments) {
          final isAdd = adj.adjustmentType == 'Add' || adj.adjustmentType == 'Stock In';
          final adjRate = adj.ratePerUnit ?? fetchedItem.buyRate ?? 0.0;
          final adjQty = adj.quantity ?? 0.0;
          final adjTotalVal = adj.totalValue ?? (adjQty * adjRate);
          txs.add(_ItemTransaction(
            type: 'Adjustment',
            date: adj.adjustmentDate ?? adj.createdAt,
            title: 'Stock Adjustment (${isAdd ? "Stock In +" : "Stock Out -"})',
            voucherNumber: isAdd ? 'Stock In' : 'Stock Out',
            partyName: adj.reason ?? (isAdd ? 'Stock Added' : 'Stock Reduced'),
            quantity: adjQty,
            unit: adj.unit ?? (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? 'PCS'),
            rate: adjRate,
            totalAmount: adjTotalVal,
            targetUuid: adj.uuid ?? adj.id.toString(),
            paymentStatus: isAdd ? 'Stock In (+)' : 'Stock Out (-)',
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
      logger.error('Failed to load item detail', e); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading item: $e'), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 10))); }
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
      ref.invalidate(itemsListProvider);
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
      builder: (context) => StockAdjustmentDialog(
        existingAdjustment: existingAdjustment,
        initialItem: existingAdjustment == null ? _item : null,
      ),
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
      ref.invalidate(itemsListProvider);

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

  Future<void> _exportItemToExcel() async {
    if (_item == null) return;
    try {
      final excel = Excel.createExcel();

      // Sheet 1: Item Details
      final sheet1 = excel['Item Details'];
      excel.setDefaultSheet('Item Details');

      sheet1.appendRow([
        TextCellValue('Field'),
        TextCellValue('Value'),
      ]);

      final item = _item!;
      final rows1 = [
        ['Item Name', item.itemName ?? ''],
        ['Item Code', item.itemCode ?? ''],
        ['Category', item.category.value?.categoryName ?? ''],
        ['Brand', item.brand.value?.brandName ?? ''],
        ['HSN Code', item.hsnCode ?? ''],
        ['Barcode', item.barcode ?? ''],
        ['Primary Unit', item.primaryUnitName ?? item.unit.value?.shortName ?? ''],
        ['Secondary Unit', item.secondaryUnit ?? 'N/A'],
        ['Conversion Factor', (item.conversionFactor ?? 1.0).toString()],
        ['Selling Price (Sell Rate)', (item.sellRate ?? 0.0).toStringAsFixed(2)],
        ['Purchase Price (Buy Rate)', (item.buyRate ?? 0.0).toStringAsFixed(2)],
        ['MRP', (item.mrp ?? 0.0).toStringAsFixed(2)],
        ['Minimum Selling Price', (item.minimumSellingPrice ?? 0.0).toStringAsFixed(2)],
        ['Wholesale Rate', (item.wholesaleRate ?? 0.0).toStringAsFixed(2)],
        ['GST Applicable', item.gstApplicable ? 'Yes' : 'No'],
        ['GST Rate (%)', (item.gstRate ?? 0.0).toString()],
        ['Cess Rate (%)', (item.cessRate ?? 0.0).toString()],
        ['Opening Stock', (item.openingStock ?? 0.0).toString()],
        ['Current Stock', (item.currentStock ?? 0.0).toString()],
        ['Minimum Stock Level', (item.minimumStock ?? 0.0).toString()],
        ['Reorder Level', (item.reorderLevel ?? 0.0).toString()],
        ['Dimensions', item.dimensions ?? 'N/A'],
        ['Description / Remarks', item.description ?? item.notes ?? ''],
      ];

      for (var r in rows1) {
        sheet1.appendRow([TextCellValue(r[0]), TextCellValue(r[1])]);
      }

      // Sheet 2: Transactions
      final sheet2 = excel['Transactions'];
      sheet2.appendRow([
        TextCellValue('Date'),
        TextCellValue('Voucher Number'),
        TextCellValue('Transaction Type'),
        TextCellValue('Party Name'),
        TextCellValue('HSN Code'),
        TextCellValue('Qty'),
        TextCellValue('Unit'),
        TextCellValue('Rate Per Unit'),
        TextCellValue('Tax Included'),
        TextCellValue('Purchase Rate'),
        TextCellValue('Discount'),
        TextCellValue('GST Rate (%)'),
        TextCellValue('Sub Total'),
        TextCellValue('Taxable Amount'),
        TextCellValue('Total Amount'),
      ]);

      final df = DateFormat('dd-MM-yyyy');
      for (var tx in _itemTransactions) {
        sheet2.appendRow([
          TextCellValue(df.format(tx.date)),
          TextCellValue(tx.voucherNumber),
          TextCellValue(tx.type),
          TextCellValue(tx.partyName),
          TextCellValue(tx.hsnCode ?? item.hsnCode ?? ''),
          DoubleCellValue(tx.quantity),
          TextCellValue(tx.unit),
          DoubleCellValue(tx.rate),
          TextCellValue(tx.isTaxInclusive ? 'Yes' : 'No'),
          DoubleCellValue(tx.purchaseRate ?? item.buyRate ?? 0.0),
          DoubleCellValue(tx.discount ?? 0.0),
          DoubleCellValue(tx.gstRate ?? item.gstRate ?? 0.0),
          DoubleCellValue(tx.subtotal ?? (tx.quantity * tx.rate)),
          DoubleCellValue(tx.taxableAmount ?? (tx.quantity * tx.rate - (tx.discount ?? 0.0))),
          DoubleCellValue(tx.totalAmount),
        ]);
      }

      final bytes = excel.encode();
      if (bytes != null) {
        final sanitizedName = (item.itemName ?? 'Item').replaceAll(RegExp(r'[^\w\s\-]'), '_');
        final fileName = 'Item_Report_${sanitizedName}_${DateFormat("yyyyMMdd").format(DateTime.now())}.xlsx';
        final resultPath = await ExcelDownloadHelper.downloadExcel(bytes, fileName);
        if (mounted && resultPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item Excel exported successfully: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export item Excel: $e'), backgroundColor: Colors.red),
        );
      }
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
        appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, ),
        body: const Center(child: Text('Product not found.')),
      );
    }

    final item = _item!;
    final isLow = stockService.isLowStock(item);
    final isOut = stockService.isOutOfStock(item);

    // Calculate Primary vs Secondary stock breakdown with 2 decimal places
    final double primaryStock = item.currentStock ?? item.openingStock ?? 0.0;
    final String primaryUnitName = item.primaryUnitName ?? item.unit.value?.shortName ?? item.unit.value?.unitName ?? 'PCS';
    final String? secUnitName = item.secondaryUnit;
    final double? convFactor = item.conversionFactor;

    final String formattedStock = primaryStock.toStringAsFixed(2);
    String stockBreakdownText = '$formattedStock $primaryUnitName';
    if (secUnitName != null && secUnitName.isNotEmpty && convFactor != null && convFactor > 1.0) {
      final double secStock = primaryStock * convFactor;
      stockBreakdownText = '$formattedStock $primaryUnitName  (${secStock.toStringAsFixed(2)} $secUnitName)';
    }

    double costRate = (item.buyRate != null && item.buyRate! > 0) ? item.buyRate! : 0.0;
    if (costRate <= 0 && item.sellRate != null && item.sellRate! > 0) {
      final double gstPct = item.gstApplicable ? (item.gstRate ?? 0.0) : 0.0;
      costRate = item.sellRate! / (1.0 + (gstPct / 100.0));
    }
    final double stockValAmt = primaryStock <= 0 ? 0.0 : primaryStock * costRate;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false,
          leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
          title: Text(item.itemName ?? 'Product Details'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Item Options',
              onSelected: (val) async {
                if (val == 'edit') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditItemScreen(itemUuid: item.uuid),
                    ),
                  );
                  _loadItem();
                } else if (val == 'delete') {
                  _deleteItem();
                } else if (val == 'export_excel') {
                  _exportItemToExcel();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Product'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_excel',
                  child: Row(
                    children: [
                      Icon(Icons.ios_share_rounded, color: Colors.purple, size: 18),
                      SizedBox(width: 8),
                      Text('Export to Excel'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete Product', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Transactions', icon: Icon(Icons.receipt_long_outlined, size: 18)),
              Tab(text: 'Product Info', icon: Icon(Icons.info_outline, size: 18)),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildImageHeader(item, theme),

            // COMPACT TOP CARD
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: NeuCard(
                color: theme.colorScheme.primaryContainer.withOpacity(0.25),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: (ref.watch(themeProvider).themeType == ThemeType.neumorphism)
                      ? BorderSide.none
                      : BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  softWrap: true,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Code: ${item.itemCode ?? "N/A"} | HSN: ${item.hsnCode ?? "N/A"}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStockBadge(isOut, isLow, theme, item),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Stock Level:',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                              ),
                              Text(
                                stockBreakdownText,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total Value: ${_currencyFormat.format(stockValAmt)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.swap_vert, size: 16),
                            label: const Text('Adjust', style: TextStyle(fontSize: 12)),
                            onPressed: _adjustStockDialog,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // TAB BAR VIEW
            Expanded(
              child: TabBarView(
                children: [
                  // TAB 1: TRANSACTIONS TAB
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: _itemTransactions.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            alignment: Alignment.center,
                            child: const Text('No transactions recorded for this item yet.'),
                          )
                        : ListView.builder(
                            itemCount: _itemTransactions.length,
                            itemBuilder: (context, index) {
                              final tx = _itemTransactions[index];
                              final dateStr = DateFormat('dd MMM yyyy').format(tx.date);

                              // Movement direction logic for Stock
                              bool isStockIn = false;
                              String signStr = '';
                              Color qtyColor = Colors.grey;

                              if (tx.type == 'Sale') {
                                isStockIn = false;
                                signStr = '-';
                                qtyColor = const Color(0xFFDC2626); // Red
                              } else if (tx.type == 'Purchase') {
                                isStockIn = true;
                                signStr = '+';
                                qtyColor = const Color(0xFF059669); // Green
                              } else if (tx.type == 'Credit Note') {
                                isStockIn = true; // Sales Return = +Stock
                                signStr = '+';
                                qtyColor = const Color(0xFF059669); // Green
                              } else if (tx.type == 'Debit Note') {
                                isStockIn = false; // Purchase Return = -Stock
                                signStr = '-';
                                qtyColor = const Color(0xFFDC2626); // Red
                              } else if (tx.type == 'Adjustment') {
                                final isAdd = tx.rawAdjustment?.adjustmentType == 'Add' || tx.rawAdjustment?.adjustmentType == 'Stock In';
                                isStockIn = isAdd;
                                signStr = isAdd ? '+' : '-';
                                qtyColor = isAdd ? const Color(0xFF059669) : const Color(0xFFDC2626);
                              } else if (tx.type == 'Order') {
                                signStr = '';
                                qtyColor = Colors.orange;
                              }

                              final String qtyFormatted = tx.quantity.toStringAsFixed(2);

                              // Status Badge Color
                              Color statusColor = Colors.grey;
                              final statusText = tx.paymentStatus ?? tx.type;
                              if (statusText.toLowerCase().contains('paid') && !statusText.toLowerCase().contains('unpaid') && !statusText.toLowerCase().contains('partially')) {
                                statusColor = Colors.green;
                              } else if (statusText.toLowerCase().contains('unpaid') || statusText.toLowerCase().contains('out')) {
                                statusColor = Colors.red;
                              } else if (statusText.toLowerCase().contains('partial') || statusText.toLowerCase().contains('return')) {
                                statusColor = Colors.orange;
                              } else {
                                statusColor = Colors.blue;
                              }

                              return NeuCard(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: (ref.watch(themeProvider).themeType == ThemeType.neumorphism)
                                      ? BorderSide.none
                                      : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _openTransactionDetail(tx),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // TOP ROW: Party Name & Actual Qty with +/-
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                tx.partyName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: qtyColor.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '$signStr$qtyFormatted ${tx.unit}',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: qtyColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // MIDDLE ROW: Voucher Number, Date, Item Line Total
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '#${tx.voucherNumber}',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  dateStr,
                                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'Total: ${_currencyFormat.format(tx.totalAmount)}',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color),
                                            ),
                                          ],
                                        ),
                                        if (tx.paymentStatus != null && tx.paymentStatus!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              tx.paymentStatus!,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // TAB 2: PRODUCT INFO TAB
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle('Pricing & Taxation', theme),
                        const SizedBox(height: 8),
                        _buildDetailTable([
                          _DetailRow('Selling Price (Retail)', _currencyFormat.format(item.sellRate ?? 0.0), isBold: true),
                          _DetailRow('Wholesale Price', _currencyFormat.format(item.wholesaleRate ?? 0.0)),
                          _DetailRow('Min Selling Price', _currencyFormat.format(item.minimumSellingPrice ?? 0.0)),
                          _DetailRow('MRP', _currencyFormat.format(item.mrp ?? 0.0)),
                          _DetailRow('Buy/Purchase Price', _currencyFormat.format(item.buyRate ?? 0.0)),
                          _DetailRow('GST Status', item.gstApplicable ? 'Applicable (${item.gstRate ?? 0.0}%)' : 'Exempt / Non-GST'),
                          _DetailRow('HSN Code', item.hsnCode ?? 'N/A'),
                        ], theme),
                        const SizedBox(height: 20),

                        _buildSectionTitle('Units & Unit Conversion', theme),
                        const SizedBox(height: 8),
                        _buildDetailTable([
                          _DetailRow('Category', item.category.value?.categoryName ?? 'N/A'),
                          _DetailRow('Brand', item.brand.value?.brandName ?? 'N/A'),
                          _DetailRow('Primary Unit', item.primaryUnitName ?? item.unit.value?.unitName ?? item.unit.value?.shortName ?? 'N/A'),
                          _DetailRow('Secondary Unit', item.secondaryUnit != null && item.secondaryUnit!.isNotEmpty ? item.secondaryUnit! : 'None'),
                          _DetailRow('Conversion Factor', (item.conversionFactor != null && item.conversionFactor! > 1.0) ? '1 ${item.primaryUnitName ?? item.unit.value?.shortName ?? "Box"} = ${item.conversionFactor} ${item.secondaryUnit}' : '1 : 1'),
                        ], theme),
                      ],
                    ),
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
          String base64Image = images[index];
          if (base64Image.contains(',')) {
            base64Image = base64Image.split(',').last;
          }
          
          try {
            return Image.memory(base64Decode(base64Image), fit: BoxFit.contain);
          } catch (e) {
            return Container(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              child: const Center(child: Text('Invalid Image Format.')),
            );
          }
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



