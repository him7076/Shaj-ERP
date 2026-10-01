const fs = require('fs');

function fixPartyTransferScreen() {
    let f = 'lib/features/transactions/presentation/screens/add_edit_party_transfer_screen.dart';
    if (!fs.existsSync(f)) return;
    let t = fs.readFileSync(f, 'utf8');

    // Fix transaction type
    t = t.replace(`txn.transactionType = 'Transfer';`, `txn.transactionType = 'Party Transfer';`);
    t = t.replace(`generateNextTransactionNumber('Transfer')`, `generateNextTransactionNumber('Party Transfer')`);

    // Add Cancel button in AppBar
    if (!t.includes(`icon: const Icon(Icons.cancel_outlined, color: Colors.red)`)) {
        t = t.replace(
            `centerTitle: true,`,
            `centerTitle: true,\n        actions: [\n          if (widget.existingTransaction != null && !(widget.existingTransaction!.isDeleted ?? false))\n            IconButton(\n              icon: const Icon(Icons.cancel_outlined, color: Colors.red),\n              tooltip: 'Cancel Transaction',\n              onPressed: () => _cancelTransaction(),\n            ),\n        ],`
        );

        const cancelMethod = `  Future<void> _cancelTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Transaction?'),
        content: const Text('Are you sure you want to cancel/void this transaction? It will be marked as deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NO')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    try {
      final txn = widget.existingTransaction!;
      txn.isDeleted = true;
      txn.updatedAt = DateTime.now();
      await ref.read(transactionRepositoryProvider).saveTransaction(txn);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction cancelled successfully')));
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
         setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save()`;

        t = t.replace(`  Future<void> _save()`, cancelMethod);
    }
    fs.writeFileSync(f, t);
}

function fixTransactionsScreen() {
    let f = 'lib/features/transactions/presentation/screens/manage_transactions_screen.dart';
    if (!fs.existsSync(f)) return;
    let t = fs.readFileSync(f, 'utf8');

    // Add Cancel to popup menu
    if (!t.includes(`value: 'cancel'`)) {
        t = t.replace(
            `                  const PopupMenuItem(value: 'delete', child: Text('Delete')),\n                ],`,
            `                  const PopupMenuItem(value: 'cancel', child: Text('Cancel / Void', style: TextStyle(color: Colors.red))),\n                  const PopupMenuItem(value: 'delete', child: Text('Delete')),\n                ],`
        );

        t = t.replace(
            `              onSelected: (value) {
                if (value == 'edit') {`,
            `              onSelected: (value) async {
                if (value == 'cancel') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Cancel Transaction?'),
                      content: const Text('Are you sure you want to cancel this transaction?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NO')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('YES, CANCEL'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                       txn.isDeleted = true;
                       txn.updatedAt = DateTime.now();
                       await ref.read(transactionRepositoryProvider).saveTransaction(txn);
                       ref.invalidate(transactionListProvider);
                    } catch(e) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                } else if (value == 'edit') {`
        );
    }
    fs.writeFileSync(f, t);
}

function fixManageCashBank() {
    let f = 'lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart';
    if (!fs.existsSync(f)) return;
    let t = fs.readFileSync(f, 'utf8');

    if (!t.includes(`if (['Party Transfer', 'Party to Party Transfer'].contains(t.transactionType)) continue;`)) {
        // Fix 1: System Cash Balance calculation
        t = t.replace(
            `        final target = (t.partyName ?? '').trim().toLowerCase();\n        final amt = t.amount ?? 0.0;\n        \n        bool matches`,
            `        if (['Party Transfer', 'Party to Party Transfer'].contains(t.transactionType)) continue;\n        final target = (t.partyName ?? '').trim().toLowerCase();\n        final amt = t.amount ?? 0.0;\n        \n        bool matches`
        );

        // Fix 2: Bank accounts loop
        t = t.replace(
            `          final target = (t.partyName ?? '').trim().toLowerCase();\n          final amt = t.amount ?? 0.0;\n\n          bool matches`,
            `          if (['Party Transfer', 'Party to Party Transfer'].contains(t.transactionType)) continue;\n          final target = (t.partyName ?? '').trim().toLowerCase();\n          final amt = t.amount ?? 0.0;\n\n          bool matches`
        );

        // Fix 3: AccountTransactionsDetailScreen loop
        t = t.replace(
            `      for (var t in rawTxns) {\n        final mode = (t.paymentMode ?? 'cash').trim().toLowerCase();`,
            `      for (var t in rawTxns) {\n        if (['Party Transfer', 'Party to Party Transfer'].contains(t.transactionType)) continue;\n        final mode = (t.paymentMode ?? 'cash').trim().toLowerCase();`
        );
    }
    fs.writeFileSync(f, t);
}

fixPartyTransferScreen();
fixTransactionsScreen();
fixManageCashBank();
console.log('Fixed party transfers and added cancel buttons!');
