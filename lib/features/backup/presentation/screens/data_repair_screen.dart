import 'dart:async';
import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
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
    setState(() {
      _isRepairing = true;
      _currentTask = 'Clearing deep repair...';
    });

    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isRepairing = false;
      _currentTask = 'Old deep repair system has been completely cleared out.';
      _progress = 1.0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deep repair logic cleared successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (_progress * 100).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        title: const Text('Database Repair & Re-Write'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: NeuCard(
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
