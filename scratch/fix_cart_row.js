const fs = require('fs');

const filesToFix = [
  'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
  'lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart',
  'lib/features/orders/presentation/screens/add_edit_order_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'
];

for (const file of filesToFix) {
  if (!fs.existsSync(file)) continue;
  let content = fs.readFileSync(file, 'utf8');

  // Find the exact delete button block and capture its onTap
  // InkWell( onTap: () => onDelete(), child: const Icon(Icons.delete_outline... )
  // We can match it generically.
  const regex = /InkWell\(\s*onTap:\s*(.*?)[,\s]*child:\s*const\s*Icon\(Icons\.delete_outline[^)]*\),\s*\)/;
  
  let m = content.match(regex);
  if (m) {
    const onTapAction = m[1];
    
    // Remove it from the top row:
    content = content.replace(/,\s*const\s*SizedBox\(width:\s*8\),\s*InkWell\(\s*onTap:\s*(.*?)[,\s]*child:\s*const\s*Icon\(Icons\.delete_outline[^)]*\),\s*\)/g, '');
    content = content.replace(/,\s*InkWell\(\s*onTap:\s*(.*?)[,\s]*child:\s*const\s*Icon\(Icons\.delete_outline[^)]*\),\s*\)/g, '');

    // Add it at the end of the column:
    content = content.replace(/if\s*\([^)]*\)\s*Padding\(\s*padding:\s*const\s*EdgeInsets\.only\(top:\s*6\.0\),\s*child:\s*Text\([\s\S]*?bodySmall\?\.color\),\s*\),\s*\),\s*\]/g, (match) => {
      return match.substring(0, match.length - 1) + 
        `  Align(
             alignment: Alignment.bottomRight,
             child: InkWell(
               onTap: ${onTapAction},
               child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
             ),
           ),
        ]`;
    });
    
    // Also fix the font size of the itemName to 13
    content = content.replace(/style:\s*const\s*TextStyle\(fontWeight:\s*FontWeight\.bold,\s*fontSize:\s*14\)/g, 'style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)');
  }
  
  fs.writeFileSync(file, content);
}
console.log('Fixed cart UI and bottom right delete buttons');
