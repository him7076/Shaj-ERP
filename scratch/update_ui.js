const fs = require('fs');

let content = fs.readFileSync('scratch/add_edit_invoice_screen_copy.dart', 'utf8');

// 1. State Variables
content = content.replace(
  '  double _gstRate = 18.0;',
  '  double _gstRate = 18.0;\n  bool _isDiscountPercent = true;\n  String? _attachedImage;'
);

// 2. Sections Replacement
const sectionAStart = content.indexOf('            // -- Section A: Invoice Details --');
const sectionBStart = content.indexOf('            // -- Section B: Payment & Discounts --');
const sectionCStart = content.indexOf('            // -- Section C: Bill Summary --');

if (sectionAStart === -1 || sectionBStart === -1 || sectionCStart === -1) {
  console.error('Missing sections!');
  process.exit(1);
}

const newSections = `            // -- Section A: Invoice Details --
            Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Invoice Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Paid Amount with auto-fill checkbox
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Checkbox(
                    value: _isPaidAmountAutoFill,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      setState(() {
                        _isPaidAmountAutoFill = val ?? false;
                        if (_isPaidAmountAutoFill) {
                          final totals = ref.read(invoiceCartProvider.notifier).calculateTotals(null);
                          final grandTotal = totals['grandTotal'] ?? 0.0;
                          _paidAmountController.text = grandTotal.toStringAsFixed(2);
                          ref.read(invoiceCartProvider.notifier).setPaidAmount(grandTotal);
                        } else {
                          _paidAmountController.clear();
                          ref.read(invoiceCartProvider.notifier).setPaidAmount(0.0);
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _paidAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Paid (\u20b9)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _isPaidAmountAutoFill = false;
                      });
                      final double? amt = double.tryParse(val);
                      if (amt != null) {
                        ref.read(invoiceCartProvider.notifier).setPaidAmount(amt);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Payment Mode Dropdown
                Expanded(
                  flex: 2,
                  child: ref.watch(bankAccountsListProvider).when(
                    data: (accounts) {
                      final activeAccounts = accounts.where((a) => !a.isDeleted).toList();
                      // Only Cash, Credit, Cheque and active bank accounts
                      final dropdownItems = <DropdownMenuItem<String>>[
                        const DropdownMenuItem(value: 'Cash', child: Text('Cash', style: TextStyle(fontSize: 13))),
                        const DropdownMenuItem(value: 'Credit', child: Text('Credit', style: TextStyle(fontSize: 13))),
                        const DropdownMenuItem(value: 'Cheque', child: Text('Cheque', style: TextStyle(fontSize: 13))),
                        ...activeAccounts.map((acc) => DropdownMenuItem(
                          value: acc.accountName,
                          child: Text(acc.accountName ?? '', style: const TextStyle(fontSize: 13)),
                        )),
                      ];
                      
                      // Ensure selected value is valid
                      if (_paymentMode.isNotEmpty && !dropdownItems.any((item) => item.value == _paymentMode)) {
                        dropdownItems.add(DropdownMenuItem(value: _paymentMode, child: Text(_paymentMode, style: const TextStyle(fontSize: 13))));
                      }
                      
                      return DropdownButtonFormField<String>(
                        value: _paymentMode.isNotEmpty ? _paymentMode : 'Cash',
                        decoration: InputDecoration(
                          labelText: 'Payment Mode',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          prefixIcon: const Icon(Icons.payment, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blue, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: _showAddPaymentModeDialog,
                          ),
                        ),
                        items: dropdownItems,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _paymentMode = val);
                          }
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => Text('Error: $err'),
                  )
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _invoiceType,
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Billing Type',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Tax Invoice', child: Text('Tax Invoice')),
                      DropdownMenuItem(value: 'Retail Invoice', child: Text('Retail Invoice')),
                      DropdownMenuItem(value: 'Cash Invoice', child: Text('Cash Invoice')),
                      DropdownMenuItem(value: 'Credit Invoice', child: Text('Credit Invoice')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _invoiceType = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (selected != null) {
                        setState(() => _dueDate = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        prefixIcon: Icon(Icons.event_outlined, size: 18),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_dueDate), style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),

            // -- Section B: Payment & Discounts --
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Discounts & Attachments', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Discount',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<bool>(
                            value: _isDiscountPercent,
                            isDense: true,
                            items: const [
                              DropdownMenuItem(value: true, child: Text('%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: false, child: Text('\u20b9', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _isDiscountPercent = val;
                                  // trigger re-calc
                                  final double? amt = double.tryParse(_discountController.text);
                                  if (_isDiscountPercent) {
                                    ref.read(invoiceCartProvider.notifier).setDiscounts(amt, null);
                                  } else {
                                    ref.read(invoiceCartProvider.notifier).setDiscounts(null, amt);
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      final double? amt = double.tryParse(val);
                      if (_isDiscountPercent) {
                        ref.read(invoiceCartProvider.notifier).setDiscounts(amt, null);
                      } else {
                        ref.read(invoiceCartProvider.notifier).setDiscounts(null, amt);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                         _attachedImage = _attachedImage == null ? 'attached.jpg' : null;
                      });
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Attachment',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        prefixIcon: const Icon(Icons.image_outlined, size: 18),
                        suffixIcon: _attachedImage != null 
                           ? IconButton(icon: const Icon(Icons.close, size: 16), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32), onPressed: () => setState(()=> _attachedImage = null)) 
                           : null,
                      ),
                      child: Text(_attachedImage != null ? 'Image Attached' : 'Add Image', style: TextStyle(fontSize: 13, color: _attachedImage != null ? Colors.green : Colors.grey)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _remarksController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Remarks / Terms',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                prefixIcon: Icon(Icons.notes_rounded, size: 18),
              ),
            ),

`;

const firstPart = content.substring(0, sectionAStart);
const lastPart = content.substring(sectionCStart);
content = firstPart + newSections + lastPart;


// 3. Replace Invoice Date and Salesman region
const invoiceDateStart = content.indexOf('                // Invoice Date');
const salesmanEnd = content.indexOf('                // Outstanding Balance Row (Optional)');
if (invoiceDateStart === -1 || salesmanEnd === -1) {
  console.error('Could not find invoice date/salesman region');
} else {
  const newRow = `                // Invoice Date & Salesman
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
                ),`;
  content = content.replace(
    /ResponsiveFormRow\([\s\S]*?\/\/\s*Outstanding Balance Row \(Optional\)/,
    newRow + '\n                // Outstanding Balance Row (Optional)'
  );
}

// 4. Update _saveInvoice to save discount details and payment details correctly
// We just find where `invoiceType = _invoiceType` is and add the new fields.
content = content.replace(
  /invoiceType = _invoiceType([\s\S]*?)invoiceStatus =/,
  'invoiceType = _invoiceType\n      ..paymentMode = _paymentMode\n      ..discountType = _isDiscountPercent ? "percentage" : "flat"\n      ..discountPercent = _isDiscountPercent ? double.tryParse(_discountController.text) : null\n      ..attachedImage = _attachedImage\n      ..invoiceStatus ='
);

fs.writeFileSync('scratch/add_edit_invoice_screen_copy.dart', content);
console.log('Update script completed successfully.');
