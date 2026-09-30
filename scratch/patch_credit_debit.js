const fs = require('fs');

const files = [
  'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'
];

files.forEach(file => {
  if (!fs.existsSync(file)) return;
  let code = fs.readFileSync(file, 'utf8');

  // 1. Party Filter
  code = code.replace(/final supplierParties = parties\.where\(\(p\) => p\.partyType == 'Supplier'\)\.toList\(\);/g, "final supplierParties = parties; // All parties");
  code = code.replace(/labelText: 'Select Supplier Account',/g, "labelText: 'Select Account',");

  // 2. Row instead of ResponsiveFormRow for Date
  code = code.replace(/ResponsiveFormRow\(\s*children: \[\s*Expanded\(\s*child: InkWell\(\s*onTap: \(\) async \{\s*final selected = await showDatePicker/g,
    `Row(\n              children: [\n                Expanded(\n                  child: InkWell(\n                    onTap: () async {\n                      final selected = await showDatePicker`);

  // 3. States
  if (!code.includes('bool _isDiscountPercent')) {
    code = code.replace(/final _remarksController = TextEditingController\(\);/g,
      `final _remarksController = TextEditingController();\n  bool _isDiscountPercent = false;\n  bool _isPaidAmountAutoFill = false;\n  String _paymentMode = 'Cash';`);
  }

  // 4. Recalculate Totals
  code = code.replace(/_discountAmount = double\.tryParse\(_discountController\.text\) \?\? 0\.0;/g,
    `final discInput = double.tryParse(_discountController.text) ?? 0.0;\n    _discountAmount = _isDiscountPercent ? (sub * (discInput / 100.0)) : discInput;`);

  // 5. Replace Discount UI
  const discountUI = `            Row(
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
                      labelText: file.includes('debit') ? 'Received (₹)' : 'Paid (₹)',
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
                                _isDiscountPercent = idx == 0;
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
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksController,
              decoration: InputDecoration(labelText: 'Remarks / Notes', ),
            ),`;

  // We find the old discount block and replace it
  const oldDiscountRegex = /TextFormField\(\s*controller: _discountController,[\s\S]*?TextFormField\(\s*controller: _remarksController,[\s\S]*?\),/m;
  if (code.match(oldDiscountRegex)) {
     // replace dynamically using function to evaluate 'file.includes'
     let finalUI = discountUI.replace(/file\.includes\('debit'\)/, file.includes('debit') ? 'true' : 'false');
     code = code.replace(oldDiscountRegex, finalUI);
  }

  // 6. Fix Save Method to include _paymentMode properly
  // Actually, we added _paymentMode. Wait, CreditNote already had `paymentMode = _paymentMode`.
  // DebitNote also has `paymentMode = _paymentMode`. We don't need to change that.

  // 7. Add Imports
  if (!code.includes('import \'package:business_sahaj_erp/core/widgets/searchable_payment_mode_dropdown.dart\';')) {
    code = "import 'package:business_sahaj_erp/core/widgets/searchable_payment_mode_dropdown.dart';\n" + code;
    code = "import 'package:business_sahaj_erp/features/bank/presentation/providers/bank_providers.dart';\n" + code;
  }

  fs.writeFileSync(file, code);
  console.log(`Patched UI elements in ${file}`);
});
