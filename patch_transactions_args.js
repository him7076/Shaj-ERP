const fs = require('fs');
let f = 'lib/features/transactions/presentation/screens/transactions_screen.dart';
let lines = fs.readFileSync(f, 'utf8').split('\n');
let inFunc = false;
for (let i = 0; i < lines.length; i++) {
  if (lines[i].includes('void _openTransaction(')) inFunc = true;
  if (inFunc && lines[i].includes("txn.transactionType == 'Credit Note'")) {
    lines[i+2] = lines[i+2].replace('const AddEditCreditNoteScreen()', 'AddEditCreditNoteScreen(parentCreditNoteUuid: txn.uuid ?? txn.id.toString())');
  }
  if (inFunc && lines[i].includes("txn.transactionType == 'Debit Note'")) {
    lines[i+2] = lines[i+2].replace('const AddEditDebitNoteScreen()', 'AddEditDebitNoteScreen(parentDebitNoteUuid: txn.uuid ?? txn.id.toString())');
  }
  if (inFunc && lines[i].includes('void _showReceiptDetailModal(')) break;
}
fs.writeFileSync(f, lines.join('\n'));
console.log('Fixed!');
