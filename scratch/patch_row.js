const fs = require('fs');
const files = [
  'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'
];

files.forEach(file => {
  let code = fs.readFileSync(file, 'utf8');
  let originalCode = code;
  code = code.replace(/ResponsiveFormRow\(\s*children: \[\s*Expanded\(\s*child: InkWell\(\s*onTap: \(\) async \{\s*final selected = await showDatePicker/gs, 
    "Row(\\n              children: [\\n                Expanded(\\n                  child: InkWell(\\n                    onTap: () async {\\n                      final selected = await showDatePicker");
  if (code !== originalCode) {
    fs.writeFileSync(file, code);
    console.log(`Patched Row in ${file}`);
  } else {
    // try matching just ResponsiveFormRow before Date
    code = code.replace(/ResponsiveFormRow\(\s*children: \[\s*Expanded\(\s*child: InkWell\(\s*onTap:/g, 
      "Row(children: [Expanded(child: InkWell(onTap:");
    if (code !== originalCode) {
      fs.writeFileSync(file, code);
      console.log(`Patched Row using fallback in ${file}`);
    }
  }
});
