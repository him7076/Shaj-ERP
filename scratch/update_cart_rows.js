const fs = require('fs');

const files = [
  'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
  'lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart',
  'lib/features/orders/presentation/screens/add_edit_order_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'
];

for (const file of files) {
  if (!fs.existsSync(file)) {
    console.log("Not found:", file);
    continue;
  }
  let content = fs.readFileSync(file, 'utf8');

  // Update FullScreenItemEntryData initialization to include description
  content = content.replace(
    /isPurchaseRateWithTax:\s*false,(\s*\),)/g,
    'isPurchaseRateWithTax: false,\n              description: cartItem.description,$1'
  );

  // Update onAdd updateItemAt to pass description
  content = content.replace(
    /expiryDate:\s*data\.expDate\s*!=\s*null\s*\?\s*DateFormat\('MM\/yyyy'\)\.format\(data\.expDate!\)\s*:\s*null,(\s*\);)/g,
    "expiryDate: data.expDate != null ? DateFormat('MM/yyyy').format(data.expDate!) : null,\n                description: data.description,$1"
  );

  // Make Cart Row Compact
  content = content.replace(
    /margin:\s*const\s*EdgeInsets\.symmetric\(vertical:\s*6\),/g,
    'margin: const EdgeInsets.symmetric(vertical: 4),'
  );
  content = content.replace(
    /padding:\s*const\s*EdgeInsets\.all\(12\.0\),/g,
    'padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),'
  );
  content = content.replace(
    /const\s*SizedBox\(height:\s*8\),/g,
    'const SizedBox(height: 4),'
  );

  // Inject Description display inside the CartItemRow UI
  const itemRowStr = `Text(
                      cartItem.item.itemName ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),`;
  
  const descUI = `Text(
                      cartItem.item.itemName ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (cartItem.description != null && cartItem.description!.isNotEmpty &&
                  (cartItem.item.isBundle == true
                      ? (ref.watch(sharedPreferencesProvider).getBool('enable_bundle_description') ?? false)
                      : (ref.watch(sharedPreferencesProvider).getBool('enable_item_description') ?? false)))
                Padding(
                  padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                  child: Text(cartItem.description!, style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox.shrink(),`;

  // We have a problem: replacing just that might break. We need to do it precisely.
  // Instead of replacing itemRowStr, let's replace:
  //               ),
  //               const SizedBox(height: 8), // (this was already replaced with height: 4)
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  // Let's use regex on the Row after item name.

  content = content.replace(
    /\]\,\s*\)\,\s*const\s*SizedBox\(height:\s*4\),\s*Row\(/g,
    `],
              ),
              if (cartItem.description != null && cartItem.description!.isNotEmpty &&
                  (cartItem.item.isBundle == true
                      ? (ref.watch(sharedPreferencesProvider).getBool('enable_bundle_description') ?? false)
                      : (ref.watch(sharedPreferencesProvider).getBool('enable_item_description') ?? false)))
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(cartItem.description!, style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                ),
              const SizedBox(height: 4),
              Row(`
  );

  // Wait, I need to make sure FullScreenItemEntry.show on the + Add Item button passes description.
  // We already modified FullScreenItemEntryData.
  // But onAdd for new items:
  content = content.replace(
    /discountAmount:\s*data\.discountAmount,(\s*\);)/g,
    'discountAmount: data.discountAmount,\n          description: data.description,$1'
  );


  fs.writeFileSync(file, content, 'utf8');
}
console.log('Updated Cart Rows');
