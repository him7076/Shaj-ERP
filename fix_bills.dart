import 'dart:io';

void main() {
  final file = File('lib/data/repositories/transaction_repository_impl.dart');
  var code = file.readAsStringSync();

  final searchApply = '''            if (type == 'Receipt' || type == 'Credit Note') {
              final invoice = await _findInvoice(billUuid);
              if (invoice != null) {
                invoice.paidAmount = (invoice.paidAmount ?? 0.0) + allocAmt;
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
              }
            } else if (type == 'Payment' || type == 'Debit Note') {
              final purchase = await _findPurchase(billUuid);
              if (purchase != null) {
                purchase.paidAmount = (purchase.paidAmount ?? 0.0) + allocAmt;
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

  final replaceApply = '''            final invoice = await _findInvoice(billUuid);
            if (invoice != null) {
              invoice.paidAmount = (invoice.paidAmount ?? 0.0) + allocAmt;
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
                purchase.paidAmount = (purchase.paidAmount ?? 0.0) + allocAmt;
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


  final searchRevert = '''              if (oldType == 'Receipt' || oldType == 'Credit Note') {
                final invoice = await _findInvoice(billUuid);
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
                }
              } else if (oldType == 'Payment' || oldType == 'Debit Note') {
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

  final replaceRevert = '''              final invoice = await _findInvoice(billUuid);
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

  code = code.replaceAll(searchApply, replaceApply);
  code = code.replaceAll(searchRevert, replaceRevert);

  file.writeAsStringSync(code);
  print('Dart fix done.');
}
