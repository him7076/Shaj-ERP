const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '..', 'lib', 'features', 'parties', 'presentation', 'screens', 'party_detail_screen.dart');
let content = fs.readFileSync(filePath, 'utf8');

const target = `            return NeuCard(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: (ref.watch(themeProvider).themeType == ThemeType.neumorphism) ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: ListTile(
                onTap: () {
                  final targetUuid = (txn.uuid != null && txn.uuid!.isNotEmpty) ? txn.uuid! : txn.id.toString();
                  if (txn.type == 'Sales Invoice') {
                    Navigator.of(context,  rootNavigator: true).push(
                      MaterialPageRoute(builder: (context) => InvoiceDetailScreen(invoiceUuid: targetUuid)),
                    ).then((_) => _loadPartyDetails());
                  } else if (txn.type == 'Purchase Bill') {
                    Navigator.of(context,  rootNavigator: true).push(
                      MaterialPageRoute(builder: (context) => AddEditPurchaseScreen(purchaseUuid: targetUuid)),
                    ).then((_) => _loadPartyDetails());
                  } else if (txn.type == 'Credit Note') {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (context) => AddEditCreditNoteScreen(parentCreditNoteUuid: txn.rawTxn?.linkedBillUuid ?? targetUuid)),
                    ).then((_) => _loadPartyDetails());
                  } else if (txn.type == 'Debit Note') {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (context) => AddEditDebitNoteScreen(parentDebitNoteUuid: txn.rawTxn?.linkedBillUuid ?? targetUuid)),
                    ).then((_) => _loadPartyDetails());
                  } else if (txn.rawTxn != null) {
                    AddEditTransactionDialog.show(context, transaction: txn.rawTxn);
                  }
                },
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(isIncoming ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
                ),
                title: Row(
                  children: [
                    Text(txn.number, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(txn.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusStr == 'PAID' || statusStr == 'CLEARED' ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(statusStr.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusStr == 'PAID' || statusStr == 'CLEARED' ? Colors.green.shade800 : Colors.orange.shade900)),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Date: \${DateFormat('dd MMM yyyy').format(txn.date)} | Mode: \${txn.mode}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  currencyFormat.format(txn.amount),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                ),
              ),
            );`;

const replacement = `            Color statusBgColor = Colors.orange.withOpacity(0.15);
            Color statusTextColor = Colors.orange.shade900;
            if (statusStr.toUpperCase() == 'PAID' || statusStr.toUpperCase() == 'CLEARED') {
              statusBgColor = Colors.green.withOpacity(0.15);
              statusTextColor = Colors.green.shade800;
            } else if (statusStr.toUpperCase() == 'PARTIALLY PAID' || statusStr.toUpperCase() == 'PARTIAL') {
              statusBgColor = Colors.blue.withOpacity(0.15);
              statusTextColor = Colors.blue.shade900;
            } else if (statusStr.toUpperCase() == 'CANCELLED') {
              statusBgColor = Colors.red.withOpacity(0.15);
              statusTextColor = Colors.red.shade900;
            }

            return NeuCard(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: (ref.watch(themeProvider).themeType == ThemeType.neumorphism) ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final targetUuid = (txn.uuid != null && txn.uuid!.isNotEmpty) ? txn.uuid! : txn.id.toString();
                  if (txn.type == 'Sales Invoice') {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (context) => InvoiceDetailScreen(invoiceUuid: targetUuid)),
                    ).then((_) => _loadPartyDetails());
                  } else if (txn.type == 'Purchase Bill') {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (context) => AddEditPurchaseScreen(purchaseUuid: targetUuid)),
                    ).then((_) => _loadPartyDetails());
                  } else if (txn.type == 'Credit Note') {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (context) => AddEditCreditNoteScreen(parentCreditNoteUuid: txn.rawTxn?.linkedBillUuid ?? targetUuid)),
                    ).then((_) => _loadPartyDetails());
                  } else if (txn.type == 'Debit Note') {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (context) => AddEditDebitNoteScreen(parentDebitNoteUuid: txn.rawTxn?.linkedBillUuid ?? targetUuid)),
                    ).then((_) => _loadPartyDetails());
                  } else if (txn.rawTxn != null) {
                    AddEditTransactionDialog.show(context, transaction: txn.rawTxn);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(isIncoming ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txn.number,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Text(
                                  DateFormat('dd MMM yyyy').format(txn.date),
                                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    txn.type,
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusBgColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusStr.toUpperCase(),
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusTextColor),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(txn.amount),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                          ),
                          if (txn.pendingAmount > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Bal: ₹\${txn.pendingAmount.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );`;

if (content.includes(target)) {
  content = content.replace(target, replacement);
  fs.writeFileSync(filePath, content, 'utf8');
  console.log('SUCCESS: party_detail_screen.dart card redesigned');
} else {
  console.log('Target string not found');
}
