const fs = require('fs');
let c = fs.readFileSync('lib/features/transactions/presentation/screens/transactions_screen.dart', 'utf8');
const lines = c.split('\n');

const popupMenu = fs.readFileSync('scratch/popup_menu_code.txt', 'utf8');

const newChildren = `
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
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                txn.transactionDate != null ? DateFormat('dd MMM yyyy').format(txn.transactionDate!) : "N/A",
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                              Text(
                                                isUsedType
                                                    ? 'Unused: \${currencyFormat.format(txn.balanceAmount ?? 0.0)}'
                                                    : 'Balance: \${currencyFormat.format(txn.balanceAmount ?? 0.0)}',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: badgeColor.withOpacity(0.8)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
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
                                              const SizedBox(width: 4),
                                              SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: ${popupMenu},
                                              ),
                                            ],
                                          ),
`;

lines.splice(980, 1139 - 980, newChildren);
fs.writeFileSync('lib/features/transactions/presentation/screens/transactions_screen.dart', lines.join('\n'), 'utf8');
console.log('Successfully replaced card layout!');
