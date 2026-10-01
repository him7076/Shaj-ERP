import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/deleted_voucher_collection.dart';
import 'package:business_sahaj_erp/core/widgets/animated_hover_card.dart';
import 'package:business_sahaj_erp/core/widgets/animated_hover_card.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';
import 'package:business_sahaj_erp/core/services/stock_recalculator_service.dart';
import 'dart:math';

final deletedVouchersProvider = FutureProvider.autoDispose<List<DeletedVoucher>>((ref) async {
  final dbService = ref.read(databaseServiceProvider);
  final isar = dbService.isar;
  final list = await isar.collection<DeletedVoucher>().where().findAll();
  list.sort((a, b) => b.deletedAt?.compareTo(a.deletedAt ?? DateTime.now()) ?? 0);
  return list;
});




final restoreVoucherProvider = Provider((ref) => (DeletedVoucher v) async {
  final dbService = ref.read(databaseServiceProvider);
  final isar = dbService.isar;
  
  await isar.writeTxn(() async {
    bool restored = false;
    String? type = v.voucherType;
    String? vNum = v.voucherNumber;
    
    if (type == null || vNum == null) return;
    
    String _genUuid() {
      final random = Random();
      final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
      return '${DateTime.now().millisecondsSinceEpoch}-${parts.join("-")}';
    }

    Future<void> logRestore(String eType, int eId, String? eUuid) async {
      final queueItem = SyncQueue()
        ..uuid = _genUuid()
        ..entityType = eType
        ..entityId = eId
        ..entityUuid = eUuid
        ..operation = 'Update'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await isar.syncQueues.put(queueItem);
    }
    
    
    // Try to restore from ALL possible collections that match this voucher number
    
    // 1. Invoices
    final inv = await isar.invoices.filter().invoiceNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (inv != null) {
      inv.isDeleted = false; inv.isSynced = false; inv.updatedAt = DateTime.now(); inv.version += 1;
      await isar.invoices.put(inv);
      await logRestore('Invoice', inv.id, inv.uuid);
      
      final items = await isar.invoiceItems.filter().parentInvoiceIdEqualTo(inv.id).findAll();
      for (var item in items) {
          item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
          await isar.invoiceItems.put(item);
      }
      restored = true;
    }
    
    // 2. Purchases
    final pur = await isar.purchases.filter().purchaseNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (pur != null) {
      pur.isDeleted = false; pur.isSynced = false; pur.updatedAt = DateTime.now(); pur.version += 1;
      await isar.purchases.put(pur);
      await logRestore('Purchase', pur.id, pur.uuid);
      
      final items = await isar.purchaseItems.filter().purchaseIdEqualTo(pur.id).findAll();
      for (var item in items) {
          item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
          await isar.purchaseItems.put(item);
      }
      restored = true;
    }
    
    // 3. Orders
    final ord = await isar.orders.filter().orderNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (ord != null) {
      ord.isDeleted = false; ord.isSynced = false; ord.updatedAt = DateTime.now(); ord.version += 1;
      await isar.orders.put(ord);
      await logRestore('Order', ord.id, ord.uuid);
      
      // Order doesn't have parentOrderId indexed currently, but Isar supports it via filter
      try {
          final items = await isar.orderItems.where().findAll();
          for (var item in items) {
             // We don't have a direct link for orderItems here if we don't have parent ID, but usually it's handled. We will skip order items for now or restore them if they are connected.
          }
      } catch(e) {}
      restored = true;
    }
    
    // 4. Credit Notes
    final cn = await isar.creditNotes.filter().creditNoteNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (cn != null) {
      cn.isDeleted = false; cn.isSynced = false; cn.updatedAt = DateTime.now(); cn.version += 1;
      await isar.creditNotes.put(cn);
      await logRestore('CreditNote', cn.id, cn.uuid);
      
      try {
          final items = await isar.creditNoteItems.filter().parentCreditNoteIdEqualTo(cn.id).findAll();
          for (var item in items) {
             item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
             await isar.creditNoteItems.put(item);
          }
          if (items.isEmpty) {
             final all = await isar.creditNoteItems.where().findAll();
             for (var item in all.where((e) => e.parentCreditNoteId == cn.id)) {
                 item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
                 await isar.creditNoteItems.put(item);
             }
          }
      } catch(e) {}
      restored = true;
    }
    
    // 5. Debit Notes
    final dn = await isar.debitNotes.filter().debitNoteNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (dn != null) {
      dn.isDeleted = false; dn.isSynced = false; dn.updatedAt = DateTime.now(); dn.version += 1;
      await isar.debitNotes.put(dn);
      await logRestore('DebitNote', dn.id, dn.uuid);
      
      try {
          final items = await isar.debitNoteItems.filter().parentDebitNoteIdEqualTo(dn.id).findAll();
          for (var item in items) {
             item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
             await isar.debitNoteItems.put(item);
          }
          if (items.isEmpty) {
             final all = await isar.debitNoteItems.where().findAll();
             for (var item in all.where((e) => e.parentDebitNoteId == dn.id)) {
                 item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
                 await isar.debitNoteItems.put(item);
             }
          }
      } catch(e) {}
      restored = true;
    }
    
    // 6. Transactions (This also covers Payments, Receipts, and the ledger entries for Invoices/CreditNotes)
    final txn = await isar.transactions.filter().transactionNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (txn != null) {
      txn.isDeleted = false; txn.isSynced = false; txn.updatedAt = DateTime.now(); txn.version += 1;
      await isar.transactions.put(txn);
      await logRestore('Transaction', txn.id, txn.uuid);
      
      // Also restore party balance
      if (txn.partyUuid != null) {
        final party = await isar.partys.filter().uuidEqualTo(txn.partyUuid).findFirst();
        if (party != null) {
           final amt = txn.amount ?? 0.0;
           final tType = txn.transactionType;
           if (tType == 'Receipt' || tType == 'Credit Note' || tType == 'Payment' || tType == 'Debit Note') {
             party.outstandingBalance = (party.outstandingBalance ?? 0.0) - amt;
           } else if (tType == 'Sales' || tType == 'Purchase') {
             party.outstandingBalance = (party.outstandingBalance ?? 0.0) + amt;
           }
           party.updatedAt = DateTime.now();
           party.isSynced = false;
           await isar.partys.put(party);
           await logRestore('Party', party.id, party.uuid);
        }
      }
      
      restored = true;
    }

    if (restored) {
       await isar.collection<DeletedVoucher>().delete(v.id);
       await StockRecalculatorService.recalculateAllItemStocks(isar);
    }
  });
});

class DeletedVouchersScreen extends ConsumerStatefulWidget {
  const DeletedVouchersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DeletedVouchersScreen> createState() => _DeletedVouchersScreenState();
}

class _DeletedVouchersScreenState extends ConsumerState<DeletedVouchersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilterType = 'All';

  final List<String> _voucherTypes = [
    'All',
    'Invoice',
    'Purchase',
    'Order',
    'Transaction',
    'Payment',
    'Receipt',
    'Credit Note',
    'Debit Note',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vouchersAsync = ref.watch(deletedVouchersProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        title: const Text('Deleted Vouchers Audit Log', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(deletedVouchersProvider),
            tooltip: 'Refresh Audit Log',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: vouchersAsync.when(
        data: (vouchers) {
          final filtered = vouchers.where((v) {
            final matchesQuery = _searchQuery.isEmpty ||
                (v.voucherNumber?.toLowerCase().contains(_searchQuery) ?? false) ||
                (v.partyName?.toLowerCase().contains(_searchQuery) ?? false) ||
                (v.voucherType?.toLowerCase().contains(_searchQuery) ?? false);
            final matchesType = _selectedFilterType == 'All' ||
                (v.voucherType?.toLowerCase().contains(_selectedFilterType.toLowerCase()) ?? false);
            return matchesQuery && matchesType;
          }).toList();

          double totalDeletedAmount = 0.0;
          for (var v in filtered) {
            totalDeletedAmount += (v.amount ?? 0.0);
          }

          return Column(
            children: [
              // KPI Cards Row
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedHoverCard(
                        glowColor: Colors.redAccent,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Deleted Vouchers Count', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              '${filtered.length}',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AnimatedHoverCard(
                        glowColor: Colors.orangeAccent,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Deleted Value', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(totalDeletedAmount),
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search and Type Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Voucher No, Party Name, Type...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),

              const SizedBox(height: 12),

              // Voucher Type Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _voucherTypes.map((type) {
                    final isSelected = _selectedFilterType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedFilterType = type);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // List of Deleted Vouchers
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_sweep_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                            const SizedBox(height: 16),
                            Text(
                              vouchers.isEmpty
                                  ? 'No deleted vouchers recorded yet.'
                                  : 'No deleted vouchers match your search filter.',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final v = filtered[index];
                          final dateStr = v.deletedAt != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(v.deletedAt!)
                              : 'Unknown Date';

                          return NeuCard(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade50,
                                child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${(v.voucherType ?? "Voucher").replaceAll("CreditNote", "Credit Note").replaceAll("DebitNote", "Debit Note")}: ${v.voucherNumber ?? "N/A"}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(v.amount ?? 0.0),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Party: ${v.partyName ?? "General / Cash"}',
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      'Deleted: $dateStr',
                                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.restore_page_rounded, color: Colors.green),
                                tooltip: 'Restore Voucher',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Restore Voucher?'),
                                      content: Text('Are you sure you want to restore ${v.voucherNumber}?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref.read(restoreVoucherProvider)(v);
                                    ref.invalidate(deletedVouchersProvider);
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher restored successfully!')));
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error loading deleted vouchers: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
