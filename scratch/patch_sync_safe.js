const fs = require('fs');
const path = 'lib/core/services/sync_service.dart';
let txt = fs.readFileSync(path, 'utf8');

// 1. Order map list
txt = txt.replace(
  /'gstAmount': item.gstAmount,\s*'totalAmount': item.totalAmount,\s*}\)\.toList\(\);/g,
  "'gstAmount': item.gstAmount,\n          'totalAmount': item.totalAmount,\n          'batchNumber': item.batchNumber,\n          'expiryDate': item.expiryDate,\n          'mfgDate': item.mfgDate,\n        }).toList();"
);

// 2. OrderItem, CreditNoteItem, DebitNoteItem in _mapEntityToMap
function addToMap(targetCase, beforeStr, toAdd) {
  const caseIdx = txt.indexOf(`case '${targetCase}':`);
  if (caseIdx === -1) return;
  const nextCaseIdx = txt.indexOf(`case '`, caseIdx + 1);
  const block = nextCaseIdx === -1 ? txt.substring(caseIdx) : txt.substring(caseIdx, nextCaseIdx);
  
  if (block.includes(toAdd.trim())) return; // already added

  const newBlock = block.replace(beforeStr, `${toAdd}\n          ${beforeStr}`);
  txt = txt.substring(0, caseIdx) + newBlock + txt.substring(nextCaseIdx === -1 ? txt.length : nextCaseIdx);
}

addToMap('OrderItem', `'orderUuid': _safeGetLinkUuid(e.order),`, `'batchNumber': e.batchNumber,\n          'expiryDate': e.expiryDate,\n          'mfgDate': e.mfgDate,`);
addToMap('CreditNoteItem', `'creditNoteUuid': e.creditNote.value?.uuid,`, `'batchNumber': e.batchNumber,\n          'expiryDate': e.expiryDate,\n          'mfgDate': e.mfgDate,`);
addToMap('DebitNoteItem', `'debitNoteUuid': e.debitNote.value?.uuid,`, `'batchNumber': e.batchNumber,\n          'expiryDate': e.expiryDate,\n          'mfgDate': e.mfgDate,`);

// 3. _mapMapToEntity replacements
function addToEntity(targetCase, beforeStr, toAdd) {
  const mapMapToEntityIdx = txt.indexOf('dynamic _mapMapToEntity');
  const caseIdx = txt.indexOf(`case '${targetCase}':`, mapMapToEntityIdx);
  if (caseIdx === -1) return;
  const nextCaseIdx = txt.indexOf(`case '`, caseIdx + 1);
  const block = nextCaseIdx === -1 ? txt.substring(caseIdx) : txt.substring(caseIdx, nextCaseIdx);
  
  if (block.includes("batchNumber")) return; // already there or added

  const newBlock = block.replace(beforeStr, `${beforeStr}\n          ${toAdd}`);
  txt = txt.substring(0, caseIdx) + newBlock + txt.substring(nextCaseIdx === -1 ? txt.length : nextCaseIdx);
}

addToEntity('OrderItem', `..totalAmount = (data['totalAmount'] as num?)?.toDouble()`, `..batchNumber = data['batchNumber'] as String?\n          ..expiryDate = data['expiryDate'] as String?\n          ..mfgDate = data['mfgDate'] as String?;`);
addToEntity('CreditNoteItem', `..totalAmount = (data['totalAmount'] as num?)?.toDouble()`, `..batchNumber = data['batchNumber'] as String?\n          ..expiryDate = data['expiryDate'] as String?\n          ..mfgDate = data['mfgDate'] as String?;`);
addToEntity('DebitNoteItem', `..totalAmount = (data['totalAmount'] as num?)?.toDouble()`, `..batchNumber = data['batchNumber'] as String?\n          ..expiryDate = data['expiryDate'] as String?\n          ..mfgDate = data['mfgDate'] as String?;`);

fs.writeFileSync(path, txt);
console.log('Patched safely');
