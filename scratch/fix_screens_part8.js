const fs = require('fs');
let screen = fs.readFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', 'utf8');

const oldBlock = `            onAdd: (data) {
              onEdit(
                index,
                quantity: data.quantity,
                unit: data.unit,
                rate: data.rate,
                buyRate: data.purchaseRate,
                discountPercent: data.discountPercent,
                discountAmount: data.discountAmount,
                batchNumber: data.batchNumber,
                mfgDate: data.mfgDate != null ? DateFormat('MM/yyyy').format(data.mfgDate!) : null,
                expiryDate: data.expDate != null ? DateFormat('MM/yyyy').format(data.expDate!) : null,
              );
            },`;

const newBlock = `            onAdd: (data) {
              onEdit(data);
            },`;

screen = screen.replace(oldBlock, newBlock);
fs.writeFileSync('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', screen);
console.log('Fixed onEdit call');
