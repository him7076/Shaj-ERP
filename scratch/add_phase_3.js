const fs = require('fs');

const path = 'lib/features/backup/presentation/screens/data_repair_screen.dart';
let code = fs.readFileSync(path, 'utf8');

const targetStr = `      // Phase 3: Complete
      // ═══════════════════════════════════════════════════════════════`;

const replacement = `      // Phase 3: Auto-generate missing Receipt/Payment Transactions
      setState(() { _currentTask = 'Generating missing Receipts/Payments...'; });
      
      final allTransactions = await isar.transactions.where().findAll();
      final txnByLinkedUuid = <String, Transaction>{};
      final txnByLinkedNumber = <String, Transaction>{};
      
      for (var t in allTransactions) {
        if (t.linkedBillUuid != null && t.linkedBillUuid!.isNotEmpty) txnByLinkedUuid[t.linkedBillUuid!] = t;
        if (t.linkedBillNumber != null && t.linkedBillNumber!.isNotEmpty) txnByLinkedNumber[t.linkedBillNumber!] = t;
      }
      
      final newTxns = <Transaction>[];
      int autoTxns = 0;
      
      // Check Invoices
      final allInvoicesCheck = await isar.invoices.where().findAll();
      for (var inv in allInvoicesCheck) {
        if (inv.paidAmount != null && inv.paidAmount! > 0) {
          if (!txnByLinkedUuid.containsKey(inv.uuid) && !txnByLinkedNumber.containsKey(inv.invoiceNumber)) {
            final t = Transaction()
              ..uuid = _generateUuid(inv.id)
              ..transactionNumber = 'RCPT-\${DateTime.now().millisecondsSinceEpoch}-\${inv.id}'
              ..transactionType = 'Receipt'
              ..amount = inv.paidAmount
              ..transactionDate = inv.invoiceDate ?? inv.createdAt
              ..partyUuid = inv.partyId != null ? partyByIdMap[inv.partyId]?.uuid : null
              ..partyName = inv.partyName
              ..remarks = 'Auto-recovered Payment for Invoice #\${inv.invoiceNumber}'
              ..paymentMode = 'Cash'
              ..paymentStatus = 'Paid'
              ..linkedBillUuid = inv.uuid
              ..linkedBillNumber = inv.invoiceNumber
              ..createdAt = inv.createdAt
              ..updatedAt = DateTime.now()
              ..isDeleted = false
              ..isSynced = false
              ..version = 1;
            newTxns.add(t);
            autoTxns++;
          }
        }
      }
      
      // Check Purchases
      final allPurchasesCheck = await isar.purchases.where().findAll();
      for (var pur in allPurchasesCheck) {
        if (pur.paidAmount != null && pur.paidAmount! > 0) {
          if (!txnByLinkedUuid.containsKey(pur.uuid) && !txnByLinkedNumber.containsKey(pur.purchaseNumber)) {
            final t = Transaction()
              ..uuid = _generateUuid(pur.id)
              ..transactionNumber = 'PAY-\${DateTime.now().millisecondsSinceEpoch}-\${pur.id}'
              ..transactionType = 'Payment'
              ..amount = pur.paidAmount
              ..transactionDate = pur.purchaseDate ?? pur.createdAt
              ..partyUuid = pur.partyId != null ? partyByIdMap[pur.partyId]?.uuid : null
              ..partyName = pur.partyName
              ..remarks = 'Auto-recovered Payment for Purchase #\${pur.purchaseNumber}'
              ..paymentMode = 'Cash'
              ..paymentStatus = 'Paid'
              ..linkedBillUuid = pur.uuid
              ..linkedBillNumber = pur.purchaseNumber
              ..createdAt = pur.createdAt
              ..updatedAt = DateTime.now()
              ..isDeleted = false
              ..isSynced = false
              ..version = 1;
            newTxns.add(t);
            autoTxns++;
          }
        }
      }
      
      if (newTxns.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.transactions.putAll(newTxns);
        });
        _repairLog.add('Auto-generated $autoTxns missing Receipt/Payment transactions.');
        _fixedRecords += autoTxns;
      }

      // Phase 4: Complete
      // ═══════════════════════════════════════════════════════════════`;

if (code.includes(targetStr)) {
  code = code.replace(targetStr, replacement);
  fs.writeFileSync(path, code);
  console.log('Successfully added Phase 3 to data_repair_screen.dart');
} else {
  console.error('Target string not found in data_repair_screen.dart');
}
