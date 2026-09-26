import os
import re

files = [
    'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
    'lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart',
    'lib/features/orders/presentation/screens/add_edit_order_screen.dart',
    'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
    'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart',
]

for file_path in files:
    if not os.path.exists(file_path): continue
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # We want to replace:
    # IconButton(
    #   icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
    
    # We can use regex with DOTALL or just replace a normalized string
    
    # regex pattern
    pattern = re.compile(r'IconButton\(\s*icon:\s*const\s*Icon\(Icons\.delete_outline_rounded,\s*color:\s*Colors\.red\),', re.MULTILINE)
    
    replacement = """Text('₹${item.calculateItemTotal(widget.isGstInclusive).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),"""
                    
    if 'item.calculateItemTotal' not in content:
        new_content = pattern.sub(replacement, content)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {file_path}")
