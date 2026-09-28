const fs = require('fs');

const file = 'lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart';
let content = fs.readFileSync(file, 'utf8');

// 1. Fix Payment Mode
const oldPaymentIcon = `suffixIcon: IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blue, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: _showAddPaymentModeDialog,
                          ),`;
const newPaymentIcon = `/* No suffix icon */`;
content = content.replace(oldPaymentIcon, newPaymentIcon);

const oldPaymentItems = `items: dropdownItems,`;
const newPaymentItems = `items: [
                          DropdownMenuItem(
                            value: 'ADD_NEW_PAYMENT',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Select...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                Text('+ Add New', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          ...dropdownItems,
                        ],`;
content = content.replace(oldPaymentItems, newPaymentItems);

const oldPaymentOnChange = `onChanged: (val) {
                          if (val != null) {
                            setState(() => _paymentMode = val);
                          }
                        },`;
const newPaymentOnChange = `onChanged: (val) {
                          if (val == 'ADD_NEW_PAYMENT') {
                            _showAddPaymentModeDialog();
                            return;
                          }
                          if (val != null) {
                            setState(() => _paymentMode = val);
                          }
                        },`;
content = content.replace(oldPaymentOnChange, newPaymentOnChange);

fs.writeFileSync(file, content);
console.log('Fixed Payment Mode safely in purchase screen.');
