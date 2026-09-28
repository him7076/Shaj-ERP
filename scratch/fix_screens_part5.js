const fs = require('fs');
let screen = fs.readFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', 'utf8');

// Change constructor to include onEdit
screen = screen.replace(
  "final VoidCallback onDelete;\n  const PurchaseCartItemRow({Key? key, required this.index, required this.cartItem, required this.isGstInclusive, this.isFixedAsset = false, required this.onDelete})",
  "final VoidCallback onDelete;\n  final Function(FullScreenItemEntryData) onEdit;\n  const PurchaseCartItemRow({Key? key, required this.index, required this.cartItem, required this.isGstInclusive, this.isFixedAsset = false, required this.onDelete, required this.onEdit})"
);

// In the caller, add onEdit parameter
screen = screen.replace(
  /onDelete: \(\) \{\s*setState\(\(\) \{\s*_draftItems\.removeAt\(index\);\s*\}\);\s*\},/g,
  `onDelete: () {
                          setState(() {
                            _draftItems.removeAt(index);
                          });
                        },
                        onEdit: (data) {
                          setState(() {
                            final item = _draftItems[index];
                            item.quantity = data.quantity;
                            item.unit = data.unit;
                            item.rate = data.rate;
                            item.discount = data.discountAmount;
                            item.batchNumber = data.batchNumber;
                            item.totalAmount = (data.quantity * data.rate) - data.discountAmount;
                            _draftItems[index] = item;
                          });
                        },`
);

fs.writeFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', screen);
console.log('Added onEdit to PurchaseCartItemRow');
