const fs = require('fs');
let content = fs.readFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', 'utf8');

// Add import
if (!content.includes('add_edit_bank_account_dialog.dart')) {
  content = content.replace(
    "import 'package:business_sahaj_erp/features/bank/presentation/screens/transfer_funds_dialog.dart';",
    "import 'package:business_sahaj_erp/features/bank/presentation/screens/transfer_funds_dialog.dart';\nimport 'package:business_sahaj_erp/features/bank/presentation/screens/add_edit_bank_account_dialog.dart';"
  );
}

const replacement = `Future<void> _showAddEditAccountDialog({BankAccount? existingAccount}) async {
    final result = await showDialog(
      context: context,
      builder: (_) => AddEditBankAccountDialog(existingAccount: existingAccount),
    );
    if (result == true) {
      _loadAccounts();
    }
  }`;

const startIndex = content.indexOf('Future<void> _showAddEditAccountDialog');
if (startIndex !== -1) {
  const endIndex = content.indexOf('  void _onFilter()', startIndex);
  if (endIndex !== -1) {
    const originalMethod = content.substring(startIndex, endIndex);
    content = content.replace(originalMethod, replacement + '\n\n');
    fs.writeFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', content);
    console.log('Replaced successfully');
  } else {
    console.log('Could not find end of method');
  }
} else {
  console.log('Could not find start of method');
}
