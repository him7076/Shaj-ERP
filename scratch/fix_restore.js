const fs = require('fs');
let content = fs.readFileSync('lib/features/reports/presentation/screens/deleted_vouchers_screen.dart', 'utf8');

const regex = /style: TextStyle\(fontSize: 11, color: theme\.colorScheme\.onSurfaceVariant\),\s*\),\s*],\s*\),\s*\),\s*\),\s*\);/g;

const replacement = `style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
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
                              ),
                            ),
                          );`;

if (regex.test(content)) {
    content = content.replace(regex, replacement);
    fs.writeFileSync('lib/features/reports/presentation/screens/deleted_vouchers_screen.dart', content, 'utf8');
    console.log("Successfully injected restore button.");
} else {
    console.log("Regex not matched.");
}
