import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/domain/models/report_models.dart';

class OutstandingReportScreen extends ConsumerWidget {
  const OutstandingReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reportAsync = ref.watch(outstandingReportProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Outstanding Balances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(outstandingReportProvider),
          ),
        ],
      ),
      body: reportAsync.when(
        data: (summary) {
          if (summary.entries.isEmpty) {
            return const Center(child: Text('All customer accounts are fully paid. No outstanding balances.'));
          }

          return Column(
            children: [
              // Summary KPIs Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overdue Accounts: ${summary.overdueCount}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                        Text('Limit Exceeded: ${summary.limitExceededCount}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total Outstanding Receivable', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                        Text(
                          currencyFormat.format(summary.totalOutstanding),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Ledger Lists
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: summary.entries.length,
                  itemBuilder: (context, index) {
                    final entry = summary.entries[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: entry.isOverdue
                              ? Colors.red[300]!.withOpacity(0.5)
                              : theme.colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.partyName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  currencyFormat.format(entry.outstandingAmount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: entry.isOverdue ? Colors.red[700] : theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            Row(
                              children: [
                                Icon(Icons.phone_rounded, size: 14, color: theme.colorScheme.outline),
                                const SizedBox(width: 4),
                                Text(
                                  entry.mobileNumber,
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                ),
                                const Spacer(),
                                Text(
                                  'Limit: ${currencyFormat.format(entry.creditLimit)}',
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Badges & Actions row
                            Row(
                              children: [
                                if (entry.isOverdue) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50]!,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Overdue by ${entry.dueDays} days',
                                      style: TextStyle(fontSize: 10, color: Colors.red[700], fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (entry.isLimitExceeded) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50]!,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Limit Exceeded',
                                      style: TextStyle(fontSize: 10, color: Colors.orange[700], fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                // Actions
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: theme.colorScheme.secondaryContainer,
                                  child: IconButton(
                                    icon: const Icon(Icons.call_rounded, size: 16),
                                    color: theme.colorScheme.onSecondaryContainer,
                                    onPressed: () {
                                      // Call trigger placeholder (uses url_launcher in production)
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Dialing ${entry.mobileNumber}...')),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.green[50],
                                  child: IconButton(
                                    icon: const Icon(Icons.message_rounded, size: 16),
                                    color: Colors.green[700],
                                    onPressed: () {
                                      // WhatsApp trigger placeholder
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Opening WhatsApp chat with ${entry.partyName}...')),
                                      );
                                    },
                                  ),
                                ),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading outstandings: $err')),
      ),
    );
  }
}
