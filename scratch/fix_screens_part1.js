const fs = require('fs');

const filesToFix = [
  'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
  'lib/features/orders/presentation/screens/add_edit_order_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart',
];

for (const file of filesToFix) {
  if (fs.existsSync(file)) {
    let content = fs.readFileSync(file, 'utf8');
    
    // Fix isSaleRateWithTax and isPurchaseRateWithTax
    content = content.replace(/isSaleRateWithTax: [^\n]+/g, 'isSaleRateWithTax: false,');
    content = content.replace(/isPurchaseRateWithTax: [^\n]+/g, 'isPurchaseRateWithTax: false,');
    
    // Fix cartItem.item.itemName -> cartItem.item.itemName ?? ''
    content = content.replace(/cartItem\.item\.itemName,/g, "cartItem.item.itemName ?? '',");
    content = content.replace(/item\.item\.itemName,/g, "item.item.itemName ?? '',");
    
    // Fix item.item.value!.isSaleRateWithTax in credit/debit note
    content = content.replace(/isSaleRateWithTax: item\.item\.value!\.isSaleRateWithTax \?\? false,/g, 'isSaleRateWithTax: false,');
    content = content.replace(/isPurchaseRateWithTax: item\.item\.value!\.isPurchaseRateWithTax \?\? false,/g, 'isPurchaseRateWithTax: false,');
    
    fs.writeFileSync(file, content);
  }
}
console.log('Fixed simple errors in invoice, order, credit, debit note screens');
