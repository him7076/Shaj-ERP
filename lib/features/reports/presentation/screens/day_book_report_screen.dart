import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';

class DayBookReportScreen extends ConsumerStatefulWidget {
  const DayBookReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DayBookReportScreen> createState() => _DayBookReportScreenState();
}

class _DayBookReportScreenState extends ConsumerState<DayBookReportScreen> {
  DateTime _selectedDate = DateTime.now();

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(filteredTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day Book Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            tooltip: 'Select Date',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Date Bar & Summary
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.event_note_rounded, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Journal Date: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Showing all recorded Debit & Credit transactions for this date',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.edit_calendar, size: 16),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),
          ),

          // Day Book Entries List
          Expanded(
            child: transactionsAsync.when(
              data: (allTxns) {
                // Filter transactions on selected date
                final dayTxns = allTxns.where((t) {
                  if (t.transactionDate == null) return false;
                  return t.transactionDate!.year == _selectedDate.year &&
                      t.transactionDate!.month == _selectedDate.month &&
                      t.transactionDate!.day == _selectedDate.day;
                }).toList();

                double totalDebit = 0.0;  // Cash / Money In
                double totalCredit = 0.0; // Cash / Money Out

                for (var t in dayTxns) {
                  final amt = t.amount ?? 0.0;
                  final type = t.transactionType;
                  if (type == 'Receipt' || type == 'Sales' || type == 'Other Income') {
                    totalDebit += amt;
                  } else if (type == 'Payment' || type == 'Purchase' || type == 'Expense') {
                    totalCredit += amt;
                  }
                }

                if (dayTxns.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No transactions recorded on this date.'),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Summary Totals
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Inflow (Debit)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                  const SizedBox(height: 4),
                                  Text(currencyFormat.format(totalDebit), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Outflow (Credit)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                                  const SizedBox(height: 4),
                                  Text(currencyFormat.format(totalCredit), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: dayTxns.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final txn = dayTxns[index];
                          final isDebit = txn.transactionType == 'Receipt' || txn.transactionType == 'Sales' || txn.transactionType == 'Other Income';
                          final amt = txn.amount ?? 0.0;

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: (isDebit ? Colors.green : Colors.red).withOpacity(0.15),
                                child: Icon(
                                  isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isDebit ? Colors.green : Colors.red,
                                  size: 18,
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    txn.partyName ?? 'General Transaction',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    currencyFormat.format(amt),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDebit ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${txn.transactionType ?? ""} #${txn.transactionNumber ?? ""} | Mode: ${txn.paymentMode ?? "Cash"}',
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
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
              error: (err, _) => Center(child: Text('Error loading Day Book: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
