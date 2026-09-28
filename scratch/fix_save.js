const fs = require('fs');

function applySaveFix(filePath, isCredit) {
  let content = fs.readFileSync(filePath, 'utf8');
  let target = '..updatedAt = DateTime.now();';
  let replacement = `..updatedAt = DateTime.now()
      ..paymentMode = _paymentMode
      ..discountType = _isDiscountPercent ? 'percentage' : 'flat'
      ..discountPercent = _isDiscountPercent ? (double.tryParse(_discountController.text) ?? 0.0) : 0.0
      ..attachedImage = _attachedImage
      ..isSynced = false;`;
  
  if (content.includes('..paymentMode = _paymentMode')) {
    console.log('Already fixed:', filePath);
  } else {
    content = content.replace(target, replacement);
    fs.writeFileSync(filePath, content);
    console.log('Fixed save for:', filePath);
  }
}

applySaveFix('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', true);
applySaveFix('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', false);
