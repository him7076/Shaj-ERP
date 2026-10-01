const fs = require('fs');

let f = 'lib/features/transactions/presentation/screens/transactions_screen.dart';
let t = fs.readFileSync(f, 'utf8');

// Add imports
if (!t.includes('expense_providers.dart')) {
    const importStr = `
import 'package:business_sahaj_erp/features/expenses/presentation/providers/expense_providers.dart';
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/providers/purchase_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/auth_providers.dart';
`;
    t = t.replace(`import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';`, `import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';${importStr}`);
}

// Fix the logic block
const badBlock = `                                                         final repo = ref.read(transactionRepositoryProvider);
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
                                                           ref.invalidate(filteredTransactionsProvider);`;

const goodBlock = `                                                         try {
                                                           final user = ref.read(currentUserProvider)?.name ?? 'System';
                                                           if (txn.transactionType == 'Expense') {
                                                              await ref.read(expenseRepositoryProvider).softDelete(txn.uuid!);
                                                           } else if (txn.transactionType == 'Sales') {
                                                              await ref.read(invoiceRepositoryProvider).cancelInvoice(txn.uuid!, 'User Cancelled', user);
                                                           } else if (txn.transactionType == 'Purchase') {
                                                              await ref.read(purchaseRepositoryProvider).softDelete(txn.uuid!);
                                                           } else {
                                                              await ref.read(transactionRepositoryProvider).softDelete(txn.uuid!);
                                                           }
                                                           ref.invalidate(filteredTransactionsProvider);
                                                           ref.invalidate(dashboardAnalyticsProvider);`;

t = t.replace(badBlock, goodBlock);

fs.writeFileSync(f, t);
console.log('Fixed transactions_screen compilation error!');
