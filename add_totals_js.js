const fs = require('fs');
const path = require('path');

const files = [
    { path: 'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart', provider: 'invoiceCartProvider' },
    { path: 'lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', provider: 'purchaseCartProvider' },
    { path: 'lib/features/orders/presentation/screens/add_edit_order_screen.dart', provider: 'orderCartProvider' },
    { path: 'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', provider: 'creditNoteCartProvider' },
    { path: 'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', provider: 'debitNoteCartProvider' },
];

for (const fileObj of files) {
    const filePath = path.join(__dirname, fileObj.path);
    if (!fs.existsSync(filePath)) continue;

    let content = fs.readFileSync(filePath, 'utf8');

    // Restore messed up invoice screen
    if (content.includes("Text('?$(${item")) {
        content = content.replace(/Text\('[^']+'\,\s*style:\s*TextStyle\(fontWeight:\s*FontWeight\.bold,\s*color:\s*theme\.colorScheme\.primary,\s*fontSize:\s*13\)\),\r?\n\s*const SizedBox\(width:\s*8\),\r?\n/, '');
    }

    const provider = fileObj.provider;
    
    // We will use a regex that is flexible about whitespace
    // IconButton(\s*icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),\s*onPressed: \(\) \{\s*ref.read\(xxx\).removeItemAt\(widget.index\);\s*\},\s*\),
    
    const regex = new RegExp(`IconButton\\(\\s*icon:\\s*const\\s*Icon\\(Icons\\.delete_outline_rounded,\\s*color:\\s*Colors\\.red\\),\\s*onPressed:\\s*\\(\\)\\s*\\{\\s*ref\\.read\\(${provider}\\.notifier\\)\\.removeItemAt\\(widget\\.index\\);\\s*\\},\\s*\\),`);
    
    const replacement = `Text('₹\${item.calculateItemTotal(widget.isGstInclusive).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 13)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: () {
                      ref.read(${provider}.notifier).removeItemAt(widget.index);
                    },
                  ),`;
                  
    if (!content.includes('item.calculateItemTotal(')) {
        content = content.replace(regex, replacement);
    }
    
    fs.writeFileSync(filePath, content, 'utf8');
    console.log('Updated totals in', fileObj.path);
}
