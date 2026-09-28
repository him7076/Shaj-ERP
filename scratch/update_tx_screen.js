const fs = require('fs');
let c = fs.readFileSync('lib/features/transactions/presentation/screens/transactions_screen.dart', 'utf8');

c = "import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_party_transfer_screen.dart';\n" + c;

c = c.replace(
  "} else if (widget.lockedType == 'Debit Note') {",
  "} else if (widget.lockedType == 'Debit Note') {\n                  Navigator.of(context, rootNavigator: true).push(\n                    MaterialPageRoute(builder: (context) => const AddEditDebitNoteScreen()),\n                  ).then((_) => ref.invalidate(filteredTransactionsProvider));\n                } else if (widget.lockedType == 'Transfer' || widget.lockedType == 'Party Transfer') {\n                  Navigator.of(context, rootNavigator: true).push(\n                    MaterialPageRoute(builder: (context) => const AddEditPartyTransferScreen()),\n                  ).then((_) => ref.invalidate(filteredTransactionsProvider));"
);

c = c.replace(
  "AddEditTransactionDialog.show(context, initialType: widget.lockedType);",
  "if (widget.lockedType != 'Debit Note' && widget.lockedType != 'Transfer' && widget.lockedType != 'Party Transfer') AddEditTransactionDialog.show(context, initialType: widget.lockedType);"
);

fs.writeFileSync('lib/features/transactions/presentation/screens/transactions_screen.dart', c);
console.log('Updated transactions_screen.dart to use AddEditPartyTransferScreen');
