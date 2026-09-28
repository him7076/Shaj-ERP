const fs = require('fs');
let content = fs.readFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', 'utf8');

const paymentStart = content.indexOf("Text('Bill settings'");
const paymentEnd = content.indexOf("_buildTotalsSummaryPanel(theme)");

if (paymentStart === -1 || paymentEnd === -1) {
  console.log('Cannot find payment region');
  process.exit(1);
}

const chunk = content.substring(paymentStart, paymentEnd);

const newRow = `Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Purchase Bill Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
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
                          _paidAmountController.text = _grandTotal.toStringAsFixed(2);
                        } else {
                          _paidAmountController.clear();
                        }
                        _recalculateTotals();
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
                      labelText: 'Paid (₹)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() { _isPaidAmountAutoFill = false; });
                      _recalculateTotals();
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
                        labelText: 'Due Date',
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
                                  _recalculateTotals();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    onChanged: (val) => _recalculateTotals(),
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

content = content.replace(chunk, newRow);

// Update _saveBill to include new fields
content = content.replace(
  /purchaseDate = _purchaseDate([\s\S]*?)isSynced =/,
  'purchaseDate = _purchaseDate\n      ..paymentMode = _paymentMode\n      ..discountType = _isDiscountPercent ? "percentage" : "flat"\n      ..discountPercent = _isDiscountPercent ? double.tryParse(_discountController.text) : null\n      ..attachedImage = _attachedImage\n      ..isSynced ='
);

fs.writeFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', content);
console.log('Update purchase script completed successfully.');
