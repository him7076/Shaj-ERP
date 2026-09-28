const fs = require('fs');

// Fix Category issue
let itemScreen = fs.readFileSync('lib/features/items/presentation/screens/add_edit_item_screen.dart', 'utf8');
itemScreen = itemScreen.replace(
  "import 'package:flutter/src/foundation/annotations.dart';",
  "import 'package:flutter/src/foundation/annotations.dart' hide Category;"
);
itemScreen = itemScreen.replace(
  "import 'package:flutter/foundation.dart';",
  "import 'package:flutter/foundation.dart' hide Category;"
);
fs.writeFileSync('lib/features/items/presentation/screens/add_edit_item_screen.dart', itemScreen);

// Fix PurchaseCartItemRow
let purchaseScreen = fs.readFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', 'utf8');
purchaseScreen = purchaseScreen.replace(/final CartItemState cartItem;/g, "final PurchaseItem cartItem;");

purchaseScreen = purchaseScreen.replace(
  "cartItem.item.itemName",
  "cartItem.itemName ?? ''"
);

// We also need to fix `cartItem.item` references in FullScreenItemEntry.show!
purchaseScreen = purchaseScreen.replace(/cartItem\.item\.isBundle/g, 'cartItem.isBundle');
purchaseScreen = purchaseScreen.replace(/cartItem\.item\.sellRate/g, 'cartItem.rate'); // Wait, buyRate?
purchaseScreen = purchaseScreen.replace(/cartItem\.item\.buyRate/g, 'cartItem.rate');
purchaseScreen = purchaseScreen.replace(/cartItem\.item\.isSaleRateWithTax/g, 'false');
purchaseScreen = purchaseScreen.replace(/cartItem\.item\.isPurchaseRateWithTax/g, 'false');
purchaseScreen = purchaseScreen.replace(/cartItem\.item/g, 'cartItem.item.value');

// Also fix the error: lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart:1384:43:
// Error: The getter 'purchaseCartProvider' isn't defined for the type 'PurchaseCartItemRow'.
purchaseScreen = purchaseScreen.replace(/ref\.read\(purchaseCartProvider\.notifier\)\.removeItemAt\(index\)/g, 'onDelete()');
purchaseScreen = purchaseScreen.replace(/ref\.read\(purchaseCartProvider\.notifier\)\.updateItemAt\(/g, 'onEdit(');

// Wait, the constructor also needs onDelete and onEdit!
purchaseScreen = purchaseScreen.replace(
  "const PurchaseCartItemRow({Key? key, required this.index, required this.cartItem, required this.isGstInclusive, this.isFixedAsset = false}) : super(key: key);",
  "final VoidCallback onDelete;\n  const PurchaseCartItemRow({Key? key, required this.index, required this.cartItem, required this.isGstInclusive, this.isFixedAsset = false, required this.onDelete}) : super(key: key);"
);

fs.writeFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', purchaseScreen);

console.log('Fixed Category and PurchaseCartItemRow');
