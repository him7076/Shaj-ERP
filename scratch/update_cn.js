const fs = require('fs');
let content = fs.readFileSync('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', 'utf8');

// 1. Add state variables if missing
if (!content.includes('_isPaidAmountAutoFill')) {
  content = content.replace(
    '  double _gstRate = 18.0;',
    '  double _gstRate = 18.0;\n  bool _isPaidAmountAutoFill = false;\n  final _paidAmountController = TextEditingController();\n  String _paymentMode = "";\n  bool _isDiscountPercent = true;\n  String? _attachedImage;\n  DateTime _dueDate = DateTime.now();\n  String _invoiceType = "Tax Invoice";'
  );
}

// 2. Replace the Order Settings area
const settingsStart = content.indexOf("Text('Note settings'");
const settingsEnd = content.indexOf("_buildTotalsSummaryPanel(theme)");

if (settingsStart !== -1 && settingsEnd !== -1) {
  const newRow = `Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Note Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
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
                          final totals = ref.read(cartProvider.notifier).calculateTotals(null);
                          final grandTotal = totals['grandTotal'] ?? 0.0;
                          _paidAmountController.text = grandTotal.toStringAsFixed(2);
                        } else {
                          _paidAmountController.clear();
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
                      labelText: 'Paid/Settled (₹)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() { _isPaidAmountAutoFill = false; });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ref.watch(bankAccountsListProvider).when(
                    data: (accounts) {
                      final activeAccounts = accounts.where((a) => !a.isDeleted).toList();
                      final dropdownItems = <DropdownMenuItem<String>>[
                        const DropdownMenuItem(value: 'Cash', child: Text('Cash', style: TextStyle(fontSize: 13))),
                        const DropdownMenuItem(value: 'Credit', child: Text('Credit', style: TextStyle(fontSize: 13))),
                        const DropdownMenuItem(value: 'Cheque', child: Text('Cheque', style: TextStyle(fontSize: 13))),
                        ...activeAccounts.map((acc) => DropdownMenuItem(
                          value: acc.accountName,
                          child: Text(acc.accountName ?? '', style: const TextStyle(fontSize: 13)),
                        )),
                      ];
                      if (_paymentMode.isNotEmpty && !dropdownItems.any((item) => item.value == _paymentMode)) {
                        dropdownItems.add(DropdownMenuItem(value: _paymentMode, child: Text(_paymentMode, style: const TextStyle(fontSize: 13))));
                      }
                      return DropdownButtonFormField<String>(
                        value: _paymentMode.isNotEmpty ? _paymentMode : 'Cash',
                        decoration: const InputDecoration(
                          labelText: 'Payment Mode',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          prefixIcon: Icon(Icons.payment, size: 18),
                        ),
                        items: dropdownItems,
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentMode = val);
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => const Text('Error'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
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
                        labelText: 'Expected Date',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        prefixIcon: Icon(Icons.event_outlined, size: 18),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_dueDate), style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _remarksController,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Remarks / Notes',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      prefixIcon: Icon(Icons.notes_rounded, size: 18),
                    ),
                  ),
                ),
              ],
            ),
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
                              DropdownMenuItem(value: false, child: Text('₹', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _isDiscountPercent = val;
                                  final double? amt = double.tryParse(_discountController.text);
                                  if (_isDiscountPercent) {
                                    ref.read(cartProvider.notifier).setOrderDiscounts(amt, null); // Reused method
                                  } else {
                                    ref.read(cartProvider.notifier).setOrderDiscounts(null, amt);
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
                        ref.read(cartProvider.notifier).setOrderDiscounts(amt, null);
                      } else {
                        ref.read(cartProvider.notifier).setOrderDiscounts(null, amt);
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
            const SizedBox(height: 12),
            `;

  content = content.replace(content.substring(settingsStart, settingsEnd), newRow);
}

// 3. Update Save logic
content = content.replace(
  /noteDate = _noteDate([\s\S]*?)isSynced =/,
  'noteDate = _noteDate\n      ..paymentMode = _paymentMode\n      ..discountType = _isDiscountPercent ? "percentage" : "flat"\n      ..discountPercent = _isDiscountPercent ? double.tryParse(_discountController.text) : null\n      ..attachedImage = _attachedImage\n      ..isSynced ='
);

// 4. Update the Date and Bill # block (top section)
const exactStartRowRegex = /ResponsiveFormRow\([\s\S]*?child: TextFormField\([\s\S]*?controller: _noteNumberController,[\s\S]*?decoration: InputDecoration\(labelText: 'Internal Note # \(Auto\)',  isDense: true\),[\s\S]*?\),[\s\S]*?\),[\s\S]*?\],[\s\S]*?\),/;

const newRowTop = `Row(
              children: [
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _noteDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null) {
                        setState(() => _noteDate = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Note Date',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_noteDate), style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _noteNumberController,
                    readOnly: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Internal Note # (Auto)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),`;

content = content.replace(exactStartRowRegex, newRowTop);

fs.writeFileSync('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', content);
console.log('Update credit note script completed successfully.');
