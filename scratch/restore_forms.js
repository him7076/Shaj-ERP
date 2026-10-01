const fs = require('fs');

function restoreFile(path, dateVar) {
    let content = fs.readFileSync(path, 'utf8');

    const brokenSnippet = `                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _originalBillNumberController,
                    decoration: const InputDecoration(
                      labelText: 'INV NO',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }`;

    const fixedSnippet = `                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GST: \${_selectedParty!.gstNumber ?? "Unregistered"} | Address: \${_selectedParty!.city ?? "N/A"} | Current Balance: ₹\${_selectedParty!.outstandingBalance?.toStringAsFixed(2) ?? "0.00"}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: ${dateVar},
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null) {
                        setState(() => ${dateVar} = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: '${dateVar === '_creditNoteDate' ? 'CreditNote Date' : 'DebitNote Date'}',  isDense: true),
                      child: Text(DateFormat('dd-MM-yyyy').format(${dateVar}), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _originalBillNumberController,
                    decoration: const InputDecoration(
                      labelText: 'INV NO',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }`;

    if (content.includes(brokenSnippet)) {
        content = content.replace(brokenSnippet, fixedSnippet);
        fs.writeFileSync(path, content, 'utf8');
        console.log("Restored " + path);
    } else {
        console.log("Could not find broken snippet in " + path);
    }
}

restoreFile('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', '_creditNoteDate');
restoreFile('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', '_debitNoteDate');
