const fs = require('fs');
let content = fs.readFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', 'utf8');

const oldContent =
  '                                      if (txn != null && mounted) {\r\n' +
  '                                        showDialog(\r\n' +
  '                                          context: context,\r\n' +
  '                                          builder: (_) => AddEditTransactionDialog(\r\n' +
  '                                            transaction: txn,\r\n' +
  '                                          ),\r\n' +
  '                                        ).then((_) => _loadTransactions());\r\n' +
  '                                      }';

const oldContentLF = oldContent.replace(/\r\n/g, '\n');

const newContent =
  '                                      if (txn != null && mounted) {\n' +
  '                                        if (txn.transactionType == \'Transfer\') {\n' +
  '                                          showDialog(\n' +
  '                                            context: context,\n' +
  '                                            builder: (_) => TransferFundsDialog(\n' +
  '                                              existingTransaction: txn,\n' +
  '                                            ),\n' +
  '                                          ).then((_) => _loadTransactions());\n' +
  '                                        } else {\n' +
  '                                          showDialog(\n' +
  '                                            context: context,\n' +
  '                                            builder: (_) => AddEditTransactionDialog(\n' +
  '                                              transaction: txn,\n' +
  '                                            ),\n' +
  '                                          ).then((_) => _loadTransactions());\n' +
  '                                        }\n' +
  '                                      }';

if (content.includes(oldContent)) {
  content = content.replace(oldContent, newContent);
  fs.writeFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', content);
  console.log('Fixed CRLF');
} else if (content.includes(oldContentLF)) {
  content = content.replace(oldContentLF, newContent);
  fs.writeFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', content);
  console.log('Fixed LF');
} else {
  console.log('Not found');
}
