const fs = require('fs');

const file = 'lib/features/transactions/presentation/screens/add_edit_transaction_dialog.dart';
let code = fs.readFileSync(file, 'utf8');

// The code currently has:
/*
                                child: ResponsiveFormRow(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Checkbox(
                                            value: isLinked,
*/

code = code.replace(/child: ResponsiveFormRow\(\s*children: \[\s*Expanded\(\s*child: Row\(/g, "child: Row(\n                                  crossAxisAlignment: CrossAxisAlignment.center,\n                                  children: [\n                                    Expanded(\n                                      child: Row(");

fs.writeFileSync(file, code);
console.log('Patched UI in Payment/Receipt dialog');
