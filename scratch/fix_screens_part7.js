const fs = require('fs');
let screen = fs.readFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', 'utf8');

const oldBlock = `                       onChanged: (qty, rate, discount, gstRate) {
                         setState(() {
                           item.quantity = qty;
                           item.rate = rate;
                           item.discount = discount;
                           item.gstRate = gstRate;
                         });
                         _recalculateTotals();
                       },`;

const newBlock = `                       onEdit: (data) {
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

screen = screen.replace(oldBlock, newBlock);
fs.writeFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', screen);
console.log('Fixed onChanged to onEdit');
