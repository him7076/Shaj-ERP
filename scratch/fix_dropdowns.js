const fs = require('fs');

const filesToFix = [
  'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
  'lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart',
  'lib/features/orders/presentation/screens/add_edit_order_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'
];

for (const file of filesToFix) {
  if (!fs.existsSync(file)) continue;
  let content = fs.readFileSync(file, 'utf8');

  // Fix Salesman Suffix Icon
  content = content.replace(
    /IconButton\(\s*icon: const Icon\(Icons\.person_add, size: 18\),\s*onPressed: _showAddSalesmanDialog,\s*constraints: const BoxConstraints\(minWidth: 32, minHeight: 32\),\s*padding: EdgeInsets\.zero,\s*\),/g,
    ''
  );

  // Fix Salesman onChanged
  content = content.replace(
    /onChanged:\s*\(val\)\s*\{\s*if\s*\(val\s*!=\s*null\)\s*setState\(\(\)\s*=>\s*_selectedSalesman\s*=\s*val\);\s*\}/g,
    `onChanged: (val) {
                                    if (val == 'ADD_NEW_SALESMAN') {
                                      _showAddSalesmanDialog();
                                      return;
                                    }
                                    if (val != null) setState(() => _selectedSalesman = val);
                                  }`
  );

  // Fix Payment Mode Suffix Icon
  content = content.replace(
    /suffixIcon:\s*IconButton\(\s*icon: const Icon\(Icons\.add_circle, color: Colors\.blue, size: 20\),\s*padding: EdgeInsets\.zero,\s*constraints: const BoxConstraints\(minWidth: 32, minHeight: 32\),\s*onPressed: _showAddPaymentModeDialog,\s*\),/g,
    ''
  );

  // Fix Payment Mode onChanged
  content = content.replace(
    /onChanged:\s*\(val\)\s*\{\s*if\s*\(val\s*!=\s*null\)\s*\{\s*setState\(\(\)\s*=>\s*_paymentMode\s*=\s*val\);\s*\}\s*\}/g,
    `onChanged: (val) {
                          if (val == 'ADD_NEW_PAYMENT') {
                            _showAddPaymentModeDialog();
                            return;
                          }
                          if (val != null) {
                            setState(() => _paymentMode = val);
                          }
                        }`
  );

  fs.writeFileSync(file, content, 'utf8');
}
console.log('Fixed Dropdowns');
