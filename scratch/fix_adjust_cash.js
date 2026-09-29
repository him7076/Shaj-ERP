const fs = require('fs');
let file = 'lib/features/reports/presentation/screens/day_book_report_screen.dart';
let code = fs.readFileSync(file, 'utf8');

let regex = /if \(txn.transactionType == 'Cash Adjustment'\) \{\s*showDialog\(context: context, builder: \(_\) => AdjustCashDialog\(existingTransaction: txn, isAdjustmentIn: \(txn.amount \?\? 0\) > 0\)\);\s*\} else \{\s*showDialog\(context: context, builder: \(_\) => TransferFundsDialog\(existingTransaction: txn\)\);\s*\}/;

let replacement = "showDialog(context: context, builder: (_) => TransferFundsDialog(existingTransaction: txn));";

if(code.match(regex)) {
    code = code.replace(regex, replacement);
    fs.writeFileSync(file, code);
    console.log('Fixed AdjustCashDialog error in day_book_report_screen.dart');
} else {
    console.log('Could not match regex in day_book_report_screen.dart');
}
