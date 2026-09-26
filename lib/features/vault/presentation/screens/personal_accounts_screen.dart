import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';

class PersonalAccountsScreen extends ConsumerWidget {
  const PersonalAccountsScreen({Key? key}) : super(key: key);

  Future<void> _addAccount(BuildContext context, WidgetRef ref) async {
    final tcName = TextEditingController();
    final tcBal = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Personal Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tcName,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Account Name (e.g. Wallet, HDFC)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tcBal,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Opening Balance (₹)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (tcName.text.trim().isEmpty) return;
              final newAcc = BankAccount()
                ..uuid = const Uuid().v4()
                ..accountName = tcName.text.trim()
                ..openingBalance = double.tryParse(tcBal.text.trim()) ?? 0.0
                ..currentBalance = double.tryParse(tcBal.text.trim()) ?? 0.0
                ..isPersonalVault = true;
              
              await ref.read(bankAccountRepositoryProvider).create(newAcc);
              ref.invalidate(bankAccountsListProvider);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Created!')));
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(bankAccountsListProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Accounts'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addAccount(context, ref),
        backgroundColor: Colors.indigo.shade900,
        child: const Icon(Icons.add),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          final personalAccounts = accounts.where((a) => a.isPersonalVault).toList();
          
          if (personalAccounts.isEmpty) {
            return const Center(
              child: Text(
                'No accounts added yet.\nTap + to create a cash or bank account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: personalAccounts.length,
            itemBuilder: (context, index) {
              final acc = personalAccounts[index];
              return NeuCard(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Icon(Icons.account_balance_wallet, color: Colors.indigo.shade900),
                  ),
                  title: Text(acc.accountName ?? 'Unknown Account', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  trailing: Text(
                    currencyFormat.format(acc.currentBalance ?? 0),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: (acc.currentBalance ?? 0) >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  onTap: () {
                    context.push('/personal-account-details/${acc.uuid}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading accounts: $e')),
      ),
    );
  }
}
