import 'package:business_sahaj_erp/features/bank/presentation/screens/add_edit_bank_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/invoice_detail_screen.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/screens/add_edit_purchase_screen.dart';
import 'package:business_sahaj_erp/features/expenses/presentation/screens/add_edit_expense_screen.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_transaction_dialog.dart';
import 'package:business_sahaj_erp/core/widgets/responsive_form_row.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/features/bank/presentation/screens/transfer_funds_dialog.dart';

import 'package:business_sahaj_erp/features/bank/presentation/screens/adjust_cash_dialog.dart';

class ManageCashAndBankScreen extends ConsumerStatefulWidget {
  const ManageCashAndBankScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManageCashAndBankScreen> createState() => _ManageCashAndBankScreenState();
}

class _ManageCashAndBankScreenState extends ConsumerState<ManageCashAndBankScreen> {
  List<BankAccount> _accounts = [];
  double _cashBalance = 0.0;
  bool _isLoading = false;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

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
          if (paid > 0 && (status == name || status.contains(name) || remarks.contains('paid via $name') || remarks.contains(name))) {
            bankInflows += paid;
          }
        }

        for (var pur in purchases) {
          if (pur.uuid != null && linkedInvoiceUuids.contains(pur.uuid)) continue;
          final status = (pur.paymentStatus ?? '').trim().toLowerCase();
          final remarks = (pur.remarks ?? '').trim().toLowerCase();
          final paid = pur.paidAmount ?? pur.grandTotal ?? 0.0;
          if (paid > 0 && (status == name || status.contains(name) || remarks.contains('paid via $name') || remarks.contains(name))) {
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
  double get _totalLiquidBalance {
    final bankTotal = _accounts.fold(0.0, (sum, acc) => sum + (acc.currentBalance ?? acc.openingBalance ?? 0.0));
    return bankTotal + _cashBalance;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        title: const Text('Manage Cash & Bank Accounts', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'adjust_bank',
                onPressed: () async {
                  final res = await showDialog(
                    context: context,
                    builder: (_) => AdjustCashDialog(
                      accountName: widget.accountName,
                      isBank: true,
                      bankUuid: widget.bankUuid,
                    ),
                  );
                  if (res == true) _loadTransactions();
                },
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Adjust Bank'),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'add_bank_txn',
                onPressed: () async {
                  final res = await showDialog(
                    context: context,
                    builder: (_) => TransferFundsDialog(defaultFromAccount: widget.accountName),
                  );
                  if (res == true) {
                    _loadTransactions();
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Bank Transaction'),
              ),
            ],
          ),
              );
              if (res == true) {
                _loadTransactions();
              }
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Bank Transaction'),
          ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Beautiful Header Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF283593), Color(0xFF3F51B5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
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
                    ),
                  ],
                ),
              ),

              // Transactions List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : txns.isEmpty
                        ? const Center(child: Text('No matching transactions found for this account.'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 80),
                            itemCount: txns.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final t = txns[index];
                              final isCredit = t.isCredit;

                              return NeuCard(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    if (t.entityUuid == null) return;
                                    if (t.entityType == 'Transaction') {
                                      final isar = ref.read(databaseServiceProvider).isar;
                                      final txn = await isar.transactions.filter().uuidEqualTo(t.entityUuid).findFirst();
                                      if (txn != null && mounted) {
                                        if (txn.transactionType == 'Transfer') {
                                          showDialog(
                                            context: context,
                                            builder: (_) => TransferFundsDialog(
                                              existingTransaction: txn,
                                            ),
                                          ).then((_) => _loadTransactions());
                                        } else {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AddEditTransactionDialog(
                                              transaction: txn,
                                            ),
                                          ).then((_) => _loadTransactions());
                                        }
                                      }
                                    } else if (t.entityType == 'Invoice') {
                                      Navigator.of(context, rootNavigator: true).push(
                                        MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceUuid: t.entityUuid!))
                                      ).then((_) => _loadTransactions());
                                    } else if (t.entityType == 'Purchase') {
                                      Navigator.of(context, rootNavigator: true).push(
                                        MaterialPageRoute(builder: (_) => AddEditPurchaseScreen(purchaseUuid: t.entityUuid))
                                      ).then((_) => _loadTransactions());
                                    } else if (t.entityType == 'Expense') {
                                      Navigator.of(context, rootNavigator: true).push(
                                        MaterialPageRoute(builder: (_) => AddEditExpenseScreen(expenseUuid: t.entityUuid))
                                      ).then((_) => _loadTransactions());
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isCredit ? Colors.green : Colors.red),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(t.partyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 4),
                                              Text('#${t.transactionNumber} • ${t.transactionType}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                              if (t.remarks != null && t.remarks!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4.0),
                                                  child: Text(t.remarks!, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${isCredit ? "+" : "-"}${currencyFormat.format(t.amount)}',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isCredit ? Colors.green : Colors.red),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(DateFormat('dd-MM-yy').format(t.date), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Cheque Management & Deposit Screen ---
class ChequeManagementScreen extends ConsumerStatefulWidget {
  const ChequeManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChequeManagementScreen> createState() => _ChequeManagementScreenState();
}

class _ChequeManagementScreenState extends ConsumerState<ChequeManagementScreen> {
  String _statusFilter = 'All'; // 'All', 'Open', 'Closed'
  String _searchQuery = '';
  String _sortBy = 'Newest First'; // 'Newest First', 'Oldest First', 'Highest Amount', 'Lowest Amount', 'Party Name (A-Z)'

  List<Transaction> _allCheques = [];
  List<BankAccount> _accounts = [];
  bool _isLoading = false;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadChequesAndAccounts();
  }

  Future<void> _loadChequesAndAccounts() async {
    setState(() => _isLoading = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      _accounts = await isar.bankAccounts.filter().isDeletedEqualTo(false).findAll();
      final allTxns = await isar.transactions.filter().isDeletedEqualTo(false).findAll();

      final cheques = allTxns.where((t) {
        final mode = (t.paymentMode ?? '').trim().toLowerCase();
        final ref = (t.referenceNumber ?? '').trim().toLowerCase();
        return mode.contains('cheque') || ref.startsWith('chq') || ref.contains('cheque');
      }).toList();

      _allCheques = cheques;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDepositDialog(Transaction cheque) async {
    DateTime depositDate = DateTime.now();
    String selectedAccount = _accounts.isNotEmpty ? (_accounts.first.accountName ?? 'Cash in Hand') : 'Cash in Hand';
    final remarksCtrl = TextEditingController(text: cheque.remarks ?? '');

    final accountOptions = ['Cash in Hand', ..._accounts.map((a) => a.accountName ?? 'Bank Account')].toSet().toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Deposit Cheque #${cheque.referenceNumber ?? cheque.transactionNumber ?? ""}', style: const TextStyle(fontSize: 16))),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Party Name: ${cheque.partyName ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Cheque Amount: ${currencyFormat.format(cheque.amount ?? 0.0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),

                    // Deposit Date Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Transfer / Deposit Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(DateFormat('dd-MM-yyyy').format(depositDate), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      trailing: const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.blue),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: depositDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => depositDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Deposit To Account Dropdown
                    DropdownButtonFormField<String>(
                      value: accountOptions.contains(selectedAccount) ? selectedAccount : accountOptions.first,
                      decoration: const InputDecoration(
                        labelText: 'Deposit To Account',
                        
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: accountOptions.map((acc) => DropdownMenuItem(value: acc, child: Text(acc))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedAccount = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Description / Clearing Remarks
                    TextField(
                      controller: remarksCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Clearing Description / Bank Notes',
                        
                        hintText: 'e.g. Deposited at main branch desk 2',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Confirm Deposit'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _processChequeDeposit(cheque, depositDate, selectedAccount, remarksCtrl.text.trim());
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processChequeDeposit(Transaction cheque, DateTime depositDate, String targetAccount, String remarks) async {
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      cheque.paymentStatus = 'Closed';
      cheque.targetPartyName = targetAccount;
      cheque.remarks = 'Deposited on ${DateFormat('dd-MM-yyyy').format(depositDate)} to $targetAccount. $remarks';
      cheque.updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.transactions.put(cheque);
      });

      ref.read(syncManagerProvider).onLocalSave();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cheque deposited to $targetAccount successfully! Status: CLOSED.')),
      );
      _loadChequesAndAccounts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error depositing cheque: $e')),
      );
    }
  }

  Future<void> _reopenCheque(Transaction cheque) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reopen Cheque?'),
        content: Text('Are you sure you want to reopen cheque #${cheque.referenceNumber ?? cheque.transactionNumber ?? ""}? This will move it back to Open status for deposit.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reopen Cheque'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final isar = ref.read(databaseServiceProvider).isar;
        cheque.paymentStatus = 'Open';
        cheque.targetPartyName = null;
        cheque.updatedAt = DateTime.now();

        await isar.writeTxn(() async {
          await isar.transactions.put(cheque);
        });

        ref.read(syncManagerProvider).onLocalSave();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cheque status changed to OPEN.')),
        );
        _loadChequesAndAccounts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reopening cheque: $e')),
        );
      }
    }
  }

  void _viewTransactionDetails(Transaction cheque) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Receipt / Txn Details #${cheque.transactionNumber ?? ""}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Party Name: ${cheque.partyName ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text('Type: ${cheque.transactionType ?? "Payment"}'),
              Text('Cheque / Ref No: ${cheque.referenceNumber ?? "N/A"}'),
              Text('Amount: ${currencyFormat.format(cheque.amount ?? 0.0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Date: ${DateFormat('dd-MM-yyyy').format(cheque.transactionDate ?? cheque.createdAt)}'),
              Text('Status: ${(cheque.paymentStatus ?? "Open").toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, color: cheque.paymentStatus == 'Closed' ? Colors.green : Colors.orange)),
              if (cheque.targetPartyName != null) Text('Deposited To: ${cheque.targetPartyName}', style: const TextStyle(fontWeight: FontWeight.w600)),
              if (cheque.remarks != null) Text('Notes: ${cheque.remarks}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter Logic
    var filtered = _allCheques.where((t) {
      final status = (t.paymentStatus ?? 'Open').trim();
      if (_statusFilter == 'Open' && status.toLowerCase() == 'closed') return false;
      if (_statusFilter == 'Closed' && status.toLowerCase() != 'closed') return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final party = (t.partyName ?? '').toLowerCase();
        final ref = (t.referenceNumber ?? '').toLowerCase();
        final num = (t.transactionNumber ?? '').toLowerCase();
        final remarks = (t.remarks ?? '').toLowerCase();
        return party.contains(q) || ref.contains(q) || num.contains(q) || remarks.contains(q);
      }
      return true;
    }).toList();

    // Sort Logic
    filtered.sort((a, b) {
      if (_sortBy == 'Newest First') {
        final dA = a.transactionDate ?? a.createdAt;
        final dB = b.transactionDate ?? b.createdAt;
        return dB.compareTo(dA);
      } else if (_sortBy == 'Oldest First') {
        final dA = a.transactionDate ?? a.createdAt;
        final dB = b.transactionDate ?? b.createdAt;
        return dA.compareTo(dB);
      } else if (_sortBy == 'Highest Amount') {
        return (b.amount ?? 0.0).compareTo(a.amount ?? 0.0);
      } else if (_sortBy == 'Lowest Amount') {
        return (a.amount ?? 0.0).compareTo(b.amount ?? 0.0);
      } else if (_sortBy == 'Party Name (A-Z)') {
        return (a.partyName ?? '').compareTo(b.partyName ?? '');
      }
      return 0;
    });

    final openCheques = _allCheques.where((t) => (t.paymentStatus ?? 'Open').toLowerCase() != 'closed').toList();
    final closedCheques = _allCheques.where((t) => (t.paymentStatus ?? 'Open').toLowerCase() == 'closed').toList();

    final totalOpenAmt = openCheques.fold(0.0, (sum, t) => sum + (t.amount ?? 0.0));

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        title: const Text('Cheques & Uncleared Drafts', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Summary Strip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('OPEN CHEQUES TO DEPOSIT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text('${openCheques.length} Cheques Pending', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(currencyFormat.format(totalOpenAmt), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                // Search & Filter Toolbar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 40,
                        child: TextField(
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search party name, cheque #...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ResponsiveFormRow(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: DropdownButtonFormField<String>(
                                value: _statusFilter,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                                decoration: const InputDecoration(
                                  labelText: 'Status Filter',
                                  
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('All Statuses', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Open', child: Text('Open Cheques', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Closed', child: Text('Closed / Deposited', style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _statusFilter = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: DropdownButtonFormField<String>(
                                value: _sortBy,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                                decoration: const InputDecoration(
                                  labelText: 'Sort By',
                                  
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Newest First', child: Text('Newest First', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Oldest First', child: Text('Oldest First', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Highest Amount', child: Text('Highest Amount', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Lowest Amount', child: Text('Lowest Amount', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Party Name (A-Z)', child: Text('Party Name (A-Z)', style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _sortBy = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cheques List
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No cheques found matching filters.'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final c = filtered[index];
                            final isClosed = (c.paymentStatus ?? 'Open').toLowerCase() == 'closed';

                            return NeuCard(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: isClosed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                          child: Icon(
                                            isClosed ? Icons.check_circle_outline_rounded : Icons.assignment_outlined,
                                            color: isClosed ? Colors.green : Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                c.partyName ?? 'Party Name',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Cheque #: ${c.referenceNumber ?? "N/A"} • ${DateFormat('dd-MM-yyyy').format(c.transactionDate ?? c.createdAt)}',
                                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currencyFormat.format(c.amount ?? 0.0),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isClosed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isClosed ? 'CLOSED' : 'OPEN',
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isClosed ? Colors.green : Colors.orange),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (c.remarks != null && c.remarks!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          c.remarks!,
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                    ],
                                    const Divider(height: 16),

                                    // Action Buttons Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (!isClosed) ...[
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.account_balance_rounded, size: 16),
                                            label: const Text('Deposit Cheque', style: TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            onPressed: () => _showDepositDialog(c),
                                          ),
                                        ] else ...[
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.receipt_long_rounded, size: 16),
                                            label: const Text('View Txn', style: TextStyle(fontSize: 12)),
                                            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                            onPressed: () => _viewTransactionDetails(c),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.orange),
                                            label: const Text('Reopen', style: TextStyle(fontSize: 12, color: Colors.orange)),
                                            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                            onPressed: () => _reopenCheque(c),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
