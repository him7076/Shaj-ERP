const fs = require('fs');

const files = [
  'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
  'lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart',
  'lib/features/orders/presentation/screens/add_edit_order_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'
];

files.forEach(f => {
  let content = fs.readFileSync(f, 'utf8');
  content = content.replace(/ÃƒÂ¯Ã‚Â¿Ã‚Â½/g, '-'); 
  content = content.replace(/Ã¢â€“Â²/g, '▲');
  content = content.replace(/Ã¢â€“Â¼/g, '▼');
  content = content.replace(/Ã¢â€šÂ¹/g, '₹');
  content = content.replace(/ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¹/g, '₹');
  content = content.replace(/ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢/g, '•');
  content = content.replace(/ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢/g, "'");
  content = content.replace(/ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“/g, "-");

  fs.writeFileSync(f, content);
});
