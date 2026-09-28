const fs = require('fs');

const files = [
  'lib/features/sales/presentation/providers/invoice_providers.dart',
  'lib/features/purchases/presentation/providers/purchase_providers.dart',
  'lib/features/orders/presentation/providers/order_providers.dart',
  'lib/features/transactions/presentation/providers/credit_note_providers.dart',
  'lib/features/transactions/presentation/providers/debit_note_providers.dart'
];

for (const file of files) {
  if (!fs.existsSync(file)) {
    console.log("Not found:", file);
    continue;
  }
  let content = fs.readFileSync(file, 'utf8');

  // Add description to addItem arguments
  content = content.replace(
    /void addItem\(Item item,\s*\{/g,
    'void addItem(Item item, {\n    String? description,'
  );

  // Pass description inside addItem to CartItemState constructor
  content = content.replace(
    /selectedSubItemName:\s*selectedSubItemName,/g,
    'selectedSubItemName: selectedSubItemName,\n        description: description,'
  );

  // Add description to updateItem arguments
  content = content.replace(
    /double\?\s*discountAmount,(\s*\}\))/g,
    'double? discountAmount,\n    String? description,$1'
  );

  // Pass description from updateItem to updateItemAt
  content = content.replace(
    /discountAmount:\s*discountAmount,(\s*\);)/g,
    'discountAmount: discountAmount,\n      description: description,$1'
  );

  // Add description to updateItemAt arguments
  content = content.replace(
    /String\?\s*mfgDate,(\s*List<String>\?\s*bundleComponentUuids,)/g,
    'String? mfgDate,\n    String? description,$1'
  );

  // Wait, what if there's no mfgDate? order_providers might not have buyRate.
  // We can just inject description before bundleComponentUuids if it exists.
  if (content.includes('bundleComponentUuids')) {
      content = content.replace(
        /List<String>\?\s*bundleComponentUuids,/g,
        'String? description,\n    List<String>? bundleComponentUuids,'
      );
  }

  // Inside updateItemAt, pass description to copyWith
  // Let's find selectedSubItemName in copyWith
  content = content.replace(
    /selectedSubItemName:\s*selectedSubItemName\s*\?\?\s*item\.selectedSubItemName,/g,
    'selectedSubItemName: selectedSubItemName ?? item.selectedSubItemName,\n        description: description ?? item.description,'
  );

  fs.writeFileSync(file, content, 'utf8');
}
console.log('Updated Providers');
