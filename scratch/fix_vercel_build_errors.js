const fs = require('fs');

// Fix 1: Bank providers import in Credit Note
let cn = fs.readFileSync('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', 'utf8');
cn = cn.replace(
  "import 'package:business_sahaj_erp/features/bank/presentation/providers/bank_providers.dart';", 
  "import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';"
);
fs.writeFileSync('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', cn);

// Fix 1: Bank providers import in Debit Note
let dn = fs.readFileSync('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', 'utf8');
dn = dn.replace(
  "import 'package:business_sahaj_erp/features/bank/presentation/providers/bank_providers.dart';", 
  "import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';"
);
// Fix 3: Debit Note originalPurchaseUuid
dn = dn.replace(/originalInvoiceUuid/g, 'originalPurchaseUuid');
fs.writeFileSync('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', dn);

// Fix 2: Expense screen _recalculateTotals
let ex = fs.readFileSync('lib/features/expenses/presentation/screens/add_edit_expense_screen.dart', 'utf8');
ex = ex.replace(/_recalculateTotals\(\)/g, '_calculateTotals()');
fs.writeFileSync('lib/features/expenses/presentation/screens/add_edit_expense_screen.dart', ex);

// Fix 4: Searchable dropdown dialog
let dd = fs.readFileSync('lib/core/widgets/searchable_payment_mode_dropdown.dart', 'utf8');
dd = dd.replace(
  "await AddEditBankAccountDialog.show(context);",
  "await showDialog(context: context, builder: (context) => const AddEditBankAccountDialog());"
);
fs.writeFileSync('lib/core/widgets/searchable_payment_mode_dropdown.dart', dd);

console.log("All vercel build errors fixed.");
