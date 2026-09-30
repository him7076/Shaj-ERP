const fs = require('fs');
const files = [
  'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'
];

files.forEach(file => {
  let code = fs.readFileSync(file, 'utf8');
  let originalCode = code;
  
  // Just find the ResponsiveFormRow before the DatePicker
  const startIdx = code.indexOf('ResponsiveFormRow(');
  if (startIdx !== -1) {
    // See if it's the one with Date picker
    const subCode = code.substring(startIdx, startIdx + 300);
    if (subCode.includes('showDatePicker')) {
       code = code.substring(0, startIdx) + 'Row(' + code.substring(startIdx + 'ResponsiveFormRow('.length);
    }
  }

  if (code !== originalCode) {
    fs.writeFileSync(file, code);
    console.log(`Patched Row directly in ${file}`);
  }
});
