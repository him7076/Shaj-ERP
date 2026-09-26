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

    // Remove old broken text if any
    content = content.replace(/Text\('₹\${item\.calculateItemTotal[^}]+\}\)', style: TextStyle[^)]+\)\),\r?\n\s*const SizedBox\(width: 8\),\r?\n\s*/g, '');

    // Now inject it cleanly before `IconButton(` that has `delete_outline_rounded`
    // We will do this by capturing the whitespace before `IconButton`
    
    // Pattern: 
    // (\s*)IconButton\(\s*icon:\s*const\s*Icon\(Icons\.delete_outline_rounded,\s*color:\s*Colors\.red\),
    
    const regex = /(\s*)IconButton\(\s*icon:\s*const\s*Icon\(Icons\.delete_outline_rounded,\s*color:\s*Colors\.red\),/g;
    
    content = content.replace(regex, (match, whitespace) => {
        return `${whitespace}Text('₹\${item.calculateItemTotal(widget.isGstInclusive).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13)),${whitespace}const SizedBox(width: 8),${whitespace}IconButton(\n${whitespace}  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),`;
    });

    fs.writeFileSync(filePath, content, 'utf8');
    console.log('Updated', file);
}
