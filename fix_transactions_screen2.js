const fs = require('fs');

let f = 'lib/features/transactions/presentation/screens/transactions_screen.dart';
let t = fs.readFileSync(f, 'utf8');

// Add Cancel to popup menu builder
if (!t.includes(`value: 'cancel'`)) {
    t = t.replace(
        `const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red, size: 20), title: Text('Delete', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero)),`,
        `const PopupMenuItem(value: 'cancel', child: ListTile(leading: Icon(Icons.cancel_outlined, color: Colors.red, size: 20), title: Text('Cancel / Void', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero)),\n                                                      const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red, size: 20), title: Text('Delete', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero)),`
    );

    t = t.replace(
        `                                                    if (action == 'edit') {`,
        `                                                    if (action == 'cancel') {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: const Text('Cancel Transaction'),
                                                          content: const Text('Are you sure you want to cancel/void this transaction? It will be marked as deleted.'),
                                                          actions: [
                                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NO')),
                                                            ElevatedButton(
                                                              onPressed: () => Navigator.pop(context, true),
                                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                                              child: const Text('YES, CANCEL'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirm == true) {
                                                         final repo = ref.read(transactionRepositoryProvider);
                                                         try {
                                                           if (txn.transactionType == 'Expense') {
                                                              final expRepo = ref.read(expenseRepositoryProvider);
                                                              final exp = await expRepo.getExpenseById(txn.uuid);
                                                              if (exp != null) {
                                                                exp.isDeleted = true;
                                                                exp.updatedAt = DateTime.now();
                                                                await expRepo.saveExpense(exp);
                                                              }
                                                           } else if (txn.transactionType == 'Sales') {
                                                              final invRepo = ref.read(invoiceRepositoryProvider);
                                                              final inv = await invRepo.getInvoiceById(txn.uuid);
                                                              if (inv != null) {
                                                                inv.isDeleted = true;
                                                                inv.updatedAt = DateTime.now();
                                                                await invRepo.saveInvoice(inv);
                                                              }
                                                           } else if (txn.transactionType == 'Purchase') {
                                                              final purRepo = ref.read(purchaseRepositoryProvider);
                                                              final pur = await purRepo.getPurchaseById(txn.uuid);
                                                              if (pur != null) {
                                                                pur.isDeleted = true;
                                                                pur.updatedAt = DateTime.now();
                                                                await purRepo.savePurchase(pur);
                                                              }
                                                           } else {
                                                              final tObj = await repo.getTransactionById(txn.uuid);
                                                              if (tObj != null) {
                                                                tObj.isDeleted = true;
                                                                tObj.updatedAt = DateTime.now();
                                                                await repo.saveTransaction(tObj);
                                                              }
                                                           }
                                                           ref.invalidate(filteredTransactionsProvider);
                                                           if (context.mounted) {
                                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction cancelled successfully')));
                                                           }
                                                         } catch (e) {
                                                           if (context.mounted) {
                                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                                           }
                                                         }
                                                      }
                                                    } else if (action == 'edit') {`
    );
}
fs.writeFileSync(f, t);
console.log('Fixed transactions_screen.dart!');
