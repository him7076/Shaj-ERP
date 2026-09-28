const fs = require('fs');
let c = fs.readFileSync('lib/core/services/sync_service.dart', 'utf8');

// 1. Update serialization
const entities = ['Purchase', 'Order', 'CreditNote', 'DebitNote'];
for (const ent of entities) {
  // Add to map
  // Find case 'Purchase': 
  //   final e = entity as Purchase;
  //   ...
  //   'grandTotal': e.grandTotal,
  // We will just replace 'grandTotal': e.grandTotal, with 'grandTotal': e.grandTotal, + new fields
  c = c.replace(
    new RegExp('case \\\'' + ent + '\\\':[\\\\s\\\\S]*?\\\'grandTotal\\\': e.grandTotal,'),
    match => match + '\\n        \\\'paymentMode\\\': e.paymentMode,\\n        \\\'discountType\\\': e.discountType,\\n        \\\'discountPercent\\\': e.discountPercent,\\n        \\\'attachedImage\\\': e.attachedImage,'
  );

  // Add to deserialization
  // Find case 'Purchase':
  //   entity = Purchase()
  //   ...
  //   ..grandTotal = (data['grandTotal'] as num?)?.toDouble()
  c = c.replace(
    new RegExp('case \\\'' + ent + '\\\':[\\\\s\\\\S]*?\\.\\.grandTotal = \\(data\\[\\\'grandTotal\\\'\\] as num\\?\\)\\?\\.toDouble\\(\\)', 'g'),
    match => match + '\\n        ..paymentMode = data[\\\'paymentMode\\\']\\n        ..discountType = data[\\\'discountType\\\']\\n        ..discountPercent = (data[\\\'discountPercent\\\'] as num?)?.toDouble()\\n        ..attachedImage = data[\\\'attachedImage\\\']'
  );
}

fs.writeFileSync('lib/core/services/sync_service.dart', c);
console.log('Updated sync_service.dart for all entities');
