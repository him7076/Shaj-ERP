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

// 1 & 2. Party Transfer: Swap logic and Auto Voucher
patchFile('lib/features/transactions/presentation/screens/add_edit_party_transfer_screen.dart', content => {
    // 1. Swap Invoices and Purchases for From/To
    let patched = content.replace(
        /if \(isFromParty\) \{\s+final allInvs = await isar\.invoices\.filter\(\)\.isDeletedEqualTo\(false\)\.findAll\(\);\s+final invs = allInvs\.where\(\(inv\) => \(inv\.party\.value\?\.uuid == partyUuid\) \|\| \(inv\.partyId == party\.id\) \|\| \(pNameLower != null && inv\.partyName\?\.trim\(\)\.toLowerCase\(\) == pNameLower\)\)\.toList\(\);\s+allBills\.addAll\(invs\);\s+\} else \{\s+final allPurs = await isar\.purchases\.filter\(\)\.isDeletedEqualTo\(false\)\.findAll\(\);\s+final purs = allPurs\.where\(\(pur\) => \(pur\.party\.value\?\.uuid == partyUuid\) \|\| \(pur\.partyId == party\.id\) \|\| \(pNameLower != null && pur\.partyName\?\.trim\(\)\.toLowerCase\(\) == pNameLower\)\)\.toList\(\);\s+allBills\.addAll\(purs\);\s+\}/g,
        `if (!isFromParty) {
      final allInvs = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
      final invs = allInvs.where((inv) => (inv.party.value?.uuid == partyUuid) || (inv.partyId == party.id) || (pNameLower != null && inv.partyName?.trim().toLowerCase() == pNameLower)).toList();
      allBills.addAll(invs);
    } else {
      final allPurs = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
      final purs = allPurs.where((pur) => (pur.party.value?.uuid == partyUuid) || (pur.partyId == party.id) || (pNameLower != null && pur.partyName?.trim().toLowerCase() == pNameLower)).toList();
      allBills.addAll(purs);
    }`
    );

    // 2. Auto Voucher
    patched = patched.replace(
        /String\? _imagePath;/g,
        `String? _imagePath;\n  String _nextVoucher = 'Auto';`
    );

    patched = patched.replace(
        /void initState\(\) \{\s+super\.initState\(\);/g,
        `void initState() {
    super.initState();
    if (widget.existingTransaction == null) {
      _fetchVoucherNumber();
    }`
    );

    // Add fetch method before _pickImage
    patched = patched.replace(
        /Future<void> _pickImage/g,
        `Future<void> _fetchVoucherNumber() async {
    try {
      final num = await ref.read(transactionRepositoryProvider).generateNextTransactionNumber('Transfer');
      if (mounted) setState(() => _nextVoucher = num);
    } catch (_) {}
  }

  Future<void> _pickImage`
    );

    patched = patched.replace(
        /widget\.existingTransaction\?\.transactionNumber \?\? 'Auto'/g,
        `widget.existingTransaction?.transactionNumber ?? _nextVoucher`
    );

    return patched;
});

// 3 & 4. Transaction Dialog: Show Voucher and Remove Filter
patchFile('lib/features/transactions/presentation/screens/add_edit_transaction_dialog.dart', content => {
    // Add _nextVoucher property
    let patched = content.replace(
        /bool _isSaving = false;/g,
        `bool _isSaving = false;\n  String _nextVoucher = 'Auto';`
    );

    patched = patched.replace(
        /void initState\(\) \{\s+super\.initState\(\);/g,
        `void initState() {
    super.initState();
    if (widget.transaction == null) {
      _fetchVoucherNumber();
    }`
    );

    patched = patched.replace(
        /Future<void> _fetchPendingBills/g,
        `Future<void> _fetchVoucherNumber() async {
    try {
      final num = await ref.read(transactionRepositoryProvider).generateNextTransactionNumber(_transactionType);
      if (mounted) setState(() => _nextVoucher = num);
    } catch (_) {}
  }

  Future<void> _fetchPendingBills`
    );

    // Reload number on chip tap
    patched = patched.replace(
        /_pendingBills = \[\];\r?\n\s+\}\);\r?\n\s+_fetchPendingBills\(\);/g,
        `_pendingBills = [];\n                  _nextVoucher = 'Loading...';\n                });\n                _fetchPendingBills();\n                _fetchVoucherNumber();`
    );

    // Remove party filter
    patched = patched.replace(
        /if \(widget\.transaction == null && widget\.initialParty == null\) \{\r?\n\s+if \(_transactionType == 'Receipt' \|\| _transactionType == 'Credit Note'\) \{\r?\n\s+filteredParties = parties\.where\(\(p\) => p\.partyType != 'Supplier'\)\.toList\(\);\r?\n\s+\} else if \(_transactionType == 'Payment' \|\| _transactionType == 'Debit Note'\) \{\r?\n\s+filteredParties = parties\.where\(\(p\) => p\.partyType == 'Supplier'\)\.toList\(\);\r?\n\s+\}\r?\n\s+\}/g,
        `// Party type filter removed to allow all parties`
    );

    // Add Voucher No field next to Date Picker
    const oldDatePicker = `                InkWell(
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
                      labelText: 'Transaction Date',
                      
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd MMMM yyyy').format(_transactionDate)),
                  ),
                ),`;
    const newDatePicker = `                Row(
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
    
    patched = patched.replace(oldDatePicker, newDatePicker);
    
    return patched;
});

// 5. Fix Unique Index in Repository
patchFile('lib/data/repositories/transaction_repository_impl.dart', content => {
    const oldGen = `  @override
  Future<String> generateNextTransactionNumber(String type) async {
    try {
      final allTxns = await collection.where().findAll();
      int maxNum = 0;
      for (var t in allTxns) {
        if (t.transactionType == type && t.transactionNumber != null) {
          final matches = RegExp(r'\\d+').allMatches(t.transactionNumber!);
          if (matches.isNotEmpty) {
            final parsed = int.tryParse(matches.last.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      final nextNum = maxNum + 1;
      final suffix = nextNum.toString().padLeft(2, '0');
      String prefix = 'PAYMENT';
      if (type == 'Receipt' || type == 'Payment In') prefix = 'RECEIPT';
      if (type == 'Expense') prefix = 'EXP';
      if (type == 'Other Income') prefix = 'OTHER Income';
      if (type == 'Credit Note') prefix = 'CN';
      if (type == 'Debit Note') prefix = 'DN';
      if (['Transfer', 'Bank Transfer', 'Cash Adjustment', 'Party Transfer', 'Party to Party Transfer'].contains(type)) prefix = 'TRF';
      return '$prefix-$suffix';
    } catch (e) {
      throw DatabaseException('Failed to generate transaction number: $e');
    }
  }`;

    const newGen = `  @override
  Future<String> generateNextTransactionNumber(String type) async {
    try {
      String prefix = 'PAYMENT';
      if (type == 'Receipt' || type == 'Payment In') prefix = 'RECEIPT';
      else if (type == 'Expense') prefix = 'EXP';
      else if (type == 'Other Income') prefix = 'OTHER Income';
      else if (type == 'Credit Note') prefix = 'CN';
      else if (type == 'Debit Note') prefix = 'DN';
      else if (['Transfer', 'Bank Transfer', 'Cash Adjustment', 'Party Transfer', 'Party to Party Transfer'].contains(type)) prefix = 'TRF';

      final allTxns = await collection.where().findAll();
      int maxNum = 0;
      for (var t in allTxns) {
        if (t.transactionNumber != null && t.transactionNumber!.startsWith(prefix)) {
          final matches = RegExp(r'\\d+').allMatches(t.transactionNumber!);
          if (matches.isNotEmpty) {
            final parsed = int.tryParse(matches.last.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      final nextNum = maxNum + 1;
      final suffix = nextNum.toString().padLeft(2, '0');
      return '$prefix-$suffix';
    } catch (e) {
      throw DatabaseException('Failed to generate transaction number: $e');
    }
  }`;

    return content.replace(oldGen, newGen);
});
