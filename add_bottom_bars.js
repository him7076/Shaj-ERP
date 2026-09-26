const fs = require('fs');
const path = require('path');

const files = [
    'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
    'lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart',
    'lib/features/orders/presentation/screens/add_edit_order_screen.dart',
    'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
    'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart',
];

for (const file of files) {
    const filePath = path.join(__dirname, file);
    if (!fs.existsSync(filePath)) continue;

    let content = fs.readFileSync(filePath, 'utf8');

    // Remove the previous partial replacement if it went wrong?
    // Let's just do a simpler search string replacement
    const searchString = `IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),`;
    const replacementString = `Text('₹\${item.calculateItemTotal(widget.isGstInclusive).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),`;

    if (content.includes(searchString) && !content.includes('item.calculateItemTotal(')) {
        content = content.replace(searchString, replacementString);
    }
    
    // Some might have different indentation:
    const searchString2 = `IconButton(\n                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),`;
    if (content.includes(searchString2) && !content.includes('item.calculateItemTotal(')) {
        content = content.replace(searchString2, replacementString);
    }

    // Try a regex with [\s\S]*?
    if (!content.includes('item.calculateItemTotal(')) {
        content = content.replace(/IconButton\(\s*icon: const Icon\(Icons\.delete_outline_rounded, color: Colors\.red\),/g, replacementString);
    }

    fs.writeFileSync(filePath, content, 'utf8');
}
