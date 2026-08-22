import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
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

  Future<void> _startRepair() async {
    final isar = ref.read(isarProvider);
    
    setState(() {
      _isRepairing = true;
      _progress = 0.0;
      _processedRecords = 0;
      _fixedRecords = 0;
      _startTime = DateTime.now();
      _currentTask = 'Counting records...';
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTimer());

    try {
      // Phase 1: Count
      final itemsCount = await isar.items.count();
      final invoicesCount = await isar.invoices.count();
      final purchasesCount = await isar.collection<Purchase>().count();
      final partiesCount = await isar.partys.count();
      final transactionsCount = await isar.transactions.count();
      final ordersCount = await isar.orders.count();
      final categoriesCount = await isar.categorys.count();
      final unitsCount = await isar.units.count();

      _totalRecords = itemsCount + invoicesCount + purchasesCount + partiesCount + 
                      transactionsCount + ordersCount + categoriesCount + unitsCount;

      if (_totalRecords == 0) {
        setState(() {
          _isRepairing = false;
          _currentTask = 'Database is empty.';
          _progress = 1.0;
        });
        _timer?.cancel();
        return;
      }

      // Helper function to process collections
      Future<void> processCollection<T>(
        String name,
        IsarCollection<dynamic> collection,
        Future<void> Function(dynamic record) fixRecord
      ) async {
        setState(() => _currentTask = 'Repairing $name...');
        
        // Process in chunks to avoid memory issues
        const chunkSize = 200;
        final total = await collection.count();
        
        for (int i = 0; i < total; i += chunkSize) {
          final chunk = await collection.where().offset(i).limit(chunkSize).findAll();
          
          for (var record in chunk) {
            await isar.writeTxn(() async {
              await fixRecord(record);
            });
            _processedRecords++;
            setState(() {
              _progress = _processedRecords / _totalRecords;
            });
            
            // Allow UI to update
            if (_processedRecords % 10 == 0) {
              await Future.delayed(const Duration(milliseconds: 1));
            }
          }
        }
      }

      // Phase 2: Repair Data
      
      // 1. Categories
      await processCollection('Categories', isar.categorys, (record) async {
        final cat = record as Category;
        bool needsFix = false;
        if (cat.name == null) { cat.name = 'Unknown'; needsFix = true; }
        if (cat.uuid == null || cat.uuid!.isEmpty) { cat.uuid = DateTime.now().millisecondsSinceEpoch.toString(); needsFix = true; }
        await isar.categorys.put(cat);
        if (needsFix) _fixedRecords++;
      });

      // 2. Units
      await processCollection('Units', isar.units, (record) async {
        final unit = record as Unit;
        bool needsFix = false;
        if (unit.uuid == null || unit.uuid!.isEmpty) { unit.uuid = DateTime.now().millisecondsSinceEpoch.toString(); needsFix = true; }
        await isar.units.put(unit);
        if (needsFix) _fixedRecords++;
      });

      // 3. Parties
      await processCollection('Parties', isar.partys, (record) async {
        final p = record as Party;
        bool needsFix = false;
        if (p.uuid == null || p.uuid!.isEmpty) { p.uuid = DateTime.now().millisecondsSinceEpoch.toString(); needsFix = true; }
        if (p.partyName == null) { p.partyName = 'Unknown Party'; needsFix = true; }
        if (p.outstandingBalance == null) { p.outstandingBalance = 0.0; needsFix = true; }
        await isar.partys.put(p);
        if (needsFix) _fixedRecords++;
      });

      // 4. Items
      await processCollection('Items', isar.items, (record) async {
        final item = record as Item;
        bool needsFix = false;
        if (item.uuid == null || item.uuid!.isEmpty) { item.uuid = DateTime.now().millisecondsSinceEpoch.toString(); needsFix = true; }
        if (item.itemName == null) { item.itemName = 'Unknown Item'; needsFix = true; }
        if (item.currentStock == null) { item.currentStock = 0.0; needsFix = true; }
        if (item.salesPrice == null) { item.salesPrice = 0.0; needsFix = true; }
        await isar.items.put(item);
        if (needsFix) _fixedRecords++;
      });

      // 5. Invoices
      await processCollection('Invoices', isar.invoices, (record) async {
        final inv = record as Invoice;
        bool needsFix = false;
        if (inv.uuid == null || inv.uuid!.isEmpty) { inv.uuid = DateTime.now().millisecondsSinceEpoch.toString(); needsFix = true; }
        if (inv.grandTotal == null) { inv.grandTotal = 0.0; needsFix = true; }
        if (inv.balanceAmount == null) { inv.balanceAmount = inv.grandTotal; needsFix = true; }
        if (inv.partyId != null && (inv.partyName == null || inv.partyName!.isEmpty)) {
          final p = await isar.partys.get(inv.partyId!);
          if (p != null) { inv.partyName = p.partyName; needsFix = true; }
        }
        await isar.invoices.put(inv);
        if (needsFix) _fixedRecords++;
      });

      // 6. Purchases
      await processCollection('Purchases', isar.collection<Purchase>(), (record) async {
        final pur = record as Purchase;
        bool needsFix = false;
        if (pur.uuid == null || pur.uuid!.isEmpty) { pur.uuid = DateTime.now().millisecondsSinceEpoch.toString(); needsFix = true; }
        if (pur.grandTotal == null) { pur.grandTotal = 0.0; needsFix = true; }
        if (pur.balanceAmount == null) { pur.balanceAmount = pur.grandTotal; needsFix = true; }
        if (pur.partyId != null && (pur.partyName == null || pur.partyName!.isEmpty)) {
          final p = await isar.partys.get(pur.partyId!);
          if (p != null) { pur.partyName = p.partyName; needsFix = true; }
        }
        await isar.collection<Purchase>().put(pur);
        if (needsFix) _fixedRecords++;
      });

      // 7. Orders
      await processCollection('Orders', isar.orders, (record) async {
        final ord = record as Order;
        bool needsFix = false;
        if (ord.uuid == null || ord.uuid!.isEmpty) { ord.uuid = DateTime.now().millisecondsSinceEpoch.toString(); needsFix = true; }
        if (ord.grandTotal == null) { ord.grandTotal = 0.0; needsFix = true; }
        await isar.orders.put(ord);
        if (needsFix) _fixedRecords++;
      });

      // 8. Transactions
      await processCollection('Transactions', isar.transactions, (record) async {
        final txn = record as Transaction;
        bool needsFix = false;
        if (txn.uuid == null || txn.uuid!.isEmpty) { txn.uuid = DateTime.now().millisecondsSinceEpoch.toString(); needsFix = true; }
        if (txn.amount == null) { txn.amount = 0.0; needsFix = true; }
        if (txn.partyId != null && (txn.partyName == null || txn.partyName!.isEmpty)) {
          final p = await isar.partys.get(txn.partyId!);
          if (p != null) { txn.partyName = p.partyName; needsFix = true; }
        }
        await isar.transactions.put(txn);
        if (needsFix) _fixedRecords++;
      });

      _timer?.cancel();
      setState(() {
        _isRepairing = false;
        _progress = 1.0;
        _currentTask = 'Data Repair & Optimization Complete!';
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
                Text('Repair Successful'),
              ],
            ),
            content: Text('Successfully scanned $_totalRecords records.\nFixed and rewrote $_fixedRecords corrupted/legacy records.'),
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
                      'This tool will scan every single entry in your database (Items, Sales, Purchases, Transactions, etc.) and rewrite them to fix missing references, broken links, null balances, and UUIDs.',
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
                          Text(_currentTask, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('Est. Time: $_estimatedTime', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
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
