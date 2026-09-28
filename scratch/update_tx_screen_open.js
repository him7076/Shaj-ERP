const fs = require('fs');
let c = fs.readFileSync('lib/features/transactions/presentation/screens/transactions_screen.dart', 'utf8');

c = c.replace(
  "} else if (txn.transactionType == 'Receipt' || txn.transactionType == 'Payment' || txn.transactionType == 'Other Income') {",
  "} else if (txn.transactionType == 'Transfer' || txn.transactionType == 'Party Transfer') {\n      Navigator.of(context, rootNavigator: true).push<bool>(\n        MaterialPageRoute(builder: (context) => AddEditPartyTransferScreen(existingTransaction: txn)),\n      ).then((changed) {\n        if (changed == true) ref.invalidate(filteredTransactionsProvider);\n      });\n    } else if (txn.transactionType == 'Receipt' || txn.transactionType == 'Payment' || txn.transactionType == 'Other Income') {"
);

fs.writeFileSync('lib/features/transactions/presentation/screens/transactions_screen.dart', c);
console.log('Updated _openTransaction to handle Party Transfer');
