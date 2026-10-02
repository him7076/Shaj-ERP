const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '..', 'lib', 'core', 'services', 'invoice_number_service.dart');
let content = fs.readFileSync(filePath, 'utf8');

const regex = /Future<String> generateNextInvoiceNumber\(\{bool isFixedAsset = false\}\) async \{[\s\S]*?throw InvoiceException\('Failed to generate next invoice number: \$e'\);\s*\}\s*\}/;

const replacement = `Future<String> generateNextInvoiceNumber({bool isFixedAsset = false}) async {
    try {
      final prefix = isFixedAsset ? 'FA-INV-' : 'INV-';
      final allInvoices = await isar.invoices.where().findAll();
      int maxNum = 0;
      final reg = isFixedAsset 
          ? RegExp(r'^FA-(?:INV-)?(\\d+)$', caseSensitive: false)
          : RegExp(r'^INV-(\\d+)$', caseSensitive: false);

      for (var inv in allInvoices) {
        if (inv.isDeleted == true) continue;
        if (inv.invoiceNumber != null && inv.invoiceNumber!.isNotEmpty) {
          final match = reg.firstMatch(inv.invoiceNumber!.trim());
          if (match != null) {
            final parsed = int.tryParse(match.group(1)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      var nextNum = maxNum + 1;
      var candidate = '$prefix\${nextNum.toString().padLeft(2, '0')}';
      final existingNumbers = allInvoices.where((e) => e.isDeleted != true).map((e) => e.invoiceNumber).toSet();
      while (existingNumbers.contains(candidate)) {
        nextNum++;
        candidate = '$prefix\${nextNum.toString().padLeft(2, '0')}';
      }
      logger.debug('Generated next invoice number: $candidate');
      return candidate;
    } catch (e) {
      throw InvoiceException('Failed to generate next invoice number: $e');
    }
  }`;

if (regex.test(content)) {
  content = content.replace(regex, replacement);
  fs.writeFileSync(filePath, content, 'utf8');
  console.log('SUCCESS: invoice_number_service.dart updated');
} else {
  console.log('Regex match failed');
}
