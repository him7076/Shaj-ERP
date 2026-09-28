const fs = require('fs');

// 1. Fix transactions_screen.dart (duplicate separatorBuilder)
let tScreen = fs.readFileSync('lib/features/transactions/presentation/screens/transactions_screen.dart', 'utf8');
const linesT = tScreen.split('\n');
let fixedT = [];
let foundSeparator = false;
for (let i = 0; i < linesT.length; i++) {
  if (linesT[i].includes('separatorBuilder: (context, index) => const SizedBox(height: 8),')) {
    if (!foundSeparator) {
      foundSeparator = true;
      fixedT.push(linesT[i]);
    } else {
      // skip duplicate
    }
  } else {
    fixedT.push(linesT[i]);
  }
}
fs.writeFileSync('lib/features/transactions/presentation/screens/transactions_screen.dart', fixedT.join('\n'));
console.log('Fixed transactions_screen.dart duplicate separatorBuilder');


// 2. Fix add_edit_purchase_screen.dart (onChanged and missing required params)
let pScreen = fs.readFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', 'utf8');
const oldOnChangedBlock = `                       onChanged: (qty, rate, discount, gstRate) {
                         setState(() {
                           item.quantity = qty;
                           item.rate = rate;
                           item.discount = discount;
                           item.gstRate = gstRate;
                         });
                         _recalculateTotals();
                       },`;
const newOnEditBlock = `                       onEdit: (data) {
                         setState(() {
                           item.quantity = data.quantity;
                           item.unit = data.unit;
                           item.rate = data.rate;
                           item.discount = data.discountAmount;
                           item.batchNumber = data.batchNumber;
                           item.totalAmount = (data.quantity * data.rate) - data.discountAmount;
                         });
                         _recalculateTotals();
                       },`;
if (pScreen.includes(oldOnChangedBlock)) {
  pScreen = pScreen.replace(oldOnChangedBlock, newOnEditBlock);
  console.log('Replaced onChanged with onEdit block correctly in add_edit_purchase_screen.dart');
} else {
  // Try regex if exact match failed due to indentation
  pScreen = pScreen.replace(/onChanged: \(qty, rate, discount, gstRate\) \{[\s\S]*?\},/, newOnEditBlock);
  console.log('Replaced onChanged via regex');
}

// Ensure PurchaseCartItemRow caller is matched properly with constructor
// It requires `onDelete` and `onEdit`.
// The constructor: const PurchaseCartItemRow({Key? key, required this.index, required this.cartItem, required this.isGstInclusive, this.isFixedAsset = false, required this.onDelete, required this.onEdit})
pScreen = pScreen.replace(/isFixedAsset: widget\.isFixedAsset,/g, 'isFixedAsset: widget.isFixedAsset,\nisGstInclusive: false,');
// Wait, I already added isGstInclusive: false in the previous script! Let me make sure it doesn't duplicate.
pScreen = pScreen.replace(/isGstInclusive: false,\s*isGstInclusive: false,/g, 'isGstInclusive: false,');

fs.writeFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', pScreen);


// 3. Fix add_edit_order_screen.dart (buyRate param)
let oScreen = fs.readFileSync('lib/features/orders/presentation/screens/add_edit_order_screen.dart', 'utf8');
oScreen = oScreen.replace(/buyRate: data\.purchaseRate,/g, '');
fs.writeFileSync('lib/features/orders/presentation/screens/add_edit_order_screen.dart', oScreen);
console.log('Fixed add_edit_order_screen.dart buyRate param');

