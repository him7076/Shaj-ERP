const fs = require('fs');
let content = fs.readFileSync('lib/features/bank/presentation/screens/transfer_funds_dialog.dart', 'utf8');

// 1. Add _adjustmentType state
content = content.replace(
  "String _transferType = 'Bank to Cash';",
  "String _transferType = 'Bank to Cash';\n  String _adjustmentType = 'Increase Balance';"
);

// 2. Replace SegmentedButton
const searchSegment = `                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Bank to Cash', label: Text('Bank \u2192 Cash'), icon: Icon(Icons.account_balance_wallet)),
                          ButtonSegment(value: 'Cash to Bank', label: Text('Cash \u2192 Bank'), icon: Icon(Icons.account_balance)),
                          ButtonSegment(value: 'Bank to Bank', label: Text('Bank \u2192 Bank'), icon: Icon(Icons.sync_alt)),
                        ],
                        selected: {_transferType},
                        onSelectionChanged: (set) {
                          setState(() {
                            _transferType = set.first;
                          });
                        },
                      ),`;

const replaceSegment = `                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Bank to Cash', label: Text('Bank \u2192 Cash')),
                            ButtonSegment(value: 'Cash to Bank', label: Text('Cash \u2192 Bank')),
                            ButtonSegment(value: 'Bank to Bank', label: Text('Bank \u2192 Bank')),
                            ButtonSegment(value: 'Adjustment', label: Text('Adjustment')),
                          ],
                          selected: {_transferType},
                          onSelectionChanged: (set) {
                            setState(() {
                              _transferType = set.first;
                            });
                          },
                        ),
                      ),`;
content = content.replace(searchSegment, replaceSegment);

// 3. Add UI fields for Adjustment
const searchFromTo = `                      if (_transferType == 'Bank to Cash')`;
const replaceFromTo = `                      if (_transferType == 'Adjustment') ...[
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Increase Balance', label: Text('Increase Balance'), icon: Icon(Icons.add_circle)),
                            ButtonSegment(value: 'Decrease Balance', label: Text('Decrease Balance'), icon: Icon(Icons.remove_circle)),
                          ],
                          selected: {_adjustmentType},
                          onSelectionChanged: (set) => setState(() => _adjustmentType = set.first),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _fromBank,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Account Name', prefixIcon: Icon(Icons.account_balance)),
                          items: _bankAccounts.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (v) => setState(() => _fromBank = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ],
                      if (_transferType == 'Bank to Cash')`;
content = content.replace(searchFromTo, replaceFromTo);

// 4. Update _saveTransfer logic
const searchSave = `    if (_transferType == 'Bank to Cash') {
      if (_fromBank == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select From Bank')));
        return;
      }
      paymentMode = _fromBank!;
      partyName = 'Cash';
    } else if (_transferType == 'Cash to Bank') {`;

const replaceSave = `    if (_transferType == 'Adjustment') {
      if (_fromBank == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select Account Name')));
        return;
      }
      if (_adjustmentType == 'Increase Balance') {
        paymentMode = 'System Adjustment';
        partyName = _fromBank!;
      } else {
        paymentMode = _fromBank!;
        partyName = 'System Adjustment';
      }
    } else if (_transferType == 'Bank to Cash') {
      if (_fromBank == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select From Bank')));
        return;
      }
      paymentMode = _fromBank!;
      partyName = 'Cash';
    } else if (_transferType == 'Cash to Bank') {`;
content = content.replace(searchSave, replaceSave);

fs.writeFileSync('lib/features/bank/presentation/screens/transfer_funds_dialog.dart', content, 'utf8');
console.log('transfer_funds_dialog updated');
