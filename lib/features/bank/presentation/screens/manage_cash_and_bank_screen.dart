import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

      // 1. Calculate Live Cash Balance
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
        final status = (inv.paymentStatus ?? '').trim().toLowerCase();
        final paid = inv.paidAmount ?? inv.grandTotal ?? 0.0;
        if (status == 'paid' || status == 'cash' || status.contains('cash')) {
          cashInflows += paid;
        }
      }

      for (var pur in purchases) {
        final status = (pur.paymentStatus ?? '').trim().toLowerCase();
        final paid = pur.paidAmount ?? pur.grandTotal ?? 0.0;
        if (status == 'paid' || status == 'cash' || status.contains('cash')) {
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
      appBar: AppBar(
        title: const Text('Manage Cash & Bank Accounts', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditAccountDialog(),
        icon: const Icon(Icons.account_balance_wallet_outlined),
        label: const Text('Add Bank Account'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Balance Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E88E5).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Net Liquid Assets', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                              child: Text('${_accounts.length + 1} Active Accounts', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(_totalLiquidBalance),
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text('Tap any account card below to view transaction history, statements & filters.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('ACCOUNTS DIRECTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 12),

                  // 1. System Cash in Hand Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onTap: () => _openAccountTransactions(accountName: 'Cash in Hand', isCash: true),
                      leading: const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.payments_rounded, color: Color(0xFF2E7D32), size: 28),
                      ),
                      title: Row(
                        children: [
                          const Expanded(child: Text('Cash in Hand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          Text(
                            currencyFormat.format(_cashBalance),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _cashBalance >= 0 ? const Color(0xFF2E7D32) : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      subtitle: const Text('Default cash register account for daily store transactions'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Cheques & Uncleared Drafts Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChequeManagementScreen(),
                          ),
                        ).then((_) => _loadAccounts());
                      },
                      leading: const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFFFFF3E0),
                        child: Icon(Icons.assignment_outlined, color: Color(0xFFE65100), size: 28),
                      ),
                      title: const Text('Cheques & Uncleared Drafts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: const Text('Track open cheques, deposit to bank/cash, & view closed receipts'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Bank Accounts List
                  if (_accounts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('No custom bank accounts added yet', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Click "+ Add Bank Account" below to manage HDFC, SBI, ICICI accounts.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final acc = _accounts[index];
                        final balance = acc.currentBalance ?? acc.openingBalance ?? 0.0;

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            onTap: () => _openAccountTransactions(accountName: acc.accountName ?? 'Bank Account', bankUuid: acc.uuid),
                            leading: const CircleAvatar(
                              radius: 26,
                              backgroundColor: Color(0xFFE3F2FD),
                              child: Icon(Icons.account_balance_rounded, color: Color(0xFF1976D2), size: 28),
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text(acc.accountName ?? 'Bank Account', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                Text(currencyFormat.format(balance), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E7D32))),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${acc.bankName ?? "Bank"} • A/C: ${acc.accountNumber ?? "N/A"} • IFSC: ${acc.ifscCode ?? "N/A"}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ),
                            trailing: Row(
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
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  // --- Add/Edit Account Dialog ---
  Future<void> _showAddEditAccountDialog({BankAccount? existingAccount}) async {
    final isEdit = existingAccount != null;
    final nameCtrl = TextEditingController(text: existingAccount?.accountName);
    final bankCtrl = TextEditingController(text: existingAccount?.bankName);
    final numCtrl = TextEditingController(text: existingAccount?.accountNumber);
    final ifscCtrl = TextEditingController(text: existingAccount?.ifscCode);
    final branchCtrl = TextEditingController(text: existingAccount?.branchName);
    final balCtrl = TextEditingController(text: (existingAccount?.openingBalance ?? 0.0).toString());

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEdit ? 'Edit Bank Account' : 'Add New Bank Account', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Account Display Name *', hintText: 'e.g. HDFC Primary A/C', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bankCtrl,
                  decoration: const InputDecoration(labelText: 'Bank Name', hintText: 'e.g. HDFC Bank, State Bank of India', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: numCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ifscCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'IFSC Code', hintText: 'e.g. HDFC0001234', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: branchCtrl,
                  decoration: const InputDecoration(labelText: 'Branch Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: balCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Opening Balance (₹)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final isar = ref.read(databaseServiceProvider).isar;
                final openBal = double.tryParse(balCtrl.text.trim()) ?? 0.0;

                final acc = existingAccount ?? BankAccount();
                acc.accountName = nameCtrl.text.trim();
                acc.bankName = bankCtrl.text.trim();
                acc.accountNumber = numCtrl.text.trim();
                acc.ifscCode = ifscCtrl.text.trim().toUpperCase();
                acc.branchName = branchCtrl.text.trim();
                acc.openingBalance = openBal;
                acc.uuid ??= const Uuid().v4();
                if (!isEdit) {
                  acc.currentBalance = openBal;
                }
                acc.updatedAt = DateTime.now();
                acc.isSynced = false;

                await isar.writeTxn(() async {
                  await isar.bankAccounts.put(acc);
                  await isar.syncQueues.put(SyncQueue()
                    ..uuid = const Uuid().v4()
                    ..entityType = 'BankAccount'
                    ..entityId = acc.id
                    ..entityUuid = acc.uuid
                    ..operation = isEdit ? 'Update' : 'Insert'
                    ..createdAt = DateTime.now()
                    ..updatedAt = DateTime.now());
                });

                try {
                  ref.read(syncServiceProvider).syncPendingChangesQuietly();
                } catch (_) {}

                ref.invalidate(bankAccountsListProvider);

                Navigator.pop(ctx);
                await _loadAccounts();
              }
            },
            child: Text(isEdit ? 'Update Account' : 'Save Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BankAccount acc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Bank Account'),
        content: Text('Are you sure you want to delete account "${acc.accountName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final isar = ref.read(databaseServiceProvider).isar;
      await isar.writeTxn(() async {
        acc.isDeleted = true;
        acc.isSynced = false;
        acc.updatedAt = DateTime.now();
        await isar.bankAccounts.put(acc);
        await isar.syncQueues.put(SyncQueue()
          ..uuid = const Uuid().v4()
          ..entityType = 'BankAccount'
          ..entityId = acc.id
          ..entityUuid = acc.uuid
          ..operation = 'Delete'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now());
      });

      try {
        ref.read(syncServiceProvider).syncPendingChangesQuietly();
      } catch (_) {}

      ref.invalidate(bankAccountsListProvider);
      await _loadAccounts();
    }
  }

  // --- Open Account Transactions Screen ---
  void _openAccountTransactions({required String accountName, String? bankUuid, bool isCash = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AccountTransactionsDetailScreen(
          accountName: accountName,
          bankUuid: bankUuid,
          isCash: isCash,
        ),
      ),
    );
  }
}

// --- Unified Display Item for Account Transactions ---
class AccountTransactionDisplayItem {
  final String transactionNumber;
  final String partyName;
  final String transactionType;
  final DateTime date;
  final double amount;
  final bool isCredit;
  final String? remarks;

  AccountTransactionDisplayItem({
    required this.transactionNumber,
    required this.partyName,
    required this.transactionType,
    required this.date,
    required this.amount,
    required this.isCredit,
    this.remarks,
  });
}

// --- Account Transactions Detailed View Screen with Filters & Search ---
class AccountTransactionsDetailScreen extends ConsumerStatefulWidget {
  final String accountName;
  final String? bankUuid;
  final bool isCash;

  const AccountTransactionsDetailScreen({
    Key? key,
    required this.accountName,
    this.bankUuid,
    this.isCash = false,
  }) : super(key: key);

  @override
  ConsumerState<AccountTransactionsDetailScreen> createState() => _AccountTransactionsDetailScreenState();
}

class _AccountTransactionsDetailScreenState extends ConsumerState<AccountTransactionsDetailScreen> {
  String _searchQuery = '';
  String _typeFilter = 'All'; // All, Receipt, Payment, Transfer
  String _sortBy = 'Newest First'; // Newest First, Oldest First, Highest Amount

  List<AccountTransactionDisplayItem> _allDisplayItems = [];
  bool _isLoading = false;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final rawTxns = await isar.transactions.filter().isDeletedEqualTo(false).findAll();
      final invoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
      final purchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
      final expenses = await isar.expenses.filter().isDeletedEqualTo(false).findAll();

      final List<AccountTransactionDisplayItem> items = [];

      for (var t in rawTxns) {
        final mode = (t.paymentMode ?? 'cash').trim().toLowerCase();
        bool matches = false;
        if (widget.isCash) {
          matches = mode == 'cash' || mode.contains('cash') || mode.isEmpty;
        } else {
          final accName = widget.accountName.trim().toLowerCase();
          matches = mode == accName || mode.contains(accName) || (accName.contains('bank') && (mode == 'bank' || mode == 'online' || mode == 'upi' || mode == 'cheque'));
        }

        if (matches) {
          final isCredit = t.transactionType == 'Receipt' || t.transactionType == 'Other Income';
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

      if (widget.isCash) {
        for (var inv in invoices) {
          final status = (inv.paymentStatus ?? '').trim().toLowerCase();
          final paid = inv.paidAmount ?? inv.grandTotal ?? 0.0;
          if ((status == 'paid' || status == 'cash' || status.contains('cash')) && paid > 0) {
            items.add(AccountTransactionDisplayItem(
              transactionNumber: inv.invoiceNumber ?? 'INV',
              partyName: inv.partyName ?? 'Customer',
              transactionType: 'Sales (Cash)',
              date: inv.invoiceDate ?? inv.createdAt,
              amount: paid,
              isCredit: true,
              remarks: inv.remarks,
            ));
          }
        }

        for (var pur in purchases) {
          final status = (pur.paymentStatus ?? '').trim().toLowerCase();
          final paid = pur.paidAmount ?? pur.grandTotal ?? 0.0;
          if ((status == 'paid' || status == 'cash' || status.contains('cash')) && paid > 0) {
            items.add(AccountTransactionDisplayItem(
              transactionNumber: pur.purchaseNumber ?? 'PUR',
              partyName: pur.partyName ?? 'Supplier',
              transactionType: 'Purchase (Cash)',
              date: pur.purchaseDate ?? pur.createdAt,
              amount: paid,
              isCredit: false,
              remarks: pur.remarks,
            ));
          }
        }

        for (var exp in expenses) {
          final mode = (exp.paymentMode ?? 'cash').trim().toLowerCase();
          if (mode == 'cash' || mode.contains('cash') || mode.isEmpty) {
            items.add(AccountTransactionDisplayItem(
              transactionNumber: exp.voucherNo ?? 'EXP',
              partyName: exp.partyName ?? exp.category ?? 'Expense',
              transactionType: 'Expense (${exp.category ?? "General"})',
              date: exp.expenseDate ?? exp.createdAt,
              amount: exp.amount ?? 0.0,
              isCredit: false,
              remarks: exp.remarks,
            ));
          }
        }
      }

      _allDisplayItems = items;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AccountTransactionDisplayItem> get _filteredTransactions {
    List<AccountTransactionDisplayItem> list = List.from(_allDisplayItems);

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((t) {
        return t.transactionNumber.toLowerCase().contains(q) ||
            t.partyName.toLowerCase().contains(q) ||
            (t.remarks?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Type filter
    if (_typeFilter != 'All') {
      if (_typeFilter == 'Receipt') {
        list = list.where((t) => t.isCredit).toList();
      } else if (_typeFilter == 'Payment') {
        list = list.where((t) => !t.isCredit).toList();
      }
    }

    // Sorting
    if (_sortBy == 'Newest First') {
      list.sort((a, b) => b.date.compareTo(a.date));
    } else if (_sortBy == 'Oldest First') {
      list.sort((a, b) => a.date.compareTo(b.date));
    } else if (_sortBy == 'Highest Amount') {
      list.sort((a, b) => b.amount.compareTo(a.amount));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txns = _filteredTransactions;

    final double totalInflow = txns.where((t) => t.isCredit).fold(0.0, (s, t) => s + t.amount);
    final double totalOutflow = txns.where((t) => !t.isCredit).fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountName, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Inflows (+)', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(currencyFormat.format(totalInflow), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    ],
                  ),
                ),
                const VerticalDivider(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Outflows (-)', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(currencyFormat.format(totalOutflow), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search & Filter Controls
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search transaction no, party, remarks...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _typeFilter,
                        decoration: const InputDecoration(labelText: 'Type Filter', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Types')),
                          DropdownMenuItem(value: 'Receipt', child: Text('Receipt / Inflows (+)')),
                          DropdownMenuItem(value: 'Payment', child: Text('Payment / Outflows (-)')),
                        ],
                        onChanged: (v) => setState(() => _typeFilter = v ?? 'All'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: const InputDecoration(labelText: 'Sorting', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: const [
                          DropdownMenuItem(value: 'Newest First', child: Text('Newest First')),
                          DropdownMenuItem(value: 'Oldest First', child: Text('Oldest First')),
                          DropdownMenuItem(value: 'Highest Amount', child: Text('Highest Amount')),
                        ],
                        onChanged: (v) => setState(() => _sortBy = v ?? 'Newest First'),
                      ),
                    ),
                  ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: txns.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final t = txns[index];
                          final isCredit = t.isCredit;

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? Colors.green : Colors.red),
                              ),
                              title: Text('#${t.transactionNumber} - ${t.partyName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Type: ${t.transactionType} • ${DateFormat('dd-MM-yyyy').format(t.date)}'),
                              trailing: Text(
                                '${isCredit ? "+" : "-"}${currencyFormat.format(t.amount)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isCredit ? Colors.green : Colors.red),
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
                        border: OutlineInputBorder(),
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
                        border: OutlineInputBorder(),
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
      appBar: AppBar(
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
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: DropdownButtonFormField<String>(
                                value: _statusFilter,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                                decoration: const InputDecoration(
                                  labelText: 'Status Filter',
                                  border: OutlineInputBorder(),
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
                                  border: OutlineInputBorder(),
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

                            return Card(
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
