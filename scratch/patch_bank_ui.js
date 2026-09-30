const fs = require('fs');
const path = 'lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart';
let code = fs.readFileSync(path, 'utf8');

const newLoadAccounts = `Future<void> _loadAccounts() async {
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
        
        bool matches = mode == 'cash' || mode.contains('cash') || mode.isEmpty;
        if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType) && (target == 'cash' || target.contains('cash'))) {
          matches = true;
        }

        if (matches) {
          bool isCredit = false;
          if (t.transactionType == 'Receipt' || t.transactionType == 'Other Income') {
            isCredit = true;
          } else if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType)) {
             isCredit = (target == 'cash' || target.contains('cash'));
          }
          if (isCredit) cashInflows += amt; else cashOutflows += amt;
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
        final accName = (acc.accountName ?? '').trim().toLowerCase();
        double bankInflows = 0.0;
        double bankOutflows = 0.0;

        for (var t in txns) {
          final mode = (t.paymentMode ?? '').trim().toLowerCase();
          final target = (t.partyName ?? '').trim().toLowerCase();
          final amt = t.amount ?? 0.0;

          bool matches = mode == accName || mode.contains(accName) || (accName.contains('bank') && (mode == 'bank' || mode == 'online' || mode == 'upi' || mode == 'cheque'));
          if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType) && (target == accName || target.contains(accName))) {
            matches = true;
          }

          if (matches) {
            bool isCredit = false;
            if (t.transactionType == 'Receipt' || t.transactionType == 'Other Income') {
              isCredit = true;
            } else if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType)) {
               isCredit = (target == accName || target.contains(accName));
            }
            if (isCredit) bankInflows += amt; else bankOutflows += amt;
          }
        }

        for (var inv in invoices) {
          if (inv.uuid != null && linkedInvoiceUuids.contains(inv.uuid)) continue;
          final status = (inv.paymentStatus ?? '').trim().toLowerCase();
          final remarks = (inv.remarks ?? '').trim().toLowerCase();
          final paid = inv.paidAmount ?? inv.grandTotal ?? 0.0;
          if (paid > 0 && (status == accName || status.contains(accName) || remarks.contains('paid via $accName') || remarks.contains(accName))) {
            bankInflows += paid;
          }
        }

        for (var pur in purchases) {
          if (pur.uuid != null && linkedInvoiceUuids.contains(pur.uuid)) continue;
          final status = (pur.paymentStatus ?? '').trim().toLowerCase();
          final remarks = (pur.remarks ?? '').trim().toLowerCase();
          final paid = pur.paidAmount ?? pur.grandTotal ?? 0.0;
          if (paid > 0 && (status == accName || status.contains(accName) || remarks.contains('paid via $accName') || remarks.contains(accName))) {
            bankOutflows += paid;
          }
        }

        for (var exp in expenses) {
          final mode = (exp.paymentMode ?? '').trim().toLowerCase();
          if (mode == accName || mode.contains(accName)) {
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
  }`;

const oldLoadAccountsStart = code.indexOf('Future<void> _loadAccounts() async {');
const oldLoadAccountsEnd = code.indexOf('  double get _totalLiquidBalance {');
if (oldLoadAccountsStart !== -1 && oldLoadAccountsEnd !== -1) {
  code = code.substring(0, oldLoadAccountsStart) + newLoadAccounts + '\n' + code.substring(oldLoadAccountsEnd);
}

// Replace ListTile trailing for bank accounts
const oldTrailing = `trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                  tooltip: 'Edit Account',
                                  onPressed: () => _showAddEditAccountDialog(existingAccount: acc),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Delete Account',
                                  onPressed: () => _deleteAccount(acc),
                                ),
                              ],
                            ),`;
code = code.replace(oldTrailing, `trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),`);

// Fix ListTile title Row wrapping
code = code.replace(
  `Expanded(child: Text(acc.accountName ?? 'Bank Account', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),`,
  `Expanded(child: Text(acc.accountName ?? 'Bank Account', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 8),`
);

code = code.replace(
  `Text(currencyFormat.format(balance), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E7D32))),`,
  `Text(currencyFormat.format(balance), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: balance >= 0 ? const Color(0xFF2E7D32) : Colors.red)),`
);

code = code.replace(
  `'\\$\\{acc.bankName ?? "Bank"\\} • A/C: \\$\\{acc.accountNumber ?? "N/A"\\} • IFSC: \\$\\{acc.ifscCode ?? "N/A"\\}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),`,
  `'\\$\\{acc.bankName ?? "Bank"\\} • A/C: \\$\\{acc.accountNumber ?? "N/A"\\}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                maxLines: 1, overflow: TextOverflow.ellipsis,`
);

// Add balance to AccountTransactionsDetailScreen
const inflowOutflowCode = `Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.arrow_downward_rounded, color: Colors.greenAccent, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text('Total Inflows (+)', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(currencyFormat.format(totalInflow), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                        ],
                      ),
                    ),
                    Container(height: 40, width: 1, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.arrow_upward_rounded, color: Colors.redAccent, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text('Total Outflows (-)', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(currencyFormat.format(totalOutflow), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                        ],
                      ),
                    ),`;

const currentBalDecl = `final double currentBalance = widget.isCash ? (totalInflow - totalOutflow) : ((widget.account?.openingBalance ?? 0.0) + totalInflow - totalOutflow);`;
const newInflowOutflowCode = `Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_downward_rounded, color: Colors.greenAccent, size: 14),
                              const SizedBox(width: 4),
                              const Text('Inflows (+)', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(currencyFormat.format(totalInflow), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(height: 30, width: 1, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_upward_rounded, color: Colors.redAccent, size: 14),
                              const SizedBox(width: 4),
                              const Text('Outflows (-)', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(currencyFormat.format(totalOutflow), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(height: 30, width: 1, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_rounded, color: Colors.blueAccent, size: 14),
                              const SizedBox(width: 4),
                              const Text('Balance', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(currencyFormat.format(currentBalance), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: currentBalance >= 0 ? Colors.white : Colors.redAccent), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),`;

const insertBalDeclIdx = code.indexOf('final double totalOutflow =');
if (insertBalDeclIdx !== -1) {
  const lineEndIdx = code.indexOf('\n', insertBalDeclIdx);
  code = code.substring(0, lineEndIdx) + '\n    ' + currentBalDecl + code.substring(lineEndIdx);
}

if (!code.includes('Total Inflows (+)')) {
  console.log("Could not find inflowOutflowCode block");
} else {
  code = code.replace(inflowOutflowCode, newInflowOutflowCode);
  fs.writeFileSync(path, code);
  console.log('Patched UI and Logic successfully.');
}
