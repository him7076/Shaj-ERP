import 'dart:io';

void main() {
  final file = File('lib/data/repositories/transaction_repository_impl.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll(RegExp(r'            party\.updatedAt = DateTime\.now\(\);\s+await isar\.partys\.put\(party\);'), '''            party.updatedAt = DateTime.now();
            party.isSynced = false;
            await isar.partys.put(party);
            await isar.syncQueues.put(SyncQueue()
              ..uuid = _generateUuid()
              ..entityType = 'Party'
              ..entityId = party.id
              ..entityUuid = party.uuid
              ..operation = 'Update'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now());''');

  content = content.replaceAll(RegExp(r'            targetParty\.updatedAt = DateTime\.now\(\);\s+await isar\.partys\.put\(targetParty\);'), '''            targetParty.updatedAt = DateTime.now();
            targetParty.isSynced = false;
            await isar.partys.put(targetParty);
            await isar.syncQueues.put(SyncQueue()
              ..uuid = _generateUuid()
              ..entityType = 'Party'
              ..entityId = targetParty.id
              ..entityUuid = targetParty.uuid
              ..operation = 'Update'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now());''');

  final targetBlockRegex = RegExp(r"            if \(type == 'Receipt' \|\| type == 'Credit Note'\) \{\s+final invoice = await _findInvoice\(billUuid\);\s+if \(invoice != null\) \{\s+invoice\.paidAmount = \(invoice\.paidAmount \?\? 0\.0\) - allocAmt;\s+if \(invoice\.paidAmount! < 0\) invoice\.paidAmount = 0\.0;\s+invoice\.pendingAmount = \(invoice\.grandTotal \?\? 0\.0\) - invoice\.paidAmount!;\s+if \(invoice\.pendingAmount! <= 0\) \{\s+invoice\.paymentStatus = 'Paid';\s+\} else if \(invoice\.paidAmount! > 0\) \{\s+invoice\.paymentStatus = 'Partially Paid';\s+\} else \{\s+invoice\.paymentStatus = 'Unpaid';\s+\}\s+invoice\.updatedAt = DateTime\.now\(\);\s+await isar\.invoices\.put\(invoice\);\s+\}\s+\} else if \(type == 'Payment' \|\| type == 'Debit Note'\) \{\s+final purchase = await _findPurchase\(billUuid\);\s+if \(purchase != null\) \{\s+purchase\.paidAmount = \(purchase\.paidAmount \?\? 0\.0\) - allocAmt;\s+if \(purchase\.paidAmount! < 0\) purchase\.paidAmount = 0\.0;\s+purchase\.pendingAmount = \(purchase\.grandTotal \?\? 0\.0\) - purchase\.paidAmount!;\s+if \(purchase\.pendingAmount! <= 0\) \{\s+purchase\.paymentStatus = 'Paid';\s+\} else if \(purchase\.paidAmount! > 0\) \{\s+purchase\.paymentStatus = 'Partially Paid';\s+\} else \{\s+purchase\.paymentStatus = 'Unpaid';\s+\}\s+purchase\.updatedAt = DateTime\.now\(\);\s+await isar\.purchases\.put\(purchase\);\s+\}\s+\}");

  final replaceBlock = '''            final invoice = await _findInvoice(billUuid);
            if (invoice != null) {
              invoice.paidAmount = (invoice.paidAmount ?? 0.0) - allocAmt;
              if (invoice.paidAmount! < 0) invoice.paidAmount = 0.0;
              invoice.pendingAmount = (invoice.grandTotal ?? 0.0) - invoice.paidAmount!;
              if (invoice.pendingAmount! <= 0) {
                invoice.paymentStatus = 'Paid';
              } else if (invoice.paidAmount! > 0) {
                invoice.paymentStatus = 'Partially Paid';
              } else {
                invoice.paymentStatus = 'Unpaid';
              }
              invoice.updatedAt = DateTime.now();
              invoice.isSynced = false;
              await isar.invoices.put(invoice);
              await isar.syncQueues.put(SyncQueue()
                ..uuid = _generateUuid()
                ..entityType = 'Invoice'
                ..entityId = invoice.id
                ..entityUuid = invoice.uuid
                ..operation = 'Update'
                ..createdAt = DateTime.now()
                ..updatedAt = DateTime.now());
            } else {
              final purchase = await _findPurchase(billUuid);
              if (purchase != null) {
                purchase.paidAmount = (purchase.paidAmount ?? 0.0) - allocAmt;
                if (purchase.paidAmount! < 0) purchase.paidAmount = 0.0;
                purchase.pendingAmount = (purchase.grandTotal ?? 0.0) - purchase.paidAmount!;
                if (purchase.pendingAmount! <= 0) {
                  purchase.paymentStatus = 'Paid';
                } else if (purchase.paidAmount! > 0) {
                  purchase.paymentStatus = 'Partially Paid';
                } else {
                  purchase.paymentStatus = 'Unpaid';
                }
                purchase.updatedAt = DateTime.now();
                purchase.isSynced = false;
                await isar.purchases.put(purchase);
                await isar.syncQueues.put(SyncQueue()
                  ..uuid = _generateUuid()
                  ..entityType = 'Purchase'
                  ..entityId = purchase.id
                  ..entityUuid = purchase.uuid
                  ..operation = 'Update'
                  ..createdAt = DateTime.now()
                  ..updatedAt = DateTime.now());
              }
            }''';

  if (targetBlockRegex.hasMatch(content)) {
    content = content.replaceFirst(targetBlockRegex, replaceBlock);
    file.writeAsStringSync(content);
    print('Patched successfully!');
  } else {
    print('Failed to find target block.');
  }
}
