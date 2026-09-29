const fs = require('fs');
let content = fs.readFileSync('lib/core/services/sync_service.dart', 'utf-8');

let newSwitch = `              switch (entityType) {
                case 'Party': await isar.partys.put(entity as Party); break;
                case 'Item': await isar.items.put(entity as Item); break;
                case 'Category': await isar.categorys.put(entity as Category); break;
                case 'Unit': await isar.units.put(entity as Unit); break;
                case 'Brand': await isar.brands.put(entity as Brand); break;
                case 'Order': await isar.orders.put(entity as Order); break;
                case 'Invoice': await isar.invoices.put(entity as Invoice); break;
                case 'Settings': await isar.settings.put(entity as Settings); break;
                case 'User': await isar.users.put(entity as User); break;
                case 'Purchase': await isar.purchases.put(entity as Purchase); break;
                case 'Expense': await isar.expenses.put(entity as Expense); break;
                case 'ExpenseItem': await isar.collection<ExpenseItem>().put(entity as ExpenseItem); break;
                case 'StockAdjustment': await isar.collection<StockAdjustment>().put(entity as StockAdjustment); break;
                case 'Transaction': await isar.transactions.put(entity as Transaction); break;
                case 'BankAccount': await isar.bankAccounts.put(entity as BankAccount); break;
                case 'CreditNote': await isar.creditNotes.put(entity as CreditNote); break;
                case 'DebitNote': await isar.debitNotes.put(entity as DebitNote); break;
                case 'WhatsAppMapping': await isar.whatsAppMappings.put(entity as WhatsAppMapping); break;
                case 'Task': await isar.tasks.put(entity as Task); break;
                case 'Machinery': await isar.collection<Machinery>().put(entity as Machinery); break;
              }`;

let lines = content.split('\n');
let start = lines.findIndex((l, i) => i > 1170 && i < 1185 && l.includes('switch (entityType) {'));
if (start > -1) {
  let end = lines.findIndex((l, i) => i > start && l.includes('              }'));
  lines.splice(start, end - start + 1, newSwitch);
  fs.writeFileSync('lib/core/services/sync_service.dart', lines.join('\n'));
  console.log('Success via line by line');
} else {
  console.log('Completely failed');
}
