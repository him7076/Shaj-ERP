import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/snapshot_backup_service.dart';
import 'package:business_sahaj_erp/core/services/stock_recalculator_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deepRepairServiceProvider = Provider((ref) => DeepRepairService());

class DeepRepairService {
  String _generateUuid() {
    return '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  Future<void> runDeepRepair({
    required DatabaseService dbService,
    required SharedPreferences prefs,
    required Function(String task, double progress) onProgress,
  }) async {
    try {
      // Step 1: Create Backup
      onProgress('Creating backup of current firm...', 0.1);
      final backupService = SnapshotBackupService();
      try {
        await backupService.createSnapshotBackup(dbService: dbService, prefs: prefs);
      } catch (e) {
        onProgress('Backup failed, continuing anyway...', 0.15);
      }

      // Step 2: Extract Data
      onProgress('Extracting data from active firm...', 0.3);
      final currentFirmId = dbService.activeFirmId;
      final allData = await dbService.exportCollectionsToJson(currentFirmId);

      // Step 3: Repair and Restructure Data based on latest schema
      onProgress('Repairing and re-structuring records...', 0.5);
      final repairedData = _repairJsonData(allData);

      // Step 4: Create new firm
      final newFirmId = 'firm_repaired_${DateTime.now().millisecondsSinceEpoch}';
      onProgress('Creating new firm: $newFirmId...', 0.7);
      
      // Give the new firm a name in SharedPreferences
      final oldName = prefs.getString('firm_name_$currentFirmId') ?? 'My Firm';
      await prefs.setString('firm_name_$newFirmId', '$oldName (Repaired)');
      
      // Switch active database to the new firm
      await dbService.switchFirm(newFirmId, prefs);

      // Step 5: Import Data
      onProgress('Importing proper data into new firm...', 0.85);
      await dbService.importCollectionsFromJson(newFirmId, repairedData);

      // Step 6: Baseline Stock Recalculation
      onProgress('Recalculating item stock levels...', 0.95);
      await StockRecalculatorService.recalculateAllItemStocks(dbService.isar);

      onProgress('Deep Repair Successful!', 1.0);
    } catch (e) {
      throw Exception('Failed to run deep repair: $e');
    }
  }

  Map<String, dynamic> _repairJsonData(Map<String, dynamic> data) {
    // 1. Sanitize all collections (isDeleted, isSynced, UUIDs, Dates)
    for (var key in data.keys) {
      if (data[key] is List) {
        for (var item in (data[key] as List)) {
          if (item is Map) {
            item['isDeleted'] = false;
            item['isSynced'] = false;
            
            if (item['uuid'] == null || item['uuid'].toString().isEmpty) {
              item['uuid'] = _generateUuid();
            }
            if (item['createdAt'] == null) {
              item['createdAt'] = DateTime.now().millisecondsSinceEpoch;
            }
            item['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
          }
        }
      }
    }

    // 2. Build lookups for transactions
    final txns = (data['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final txnByLinkedUuid = <String, Map<String, dynamic>>{};
    final txnByLinkedNumber = <String, Map<String, dynamic>>{};
    
    for (var t in txns) {
      final lu = t['linkedBillUuid']?.toString();
      final ln = t['linkedBillNumber']?.toString();
      if (lu != null && lu.isNotEmpty) txnByLinkedUuid[lu] = t;
      if (ln != null && ln.isNotEmpty) txnByLinkedNumber[ln] = t;
    }

    final newTransactions = <Map<String, dynamic>>[];

    // 3. Process Invoices (recalculate balances & auto-generate receipts)
    final invoices = (data['invoices'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (var inv in invoices) {
      final grandTotal = (inv['grandTotal'] as num?)?.toDouble() ?? 0.0;
      final paidAmount = (inv['paidAmount'] as num?)?.toDouble() ?? 0.0;
      inv['grandTotal'] = grandTotal;
      inv['paidAmount'] = paidAmount;
      inv['subtotal'] = (inv['subtotal'] as num?)?.toDouble() ?? grandTotal;
      inv['pendingAmount'] = (grandTotal - paidAmount).clamp(0.0, double.infinity);
      
      if (grandTotal > 0 && paidAmount >= grandTotal) {
        inv['paymentStatus'] = 'Paid';
      } else if (paidAmount > 0) {
        inv['paymentStatus'] = 'Partially Paid';
      } else {
        inv['paymentStatus'] = 'Unpaid';
      }

      if (paidAmount > 0) {
        final uuid = inv['uuid']?.toString();
        final num = inv['invoiceNumber']?.toString();
        if ((uuid != null && !txnByLinkedUuid.containsKey(uuid)) && 
            (num != null && !txnByLinkedNumber.containsKey(num))) {
          // Missing receipt
          newTransactions.add({
            'id': null,
            'uuid': _generateUuid(),
            'transactionNumber': 'RCPT-${DateTime.now().millisecondsSinceEpoch}-${inv['id'] ?? Random().nextInt(1000)}',
            'transactionType': 'Receipt',
            'amount': paidAmount,
            'transactionDate': inv['invoiceDate'] ?? inv['createdAt'],
            'partyUuid': inv['partyUuid'],
            'partyName': inv['partyName'] ?? 'Unknown Party',
            'remarks': 'Auto-recovered Payment for Invoice #$num',
            'paymentMode': 'Cash',
            'paymentStatus': 'Paid',
            'linkedBillUuid': uuid,
            'linkedBillNumber': num,
            'isDeleted': false,
            'isSynced': false,
            'createdAt': inv['createdAt'],
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }
    }

    // 4. Process Purchases (recalculate balances & auto-generate payments)
    final purchases = (data['purchases'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (var pur in purchases) {
      final grandTotal = (pur['grandTotal'] as num?)?.toDouble() ?? 0.0;
      final paidAmount = (pur['paidAmount'] as num?)?.toDouble() ?? 0.0;
      pur['grandTotal'] = grandTotal;
      pur['paidAmount'] = paidAmount;
      pur['subtotal'] = (pur['subtotal'] as num?)?.toDouble() ?? grandTotal;
      pur['pendingAmount'] = (grandTotal - paidAmount).clamp(0.0, double.infinity);
      
      if (grandTotal > 0 && paidAmount >= grandTotal) {
        pur['paymentStatus'] = 'Paid';
      } else if (paidAmount > 0) {
        pur['paymentStatus'] = 'Partially Paid';
      } else {
        pur['paymentStatus'] = 'Unpaid';
      }

      if (paidAmount > 0) {
        final uuid = pur['uuid']?.toString();
        final num = pur['purchaseNumber']?.toString();
        if ((uuid != null && !txnByLinkedUuid.containsKey(uuid)) && 
            (num != null && !txnByLinkedNumber.containsKey(num))) {
          // Missing payment
          newTransactions.add({
            'id': null,
            'uuid': _generateUuid(),
            'transactionNumber': 'PAY-${DateTime.now().millisecondsSinceEpoch}-${pur['id'] ?? Random().nextInt(1000)}',
            'transactionType': 'Payment',
            'amount': paidAmount,
            'transactionDate': pur['purchaseDate'] ?? pur['createdAt'],
            'partyUuid': pur['partyUuid'],
            'partyName': pur['partyName'] ?? 'Unknown Party',
            'remarks': 'Auto-recovered Payment for Purchase #$num',
            'paymentMode': 'Cash',
            'paymentStatus': 'Paid',
            'linkedBillUuid': uuid,
            'linkedBillNumber': num,
            'isDeleted': false,
            'isSynced': false,
            'createdAt': pur['createdAt'],
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }
    }

    if (newTransactions.isNotEmpty) {
      if (data['transactions'] == null) {
        data['transactions'] = [];
      }
      (data['transactions'] as List).addAll(newTransactions);
    }

    return data;
  }
}
