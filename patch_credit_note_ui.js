const fs = require('fs');

let f = 'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart';
let t = fs.readFileSync(f, 'utf8');

// 1) Date font size small (around line 900) & 2,3) Remove internal bill and 50% width & 6) Remove link from supplier invoice
const oldRowStr = `            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _creditNoteDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null) {
                        setState(() => _creditNoteDate = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: 'CreditNote Date',  isDense: true),
                      child: Text(DateFormat('dd-MM-yyyy').format(_creditNoteDate), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _billNumberController,
                    readOnly: true,
                    decoration: InputDecoration(labelText: 'Internal Bill # (Auto)',  isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _originalBillNumberController,
                    decoration: InputDecoration(
                      labelText: 'Supplier Invoice #',
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.link, color: Colors.blue),
                        onPressed: _showLinkBillsModal,
                      ),
                    ),
                  ),
                ),
              ],
            ),`;

const newRowStr = `            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _creditNoteDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null) {
                        setState(() => _creditNoteDate = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'CreditNote Date', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      child: Text(
                        DateFormat('dd-MM-yyyy').format(_creditNoteDate), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _originalBillNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Invoice #',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),`;

t = t.replace(oldRowStr, newRowStr);

// 4) Top navigation bar title
t = t.replace(`'Edit CreditNote Bill \${_billNumberController.text.isNotEmpty ? "(#\${_billNumberController.text})" : ""}'`, `'Edit CreditNote \${_billNumberController.text.isNotEmpty ? "(#\${_billNumberController.text})" : ""}'`);
t = t.replace(`'New CreditNote Bill \${_billNumberController.text.isNotEmpty ? "(#\${_billNumberController.text})" : ""}'`, `'New CreditNote \${_billNumberController.text.isNotEmpty ? "(#\${_billNumberController.text})" : ""}'`);

// 7) Bottom Layout Payment & Discount
const oldPaymentRow = `                        Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                    decoration: InputDecoration(
                      labelText: false ? 'Received (₹)' : 'Paid (₹)',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() => _isPaidAmountAutoFill = false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ref.watch(bankAccountsListProvider).when(
                    data: (accounts) {
                      final activeAccounts = accounts.where((a) => !a.isDeleted).toList();
                      final modes = ['Cash', 'Credit', 'Cheque', 'UPI', 'Bank Transfer', ...activeAccounts.map((a) => a.bankName ?? '')].toSet().toList();
                      return SearchablePaymentModeDropdown(
                        paymentModes: modes,
                        selectedMode: _paymentMode,
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentMode = val);
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Discount',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                          child: ToggleButtons(
                            isSelected: [_isDiscountPercent, !_isDiscountPercent],
                            onPressed: (idx) {
                                  setState(() {
                                    bool newIsPercent = idx == 0;
                                    if (newIsPercent == _isDiscountPercent) return;
                                    
                                    _isDiscountPercent = newIsPercent;
                                    
                                    if (_isDiscountPercent) {
                                       double percent = 0.0;
                                       if (_subtotal > 0) percent = (_discountAmount / _subtotal) * 100.0;
                                       _discountController.text = (percent % 1 == 0) ? percent.toInt().toString() : percent.toStringAsFixed(2);
                                    } else {
                                       _discountController.text = (_discountAmount % 1 == 0) ? _discountAmount.toInt().toString() : _discountAmount.toStringAsFixed(2);
                                    }
                                    _recalculateTotals();
                                  });
                            },
                            borderRadius: BorderRadius.circular(8),
                            constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                            children: const [
                              Text('%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('₹', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    onChanged: (val) => _recalculateTotals(),
                  ),
                ),
              ],
            ),`;

const newPaymentRow = `            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                      });
                    },
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _paidAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Paid Amount (₹)',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() => _isPaidAmountAutoFill = false);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showLinkBillsModal,
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Link'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: ref.watch(bankAccountsListProvider).when(
                    data: (accounts) {
                      final activeAccounts = accounts.where((a) => !a.isDeleted).toList();
                      final modes = ['Cash', 'Credit', 'Cheque', 'UPI', 'Bank Transfer', ...activeAccounts.map((a) => a.bankName ?? '')].toSet().toList();
                      return SearchablePaymentModeDropdown(
                        paymentModes: modes,
                        selectedMode: _paymentMode,
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentMode = val);
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Discount',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                          child: ToggleButtons(
                            isSelected: [_isDiscountPercent, !_isDiscountPercent],
                            onPressed: (idx) {
                                  setState(() {
                                    bool newIsPercent = idx == 0;
                                    if (newIsPercent == _isDiscountPercent) return;
                                    
                                    _isDiscountPercent = newIsPercent;
                                    
                                    if (_isDiscountPercent) {
                                       double percent = 0.0;
                                       if (_subtotal > 0) percent = (_discountAmount / _subtotal) * 100.0;
                                       _discountController.text = (percent % 1 == 0) ? percent.toInt().toString() : percent.toStringAsFixed(2);
                                    } else {
                                       _discountController.text = (_discountAmount % 1 == 0) ? _discountAmount.toInt().toString() : _discountAmount.toStringAsFixed(2);
                                    }
                                    _recalculateTotals();
                                  });
                            },
                            borderRadius: BorderRadius.circular(8),
                            constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                            children: const [
                              Text('%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('₹', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    onChanged: (val) => _recalculateTotals(),
                  ),
                ),
              ],
            ),`;

t = t.replace(oldPaymentRow, newPaymentRow);

fs.writeFileSync(f, t);
console.log('Credit Note UI patched!');
