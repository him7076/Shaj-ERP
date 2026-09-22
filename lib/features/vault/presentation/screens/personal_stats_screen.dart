import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/features/vault/presentation/providers/vault_provider.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:go_router/go_router.dart';

class PersonalStatsScreen extends ConsumerWidget {
  const PersonalStatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(transactionTotalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Vault Stats'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.business_rounded),
            tooltip: 'Switch to Business Vault',
            onPressed: () {
              ref.read(vaultModeProvider.notifier).setMode(VaultMode.business);
              context.go('/dashboard');
            },
          ),
        ],
      ),
      body: totalsAsync.when(
        data: (totals) {
          final balance = totals.totalIn - totals.totalOut;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCard(
                  context,
                  title: 'Net Balance',
                  amount: balance,
                  icon: Icons.account_balance_wallet,
                  color: balance >= 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: 'Total Income',
                        amount: totals.totalIn,
                        icon: Icons.arrow_downward_rounded,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: 'Total Expense',
                        amount: totals.totalOut,
                        icon: Icons.arrow_upward_rounded,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildRecentTransactions(ref),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading stats: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open add transaction dialog with personal vault context
          // Since we switch VaultMode globally, the global Add Transaction Dialog will automatically inherit it
          // Wait, there is no generic dialog route. We must use the custom dialog.
          // But I can just route to transactions which handles this.
          context.push('/transactions');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
        backgroundColor: Colors.indigo.shade900,
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {required String title, required double amount, required IconData icon, required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(WidgetRef ref) {
    final recentAsync = ref.watch(recentTransactionsProvider);
    
    return recentAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No recent entries.'),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final txn = transactions[index];
            final isCredit = txn.transactionType == 'Receipt' || txn.transactionType == 'Other Income';
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  child: Icon(
                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(txn.remarks?.isNotEmpty == true ? txn.remarks! : (txn.transactionType ?? 'Entry')),
                subtitle: Text(txn.transactionDate != null ? txn.transactionDate!.toString().split(' ')[0] : ''),
                trailing: Text(
                  '${isCredit ? '+' : '-'}₹${(txn.amount ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading transactions: $e')),
    );
  }
}
