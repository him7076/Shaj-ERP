const fs = require('fs');
let content = fs.readFileSync('lib/features/sales/presentation/screens/invoice_detail_screen.dart', 'utf8');

const t1 = "final banks = await isar.bankAccounts.filter().printOnInvoiceEqualTo(true).findAll();";
const r1 = "final allBanks = await isar.bankAccounts.where().findAll();\n      final banks = allBanks.where((b) => b.printOnInvoice == true).toList();";

content = content.replace(t1, r1);
fs.writeFileSync('lib/features/sales/presentation/screens/invoice_detail_screen.dart', content);
console.log('Fixed invoice filter');
