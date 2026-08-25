import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/brand_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/stock_adjustment_collection.dart';
import 'package:isar/isar.dart';

class DataRepairScreen extends ConsumerStatefulWidget {
  const DataRepairScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DataRepairScreen> createState() => _DataRepairScreenState();
}

class _DataRepairScreenState extends ConsumerState<DataRepairScreen> {
  bool _isRepairing = false;
  double _progress = 0.0;
  String _currentTask = 'Ready to analyze database';
  int _totalRecords = 0;
  int _processedRecords = 0;
  int _fixedRecords = 0;
  DateTime? _startTime;
  String _estimatedTime = '--:--';
  final List<String> _repairLog = [];

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimer() {
    if (_startTime == null || _processedRecords == 0) return;
    
    final elapsed = DateTime.now().difference(_startTime!);
    final msPerRecord = elapsed.inMilliseconds / _processedRecords;
    final remainingRecords = _totalRecords - _processedRecords;
    final remainingMs = remainingRecords * msPerRecord;
    
    final remainingDuration = Duration(milliseconds: remainingMs.toInt());
    
    setState(() {
      _estimatedTime = '${remainingDuration.inMinutes.toString().padLeft(2, '0')}:${(remainingDuration.inSeconds % 60).toString().padLeft(2, '0')}';
    });
  }

  /// Generate a guaranteed-unique UUID using microseconds + record ID to avoid collision
  String _generateUuid(int recordId) {
    return '${DateTime.now().microsecondsSinceEpoch}_$recordId';
  }

  Future<void> _startRepair() async {
    final isar = ref.read(isarProvider);
    
    setState(() {
      _isRepairing = true;
      _progress = 0.0;
      _processedRecords = 0;
      _fixedRecords = 0;
      _startTime = DateTime.now();
      _currentTask = 'Counting records...';
      _repairLog.clear();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTimer());

    try {
      // Phase 1: Count ALL collections
      final counts = <String, int>{};
      counts['Categories'] = await isar.categorys.count();
      counts['Units'] = await isar.units.count();
      counts['Brands'] = await isar.collection<Brand>().count();
      counts['Parties'] = await isar.partys.count();
      counts['Items'] = await isar.items.count();
      counts['Invoices'] = await isar.invoices.count();
      counts['InvoiceItems'] = await isar.collection<InvoiceItem>().count();
      counts['Purchases'] = await isar.collection<Purchase>().count();
      counts['PurchaseItems'] = await isar.collection<PurchaseItem>().count();
      counts['Orders'] = await isar.orders.count();
      counts['OrderItems'] = await isar.collection<OrderItem>().count();
      counts['Transactions'] = await isar.transactions.count();
      counts['Expenses'] = await isar.collection<Expense>().count();
      counts['ExpenseItems'] = await isar.collection<ExpenseItem>().count();
      counts['CreditNotes'] = await isar.collection<CreditNote>().count();
      counts['CreditNoteItems'] = await isar.collection<CreditNoteItem>().count();
      counts['DebitNotes'] = await isar.collection<DebitNote>().count();
      counts['DebitNoteItems'] = await isar.collection<DebitNoteItem>().count();
      counts['BankAccounts'] = await isar.collection<BankAccount>().count();
      counts['StockAdjustments'] = await isar.collection<StockAdjustment>().count();

      _totalRecords = counts.values.fold(0, (sum, c) => sum + c);

      if (_totalRecords == 0) {
        setState(() {
          _isRepairing = false;
          _currentTask = 'Database is empty.';
          _progress = 1.0;
        });
        _timer?.cancel();
        return;
      }

      // Pre-build party lookup maps for partyName resolution
      setState(() => _currentTask = 'Building party lookup indexes...');
      final allParties = await isar.partys.where().findAll();
      final Map<int, Party> partyByIdMap = {};
      final Map<String, Party> partyByUuidMap = {};
      for (var p in allParties) {
        partyByIdMap[p.id] = p;
        if (p.uuid != null && p.uuid!.isNotEmpty) {
          partyByUuidMap[p.uuid!] = p;
        }
      }

      // Pre-build item lookup map for itemName resolution
      final allItems = await isar.items.where().findAll();
      final Map<int, Item> itemByIdMap = {};
      final Map<String, Item> itemByUuidMap = {};
      for (var item in allItems) {
        itemByIdMap[item.id] = item;
        if (item.uuid != null && item.uuid!.isNotEmpty) {
          itemByUuidMap[item.uuid!] = item;
        }
      }

      // Helper function to process collections in chunks with conditional write-back
      Future<void> processCollection<T>(
        String name,
        IsarCollection<dynamic> collection,
        bool Function(dynamic record) fixRecord,
      ) async {
        setState(() => _currentTask = 'Repairing $name...');
        
        const chunkSize = 200;
        final total = await collection.count();
        int collectionFixed = 0;
        
        for (int i = 0; i < total; i += chunkSize) {
          final chunk = await collection.where().offset(i).limit(chunkSize).findAll();
          
          // Collect only records that need fixing
          final List<dynamic> toWrite = [];
          for (var record in chunk) {
            final needsFix = fixRecord(record);
            if (needsFix) {
              toWrite.add(record);
              collectionFixed++;
            }
          }
          
          // Only open a write transaction if there are records to fix
          if (toWrite.isNotEmpty) {
            await isar.writeTxn(() async {
              for (var record in toWrite) {
                await collection.put(record);
              }
            });
          }
          
          _processedRecords += chunk.length;
          setState(() {
            _progress = _processedRecords / _totalRecords;
          });
          
          // Allow UI to update
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        if (collectionFixed > 0) {
          _repairLog.add('$name: Fixed $collectionFixed / $total records');
        }
        _fixedRecords += collectionFixed;
      }

      // ═══════════════════════════════════════════════════════════════
      // Phase 2: Repair ALL Collections
      // ═══════════════════════════════════════════════════════════════

      // 1. Categories
      await processCollection('Categories', isar.categorys, (record) {
        final cat = record as Category;
        bool needsFix = false;
        if (cat.categoryName == null || cat.categoryName!.trim().isEmpty) { cat.categoryName = 'Unknown'; needsFix = true; }
        if (cat.uuid == null || cat.uuid!.isEmpty) { cat.uuid = _generateUuid(cat.id); needsFix = true; }
        return needsFix;
      });

      // 2. Units
      await processCollection('Units', isar.units, (record) {
        final unit = record as Unit;
        bool needsFix = false;
        if (unit.uuid == null || unit.uuid!.isEmpty) { unit.uuid = _generateUuid(unit.id); needsFix = true; }
        return needsFix;
      });

      // 3. Brands
      await processCollection('Brands', isar.collection<Brand>(), (record) {
        final brand = record as Brand;
        bool needsFix = false;
        if (brand.uuid == null || brand.uuid!.isEmpty) { brand.uuid = _generateUuid(brand.id); needsFix = true; }
        if (brand.brandName == null || brand.brandName!.trim().isEmpty) { brand.brandName = 'Unknown Brand'; needsFix = true; }
        return needsFix;
      });

      // 4. Parties
      await processCollection('Parties', isar.partys, (record) {
        final p = record as Party;
        bool needsFix = false;
        if (p.uuid == null || p.uuid!.isEmpty) { p.uuid = _generateUuid(p.id); needsFix = true; }
        if (p.partyName == null || p.partyName!.trim().isEmpty) { p.partyName = 'Unknown Party'; needsFix = true; }
        if (p.partyType == null || p.partyType!.trim().isEmpty) { p.partyType = 'Customer'; needsFix = true; }
        if (p.outstandingBalance == null) { p.outstandingBalance = 0.0; needsFix = true; }
        if (p.openingBalance == null) { p.openingBalance = 0.0; needsFix = true; }
        return needsFix;
      });

      // 5. Items
      await processCollection('Items', isar.items, (record) {
        final item = record as Item;
        bool needsFix = false;
        if (item.uuid == null || item.uuid!.isEmpty) { item.uuid = _generateUuid(item.id); needsFix = true; }
        if (item.itemName == null || item.itemName!.trim().isEmpty) { item.itemName = 'Unknown Item'; needsFix = true; }
        if (item.currentStock == null) { item.currentStock = item.openingStock ?? 0.0; needsFix = true; }
        if (item.sellRate == null) { item.sellRate = 0.0; needsFix = true; }
        if (item.buyRate == null) { item.buyRate = 0.0; needsFix = true; }
        if (item.gstRate == null) { item.gstRate = 0.0; needsFix = true; }
        if (item.openingStock == null) { item.openingStock = 0.0; needsFix = true; }
        if (item.reorderLevel == null) { item.reorderLevel = 0.0; needsFix = true; }
        return needsFix;
      });

      // 6. Invoices — with paymentStatus recalculation + partyName resolution
      await processCollection('Invoices', isar.invoices, (record) {
        final inv = record as Invoice;
        bool needsFix = false;
        if (inv.uuid == null || inv.uuid!.isEmpty) { inv.uuid = _generateUuid(inv.id); needsFix = true; }
        if (inv.grandTotal == null) { inv.grandTotal = 0.0; needsFix = true; }
        if (inv.paidAmount == null) { inv.paidAmount = 0.0; needsFix = true; }
        if (inv.subtotal == null) { inv.subtotal = inv.grandTotal ?? 0.0; needsFix = true; }
        if (inv.invoiceType == null || inv.invoiceType!.trim().isEmpty) { inv.invoiceType = 'Tax Invoice'; needsFix = true; }
        
        // Resolve partyName from partyId if missing
        if (inv.partyId != null && (inv.partyName == null || inv.partyName!.trim().isEmpty)) {
          final p = partyByIdMap[inv.partyId!];
          if (p != null) { inv.partyName = p.partyName; needsFix = true; }
        }
        
        // Recalculate paymentStatus from actual paidAmount vs grandTotal
        final paid = inv.paidAmount ?? 0.0;
        final grand = inv.grandTotal ?? 0.0;
        final correctPending = (grand - paid).clamp(0.0, double.infinity);
        
        if (inv.pendingAmount == null || (inv.pendingAmount! - correctPending).abs() > 0.01) {
          inv.pendingAmount = correctPending;
          needsFix = true;
        }
        
        String correctStatus;
        if (grand > 0 && paid >= grand) {
          correctStatus = 'Paid';
        } else if (paid > 0) {
          correctStatus = 'Partially Paid';
        } else {
          correctStatus = 'Unpaid';
        }
        
        if (inv.paymentStatus != correctStatus) {
          inv.paymentStatus = correctStatus;
          needsFix = true;
        }
        
        return needsFix;
      });

      // 7. Invoice Items
      await processCollection('Invoice Items', isar.collection<InvoiceItem>(), (record) {
        final ii = record as InvoiceItem;
        bool needsFix = false;
        if (ii.uuid == null || ii.uuid!.isEmpty) { ii.uuid = _generateUuid(ii.id); needsFix = true; }
        if (ii.quantity == null) { ii.quantity = 0.0; needsFix = true; }
        if (ii.rate == null) { ii.rate = 0.0; needsFix = true; }
        if (ii.totalAmount == null) { ii.totalAmount = (ii.quantity ?? 0.0) * (ii.rate ?? 0.0); needsFix = true; }
        // Resolve itemName from itemId if missing
        if (ii.itemId != null && (ii.itemName == null || ii.itemName!.trim().isEmpty)) {
          final item = itemByIdMap[ii.itemId!];
          if (item != null) { ii.itemName = item.itemName; needsFix = true; }
        }
        return needsFix;
      });

      // 8. Purchases — with paymentStatus recalculation + partyName resolution
      await processCollection('Purchases', isar.collection<Purchase>(), (record) {
        final pur = record as Purchase;
        bool needsFix = false;
        if (pur.uuid == null || pur.uuid!.isEmpty) { pur.uuid = _generateUuid(pur.id); needsFix = true; }
        if (pur.grandTotal == null) { pur.grandTotal = 0.0; needsFix = true; }
        if (pur.paidAmount == null) { pur.paidAmount = 0.0; needsFix = true; }
        if (pur.subtotal == null) { pur.subtotal = pur.grandTotal ?? 0.0; needsFix = true; }
        
        // Resolve partyName from partyId if missing
        if (pur.partyId != null && (pur.partyName == null || pur.partyName!.trim().isEmpty)) {
          final p = partyByIdMap[pur.partyId!];
          if (p != null) { pur.partyName = p.partyName; needsFix = true; }
        }
        
        // Recalculate paymentStatus
        final paid = pur.paidAmount ?? 0.0;
        final grand = pur.grandTotal ?? 0.0;
        final correctPending = (grand - paid).clamp(0.0, double.infinity);
        
        if (pur.pendingAmount == null || (pur.pendingAmount! - correctPending).abs() > 0.01) {
          pur.pendingAmount = correctPending;
          needsFix = true;
        }
        
        String correctStatus;
        if (grand > 0 && paid >= grand) {
          correctStatus = 'Paid';
        } else if (paid > 0) {
          correctStatus = 'Partially Paid';
        } else {
          correctStatus = 'Unpaid';
        }
        
        if (pur.paymentStatus != correctStatus) {
          pur.paymentStatus = correctStatus;
          needsFix = true;
        }
        
        return needsFix;
      });

      // 9. Purchase Items
      await processCollection('Purchase Items', isar.collection<PurchaseItem>(), (record) {
        final pi = record as PurchaseItem;
        bool needsFix = false;
        if (pi.uuid == null || pi.uuid!.isEmpty) { pi.uuid = _generateUuid(pi.id); needsFix = true; }
        if (pi.quantity == null) { pi.quantity = 0.0; needsFix = true; }
        if (pi.rate == null) { pi.rate = 0.0; needsFix = true; }
        if (pi.totalAmount == null) { pi.totalAmount = (pi.quantity ?? 0.0) * (pi.rate ?? 0.0); needsFix = true; }
        // Resolve itemName from itemId if missing
        if (pi.itemId != null && (pi.itemName == null || pi.itemName!.trim().isEmpty)) {
          final item = itemByIdMap[pi.itemId!];
          if (item != null) { pi.itemName = item.itemName; needsFix = true; }
        }
        return needsFix;
      });

      // 10. Orders — with partyName resolution + status default
      await processCollection('Orders', isar.orders, (record) {
        final ord = record as Order;
        bool needsFix = false;
        if (ord.uuid == null || ord.uuid!.isEmpty) { ord.uuid = _generateUuid(ord.id); needsFix = true; }
        if (ord.grandTotal == null) { ord.grandTotal = 0.0; needsFix = true; }
        if (ord.status == null || ord.status!.trim().isEmpty) { ord.status = 'Pending'; needsFix = true; }
        // Resolve partyName from partyId if missing
        if (ord.partyId != null && (ord.partyName == null || ord.partyName!.trim().isEmpty)) {
          final p = partyByIdMap[ord.partyId!];
          if (p != null) { ord.partyName = p.partyName; needsFix = true; }
        }
        return needsFix;
      });

      // 11. Order Items
      await processCollection('Order Items', isar.collection<OrderItem>(), (record) {
        final oi = record as OrderItem;
        bool needsFix = false;
        if (oi.uuid == null || oi.uuid!.isEmpty) { oi.uuid = _generateUuid(oi.id); needsFix = true; }
        if (oi.quantity == null) { oi.quantity = 0.0; needsFix = true; }
        if (oi.rate == null) { oi.rate = 0.0; needsFix = true; }
        if (oi.totalAmount == null) { oi.totalAmount = (oi.quantity ?? 0.0) * (oi.rate ?? 0.0); needsFix = true; }
        // Resolve itemName from itemId if missing
        if (oi.itemId != null && (oi.itemName == null || oi.itemName!.trim().isEmpty)) {
          final item = itemByIdMap[oi.itemId!];
          if (item != null) { oi.itemName = item.itemName; needsFix = true; }
        }
        return needsFix;
      });

      // 12. Transactions — with partyName resolution + defaults
      await processCollection('Transactions', isar.transactions, (record) {
        final txn = record as Transaction;
        bool needsFix = false;
        if (txn.uuid == null || txn.uuid!.isEmpty) { txn.uuid = _generateUuid(txn.id); needsFix = true; }
        if (txn.amount == null) { txn.amount = 0.0; needsFix = true; }
        if (txn.transactionType == null || txn.transactionType!.trim().isEmpty) { txn.transactionType = 'Receipt'; needsFix = true; }
        if (txn.paymentMode == null || txn.paymentMode!.trim().isEmpty) { txn.paymentMode = 'Cash'; needsFix = true; }
        // Resolve partyName from partyUuid if missing
        if (txn.partyUuid != null && txn.partyUuid!.isNotEmpty && (txn.partyName == null || txn.partyName!.trim().isEmpty)) {
          final p = partyByUuidMap[txn.partyUuid!];
          if (p != null) { txn.partyName = p.partyName; needsFix = true; }
        }
        return needsFix;
      });

      // 13. Expenses
      await processCollection('Expenses', isar.collection<Expense>(), (record) {
        final exp = record as Expense;
        bool needsFix = false;
        if (exp.uuid == null || exp.uuid!.isEmpty) { exp.uuid = _generateUuid(exp.id); needsFix = true; }
        if (exp.amount == null) { exp.amount = 0.0; needsFix = true; }
        if (exp.category == null || exp.category!.trim().isEmpty) { exp.category = 'Other'; needsFix = true; }
        if (exp.paymentMode == null || exp.paymentMode!.trim().isEmpty) { exp.paymentMode = 'Cash'; needsFix = true; }
        return needsFix;
      });

      // 14. Expense Items (master list)
      await processCollection('Expense Items', isar.collection<ExpenseItem>(), (record) {
        final ei = record as ExpenseItem;
        bool needsFix = false;
        if (ei.uuid == null || ei.uuid!.isEmpty) { ei.uuid = _generateUuid(ei.id); needsFix = true; }
        if (ei.itemName == null || ei.itemName!.trim().isEmpty) { ei.itemName = 'Unknown Expense'; needsFix = true; }
        return needsFix;
      });

      // 15. Credit Notes — with partyName resolution
      await processCollection('Credit Notes', isar.collection<CreditNote>(), (record) {
        final cn = record as CreditNote;
        bool needsFix = false;
        if (cn.uuid == null || cn.uuid!.isEmpty) { cn.uuid = _generateUuid(cn.id); needsFix = true; }
        if (cn.grandTotal == null) { cn.grandTotal = 0.0; needsFix = true; }
        if (cn.subtotal == null) { cn.subtotal = cn.grandTotal ?? 0.0; needsFix = true; }
        // Resolve partyName from partyId if missing
        if (cn.partyId != null && (cn.partyName == null || cn.partyName!.trim().isEmpty)) {
          final p = partyByIdMap[cn.partyId!];
          if (p != null) { cn.partyName = p.partyName; needsFix = true; }
        }
        return needsFix;
      });

      // 16. Credit Note Items
      await processCollection('Credit Note Items', isar.collection<CreditNoteItem>(), (record) {
        final cni = record as CreditNoteItem;
        bool needsFix = false;
        if (cni.uuid == null || cni.uuid!.isEmpty) { cni.uuid = _generateUuid(cni.id); needsFix = true; }
        if (cni.quantity == null) { cni.quantity = 0.0; needsFix = true; }
        if (cni.rate == null) { cni.rate = 0.0; needsFix = true; }
        if (cni.totalAmount == null) { cni.totalAmount = (cni.quantity ?? 0.0) * (cni.rate ?? 0.0); needsFix = true; }
        if (cni.itemId != null && (cni.itemName == null || cni.itemName!.trim().isEmpty)) {
          final item = itemByIdMap[cni.itemId!];
          if (item != null) { cni.itemName = item.itemName; needsFix = true; }
        }
        return needsFix;
      });

      // 17. Debit Notes — with partyName resolution
      await processCollection('Debit Notes', isar.collection<DebitNote>(), (record) {
        final dn = record as DebitNote;
        bool needsFix = false;
        if (dn.uuid == null || dn.uuid!.isEmpty) { dn.uuid = _generateUuid(dn.id); needsFix = true; }
        if (dn.grandTotal == null) { dn.grandTotal = 0.0; needsFix = true; }
        if (dn.subtotal == null) { dn.subtotal = dn.grandTotal ?? 0.0; needsFix = true; }
        // Resolve partyName from partyId if missing
        if (dn.partyId != null && (dn.partyName == null || dn.partyName!.trim().isEmpty)) {
          final p = partyByIdMap[dn.partyId!];
          if (p != null) { dn.partyName = p.partyName; needsFix = true; }
        }
        return needsFix;
      });

      // 18. Debit Note Items
      await processCollection('Debit Note Items', isar.collection<DebitNoteItem>(), (record) {
        final dni = record as DebitNoteItem;
        bool needsFix = false;
        if (dni.uuid == null || dni.uuid!.isEmpty) { dni.uuid = _generateUuid(dni.id); needsFix = true; }
        if (dni.quantity == null) { dni.quantity = 0.0; needsFix = true; }
        if (dni.rate == null) { dni.rate = 0.0; needsFix = true; }
        if (dni.totalAmount == null) { dni.totalAmount = (dni.quantity ?? 0.0) * (dni.rate ?? 0.0); needsFix = true; }
        if (dni.itemId != null && (dni.itemName == null || dni.itemName!.trim().isEmpty)) {
          final item = itemByIdMap[dni.itemId!];
          if (item != null) { dni.itemName = item.itemName; needsFix = true; }
        }
        return needsFix;
      });

      // 19. Bank Accounts
      await processCollection('Bank Accounts', isar.collection<BankAccount>(), (record) {
        final ba = record as BankAccount;
        bool needsFix = false;
        if (ba.uuid == null || ba.uuid!.isEmpty) { ba.uuid = _generateUuid(ba.id); needsFix = true; }
        if (ba.accountName == null || ba.accountName!.trim().isEmpty) { ba.accountName = 'Unknown Account'; needsFix = true; }
        if (ba.openingBalance == null) { ba.openingBalance = 0.0; needsFix = true; }
        if (ba.currentBalance == null) { ba.currentBalance = ba.openingBalance ?? 0.0; needsFix = true; }
        return needsFix;
      });

      // 20. Stock Adjustments — with itemName resolution
      await processCollection('Stock Adjustments', isar.collection<StockAdjustment>(), (record) {
        final sa = record as StockAdjustment;
        bool needsFix = false;
        if (sa.uuid == null || sa.uuid!.isEmpty) { sa.uuid = _generateUuid(sa.id); needsFix = true; }
        if (sa.quantity == null) { sa.quantity = 0.0; needsFix = true; }
        if (sa.adjustmentType == null || sa.adjustmentType!.trim().isEmpty) { sa.adjustmentType = 'Add'; needsFix = true; }
        // Resolve itemName from itemUuid if missing
        if (sa.itemUuid != null && sa.itemUuid!.isNotEmpty && (sa.itemName == null || sa.itemName!.trim().isEmpty)) {
          final item = itemByUuidMap[sa.itemUuid!];
          if (item != null) { sa.itemName = item.itemName; needsFix = true; }
        }
        // Resolve itemName from itemId if missing and itemUuid didn't resolve
        if (sa.itemId != null && (sa.itemName == null || sa.itemName!.trim().isEmpty)) {
          final item = itemByIdMap[sa.itemId!];
          if (item != null) { sa.itemName = item.itemName; needsFix = true; }
        }
        return needsFix;
      });

      // ═══════════════════════════════════════════════════════════════
      // Phase 3: Complete
      // ═══════════════════════════════════════════════════════════════

      _timer?.cancel();
      setState(() {
        _isRepairing = false;
        _progress = 1.0;
        _currentTask = 'Deep Repair Complete!';
        _estimatedTime = '00:00';
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Expanded(child: Text('Repair Successful', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Scanned $_totalRecords records across 20 collections.\nFixed $_fixedRecords corrupted/legacy records.',
                    style: const TextStyle(fontWeight: FontWeight.w600, height: 1.5),
                  ),
                  if (_repairLog.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Repair Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ..._repairLog.map((log) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Colors.green),
                          const SizedBox(width: 6),
                          Expanded(child: Text(log, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    )),
                  ],
                  if (_repairLog.isEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      '✅ All records are already in perfect condition! No fixes needed.',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      _timer?.cancel();
      setState(() {
        _isRepairing = false;
        _currentTask = 'Repair failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (_progress * 100).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Repair & Re-Write'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.build_circle_outlined, size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Deep Data Integrity Repair',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This tool scans ALL 20 database collections and repairs missing UUIDs, broken party/item links, incorrect payment statuses, null balances, and imported data inconsistencies.\n\nSafe to run on any version restore or Excel import.',
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.4, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    // Progress Section
                    if (_isRepairing || _progress > 0) ...[
                      LinearProgressIndicator(
                        value: _progress,
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(6),
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$_processedRecords / $_totalRecords Records', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('$percent%', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(_currentTask, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                          Text('Est. Time: $_estimatedTime', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      if (_fixedRecords > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '$_fixedRecords records fixed so far',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                        ),
                      ],
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _isRepairing ? Colors.grey : theme.colorScheme.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isRepairing 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.warning_amber_rounded),
                        label: Text(_isRepairing ? 'Repairing Database...' : 'START DEEP REPAIR', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: _isRepairing ? null : _startRepair,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
