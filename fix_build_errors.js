const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, 'lib/features');

function walkFiles(dirPath, callback) {
    const files = fs.readdirSync(dirPath);
    for (const f of files) {
        const fullPath = path.join(dirPath, f);
        if (fs.statSync(fullPath).isDirectory()) {
            walkFiles(fullPath, callback);
        } else if (f.endsWith('.dart')) {
            callback(fullPath);
        }
    }
}

walkFiles(dir, (filePath) => {
    let content = fs.readFileSync(filePath, 'utf8');
    let original = content;

    // 1. Fix "const Scaffold(bottomNavigationBar: ..."
    // We should just remove the `const ` before Scaffold if it contains `theme.scaffoldBackgroundColor`
    content = content.replace(/return const Scaffold\(\s*bottomNavigationBar/g, 'return Scaffold(bottomNavigationBar');

    // 2. Fix the injected `calculateItemTotal` in Purchase, Credit Note, Debit Note screens.
    // In these screens, `PurchaseItem`, `CreditNoteItem`, `DebitNoteItem` don't have `calculateItemTotal`.
    // We should just remove the injected Text widgets entirely, as they already have a "Total" pill below.
    // The injected code looks like:
    // Text('₹${item.calculateItemTotal(widget.isGstInclusive).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
    // const SizedBox(width: 8),
    // Text('₹${item.calculateItemTotal(widget.isGstInclusive).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
    // const SizedBox(width: 8),
    // IconButton(
    
    // Some might have one Text, some might have two (due to duplicate runs or regex issues).
    // Let's replace the block with just the IconButton.
    const textRegex = /Text\('₹\$\{item\.calculateItemTotal\(widget\.isGstInclusive\)\.toStringAsFixed\(2\)\}',\s*style:\s*TextStyle\(fontWeight:\s*FontWeight\.bold,\s*color:\s*Theme\.of\(context\)\.colorScheme\.primary,\s*fontSize:\s*13\)\),\s*const\s*SizedBox\(width:\s*8\),\s*/g;
    
    if (filePath.includes('add_edit_purchase_screen.dart') || 
        filePath.includes('add_edit_credit_note_screen.dart') || 
        filePath.includes('add_edit_debit_note_screen.dart')) {
        content = content.replace(textRegex, '');
    }

    if (content !== original) {
        fs.writeFileSync(filePath, content, 'utf8');
        console.log('Fixed:', filePath);
    }
});
