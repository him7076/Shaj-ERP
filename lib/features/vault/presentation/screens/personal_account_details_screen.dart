import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_personal_transaction_dialog.dart';

class PersonalAccountDetailsScreen extends ConsumerStatefulWidget {
  final String accountUuid;
  const PersonalAccountDetailsScreen({Key? key, required this.accountUuid}) : super(key: key);

  @override
  ConsumerState<PersonalAccountDetailsScreen> createState() => _PersonalAccountDetailsScreenState();
}

class _PersonalAccountDetailsScreenState extends ConsumerState<PersonalAccountDetailsScreen> {
  
  Future<void> _editAccount(BuildContext context, BankAccount account) async {
    final tcName = TextEditingController(text: account.accountName);
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tcName,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Account Name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (tcName.text.trim().isEmpty) return;
              account.accountName = tcName.text.trim();
              await ref.read(bankAccountRepositoryProvider).update(account);
              ref.invalidate(bankAccountsListProvider);
              if (context.mounted) {
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Updated')));
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, BankAccount account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete this account? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          )
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(bankAccountRepositoryProvider).delete(account.id);
      ref.invalidate(bankAccountsListProvider);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNeu = ref.watch(themeProvider).themeType == ThemeType.neumorphism;
    final accountsAsync = ref.watch(bankAccountsListProvider);
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return accountsAsync.when(
      data: (accounts) {
        final account = accounts.where((a) => a.uuid == widget.accountUuid).firstOrNull;
        if (account == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Account not found or deleted.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(account.accountName ?? 'Account Details'),
            backgroundColor: Colors.indigo.shade900,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => _editAccount(context, account),
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded),
                onPressed: () => _deleteAccount(context, account),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.indigo.shade900,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('Current Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(account.currentBalance ?? 0),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: (account.currentBalance ?? 0) >= 0 ? Colors.white : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Account Transactions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade50,
                        foregroundColor: Colors.indigo.shade900,
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Entry'),
                      onPressed: () {
                        AddEditPersonalTransactionDialog.show(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: transactionsAsync.when(
                  data: (transactions) {
                    final accTxns = transactions.where((t) => 
                      t.partyUuid == account.uuid || t.targetPartyUuid == account.uuid
                    ).toList();

                    if (accTxns.isEmpty) {
                      return const Center(child: Text('No transactions recorded for this account.'));
                    }

                    return ListView.builder(
                      itemCount: accTxns.length,
                      itemBuilder: (context, index) {
                        final txn = accTxns[index];
                        final isIncoming = txn.transactionType == 'Other Income' || 
                                           txn.transactionType == 'Income' || 
                                           txn.transactionType == 'Receipt' ||
                                           (txn.transactionType == 'Transfer' && txn.targetPartyUuid == account.uuid);
                        
                        return NeuCard(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isIncoming ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              child: Icon(
                                isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isIncoming ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(txn.remarks?.isNotEmpty == true ? txn.remarks! : (txn.transactionType ?? 'Entry')),
                            subtitle: Text(
                              txn.transactionDate != null ? DateFormat('dd MMM yyyy').format(txn.transactionDate!) : '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              '${isIncoming ? '+' : '-'}₹${(txn.amount ?? 0).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isIncoming ? Colors.green : Colors.red,
                              ),
                            ),
                            onTap: () {
                              AddEditPersonalTransactionDialog.show(context, transaction: txn);
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading transactions: $e')),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
