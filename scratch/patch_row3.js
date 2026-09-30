const fs = require('fs');
['lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', 'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'].forEach(f => {
  let code = fs.readFileSync(f, 'utf8');
  let originalCode = code;

  // Replace ResponsiveFormRow with Row for the date section
  code = code.replace(/ResponsiveFormRow\(\s*children:\s*\[\s*Expanded\(\s*child:\s*InkWell\(/gs, "Row(children: [Expanded(child: InkWell(");

  if (code !== originalCode) {
    fs.writeFileSync(f, code);
    console.log('Patched ' + f);
  }
});
