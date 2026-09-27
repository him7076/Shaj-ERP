import 'dart:io';

void main() {
  final file = File('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart');
  var content = file.readAsStringSync();
  
  // Update _loadAccounts
  final startLoadAccounts = content.indexOf('  Future<void> _loadAccounts() async {');
  final endLoadAccounts = content.indexOf('  double get _totalLiquidBalance {');
  
  if (startLoadAccounts == -1 || endLoadAccounts == -1) {
    print('Could not find _loadAccounts bounds');
    return;
  }
  
  final newLoadAccounts = '''
  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      _accounts = await isar.bankAccounts.filter().isDeletedEqualTo(false).findAll();
      final txns = await isar.transactions.filter().isDeletedEqualTo(false).findAll();
      final invoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
      final purchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
      final expenses = await isar.expenses.filter().isDeletedEqualTo(false).findAll();

      final Set<String> linkedInvoiceUuids = txns.where((t) => t.linkedBillUuid != null).map((t) => t.linkedBillUuid!).toSet();

      // 1. Calculate Live Cash in Hand Balance
      double cashInflows = 0.0;
      double cashOutflows = 0.0;

      for (var t in txns) {
        final mode = (t.paymentMode ?? 'cash').trim().toLowerCase();
        final target = (t.partyName ?? '').trim().toLowerCase();
        final amt = t.amount ?? 0.0;

        if (mode == 'cash' || mode.contains('cash') || mode.isEmpty) {
          if (t.transactionType == 'Receipt' || t.transactionType == 'Other Income') {
            cashInflows += amt;
          } else if (t.transactionType == 'Payment' || t.transactionType == 'Expense') {
            cashOutflows += amt;
          } else if (t.transactionType == 'Transfer') {
            cashOutflows += amt;
          }
        }

        if (t.transactionType == 'Transfer' && (target == 'cash' || target.contains('cash'))) {
          cashInflows += amt;
        }
      }

      for (var inv in invoices) {
        if (inv.uuid != null && linkedInvoiceUuids.contains(inv.uuid)) continue;
        final status = (inv.paymentStatus ?? '').trim().toLowerCase();
        final remarks = (inv.remarks ?? '').trim().toLowerCase();
        final paid = inv.paidAmount ?? inv.grandTotal ?? 0.0;
        if (paid > 0 && (status == 'paid' || status == 'cash' || status.contains('cash') || remarks.contains('paid via cash'))) {
          cashInflows += paid;
        }
      }

      for (var pur in purchases) {
        if (pur.uuid != null && linkedInvoiceUuids.contains(pur.uuid)) continue;
        final status = (pur.paymentStatus ?? '').trim().toLowerCase();
        final remarks = (pur.remarks ?? '').trim().toLowerCase();
        final paid = pur.paidAmount ?? pur.grandTotal ?? 0.0;
        if (paid > 0 && (status == 'paid' || status == 'cash' || status.contains('cash') || remarks.contains('paid via cash'))) {
          cashOutflows += paid;
        }
      }

      for (var exp in expenses) {
        final mode = (exp.paymentMode ?? 'cash').trim().toLowerCase();
        if (mode == 'cash' || mode.contains('cash') || mode.isEmpty) {
          cashOutflows += (exp.amount ?? 0.0);
        }
      }

      _cashBalance = cashInflows - cashOutflows;

      // 2. Calculate Live Bank Account Balances
      for (var acc in _accounts) {
        final name = (acc.accountName ?? '').trim().toLowerCase();
        double bankInflows = 0.0;
        double bankOutflows = 0.0;

        for (var t in txns) {
          final mode = (t.paymentMode ?? '').trim().toLowerCase();
          final target = (t.partyName ?? '').trim().toLowerCase();
          final amt = t.amount ?? 0.0;

          if (mode == name || (mode.isNotEmpty && name.isNotEmpty && mode.contains(name))) {
            if (t.transactionType == 'Receipt' || t.transactionType == 'Other Income') {
              bankInflows += amt;
            } else if (t.transactionType == 'Payment' || t.transactionType == 'Expense' || t.transactionType == 'Transfer') {
              bankOutflows += amt;
            }
          }

          if (t.transactionType == 'Transfer' && (target == name || (target.isNotEmpty && name.isNotEmpty && target.contains(name)))) {
            bankInflows += amt;
          }
        }

        for (var inv in invoices) {
          if (inv.uuid != null && linkedInvoiceUuids.contains(inv.uuid)) continue;
          final status = (inv.paymentStatus ?? '').trim().toLowerCase();
          final remarks = (inv.remarks ?? '').trim().toLowerCase();
          final paid = inv.paidAmount ?? inv.grandTotal ?? 0.0;
          if (paid > 0 && (status == name || status.contains(name) || remarks.contains('paid via \$name') || remarks.contains(name))) {
            bankInflows += paid;
          }
        }

        for (var pur in purchases) {
          if (pur.uuid != null && linkedInvoiceUuids.contains(pur.uuid)) continue;
          final status = (pur.paymentStatus ?? '').trim().toLowerCase();
          final remarks = (pur.remarks ?? '').trim().toLowerCase();
          final paid = pur.paidAmount ?? pur.grandTotal ?? 0.0;
          if (paid > 0 && (status == name || status.contains(name) || remarks.contains('paid via \$name') || remarks.contains(name))) {
            bankOutflows += paid;
          }
        }

        for (var exp in expenses) {
          final mode = (exp.paymentMode ?? '').trim().toLowerCase();
          if (mode == name || (mode.isNotEmpty && name.isNotEmpty && mode.contains(name))) {
            bankOutflows += (exp.amount ?? 0.0);
          }
        }

        final openBal = acc.openingBalance ?? 0.0;
        acc.currentBalance = openBal + bankInflows - bankOutflows;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

''';

  content = content.replaceRange(startLoadAccounts, endLoadAccounts, newLoadAccounts);
  
  // Now update _loadTransactions inside AccountTransactionsDetailScreenState
  final startLoadTxns = content.indexOf('  Future<void> _loadTransactions() async {');
  final endLoadTxns = content.indexOf('  List<AccountTransactionDisplayItem> get _filteredTransactions {');
  
  if (startLoadTxns == -1 || endLoadTxns == -1) {
    print('Could not find _loadTransactions bounds');
    return;
  }
  
  final newLoadTxns = '''
  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final rawTxns = await isar.transactions.filter().isDeletedEqualTo(false).findAll();
      final invoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
      final purchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
      final expenses = await isar.expenses.filter().isDeletedEqualTo(false).findAll();

      final List<AccountTransactionDisplayItem> items = [];
      final Set<String> linkedInvoiceUuids = rawTxns.where((t) => t.linkedBillUuid != null).map((t) => t.linkedBillUuid!).toSet();

      for (var t in rawTxns) {
        final mode = (t.paymentMode ?? 'cash').trim().toLowerCase();
        final target = (t.partyName ?? '').trim().toLowerCase();
        bool matches = false;
        if (widget.isCash) {
          matches = mode == 'cash' || mode.contains('cash') || mode.isEmpty;
          if (t.transactionType == 'Transfer' && (target == 'cash' || target.contains('cash'))) {
            matches = true;
          }
        } else {
          final accName = widget.accountName.trim().toLowerCase();
          matches = mode == accName || mode.contains(accName) || (accName.contains('bank') && (mode == 'bank' || mode == 'online' || mode == 'upi' || mode == 'cheque'));
          if (t.transactionType == 'Transfer' && (target == accName || target.contains(accName))) {
            matches = true;
          }
        }

        if (matches) {
          bool isCredit = false;
          if (t.transactionType == 'Receipt' || t.transactionType == 'Other Income') {
            isCredit = true;
          } else if (t.transactionType == 'Transfer') {
             // If this account was the target, it's a credit!
             if (widget.isCash) {
                isCredit = (target == 'cash' || target.contains('cash'));
             } else {
                final accName = widget.accountName.trim().toLowerCase();
                isCredit = (target == accName || target.contains(accName));
             }
          }

          items.add(AccountTransactionDisplayItem(
            transactionNumber: t.transactionNumber ?? 'TXN',
            partyName: t.partyName ?? 'Party',
            transactionType: t.transactionType ?? 'Payment',
            date: t.transactionDate ?? t.createdAt,
            amount: t.amount ?? 0.0,
            isCredit: isCredit,
            remarks: t.remarks,
          ));
        }
      }

      for (var inv in invoices) {
        if (inv.uuid != null && linkedInvoiceUuids.contains(inv.uuid)) continue;
        final status = (inv.paymentStatus ?? '').trim().toLowerCase();
        final remarks = (inv.remarks ?? '').trim().toLowerCase();
        final paid = inv.paidAmount ?? inv.grandTotal ?? 0.0;
        
        bool matches = false;
        if (widget.isCash) {
           if (paid > 0 && (status == 'paid' || status == 'cash' || status.contains('cash') || remarks.contains('paid via cash'))) {
              matches = true;
           }
        } else {
           final accName = widget.accountName.trim().toLowerCase();
           if (paid > 0 && (status == accName || status.contains(accName) || remarks.contains('paid via \$accName') || remarks.contains(accName))) {
              matches = true;
           }
        }

        if (matches) {
          items.add(AccountTransactionDisplayItem(
            transactionNumber: inv.invoiceNumber ?? 'INV',
            partyName: inv.partyName ?? 'Customer',
            transactionType: 'Sales',
            date: inv.invoiceDate ?? inv.createdAt,
            amount: paid,
            isCredit: true,
            remarks: inv.remarks,
          ));
        }
      }

      for (var pur in purchases) {
        if (pur.uuid != null && linkedInvoiceUuids.contains(pur.uuid)) continue;
        final status = (pur.paymentStatus ?? '').trim().toLowerCase();
        final remarks = (pur.remarks ?? '').trim().toLowerCase();
        final paid = pur.paidAmount ?? pur.grandTotal ?? 0.0;
        
        bool matches = false;
        if (widget.isCash) {
           if (paid > 0 && (status == 'paid' || status == 'cash' || status.contains('cash') || remarks.contains('paid via cash'))) {
              matches = true;
           }
        } else {
           final accName = widget.accountName.trim().toLowerCase();
           if (paid > 0 && (status == accName || status.contains(accName) || remarks.contains('paid via \$accName') || remarks.contains(accName))) {
              matches = true;
           }
        }

        if (matches) {
          items.add(AccountTransactionDisplayItem(
            transactionNumber: pur.purchaseNumber ?? 'PUR',
            partyName: pur.partyName ?? 'Supplier',
            transactionType: 'Purchase',
            date: pur.purchaseDate ?? pur.createdAt,
            amount: paid,
            isCredit: false,
            remarks: pur.remarks,
          ));
        }
      }

      for (var exp in expenses) {
        final mode = (exp.paymentMode ?? 'cash').trim().toLowerCase();
        bool matches = false;
        if (widget.isCash) {
          if (mode == 'cash' || mode.contains('cash') || mode.isEmpty) matches = true;
        } else {
          final accName = widget.accountName.trim().toLowerCase();
          if (mode == accName || mode.contains(accName)) matches = true;
        }

        if (matches) {
          items.add(AccountTransactionDisplayItem(
            transactionNumber: exp.voucherNo ?? 'EXP',
            partyName: exp.partyName ?? exp.category ?? 'Expense',
            transactionType: 'Expense (\${exp.category ?? "General"})',
            date: exp.expenseDate ?? exp.createdAt,
            amount: exp.amount ?? 0.0,
            isCredit: false,
            remarks: exp.remarks,
          ));
        }
      }

      _allDisplayItems = items;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

''';

  content = content.replaceRange(startLoadTxns, endLoadTxns, newLoadTxns);
  
  file.writeAsStringSync(content);
  print('Successfully updated _loadAccounts and _loadTransactions!');
}
