import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/features/vault/presentation/providers/vault_provider.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(Icons.business_rounded, size: 18),
              label: const Text('Switch to Business', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () {
                ref.read(vaultModeProvider.notifier).setMode(VaultMode.business);
                context.go('/dashboard');
              },
            ),
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
                _buildPieChartsSection(ref),
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

  Widget _buildPieChartsSection(WidgetRef ref) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) return const SizedBox.shrink();

        final incomeData = <String, double>{};
        final expenseData = <String, double>{};

        for (final txn in transactions) {
          final amt = txn.amount ?? 0.0;
          if (amt == 0) continue;
          
          final type = txn.transactionType;
          final cat = txn.categoryName?.isNotEmpty == true ? txn.categoryName! : 'Other';

          if (type == 'Income' || type == 'Other Income' || type == 'Receipt') {
            incomeData[cat] = (incomeData[cat] ?? 0.0) + amt;
          } else if (type == 'Expense' || type == 'Payment') {
            expenseData[cat] = (expenseData[cat] ?? 0.0) + amt;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (expenseData.isNotEmpty) ...[
              const Text(
                'Expenses by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: _buildPieChart(expenseData, Colors.red),
              ),
              const SizedBox(height: 32),
            ],
            if (incomeData.isNotEmpty) ...[
              const Text(
                'Income by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: _buildPieChart(incomeData, Colors.green),
              ),
              const SizedBox(height: 16),
            ]
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildPieChart(Map<String, double> data, MaterialColor baseColor) {
    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sortedEntries.isEmpty) return const SizedBox();

    final List<Color> colors = [
      baseColor.shade400,
      baseColor.shade600,
      baseColor.shade300,
      baseColor.shade700,
      baseColor.shade200,
      baseColor.shade800,
    ];

    double total = data.values.fold(0, (sum, val) => sum + val);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sortedEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final val = entry.value.value;
                final pct = (val / total * 100);
                return PieChartSectionData(
                  color: colors[index % colors.length],
                  value: val,
                  title: '${pct.toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedEntries.length,
            itemBuilder: (context, index) {
              final cat = sortedEntries[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, color: colors[index % colors.length]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.key,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
