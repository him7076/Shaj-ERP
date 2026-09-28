const fs = require('fs');
let c = fs.readFileSync('lib/features/sales/presentation/screens/add_edit_invoice_screen.dart', 'utf8');

const newSalesman = `DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _salesmenList.contains(_selectedSalesman) ? _selectedSalesman : null,
                                  hint: const Text('Select Salesman', style: TextStyle(fontSize: 13)),
                                  icon: const SizedBox.shrink(),
                                  decoration: InputDecoration(
                                    labelText: 'Salesman Name',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_selectedSalesman.isNotEmpty && _selectedSalesman != 'Default Salesman')
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 16),
                                            onPressed: () => setState(() => _selectedSalesman = ''),
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.person_add, size: 18),
                                          onPressed: _showAddSalesmanDialog,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  ),
                                  items: _salesmenList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedSalesman = val);
                                  },
                                )`;

const startIdx = c.indexOf('RawAutocomplete<String>(');
if (startIdx !== -1) {
  const fieldViewBuilderIdx = c.indexOf('fieldViewBuilder:', startIdx);
  const endParenIdx = c.indexOf(';', fieldViewBuilderIdx); // The end of the RawAutocomplete statement is probably after it, wait, it's inside a widget tree.
  // Actually, I can just find the end by counting brackets.
  let openCount = 0;
  let endIdx = -1;
  for (let i = startIdx + 15; i < c.length; i++) {
    if (c[i] === '(') openCount++;
    if (c[i] === ')') openCount--;
    if (openCount === 0) {
      endIdx = i;
      break;
    }
  }
  
  if (endIdx !== -1) {
    c = c.substring(0, startIdx) + newSalesman + c.substring(endIdx + 1);
    fs.writeFileSync('lib/features/sales/presentation/screens/add_edit_invoice_screen.dart', c);
    console.log('Successfully replaced RawAutocomplete!');
  }
}
