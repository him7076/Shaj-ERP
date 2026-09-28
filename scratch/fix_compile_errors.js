const fs = require('fs');

const files = [
  'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
  'lib/features/orders/presentation/screens/add_edit_order_screen.dart',
  'lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart'
];

for (const file of files) {
  if (fs.existsSync(file)) {
    let content = fs.readFileSync(file, 'utf8');
    
    // Remove if (newItem is InvoiceItem) { ... } else if ...
    const regex = /if\s*\(newItem\s*is\s*InvoiceItem\)\s*\{[\s\S]*?\}\s*(?:else\s*if\s*\(newItem\s*is\s*[A-Za-z]+\)\s*\{[\s\S]*?\}\s*)*/g;
    content = content.replace(regex, '');
    
    // Replace ref.read(itemsListProvider.notifier).updateItem(item);
    content = content.replace(/ref\.read\(itemsListProvider\.notifier\)\.updateItem\(item\);/g, 'ref.invalidate(itemsListProvider);');

    fs.writeFileSync(file, content);
  }
}

// Special fixes for credit and debit note screens which don't use cart providers
const noteFiles = [
  'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'
];

for (const file of noteFiles) {
  if (fs.existsSync(file)) {
    let content = fs.readFileSync(file, 'utf8');
    
    // Remove if (newItem is ...) block
    const regex = /if\s*\(newItem\s*is\s*InvoiceItem\)\s*\{[\s\S]*?\}\s*(?:else\s*if\s*\(newItem\s*is\s*[A-Za-z]+\)\s*\{[\s\S]*?\}\s*)*/g;
    content = content.replace(regex, '');
    
    // Fix notifier.addItem and updateItemAt (lines 315-344)
    // Replace the block from: final notifier = ref.read(creditNoteCartProvider.notifier);
    // up to the catch(e) { ... } block
    // with just:
    // setState(() { _draftItems.add(newItem); });
    // _recalculateTotals();

    const providerRegex = /final\s+notifier\s*=\s*ref\.read\([A-Za-z]+CartProvider\.notifier\);[\s\S]*?catch\s*\([A-Za-z]+\)\s*\{[\s\S]*?\}\s*\}/g;
    content = content.replace(providerRegex, 'setState(() { _draftItems.add(newItem); });\n    _recalculateTotals();');
    
    // Also replace itemsListProvider.notifier
    content = content.replace(/ref\.read\(itemsListProvider\.notifier\)\.updateItem\(item\);/g, 'ref.invalidate(itemsListProvider);');

    fs.writeFileSync(file, content);
  }
}

// Fix add_edit_order_screen discount setter error
// Error: The setter 'discount' isn't defined for the type 'OrderItem'.
// Line 839: ..discount = data.discountAmount // some models use discountAmount, some use discount
// OrderItem uses discountAmount and discountPercent
let orderFile = 'lib/features/orders/presentation/screens/add_edit_order_screen.dart';
if (fs.existsSync(orderFile)) {
    let orderContent = fs.readFileSync(orderFile, 'utf8');
    orderContent = orderContent.replace(/\.\.discount = data\.discountAmount/g, '..discountAmount = data.discountAmount');
    fs.writeFileSync(orderFile, orderContent);
}

// Remove theme provider import in full_screen_item_entry.dart
let fullScreen = fs.readFileSync('lib/core/widgets/full_screen_item_entry.dart', 'utf8');
fullScreen = fullScreen.replace(/import 'package:business_sahaj_erp\/core\/theme\/theme_provider\.dart';\n/g, '');
fs.writeFileSync('lib/core/widgets/full_screen_item_entry.dart', fullScreen);

console.log('Fixed syntax errors via script');
