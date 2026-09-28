const fs = require('fs');
const files = ['lib/features/transactions/presentation/providers/transaction_providers.dart'];
for (const file of files) {
  if (!fs.existsSync(file)) continue;
  let content = fs.readFileSync(file, 'utf8');

  content = content.replace(
    /void addItem\(Item item,\s*\{/g,
    'void addItem(Item item, {\n    String? description,'
  );
  content = content.replace(
    /selectedSubItemName:\s*selectedSubItemName,/g,
    'selectedSubItemName: selectedSubItemName,\n        description: description,'
  );
  content = content.replace(
    /double\?\s*discountAmount,(\s*\}\))/g,
    'double? discountAmount,\n    String? description,$1'
  );
  content = content.replace(
    /discountAmount:\s*discountAmount,(\s*\);)/g,
    'discountAmount: discountAmount,\n      description: description,$1'
  );
  content = content.replace(
    /String\?\s*mfgDate,(\s*List<String>\?\s*bundleComponentUuids,)/g,
    'String? mfgDate,\n    String? description,$1'
  );
  if (content.includes('bundleComponentUuids')) {
      content = content.replace(
        /List<String>\?\s*bundleComponentUuids,/g,
        'String? description,\n    List<String>? bundleComponentUuids,'
      );
  }
  content = content.replace(
    /selectedSubItemName:\s*selectedSubItemName\s*\?\?\s*item\.selectedSubItemName,/g,
    'selectedSubItemName: selectedSubItemName ?? item.selectedSubItemName,\n        description: description ?? item.description,'
  );
  fs.writeFileSync(file, content, 'utf8');
}
console.log('Updated Transaction Provider');
