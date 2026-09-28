const fs = require('fs');

// 1. full_screen_item_entry.dart
let f = fs.readFileSync('lib/core/widgets/full_screen_item_entry.dart', 'utf8');
f = f.replace('required this.isBundle,', 'required this.isBundle, this.description,');
if (!f.includes('core_providers.dart')) {
  f = f.replace('import \'package:flutter/material.dart\';', 'import \'package:flutter/material.dart\';\nimport \'package:business_sahaj_erp/presentation/providers/core_providers.dart\';');
}
fs.writeFileSync('lib/core/widgets/full_screen_item_entry.dart', f, 'utf8');

// 2. adjust_cash_dialog.dart
let a = fs.readFileSync('lib/features/bank/presentation/screens/adjust_cash_dialog.dart', 'utf8');
if (!a.includes('core_providers.dart')) {
  a = a.replace('import \'package:business_sahaj_erp/core/utils/responsive_layout.dart\';', 'import \'package:business_sahaj_erp/core/utils/responsive_layout.dart\';\nimport \'package:business_sahaj_erp/presentation/providers/core_providers.dart\';');
}
fs.writeFileSync('lib/features/bank/presentation/screens/adjust_cash_dialog.dart', a, 'utf8');

// 3. order_providers.dart
let o = fs.readFileSync('lib/features/orders/presentation/providers/order_providers.dart', 'utf8');
// "Duplicated parameter name 'description'."
// Let's replace the duplicate in updateCartItem
o = o.replace(/String\? description,\s*String\? description,/g, 'String? description,');
fs.writeFileSync('lib/features/orders/presentation/providers/order_providers.dart', o, 'utf8');

// 4. invoice_providers.dart
let i = fs.readFileSync('lib/features/sales/presentation/providers/invoice_providers.dart', 'utf8');
i = i.replace(/String\? description,\s*String\? description,/g, 'String? description,');
fs.writeFileSync('lib/features/sales/presentation/providers/invoice_providers.dart', i, 'utf8');

// 5. transaction_providers.dart (No named parameter with the name 'description')
// The compiler says: lib/features/transactions/presentation/providers/transaction_providers.dart:686:7:
let t = fs.readFileSync('lib/features/transactions/presentation/providers/transaction_providers.dart', 'utf8');
t = t.replace(/description: description,/g, ''); // maybe it's not accepted in some method call? Wait, it might be updateCartItem that doesn't have it? Let's check updateCartItem signature in transaction_providers
// I will just replace description: description, with '' if it's there
// Actually, let's fix the providers manually if this fails.
// Just write this script first.
