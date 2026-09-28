const fs = require('fs');

const path = 'lib/core/services/sync_service.dart';
let txt = fs.readFileSync(path, 'utf8');

function addFieldsToMap(target) {
  const marker = `'itemUuid': _safeGetLinkUuid(e.item),`;
  const replacement = `'batchNumber': e.batchNumber,
          'expiryDate': e.expiryDate,
          'mfgDate': e.mfgDate,
          'itemUuid': _safeGetLinkUuid(e.item),`;
          
  const regex = new RegExp(`case '${target}':([\\s\\S]*?)${marker}`);
  txt = txt.replace(regex, `case '${target}':$1${replacement}`);
}

function addFieldsToEntity(target) {
  const marker = `..itemUuid = data['itemUuid'] as String?;`;
  const replacement = `..batchNumber = data['batchNumber'] as String?
          ..expiryDate = data['expiryDate'] as String?
          ..mfgDate = data['mfgDate'] as String?
          ..itemUuid = data['itemUuid'] as String?;`;

  const regex = new RegExp(`case '${target}':([\\s\\S]*?)${marker}`);
  txt = txt.replace(regex, `case '${target}':$1${replacement}`);
}

// Order mapping misses items batch/expiry fields? 
// No, Order's `itemsMapList` maps items. Let's fix that.
const orderItemsMapStr = `          'gstAmount': item.gstAmount,
          'totalAmount': item.totalAmount,
        }).toList();`;
const orderItemsMapRepl = `          'gstAmount': item.gstAmount,
          'totalAmount': item.totalAmount,
          'batchNumber': item.batchNumber,
          'expiryDate': item.expiryDate,
          'mfgDate': item.mfgDate,
        }).toList();`;
if (txt.includes(orderItemsMapStr)) {
    txt = txt.replace(orderItemsMapStr, orderItemsMapRepl);
}

// Add to OrderItem, CreditNoteItem, DebitNoteItem
const targets = ['OrderItem', 'CreditNoteItem', 'DebitNoteItem'];
for (const t of targets) {
  addFieldsToMap(t);
  
  // For _mapMapToEntity, wait, the property `itemUuid` doesn't exist in local model, it is `e.item.value?.uuid`?
  // Actually, OrderItem doesn't have `itemUuid` in Isar. It just uses `item` IsarLink.
  // The correct marker for mapMapToEntity is where it sets `..totalAmount` or something.
}

// Let's do it simply by inserting before `break;` for each case in _mapMapToEntity
function addFieldsToMapToEntity(target) {
  const regex = new RegExp(`(case '${target}':[\\s\\S]*?\\.\\.totalAmount = [^\\n]+)`);
  txt = txt.replace(regex, `$1\n          ..batchNumber = data['batchNumber']\n          ..expiryDate = data['expiryDate']\n          ..mfgDate = data['mfgDate']`);
}

for (const t of targets) {
  addFieldsToMapToEntity(t);
}

// Same for InvoiceItem and PurchaseItem just in case? InvoiceItem and PurchaseItem mapMapToEntity:
addFieldsToMapToEntity('InvoiceItem');
addFieldsToMapToEntity('PurchaseItem');

fs.writeFileSync(path, txt);
console.log('Patched sync_service.dart');
