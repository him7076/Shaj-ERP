const fs = require('fs');

const path = 'lib/features/reports/presentation/screens/deleted_vouchers_screen.dart';
let content = fs.readFileSync(path, 'utf8');

const targetStr = `                                      'Deleted: $dateStr',
                                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),`;

const replaceStr = `                                      'Deleted: $dateStr',
                                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.restore_page_rounded, color: Colors.green),
                                tooltip: 'Restore Voucher',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Restore Voucher?'),
                                      content: Text('Are you sure you want to restore \${v.voucherNumber}?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref.read(restoreVoucherProvider)(v);
                                    ref.invalidate(deletedVouchersProvider);
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher restored successfully!')));
                                  }
                                },
                              ),`;

if (content.includes(targetStr)) {
    content = content.replace(targetStr, replaceStr);
    fs.writeFileSync(path, content, 'utf8');
    console.log('Restore button injected successfully.');
} else {
    console.log('Restore button target string not found.');
}
