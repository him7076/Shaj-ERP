const fs = require('fs');
let c = fs.readFileSync('lib/features/transactions/presentation/screens/add_edit_party_transfer_screen.dart', 'utf8');

c = c.replace(
  "SearchablePartyDropdown(\n                                parties: parties,\n                                selectedParty: _fromParty,\n                                labelText: 'Select From Party',\n                                onChanged: (p) => setState(() => _fromParty = p),\n                              ),",
  `SearchablePartyDropdown(
                                parties: parties,
                                selectedParty: _fromParty,
                                labelText: 'Select From Party',
                                onChanged: (p) => setState(() => _fromParty = p),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  labelText: 'Amount Deducted',
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  filled: true,
                                ),
                                onChanged: (val) {
                                  _amountController.text = val;
                                },
                              ),`
);

c = c.replace(
  "SearchablePartyDropdown(\n                                parties: parties,\n                                selectedParty: _toParty,\n                                labelText: 'Select To Party',\n                                onChanged: (p) => setState(() => _toParty = p),\n                              ),",
  `SearchablePartyDropdown(
                                parties: parties,
                                selectedParty: _toParty,
                                labelText: 'Select To Party',
                                onChanged: (p) => setState(() => _toParty = p),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  labelText: 'Amount Received',
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  filled: true,
                                ),
                                onChanged: (val) {
                                  _amountController.text = val;
                                },
                              ),`
);

const toRemove = `const SizedBox(height: 24);
                        // AMOUNT
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: 'Transfer Amount',
                            prefixText: '₹ ',
                            prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.blue[50],
                          ),
                        ),`;

c = c.replace(toRemove, "");

fs.writeFileSync('lib/features/transactions/presentation/screens/add_edit_party_transfer_screen.dart', c);
