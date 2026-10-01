const fs = require('fs');

const path = 'lib/features/reports/presentation/screens/deleted_vouchers_screen.dart';
let content = fs.readFileSync(path, 'utf8');

if (!content.includes('restoreVoucher')) {
    const importReplacement = `import 'package:business_sahaj_erp/core/widgets/animated_hover_card.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'dart:math';`;
    content = content.replace("import 'package:isar/isar.dart';", importReplacement);

    const providerCode = `
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
      return '\${DateTime.now().millisecondsSinceEpoch}-\${parts.join("-")}';
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
    
    if (type.contains('Invoice')) {
      final item = await isar.invoices.filter().invoiceNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
      if (item != null) {
        item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
        await isar.invoices.put(item);
        await logRestore('Invoice', item.id, item.uuid);
        restored = true;
      }
    } else if (type.contains('Purchase')) {
      final item = await isar.purchases.filter().purchaseNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
      if (item != null) {
        item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
        await isar.purchases.put(item);
        await logRestore('Purchase', item.id, item.uuid);
        restored = true;
      }
    } else if (type.contains('Order')) {
      final item = await isar.orders.filter().orderNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
      if (item != null) {
        item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
        await isar.orders.put(item);
        await logRestore('Order', item.id, item.uuid);
        restored = true;
      }
    } else if (type.contains('Credit Note')) {
      final item = await isar.creditNotes.filter().creditNoteNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
      if (item != null) {
        item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
        await isar.creditNotes.put(item);
        await logRestore('CreditNote', item.id, item.uuid);
        restored = true;
      }
    } else if (type.contains('Debit Note')) {
      final item = await isar.debitNotes.filter().debitNoteNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
      if (item != null) {
        item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
        await isar.debitNotes.put(item);
        await logRestore('DebitNote', item.id, item.uuid);
        restored = true;
      }
    } else if (type.contains('Payment') || type.contains('Receipt') || type.contains('Transaction')) {
      final item = await isar.transactions.filter().transactionNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
      if (item != null) {
        item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
        await isar.transactions.put(item);
        await logRestore('Transaction', item.id, item.uuid);
        restored = true;
      }
    }

    if (restored) {
       await isar.collection<DeletedVoucher>().delete(v.id);
    }
  });
});
`;
    content = content.replace('class DeletedVouchersScreen', providerCode + '\nclass DeletedVouchersScreen');

    const restoreButton = `                                    Text(
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
                                      content: Text('Are you sure you want to restore \${v.voucherNumber}?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref.read(restoreVoucherProvider)(v);
                                    ref.invalidate(deletedVouchersProvider);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher restored successfully!')));
                                  }
                                },
                              ),`;
    content = content.replace(`                                    Text(
                                      'Deleted: $dateStr',
                                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),`, restoreButton);

    fs.writeFileSync(path, content, 'utf8');
    console.log('Restored restore logic to DeletedVouchersScreen');
}
