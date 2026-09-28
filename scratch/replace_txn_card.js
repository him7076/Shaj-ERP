const fs = require('fs');

let c = fs.readFileSync('lib/features/transactions/presentation/screens/transactions_screen.dart', 'utf8');

const startStr = 'final txn = visibleList[index];';
const endStr = 'loading: () => const Center(child: CircularProgressIndicator()),';

const startIdx = c.indexOf(startStr);
const endIdx = c.lastIndexOf('},', c.indexOf(endStr));

if (startIdx !== -1 && endIdx !== -1) {
  const newCode = `final txn = visibleList[index];
                      final isIncoming = txn.transactionType == 'Receipt' ||
                          txn.transactionType == 'Sales' ||
                          txn.transactionType == 'Other Income';
                      final isOutgoing = txn.transactionType == 'Payment' ||
                          txn.transactionType == 'Purchase' ||
                          txn.transactionType == 'Expense';

                      Color badgeColor = Colors.grey;
                      if (isIncoming) badgeColor = Colors.green;
                      if (isOutgoing) badgeColor = Colors.red;
                      if (txn.transactionType == 'Credit Note') badgeColor = Colors.orange;
                      if (txn.transactionType == 'Debit Note') badgeColor = Colors.orange;
                      if (txn.transactionType == 'Party to Party Transfer' || txn.transactionType == 'Party Transfer') badgeColor = Colors.blue;

                      String displayStatus = txn.paymentStatus ??
                          (txn.linkedBillUuid != null && txn.linkedBillUuid!.isNotEmpty ? 'LINKED' : 'CLEARED');
                      String upperStatus = displayStatus.toUpperCase();

                      bool isUsedType = [
                        'Credit Note',
                        'Debit Note',
                        'Payment',
                        'Receipt',
                        'Party to Party Transfer',
                        'Party Transfer'
                      ].contains(txn.transactionType);

                      if (isUsedType) {
                        if (upperStatus == 'PAID' || upperStatus == 'CLEARED') upperStatus = 'USED';
                        if (upperStatus == 'UNPAID' || upperStatus == 'PENDING') upperStatus = 'UNUSED';
                        if (upperStatus == 'PARTIALLY PAID') upperStatus = 'PARTIALLY USED';
                      } else {
                        if (upperStatus == 'USED' || upperStatus == 'CLEARED') upperStatus = 'PAID';
                        if (upperStatus == 'UNUSED' || upperStatus == 'PENDING') upperStatus = 'UNPAID';
                        if (upperStatus == 'PARTIALLY USED') upperStatus = 'PARTIALLY PAID';
                      }

                      Color statusBg = Colors.blue.withOpacity(0.12);
                      Color statusFg = Colors.blue.shade800;

                      if (upperStatus == 'PAID' || upperStatus == 'USED' || upperStatus == 'LINKED') {
                        statusBg = Colors.green.withOpacity(0.15);
                        statusFg = Colors.green.shade800;
                      } else if (upperStatus == 'PARTIALLY PAID' || upperStatus == 'PARTIALLY USED') {
                        statusBg = Colors.orange.withOpacity(0.15);
                        statusFg = Colors.orange.shade900;
                      } else if (upperStatus == 'UNPAID' || upperStatus == 'UNUSED' || upperStatus == 'PENDING') {
                        statusBg = Colors.red.withOpacity(0.15);
                        statusFg = Colors.red.shade800;
                      }

                      return NeuCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 5,
                                  color: badgeColor,
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _openTransaction(context, txn),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  txn.partyName ?? (txn.transactionType == 'Expense' ? 'General Expense' : 'Other Income Ledger'),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                currencyFormat.format(txn.amount ?? 0.0),
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: badgeColor),
                                              ),
                                              const SizedBox(width: 4),
                                              SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: PopupMenuButton<String>(
                                                  padding: EdgeInsets.zero,
                                                  icon: const Icon(Icons.more_vert, size: 20),
                                                  onSelected: (action) async {
                                                    if (action == 'edit') {
                                                      _openTransaction(context, txn);
                                                    } else if (action == 'send_pdf' || action == 'print') {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('To \${action == 'print' ? 'print' : 'send PDF'}, please tap to open the transaction first.')),
                                                      );
                                                    } else if (action == 'link') {
                                                      AddEditTransactionDialog.show(context, transaction: txn);
                                                    } else if (action == 'receive_payment') {
                                                      AddEditTransactionDialog.show(
                                                        context,
                                                        initialType: 'Receipt',
                                                        initialPartyName: txn.partyName,
                                                        initialPartyUuid: txn.partyUuid,
                                                        initialBillUuid: txn.uuid,
                                                        initialBillNumber: txn.transactionNumber,
                                                        initialAmount: txn.amount ?? 0.0,
                                                      );
                                                    } else if (action == 'make_payment') {
                                                      AddEditTransactionDialog.show(
                                                        context,
                                                        initialType: 'Payment',
                                                        initialPartyName: txn.partyName,
                                                        initialPartyUuid: txn.partyUuid,
                                                        initialBillUuid: txn.uuid,
                                                        initialBillNumber: txn.transactionNumber,
                                                        initialAmount: txn.amount ?? 0.0,
                                                      );
                                                    } else if (action == 'create_credit_note') {
                                                      Navigator.of(context, rootNavigator: true).push(
                                                        MaterialPageRoute(
                                                          builder: (context) => AddEditCreditNoteScreen(
                                                            initialInvoiceNumber: txn.transactionNumber,
                                                            initialInvoiceUuid: txn.uuid,
                                                          ),
                                                        ),
                                                      ).then((_) => ref.invalidate(filteredTransactionsProvider));
                                                    } else if (action == 'create_debit_note') {
                                                      Navigator.of(context, rootNavigator: true).push(
                                                        MaterialPageRoute(
                                                          builder: (context) => AddEditDebitNoteScreen(
                                                            initialInvoiceNumber: txn.transactionNumber,
                                                            initialInvoiceUuid: txn.uuid,
                                                          ),
                                                        ),
                                                      ).then((_) => ref.invalidate(filteredTransactionsProvider));
                                                    } else if (action == 'delete') {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: const Text('Delete Transaction'),
                                                          content: const Text('Are you sure you want to delete this transaction?'),
                                                          actions: [
                                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
                                                    const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit, size: 20), title: Text('Edit'), contentPadding: EdgeInsets.zero)),
                                                    const PopupMenuItem(value: 'send_pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf, size: 20, color: Colors.blue), title: Text('Send PDF'), contentPadding: EdgeInsets.zero)),
                                                    const PopupMenuItem(value: 'print', child: ListTile(leading: Icon(Icons.print, size: 20, color: Colors.blue), title: Text('Print'), contentPadding: EdgeInsets.zero)),
                                                    if (txn.transactionType == 'Receipt' || txn.transactionType == 'Payment')
                                                      const PopupMenuItem(value: 'link', child: ListTile(leading: Icon(Icons.link, size: 20), title: Text('Link to Bills'), contentPadding: EdgeInsets.zero)),
                                                    if (txn.transactionType == 'Sales') ...[
                                                      const PopupMenuItem(value: 'receive_payment', child: ListTile(leading: Icon(Icons.download_rounded, size: 20, color: Colors.green), title: Text('Receive Payment', style: TextStyle(color: Colors.green)), contentPadding: EdgeInsets.zero)),
                                                      const PopupMenuItem(value: 'create_credit_note', child: ListTile(leading: Icon(Icons.keyboard_return_rounded, size: 20, color: Colors.orange), title: Text('Create Credit Note', style: TextStyle(color: Colors.orange)), contentPadding: EdgeInsets.zero)),
                                                    ],
                                                    if (txn.transactionType == 'Purchase') ...[
                                                      const PopupMenuItem(value: 'make_payment', child: ListTile(leading: Icon(Icons.upload_rounded, size: 20, color: Colors.red), title: Text('Make Payment', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero)),
                                                      const PopupMenuItem(value: 'create_debit_note', child: ListTile(leading: Icon(Icons.keyboard_return_rounded, size: 20, color: Colors.orange), title: Text('Create Debit Note', style: TextStyle(color: Colors.orange)), contentPadding: EdgeInsets.zero)),
                                                    ],
                                                    const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red, size: 20), title: Text('Delete', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                txn.transactionNumber ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                                child: Text(
                                                  txn.transactionType ?? '',
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(4)),
                                                child: Text(
                                                  upperStatus,
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusFg),
                                                ),
                                              ),
                                              Text(
                                                txn.transactionDate != null ? DateFormat('dd MMM yyyy').format(txn.transactionDate!) : "N/A",
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          if (txn.remarks != null && txn.remarks!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(txn.remarks!, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                                          ],
                                          if (txn.linkedBillUuid != null && txn.linkedBillUuid!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.link, size: 12, color: Colors.green[800]),
                                                const SizedBox(width: 4),
                                                Text('Linked: \${txn.linkedBillNumber ?? "Yes"}', style: TextStyle(color: Colors.green[800], fontSize: 11, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
`;

  c = c.substring(0, startIdx) + newCode + '\n' + c.substring(endIdx);
  fs.writeFileSync('lib/features/transactions/presentation/screens/transactions_screen.dart', c);
  console.log('Successfully updated transactions card!');
} else {
  console.log('Could not find start/end indices');
}
