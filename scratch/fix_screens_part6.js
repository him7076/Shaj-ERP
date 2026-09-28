const fs = require('fs');

// 1. Fix add_edit_order_screen.dart
let orderScreen = fs.readFileSync('lib/features/orders/presentation/screens/add_edit_order_screen.dart', 'utf8');
orderScreen = orderScreen.replace(/orderCartProvider/g, 'cartProvider');
fs.writeFileSync('lib/features/orders/presentation/screens/add_edit_order_screen.dart', orderScreen);


// 2. Fix add_edit_purchase_screen.dart
let purchaseScreen = fs.readFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', 'utf8');

// Fix 1297: Constructor args missing onDelete and onEdit in the instantiation (line 1063)
purchaseScreen = purchaseScreen.replace(
  /return PurchaseCartItemRow\(\s*index: index,\s*cartItem: item,\s*isFixedAsset: widget\.isFixedAsset,/g,
  `return PurchaseCartItemRow(
                        index: index,
                        cartItem: item,
                        isGstInclusive: false,
                        isFixedAsset: widget.isFixedAsset,`
);

// Fix 1376: valueName -> itemName
purchaseScreen = purchaseScreen.replace(/cartItem\.item\.valueName/g, 'cartItem.itemName');

// Fix 1381, 1396, 1400: toStringAsFixed and * on double?
purchaseScreen = purchaseScreen.replace(/cartItem\.totalAmount\.toStringAsFixed/g, '(cartItem.totalAmount ?? 0.0).toStringAsFixed');
purchaseScreen = purchaseScreen.replace(/cartItem\.rate\.toStringAsFixed/g, '(cartItem.rate ?? 0.0).toStringAsFixed');
purchaseScreen = purchaseScreen.replace(/\(cartItem\.quantity \* cartItem\.rate\)/g, '((cartItem.quantity ?? 0.0) * (cartItem.rate ?? 0.0))');

// Fix 1405, 1409, 1413, 1417: discountAmount -> discount, discountPercent -> 0.0 (or just remove percent logic), taxAmount -> gstAmount, gstPercent -> gstRate
purchaseScreen = purchaseScreen.replace(/cartItem\.discountAmount/g, '(cartItem.discount ?? 0.0)');
purchaseScreen = purchaseScreen.replace(/cartItem\.discountPercent/g, '0.0');
purchaseScreen = purchaseScreen.replace(/cartItem\.taxAmount/g, '(cartItem.gstAmount ?? 0.0)');
purchaseScreen = purchaseScreen.replace(/cartItem\.gstPercent/g, '(cartItem.gstRate ?? 0.0)');

// Fix 1334: item: cartItem.item.value
// Needs to accept Item? or just not crash. We can pass a dummy item if it's null, but FullScreenItemEntryData needs Item!
purchaseScreen = purchaseScreen.replace(
  /item: cartItem\.item\.value,/g,
  `item: cartItem.item.value ?? Item()..itemName = cartItem.itemName,`
);

// Fix 1335, 1336, 1344: double? -> double
purchaseScreen = purchaseScreen.replace(/quantity: cartItem\.quantity,/g, 'quantity: cartItem.quantity ?? 1.0,');
purchaseScreen = purchaseScreen.replace(/rate: cartItem\.rate,/g, 'rate: cartItem.rate ?? 0.0,');
purchaseScreen = purchaseScreen.replace(/saleRate: cartItem\.rate \?\? cartItem\.rate,/g, 'saleRate: cartItem.rate ?? 0.0,');

fs.writeFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', purchaseScreen);

console.log('Fixed order and purchase screens errors.');
