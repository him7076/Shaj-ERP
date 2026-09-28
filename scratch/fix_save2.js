const fs = require('fs');

function fixInvoiceSave() {
  const filePath = 'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart';
  let content = fs.readFileSync(filePath, 'utf8');
  
  let target = '..updatedAt = DateTime.now()';
  let replacement = `..updatedAt = DateTime.now()
      ..paymentMode = _paymentMode
      ..discountType = _isDiscountPercent ? 'percentage' : 'flat'
      ..discountPercent = _isDiscountPercent ? (double.tryParse(_discountController.text) ?? 0.0) : 0.0
      ..attachedImage = _attachedImage
      ..isSynced = false`;

  if (content.includes('..paymentMode = _paymentMode')) {
    console.log('Invoice save already fixed');
  } else {
    content = content.replace(target, replacement);
    fs.writeFileSync(filePath, content);
    console.log('Fixed invoice save block');
  }
}

fixInvoiceSave();
