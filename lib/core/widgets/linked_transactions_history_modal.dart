import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';

class LinkedTransactionItem {
  final Transaction transaction;
  final double allocatedAmount;

  LinkedTransactionItem({
    required this.transaction,
    required this.allocatedAmount,
  });
}

class LinkedTransactionsHistoryModal extends StatefulWidget {
  final String billUuid;
  final String? billNumber;

  const LinkedTransactionsHistoryModal({
    Key? key,
    required this.billUuid,
    this.billNumber,
  }) : super(key: key);

  static Future<List<LinkedTransactionItem>> fetchLinkedTransactions(Isar isar, String billUuid, [String? billNumber]) async {
    if (billUuid.isEmpty) return [];

    final txns = await isar.transactions
        .filter()
        .isDeletedEqualTo(false)
        .findAll();

    final List<LinkedTransactionItem> results = [];

    for (var t in txns) {
      if (t.paymentStatus == 'Cancelled') continue;
      if (t.linkedBillUuid == null || t.linkedBillUuid!.trim().isEmpty) continue;
      final rawLink = t.linkedBillUuid!.trim();

      double allocAmt = 0.0;
      bool matches = false;

      if (rawLink.startsWith('{')) {
        try {
          final Map<String, dynamic> map = json.decode(rawLink);
          if (map.containsKey(billUuid)) {
            matches = true;
            allocAmt = (map[billUuid] as num).toDouble();
          } else if (billNumber != null && billNumber.isNotEmpty && map.containsKey(billNumber)) {
            matches = true;
            allocAmt = (map[billNumber] as num).toDouble();
          }
        } catch (_) {}
      } else {
        if (rawLink == billUuid || (billNumber != null && billNumber.isNotEmpty && rawLink == billNumber)) {
          matches = true;
          allocAmt = t.amount ?? 0.0;
        }
      }

      if (matches) {
        results.add(LinkedTransactionItem(transaction: t, allocatedAmount: allocAmt));
      }
    }

    results.sort((a, b) {
      final aDate = a.transaction.transactionDate ?? DateTime(2000);
      final bDate = b.transaction.transactionDate ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return results;
  }

  static void show(BuildContext context, Isar isar, String billUuid, {String? billNumber}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => LinkedTransactionsHistoryModal(billUuid: billUuid, billNumber: billNumber),
    );
  }

  @override
  State<LinkedTransactionsHistoryModal> createState() => _LinkedTransactionsHistoryModalState();
}

class _LinkedTransactionsHistoryModalState extends State<LinkedTransactionsHistoryModal> {
  List<LinkedTransactionItem> _linkedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final isar = DatabaseService().isar;
    final items = await LinkedTransactionsHistoryModal.fetchLinkedTransactions(isar, widget.billUuid, widget.billNumber);
    if (mounted) {
      setState(() {
        _linkedItems = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final totalLinked = _linkedItems.fold(0.0, (sum, item) => sum + item.allocatedAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Linked Transactions History',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          if (widget.billNumber != null && widget.billNumber!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Voucher Number: ${widget.billNumber}',
                style: TextStyle(color: theme.hintColor, fontSize: 13),
              ),
            ),
          const Divider(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_linkedItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('No linked transactions found for this bill.'),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _linkedItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _linkedItems[index];
                  final txn = item.transaction;
                  final totalAmt = txn.amount ?? 0.0;
                  final allocAmt = item.allocatedAmount;
                  final balAmt = totalAmt - allocAmt;
                  final dateStr = txn.transactionDate != null
                      ? DateFormat('dd MMM yyyy').format(txn.transactionDate!)
                      : 'N/A';

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${txn.transactionType ?? "TXN"} - ${txn.transactionNumber ?? txn.referenceNumber ?? "N/A"}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                dateStr,
                                style: TextStyle(color: theme.hintColor, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Amount: ${currencyFormat.format(totalAmt)}',
                                  style: const TextStyle(fontSize: 12)),
                              Text('Linked Amount: ${currencyFormat.format(allocAmt)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Balance Amount: ${currencyFormat.format(balAmt > 0 ? balAmt : 0.0)}',
                              style: TextStyle(fontSize: 12, color: theme.hintColor)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Linked Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(currencyFormat.format(totalLinked), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
