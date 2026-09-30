const fs = require('fs');
const path = 'lib/core/services/sync_service.dart';
let content = fs.readFileSync(path, 'utf8');

// Normalize line endings
content = content.replace(/\r\n/g, '\n');

// Replace allEntityTypes definition body
content = content.replace(/final allEntityTypes = \[\n\s+'Category', 'Unit', 'Brand', 'Party', 'Item',\n\s+'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',\n\s+'Purchase', 'PurchaseItem', 'Expense', 'ExpenseItem', 'Transaction',\n\s+'BankAccount', 'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem',\n\s+'StockAdjustment', 'WhatsAppMapping', 'Task', 'Machinery'\n\s+\];/g, 
`final allEntityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
      'Purchase', 'PurchaseItem', 'Expense', 'ExpenseItem', 
      'Transaction_receipt', 'Transaction_payment', 'Transaction_other_income', 
      'Transaction_credit_note', 'Transaction_debit_note', 'Transaction_transfer', 
      'Transaction_journal', 'Transaction_unknown',
      'Transaction', 'BankAccount', 'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem',
      'StockAdjustment', 'WhatsAppMapping', 'Task', 'Machinery'
    ];`);

// Replace entityTypes definition body
content = content.replace(/final entityTypes = \[\n\s+'Category', 'Unit', 'Brand', 'Party', 'Item',\n\s+'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',\n\s+'Purchase', 'PurchaseItem', 'Expense', 'ExpenseItem', 'Transaction', 'BankAccount',\n\s+'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem', 'WhatsAppMapping', 'Task', 'Machinery'\n\s+\];/g,
`final entityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
      'Purchase', 'PurchaseItem', 'Expense', 'ExpenseItem',
      'Transaction_receipt', 'Transaction_payment', 'Transaction_other_income', 
      'Transaction_credit_note', 'Transaction_debit_note', 'Transaction_transfer', 
      'Transaction_journal', 'Transaction_unknown',
      'Transaction', 'BankAccount',
      'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem', 'WhatsAppMapping', 'Task', 'Machinery'
    ];`);
    
// Replace carriage returns
content = content.replace(/\n/g, '\r\n');

fs.writeFileSync(path, content, 'utf8');
console.log('Successfully updated arrays in sync_service.dart');
