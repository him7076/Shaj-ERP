const fs = require('fs');
const path = require('path');

const files = [
  'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
  'lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart',
  'lib/features/orders/presentation/screens/add_edit_order_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'
];

files.forEach(f => {
  let content = fs.readFileSync(f, 'utf8');
  
  // Replace Rupee symbols
  content = content.replace(/ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¹/g, '₹');
  content = content.replace(/Ã¢â€šÂ¹/g, '₹');
  content = content.replace(/ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¹/g, '₹'); // In case

  // Replace bullets
  content = content.replace(/ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢/g, '•');
  
  fs.writeFileSync(f, content);
  console.log('Cleaned up text in', f);
});
