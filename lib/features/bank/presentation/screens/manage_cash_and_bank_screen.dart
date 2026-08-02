import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';

class ManageCashAndBankScreen extends ConsumerStatefulWidget {
  const ManageCashAndBankScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManageCashAndBankScreen> createState() => _ManageCashAndBankScreenState();
}

class _ManageCashAndBankScreenState extends ConsumerState<ManageCashAndBankScreen> {
  List<BankAccount> _accounts = [];
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
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalLiquidBalance {
    return _accounts.fold(0.0, (sum, acc) => sum + (acc.currentBalance ?? acc.openingBalance ?? 0.0));
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
                      title: const Text('Cash in Hand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                if (!isEdit) {
                  acc.uuid = DateTime.now().millisecondsSinceEpoch.toString();
                  acc.currentBalance = openBal;
                }
                acc.updatedAt = DateTime.now();

                await isar.writeTxn(() async {
                  await isar.bankAccounts.put(acc);
                });

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
        await isar.bankAccounts.put(acc);
      });
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

  List<Transaction> _allTransactions = [];
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
      _allTransactions = rawTxns;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Transaction> get _filteredTransactions {
    List<Transaction> list = _allTransactions.where((t) {
      if (widget.isCash) {
        return t.paymentMode == 'Cash' || t.paymentMode == null;
      }
      return t.paymentMode?.contains(widget.accountName) == true || t.paymentMode == 'Bank';
    }).toList();

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((t) {
        return (t.transactionNumber?.toLowerCase().contains(q) ?? false) ||
            (t.partyName?.toLowerCase().contains(q) ?? false) ||
            (t.remarks?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Type filter
    if (_typeFilter != 'All') {
      list = list.where((t) => t.transactionType == _typeFilter).toList();
    }

    // Sorting
    if (_sortBy == 'Newest First') {
      list.sort((a, b) => (b.transactionDate ?? DateTime(2000)).compareTo(a.transactionDate ?? DateTime(2000)));
    } else if (_sortBy == 'Oldest First') {
      list.sort((a, b) => (a.transactionDate ?? DateTime(2000)).compareTo(b.transactionDate ?? DateTime(2000)));
    } else if (_sortBy == 'Highest Amount') {
      list.sort((a, b) => (b.amount ?? 0.0).compareTo(a.amount ?? 0.0));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txns = _filteredTransactions;

    final double totalInflow = txns.where((t) => t.transactionType == 'Receipt' || t.transactionType == 'Other Income').fold(0.0, (s, t) => s + (t.amount ?? 0.0));
    final double totalOutflow = txns.where((t) => t.transactionType == 'Payment' || t.transactionType == 'Expense').fold(0.0, (s, t) => s + (t.amount ?? 0.0));

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
                          DropdownMenuItem(value: 'Receipt', child: Text('Receipt (Inflow)')),
                          DropdownMenuItem(value: 'Payment', child: Text('Payment (Outflow)')),
                          DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                          DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
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
                          final isCredit = t.transactionType == 'Receipt' || t.transactionType == 'Other Income';

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
                              title: Text('#${t.transactionNumber} - ${t.partyName ?? "Party"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Type: ${t.transactionType} • ${t.transactionDate != null ? DateFormat('dd-MM-yyyy').format(t.transactionDate!) : "N/A"}'),
                              trailing: Text(
                                '${isCredit ? "+" : "-"}${currencyFormat.format(t.amount ?? 0.0)}',
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
