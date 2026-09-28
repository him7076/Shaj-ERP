const fs = require('fs');
let content = fs.readFileSync('scratch/add_edit_invoice_screen_copy.dart', 'utf8');

const i1 = content.indexOf('// Invoice Date');
const i2 = content.lastIndexOf('ResponsiveFormRow', i1);
const i3 = content.indexOf('Widget _buildCartItemsTable', i1);

const chunk = content.substring(i2, i3);

const newRow = `            // Invoice Date & Salesman
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _invoiceDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null) {
                        setState(() => _invoiceDate = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Invoice Date',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_invoiceDate), style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: RawAutocomplete<String>(
                    textEditingController: TextEditingController(text: _selectedSalesman),
                    focusNode: FocusNode(),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final query = textEditingValue.text.trim().toLowerCase();
                      if (query.isEmpty) return _salesmenList;
                      return _salesmenList.where((s) => s.toLowerCase().contains(query)).toList();
                    },
                    onSelected: (String s) {
                      setState(() { _selectedSalesman = s; });
                      FocusScope.of(context).unfocus();
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 250,
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  title: Text(option, style: const TextStyle(fontSize: 13)),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Salesman',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blue, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: _showAddSalesmanDialog,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  `;

content = content.replace(chunk, newRow);

// 4. Update _saveInvoice to save discount details and payment details correctly
// We just find where `invoiceType = _invoiceType` is and add the new fields.
content = content.replace(
  /invoiceType = _invoiceType([\s\S]*?)invoiceStatus =/,
  'invoiceType = _invoiceType\n      ..paymentMode = _paymentMode\n      ..discountType = _isDiscountPercent ? "percentage" : "flat"\n      ..discountPercent = _isDiscountPercent ? double.tryParse(_discountController.text) : null\n      ..attachedImage = _attachedImage\n      ..invoiceStatus ='
);

fs.writeFileSync('scratch/add_edit_invoice_screen_copy.dart', content);
console.log('Update script 3 completed successfully.');
