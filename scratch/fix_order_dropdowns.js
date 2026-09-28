const fs = require('fs');

const file = 'lib/features/orders/presentation/screens/add_edit_order_screen.dart';
let content = fs.readFileSync(file, 'utf8');

// 1. Fix Salesman
const oldSalesmanItems = `items: _salesmenList.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),`;
const newSalesmanItems = `items: [
                            DropdownMenuItem(
                              value: 'ADD_NEW_SALESMAN',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Select...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  Text('+ Add New', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                            ..._salesmenList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))),
                          ],`;
content = content.replace(oldSalesmanItems, newSalesmanItems);

const oldSalesmanOnChange = `onChanged: (val) {
                            if (val != null) setState(() => _selectedSalesman = val);
                          },`;
const newSalesmanOnChange = `onChanged: (val) {
                            if (val == 'ADD_NEW_SALESMAN') {
                              _showAddSalesmanDialog();
                              return;
                            }
                            if (val != null) setState(() => _selectedSalesman = val);
                          },`;
content = content.replace(oldSalesmanOnChange, newSalesmanOnChange);

// Remove the standalone IconButton for Add Salesman next to the dropdown
const oldSalesmanButton = `const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.person_add_alt_1),
                        tooltip: 'Add Salesman',
                        onPressed: _showAddSalesmanDialog,
                      ),`;
content = content.replace(oldSalesmanButton, '');


fs.writeFileSync(file, content);
console.log('Fixed Salesman in order screen.');
