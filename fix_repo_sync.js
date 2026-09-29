const fs = require('fs');

const filePath = 'lib/data/repositories/transaction_repository_impl.dart';
let content = fs.readFileSync(filePath, 'utf8');

const p1 = /            party\.updatedAt = DateTime\.now\(\);\r?\n            await isar\.partys\.put\(party\);/g;
content = content.replace(p1, `            party.updatedAt = DateTime.now();
            party.isSynced = false;
            await isar.partys.put(party);
            await isar.syncQueues.put(SyncQueue()
              ..uuid = _generateUuid()
              ..entityType = 'Party'
              ..entityId = party.id
              ..entityUuid = party.uuid
              ..operation = 'Update'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now());`);

const p2 = /            targetParty\.updatedAt = DateTime\.now\(\);\r?\n            await isar\.partys\.put\(targetParty\);/g;
content = content.replace(p2, `            targetParty.updatedAt = DateTime.now();
            targetParty.isSynced = false;
            await isar.partys.put(targetParty);
            await isar.syncQueues.put(SyncQueue()
              ..uuid = _generateUuid()
              ..entityType = 'Party'
              ..entityId = targetParty.id
              ..entityUuid = targetParty.uuid
              ..operation = 'Update'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now());`);

const p3 = /            if \(type == 'Receipt' \|\| type == 'Credit Note'\) \{\r?\n\s+final invoice = await _findInvoice\(billUuid\);\r?\n\s+if \(invoice != null\) \{\r?\n\s+invoice\.paidAmount = \(invoice\.paidAmount \?\? 0\.0\) - allocAmt;\r?\n\s+if \(invoice\.paidAmount! < 0\) invoice\.paidAmount = 0\.0;\r?\n\s+invoice\.pendingAmount = \(invoice\.grandTotal \?\? 0\.0\) - invoice\.paidAmount!;\r?\n\s+if \(invoice\.pendingAmount! <= 0\) \{\r?\n\s+invoice\.paymentStatus = 'Paid';\r?\n\s+\} else if \(invoice\.paidAmount! > 0\) \{\r?\n\s+invoice\.paymentStatus = 'Partially Paid';\r?\n\s+\} else \{\r?\n\s+invoice\.paymentStatus = 'Unpaid';\r?\n\s+\}\r?\n\s+invoice\.updatedAt = DateTime\.now\(\);\r?\n\s+await isar\.invoices\.put\(invoice\);\r?\n\s+\}\r?\n\s+\} else if \(type == 'Payment' \|\| type == 'Debit Note'\) \{\r?\n\s+final purchase = await _findPurchase\(billUuid\);\r?\n\s+if \(purchase != null\) \{\r?\n\s+purchase\.paidAmount = \(purchase\.paidAmount \?\? 0\.0\) - allocAmt;\r?\n\s+if \(purchase\.paidAmount! < 0\) purchase\.paidAmount = 0\.0;\r?\n\s+purchase\.pendingAmount = \(purchase\.grandTotal \?\? 0\.0\) - purchase\.paidAmount!;\r?\n\s+if \(purchase\.pendingAmount! <= 0\) \{\r?\n\s+purchase\.paymentStatus = 'Paid';\r?\n\s+\} else if \(purchase\.paidAmount! > 0\) \{\r?\n\s+purchase\.paymentStatus = 'Partially Paid';\r?\n\s+\} else \{\r?\n\s+purchase\.paymentStatus = 'Unpaid';\r?\n\s+\}\r?\n\s+purchase\.updatedAt = DateTime\.now\(\);\r?\n\s+await isar\.purchases\.put\(purchase\);\r?\n\s+\}\r?\n\s+\}/;

const replaceBlock = `            final invoice = await _findInvoice(billUuid);
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
            }`;

if (p3.test(content)) {
    content = content.replace(p3, replaceBlock);
    fs.writeFileSync(filePath, content, 'utf8');
    console.log("Patched!");
} else {
    console.log("Target block not found");
}
