const fs = require('fs');

function patchFile(path, replacerFn) {
    let content = fs.readFileSync(path, 'utf8');
    const newContent = replacerFn(content);
    if (content !== newContent) {
        fs.writeFileSync(path, newContent, 'utf8');
        console.log(`Patched ${path}`);
    } else {
        console.log(`No changes made to ${path}`);
    }
}

// 1. Separate Party Transfer prefix to start from 1 (PT-01)
patchFile('lib/data/repositories/transaction_repository_impl.dart', content => {
    return content.replace(
        /else if \(\['Transfer', 'Bank Transfer', 'Cash Adjustment', 'Party Transfer', 'Party to Party Transfer'\]\.contains\(type\)\) prefix = 'TRF';/,
        `else if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(type)) prefix = 'TRF';
      else if (type == 'Party Transfer' || type == 'Party to Party Transfer') prefix = 'PT';`
    );
});

// 2 & 3. Voucher Number, Fullscreen Link Dialog, Checkbox Alignment
patchFile('lib/features/transactions/presentation/screens/add_edit_transaction_dialog.dart', content => {
    
    // Add Voucher No next to DatePicker
    // I will replace the exact block of InkWell for Date Picker
    const datePickerRegex = /\/\/ Date Picker\r?\n\s+InkWell\([\s\S]*?child: Text\(DateFormat\('dd MMMM yyyy'\)\.format\(_transactionDate\)\),\r?\n\s+\),\r?\n\s+\),/;
    
    const newDatePicker = `// Date Picker and Voucher
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _transactionDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _transactionDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(DateFormat('dd MMM yy').format(_transactionDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Voucher No.',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        child: Text(widget.transaction?.transactionNumber ?? _nextVoucher, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),`;
                
    let patched = content.replace(datePickerRegex, newDatePicker);
    
    // Fullscreen Dialog
    const dialogRegex = /return Dialog\(\r?\n\s+shape: RoundedRectangleBorder\(borderRadius: BorderRadius\.circular\(16\)\),\r?\n\s+child: Container\(\r?\n\s+width: min\(580\.0, MediaQuery\.of\(context\)\.size\.width - 24\.0\),\r?\n\s+padding: const EdgeInsets\.all\(20\),/g;
    const fullscreenDialog = `return Dialog.fullscreen(
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(20),`;
    patched = patched.replace(dialogRegex, fullscreenDialog);
    
    // Checkbox alignment - inside ResponsiveFormRow
    const checkboxRegex = /Checkbox\(\r?\n\s+value: isLinked,[\s\S]*?setState\(\(\) \{\}\);\r?\n\s+\},\r?\n\s+\),\r?\n\s+Expanded\(\r?\n\s+child: Column\(\r?\n\s+crossAxisAlignment: CrossAxisAlignment\.start,\r?\n\s+children: \[\r?\n\s+Text\([\s\S]*?fontWeight: FontWeight\.bold\),\r?\n\s+\),\r?\n\s+Text\([\s\S]*?fontSize: 12\),\r?\n\s+\),\r?\n\s+\],\r?\n\s+\),\r?\n\s+\),/;
    
    const newCheckbox = `Expanded(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Checkbox(
                                            value: isLinked,
                                            onChanged: (val) {
                                              setModalState(() {
                                                if (val == true) {
                                                  final allocVal = min(remainingUnallocated, pendingToPay);
                                                  _linkedAllocations[uuid] = double.parse(allocVal.toStringAsFixed(2));
                                                } else {
                                                  _linkedAllocations.remove(uuid);
                                                }
                                                _updateControllers();
                                              });
                                              setState(() {});
                                            },
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _transactionType == 'Receipt' || _transactionType == 'Credit Note'
                                                      ? 'Invoice #\${bill.invoiceNumber ?? bill.uuid.substring(0, 8)}'
                                                      : 'Bill #\${bill.purchaseNumber ?? bill.uuid.substring(0, 8)}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  'Total: ₹\${grandTotal.toStringAsFixed(2)} | Pending: ₹\${remainingOnInvoice.toStringAsFixed(2)}',
                                                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),`;
                                    
    patched = patched.replace(checkboxRegex, newCheckbox);
    
    return patched;
});
