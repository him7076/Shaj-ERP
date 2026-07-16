import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_transaction_dialog.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_credit_note_screen.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_debit_note_screen.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final String? lockedType;
  final bool createImmediately;
  const TransactionsScreen({Key? key, this.lockedType, this.createImmediately = false}) : super(key: key);

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.lockedType != null) {
        ref.read(transactionSearchFilterProvider.notifier).state =
            ref.read(transactionSearchFilterProvider).copyWith(transactionType: widget.lockedType);
      }
      if (widget.createImmediately) {
        AddEditTransactionDialog.show(context, initialType: widget.lockedType);
      }
    });
  }

  @override
  void didUpdateWidget(covariant TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lockedType != oldWidget.lockedType && widget.lockedType != null) {
      ref.read(transactionSearchFilterProvider.notifier).state =
          ref.read(transactionSearchFilterProvider).copyWith(transactionType: widget.lockedType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(transactionSearchFilterProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(widget.lockedType == 'Receipt'
            ? 'Receipts (Payment In)'
            : widget.lockedType == 'Payment'
                ? 'Payments (Payment Out)'
                : widget.lockedType == 'Credit Note'
                    ? 'Credit Notes'
                    : widget.lockedType == 'Debit Note'
                        ? 'Debit Notes'
                        : widget.lockedType == 'Transfer'
                            ? 'Party Transfers'
                            : widget.lockedType == 'Other Income'
                                ? 'Other Income'
                                : 'Payments & Transactions'),
        actions: [
          if (widget.lockedType != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (widget.lockedType == 'Credit Note') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddEditCreditNoteScreen()),
                    ).then((_) => ref.invalidate(filteredTransactionsProvider));
                  } else if (widget.lockedType == 'Debit Note') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddEditDebitNoteScreen()),
                    ).then((_) => ref.invalidate(filteredTransactionsProvider));
                  } else {
                    AddEditTransactionDialog.show(context, initialType: widget.lockedType);
                  }
                },
                icon: Icon(
                  widget.lockedType == 'Receipt'
                      ? Icons.arrow_downward_rounded
                      : widget.lockedType == 'Payment'
                          ? Icons.arrow_upward_rounded
                          : widget.lockedType == 'Credit Note'
                              ? Icons.assignment_return_rounded
                              : widget.lockedType == 'Debit Note'
                                  ? Icons.assignment_returned_rounded
                                  : widget.lockedType == 'Transfer'
                                      ? Icons.swap_horiz_rounded
                                      : Icons.monetization_on_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  widget.lockedType == 'Receipt'
                      ? 'Record Receipt'
                      : widget.lockedType == 'Payment'
                          ? 'Record Payment'
                          : widget.lockedType == 'Credit Note'
                              ? 'New Credit Note'
                              : widget.lockedType == 'Debit Note'
                                  ? 'New Debit Note'
                                  : widget.lockedType == 'Transfer'
                                      ? 'New Transfer'
                                      : 'Record Income',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              tooltip: 'Record new entry',
              onSelected: (type) {
                AddEditTransactionDialog.show(context, initialType: type);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Record Transaction',
                      style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'Receipt',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward_rounded, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      const Text('Receipt (Payment In)'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'Payment',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      const Text('Payment (Payment Out)'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'Credit Note',
                  child: Row(
                    children: [
                      Icon(Icons.assignment_return_rounded, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Text('Credit Note (Sales Return)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'Debit Note',
                  child: Row(
                    children: [
                      Icon(Icons.assignment_returned_rounded, color: Colors.orange),
                      const SizedBox(width: 12),
                      Text('Debit Note (Purchase Return)'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'Expense',
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Text('Other Expense'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'Transfer',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, color: Colors.teal),
                      const SizedBox(width: 12),
                      Text('Party to Party Transfer'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'Other Income',
                  child: Row(
                    children: [
                      Icon(Icons.monetization_on_rounded, color: Colors.blue),
                      const SizedBox(width: 12),
                      Text('Other Income'),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Metrics Row
          transactionsAsync.when(
            data: (list) {
              if (widget.lockedType != null) {
                final totalAmount = list.fold(0.0, (sum, t) => sum + (t.amount ?? 0.0));
                Color typeColor = Colors.grey;
                IconData typeIcon = Icons.info_outline;
                String metricTitle = '';

                if (widget.lockedType == 'Receipt') {
                  typeColor = Colors.green;
                  typeIcon = Icons.arrow_downward;
                  metricTitle = 'Total Receipts Received';
                } else if (widget.lockedType == 'Payment') {
                  typeColor = Colors.red;
                  typeIcon = Icons.arrow_upward;
                  metricTitle = 'Total Payments Paid';
                } else if (widget.lockedType == 'Credit Note') {
                  typeColor = Colors.indigo;
                  typeIcon = Icons.assignment_return_rounded;
                  metricTitle = 'Total Credit Note Amount';
                } else if (widget.lockedType == 'Debit Note') {
                  typeColor = Colors.orange;
                  typeIcon = Icons.assignment_returned_rounded;
                  metricTitle = 'Total Debit Note Amount';
                } else if (widget.lockedType == 'Transfer') {
                  typeColor = Colors.teal;
                  typeIcon = Icons.swap_horiz;
                  metricTitle = 'Total Transferred Amount';
                } else if (widget.lockedType == 'Other Income') {
                  typeColor = Colors.blue;
                  typeIcon = Icons.monetization_on;
                  metricTitle = 'Total Other Income';
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildMetricCard(
                    theme: theme,
                    title: metricTitle,
                    value: currencyFormat.format(totalAmount),
                    icon: typeIcon,
                    color: typeColor,
                  ),
                );
              }

              double totalIn = 0.0;
              double totalOut = 0.0;

              for (var t in list) {
                final amt = t.amount ?? 0.0;
                final type = t.transactionType;
                if (type == 'Receipt' || type == 'Sales' || type == 'Other Income') {
                  totalIn += amt;
                } else if (type == 'Payment' || type == 'Purchase' || type == 'Expense') {
                  totalOut += amt;
                }
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    return Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      children: [
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: _buildMetricCard(
                            theme: theme,
                            title: 'Total Inflow (Receipts & Sales)',
                            value: currencyFormat.format(totalIn),
                            icon: Icons.arrow_downward,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16, height: 16),
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: _buildMetricCard(
                            theme: theme,
                            title: 'Total Outflow (Payments & Expenses)',
                            value: currencyFormat.format(totalOut),
                            icon: Icons.arrow_upward,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16, height: 16),
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: _buildMetricCard(
                            theme: theme,
                            title: 'Net Cash Flow',
                            value: currencyFormat.format(totalIn - totalOut),
                            icon: Icons.swap_vert,
                            color: (totalIn - totalOut) >= 0 ? Colors.blue : Colors.orange,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Horizontal Action Buttons Row (Only show if not locked to specific type)
          if (widget.lockedType == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickActionChip(
                      context: context,
                      label: 'Receipt (Payment In)',
                      icon: Icons.arrow_downward_rounded,
                      color: Colors.green,
                      type: 'Receipt',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionChip(
                      context: context,
                      label: 'Payment (Payment Out)',
                      icon: Icons.arrow_upward_rounded,
                      color: Colors.red,
                      type: 'Payment',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionChip(
                      context: context,
                      label: 'Credit Note',
                      icon: Icons.assignment_return_rounded,
                      color: Colors.indigo,
                      type: 'Credit Note',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionChip(
                      context: context,
                      label: 'Debit Note',
                      icon: Icons.assignment_returned_rounded,
                      color: Colors.orange,
                      type: 'Debit Note',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionChip(
                      context: context,
                      label: 'Other Expense',
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.redAccent,
                      type: 'Expense',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionChip(
                      context: context,
                      label: 'Party Transfer',
                      icon: Icons.swap_horiz_rounded,
                      color: Colors.teal,
                      type: 'Transfer',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionChip(
                      context: context,
                      label: 'Other Income',
                      icon: Icons.monetization_on_rounded,
                      color: Colors.blue,
                      type: 'Other Income',
                    ),
                  ],
                ),
              ),
            ),

          // Filters Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: isMobile
                    ? Column(
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search transaction no, party, remarks...',
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              ref.read(transactionSearchFilterProvider.notifier).state =
                                  filter.copyWith(query: val);
                            },
                          ),
                          if (widget.lockedType == null) ...[
                            const Divider(height: 1),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: filter.transactionType,
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('All Types')),
                                  DropdownMenuItem(value: 'Receipt', child: Text('Receipt (Payment In)')),
                                  DropdownMenuItem(value: 'Payment', child: Text('Payment (Payment Out)')),
                                  DropdownMenuItem(value: 'Sales', child: Text('Sales Invoice')),
                                  DropdownMenuItem(value: 'Purchase', child: Text('Purchase Bill')),
                                  DropdownMenuItem(value: 'Credit Note', child: Text('Credit Note')),
                                  DropdownMenuItem(value: 'Debit Note', child: Text('Debit Note')),
                                  DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                                  DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                                  DropdownMenuItem(value: 'Other Income', child: Text('Other Income')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    ref.read(transactionSearchFilterProvider.notifier).state =
                                        filter.copyWith(transactionType: val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      )
                    : Row(
                        children: [
                          // Search Query
                          Expanded(
                            flex: 3,
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search transaction no, party, remarks...',
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                ref.read(transactionSearchFilterProvider.notifier).state =
                                    filter.copyWith(query: val);
                              },
                            ),
                          ),
                          if (widget.lockedType == null) ...[
                            const VerticalDivider(),
                            
                            // Transaction Type filter
                            Expanded(
                              flex: 2,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: filter.transactionType,
                                  items: const [
                                    DropdownMenuItem(value: 'All', child: Text('All Types')),
                                    DropdownMenuItem(value: 'Receipt', child: Text('Receipt (Payment In)')),
                                    DropdownMenuItem(value: 'Payment', child: Text('Payment (Payment Out)')),
                                    DropdownMenuItem(value: 'Sales', child: Text('Sales Invoice')),
                                    DropdownMenuItem(value: 'Purchase', child: Text('Purchase Bill')),
                                    DropdownMenuItem(value: 'Credit Note', child: Text('Credit Note')),
                                    DropdownMenuItem(value: 'Debit Note', child: Text('Debit Note')),
                                    DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                                    DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                                    DropdownMenuItem(value: 'Other Income', child: Text('Other Income')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(transactionSearchFilterProvider.notifier).state =
                                          filter.copyWith(transactionType: val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Data list
          Expanded(
            child: transactionsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap "Record Transaction" to add your first payment or receipt entry.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final txn = list[index];
                    final isIncoming = txn.transactionType == 'Receipt' ||
                        txn.transactionType == 'Sales' ||
                        txn.transactionType == 'Other Income';
                    final isOutgoing = txn.transactionType == 'Payment' ||
                        txn.transactionType == 'Purchase' ||
                        txn.transactionType == 'Expense';

                    Color badgeColor = Colors.grey;
                    if (isIncoming) badgeColor = Colors.green;
                    if (isOutgoing) badgeColor = Colors.red;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 6,
                                color: badgeColor,
                              ),
                              Expanded(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  leading: CircleAvatar(
                                    backgroundColor: badgeColor.withOpacity(0.08),
                                    child: Icon(
                                      isIncoming ? Icons.arrow_downward : (isOutgoing ? Icons.arrow_upward : Icons.swap_horiz),
                                      color: badgeColor,
                                      size: 20,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        txn.transactionNumber ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          txn.transactionType ?? '',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: badgeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      Text(
                                        txn.partyName ?? (txn.transactionType == 'Expense' ? 'General Expense' : 'Other Income Ledger'),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      if (txn.remarks != null && txn.remarks!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(txn.remarks!, style: theme.textTheme.bodySmall),
                                      ],
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            'Date: ${txn.transactionDate != null ? DateFormat('dd MMM yyyy').format(txn.transactionDate!) : "N/A"}',
                                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Mode: ${txn.paymentMode ?? "Cash"}',
                                              style: TextStyle(
                                                color: theme.colorScheme.onSurface,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currencyFormat.format(txn.amount ?? 0.0),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: badgeColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      PopupMenuButton<String>(
                                        onSelected: (action) async {
                                          if (action == 'edit') {
                                            AddEditTransactionDialog.show(context, transaction: txn);
                                          } else if (action == 'delete') {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Transaction'),
                                                content: const Text('Are you sure you want to delete this transaction? This will revert any changes made to the outstanding balances and invoice payments.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await ref.read(transactionRepositoryProvider).deleteTransaction(txn);
                                              ref.invalidate(filteredTransactionsProvider);
                                              ref.invalidate(dashboardAnalyticsProvider);
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: ListTile(
                                              leading: Icon(Icons.edit, size: 20),
                                              title: Text('Edit'),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: ListTile(
                                              leading: Icon(Icons.delete, color: Colors.red, size: 20),
                                              title: Text('Delete', style: TextStyle(color: Colors.red)),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading transactions: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (widget.lockedType == 'Credit Note') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddEditCreditNoteScreen()),
            ).then((_) => ref.invalidate(filteredTransactionsProvider));
          } else if (widget.lockedType == 'Debit Note') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddEditDebitNoteScreen()),
            ).then((_) => ref.invalidate(filteredTransactionsProvider));
          } else {
            AddEditTransactionDialog.show(context, initialType: widget.lockedType);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(widget.lockedType == 'Receipt'
            ? 'Record Receipt'
            : widget.lockedType == 'Payment'
                ? 'Record Payment'
                : widget.lockedType == 'Credit Note'
                    ? 'New Credit Note'
                    : widget.lockedType == 'Debit Note'
                        ? 'New Debit Note'
                        : widget.lockedType == 'Transfer'
                            ? 'New Transfer'
                            : widget.lockedType == 'Other Income'
                                ? 'Record Income'
                                : 'New Entry'),
      ),
    );
  }

  Widget _buildMetricCard({
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [theme.colorScheme.surface, color.withOpacity(0.01)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onBackground,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      onPressed: () => AddEditTransactionDialog.show(context, initialType: type),
      backgroundColor: color.withOpacity(0.06),
      side: BorderSide(color: color.withOpacity(0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
