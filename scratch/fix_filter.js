const fs = require('fs');
const path = 'lib/features/reports/presentation/screens/deleted_vouchers_screen.dart';
let content = fs.readFileSync(path, 'utf8');

const oldFilter = `            final matchesType = _selectedFilterType == 'All' ||
                (v.voucherType?.toLowerCase().contains(_selectedFilterType.toLowerCase()) ?? false);`;
const newFilter = `            final matchesType = _selectedFilterType == 'All' ||
                (v.voucherType?.toLowerCase().replaceAll(' ', '').contains(_selectedFilterType.toLowerCase().replaceAll(' ', '')) ?? false);`;

content = content.replace(oldFilter, newFilter);

// Also let's double check if we need to fix the display text for voucher type in the UI list
const oldTitle = `                                      '\${v.voucherType ?? "Voucher"}: \${v.voucherNumber ?? "N/A"}',`;
const newTitle = `                                      '\${(v.voucherType ?? "Voucher").replaceAll("CreditNote", "Credit Note").replaceAll("DebitNote", "Debit Note")}: \${v.voucherNumber ?? "N/A"}',`;

content = content.replace(oldTitle, newTitle);

fs.writeFileSync(path, content, 'utf8');
console.log("Fixed filter and display logic.");
