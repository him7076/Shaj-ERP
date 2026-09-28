const fs = require('fs');
const files = [
  'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
  'lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart',
  'lib/features/orders/presentation/screens/add_edit_order_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'
];

files.forEach(f => {
  if (fs.existsSync(f)) {
    let c = fs.readFileSync(f, 'utf8');
    if (!c.includes('package:intl/intl.dart')) {
      c = "import 'package:intl/intl.dart';\n" + c;
      fs.writeFileSync(f, c);
    }
  }
});
