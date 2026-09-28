const fs = require('fs');
let content = fs.readFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', 'utf8');

const topStart = content.indexOf('return SearchablePartyDropdown(');
const topEnd = content.indexOf('        Widget _buildCartItemsTable(ThemeData theme) {');

if (topStart === -1 || topEnd === -1) {
  console.log('Cannot find top region');
  process.exit(1);
}

// We need to carefully replace the UI part
// To be very safe, let's find the closing bracket of the left column which is just before `Widget _buildCartItemsTable`
// Actually, let's just grep the exact region:
const exactStart = content.indexOf('                ResponsiveFormRow(\n                  children: [\n                    Expanded(\n                      child: InkWell(');
if(exactStart === -1) {
   console.log('Cannot find exactStart');
} else {
  // Let's replace the `ResponsiveFormRow` with `Row` and put Supplier next to it?
  // Wait, Supplier is generated using `ref.watch(partiesProvider)` before the date!
  // In `add_edit_purchase_screen.dart`, it looks like this:
  /*
                    ref.watch(partiesProvider).when( ... ),
                    if (_selectedParty != null) ...[ ... ],
                    const Divider(height: 24),
                    ResponsiveFormRow(...)
  */
  // Let's modify the file to put Date and Supplier on the same line if possible, 
  // but since SearchablePartyDropdown is complex and needs `partiesProvider`, maybe just placing them neatly is enough.
  // Actually, I can use a script to replace the ResponsiveFormRow with a tighter Row.
  const rowStart = content.indexOf('                ResponsiveFormRow(\n                  children: [\n                    Expanded(\n                      child: InkWell(\n                        onTap: () async {\n                          final selected = await showDatePicker(');
  const rowEndStr = '                          ),\n                        ),\n                      ],\n                    ),\n                  ],\n                ),\n              ),\n            ),\n          );\n        }';
  const rowEnd = content.indexOf(rowEndStr);
  
  if (rowStart !== -1 && rowEnd !== -1) {
    const newRow = `                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: _purchaseDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (selected != null) {
                            setState(() => _purchaseDate = selected);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Purchase Date',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                          ),
                          child: Text(DateFormat('dd MMM yyyy').format(_purchaseDate), style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _billNumberController,
                        readOnly: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Internal Bill # (Auto)',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _supplierInvoiceNumberController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Supplier Invoice #',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),`;
    content = content.replace(content.substring(rowStart, rowEnd), newRow + '\n                  ],\n                ),\n              ),\n            ),\n          );\n        }');
    fs.writeFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', content);
    console.log('Update top script completed successfully.');
  } else {
    console.log('Row start or end not found.');
  }
}
