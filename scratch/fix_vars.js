const fs = require('fs');
const files = [
  'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
  'lib/features/orders/presentation/screens/add_edit_order_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'
];

files.forEach(f => {
  let content = fs.readFileSync(f, 'utf8');
  let varsToAdd = [];
  if (!content.includes('bool _isDiscountPercent')) varsToAdd.push('  bool _isDiscountPercent = true;');
  if (!content.includes('String? _attachedImage')) varsToAdd.push('  String? _attachedImage;');
  if (!content.includes('String _paymentMode')) varsToAdd.push('  String _paymentMode = "Cash";');
  if (!content.includes('bool _isPaidAmountAutoFill')) varsToAdd.push('  bool _isPaidAmountAutoFill = false;');
  
  if (f.includes('order_screen') && !content.includes('DateTime _dueDate')) varsToAdd.push('  DateTime _dueDate = DateTime.now();');
  if (f.includes('order_screen') && !content.includes('_paidAmountController =')) varsToAdd.push('  final _paidAmountController = TextEditingController();');

  if (varsToAdd.length > 0) {
    const insertIdx = content.indexOf('@override'); // Insert before first @override (which is usually initState or dispose, but let's be safer)
    
    // Better to find `void initState()`
    const initIdx = content.indexOf('void initState() {');
    if (initIdx !== -1) {
      // Find the `@override` right before `void initState`
      const beforeInit = content.lastIndexOf('@override', initIdx);
      const actualInsertIdx = beforeInit !== -1 ? beforeInit : initIdx;
      
      const p1 = content.substring(0, actualInsertIdx);
      const p2 = content.substring(actualInsertIdx);
      fs.writeFileSync(f, p1 + varsToAdd.join('\\n') + '\\n\\n  ' + p2);
      console.log('Fixed vars in', f);
    } else {
      console.log('initState not found in', f);
    }
  } else {
    console.log('No vars missing in', f);
  }
});
