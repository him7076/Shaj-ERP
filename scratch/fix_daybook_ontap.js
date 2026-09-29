const fs = require('fs');

function fixDayBookOnTap() {
    let file = 'lib/features/reports/presentation/screens/day_book_report_screen.dart';
    let code = fs.readFileSync(file, 'utf8');

    // Add imports
    code = code.replace(/import 'package:business_sahaj_erp\/data\/local\/collections\/debit_note_collection.dart';/, 
      "import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';\nimport 'package:business_sahaj_erp/features/bank/presentation/screens/adjust_cash_dialog.dart';\nimport 'package:business_sahaj_erp/features/bank/presentation/screens/transfer_funds_dialog.dart';");

    // Replace onTap
    let regex = /onTap: v\.entityUuid != null \? \(\) \{\s+if \(v\.voucherType\.contains\('Sale Invoice'\)\) \{\s+Navigator\.push\(context, MaterialPageRoute\(builder: \(_\) => InvoiceDetailScreen\(invoiceUuid: v\.entityUuid!\)\)\);\s+\} else if \(v\.voucherType\.contains\('Purchase Bill'\)\) \{\s+Navigator\.push\(context, MaterialPageRoute\(builder: \(_\) => AddEditPurchaseScreen\(purchaseUuid: v\.entityUuid!\)\)\);\s+\} else if \(v\.voucherType\.contains\('Credit Note'\)\) \{\s+Navigator\.push\(context, MaterialPageRoute\(builder: \(_\) => AddEditCreditNoteScreen\(parentCreditNoteUuid: v\.entityUuid!\)\)\);\s+\} else if \(v\.voucherType\.contains\('Debit Note'\)\) \{\s+Navigator\.push\(context, MaterialPageRoute\(builder: \(_\) => AddEditDebitNoteScreen\(parentDebitNoteUuid: v\.entityUuid!\)\)\);\s+\} else if \(v\.voucherType == 'Receipt' \|\| v\.voucherType == 'Payment' \|\| v\.voucherType == 'Other Income' \|\| \['Transfer', 'Bank Transfer', 'Cash Adjustment'\]\.contains\(v\.voucherType\)\) \{\s+\/\/ For generic transactions, open the transaction dialog\s+showDialog\(context: context, builder: \(_\) => AddEditTransactionDialog\(\s+initialType: v\.voucherType,\s+transaction: null, \/\/ Note: To edit properly we'd need the whole object, but they asked for detailed view\s+\)\);\s+\}\s+\} : null,/m;

    let replacement = `onTap: v.entityUuid != null ? () async {
                              if (v.voucherType.contains('Sale Invoice')) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceUuid: v.entityUuid!)));
                              } else if (v.voucherType.contains('Purchase Bill')) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditPurchaseScreen(purchaseUuid: v.entityUuid!)));
                              } else if (v.voucherType.contains('Credit Note')) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditCreditNoteScreen(parentCreditNoteUuid: v.entityUuid!)));
                              } else if (v.voucherType.contains('Debit Note')) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditDebitNoteScreen(parentDebitNoteUuid: v.entityUuid!)));
                              } else if (v.voucherType == 'Receipt' || v.voucherType == 'Payment' || v.voucherType == 'Other Income' || ['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(v.voucherType)) {
                                final isar = ref.read(databaseServiceProvider).isar;
                                final txn = await isar.transactions.filter().uuidEqualTo(v.entityUuid).findFirst();
                                if (txn != null && mounted) {
                                   if (txn.transactionType == 'Bank Transfer' || txn.transactionType == 'Cash Adjustment') {
                                      if (txn.transactionType == 'Cash Adjustment') {
                                         showDialog(context: context, builder: (_) => AdjustCashDialog(existingTransaction: txn, isAdjustmentIn: (txn.amount ?? 0) > 0));
                                      } else {
                                         showDialog(context: context, builder: (_) => TransferFundsDialog(existingTransaction: txn));
                                      }
                                   } else {
                                      showDialog(context: context, builder: (_) => AddEditTransactionDialog(transaction: txn, initialType: txn.transactionType ?? v.voucherType));
                                   }
                                }
                              }
                            } : null,`;

    if (code.match(regex)) {
        code = code.replace(regex, replacement);
        fs.writeFileSync(file, code);
        console.log('Fixed day_book_report_screen.dart onTap');
    } else {
        console.log('Regex did not match day_book_report_screen.dart onTap. It may already be replaced or changed.');
    }
}

fixDayBookOnTap();
