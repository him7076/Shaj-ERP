const fs = require('fs');
let c = fs.readFileSync('lib/features/sales/presentation/screens/add_edit_invoice_screen.dart', 'utf8');

const targetStr = ")String>(\n                    textEditingController: TextEditingController(text: _selectedSalesman),";
const index = c.indexOf(targetStr);
if (index !== -1) {
  const endIndex = c.indexOf("\n                  ),\n                ),\n              ],\n            ),", index);
  if (endIndex !== -1) {
    const newC = c.substring(0, index) + ")" + c.substring(endIndex + 20);
    fs.writeFileSync('lib/features/sales/presentation/screens/add_edit_invoice_screen.dart', newC);
    console.log('Fixed syntax error in add_edit_invoice_screen.dart');
  } else {
    console.log('Could not find end index');
  }
} else {
  console.log('Could not find targetStr');
}
