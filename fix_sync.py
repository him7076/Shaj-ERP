import re

with open('lib/core/services/sync_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove poison ID assignments in _reconstructEntity
content = re.sub(r'^\s*\.\.partyId = data\[\'partyId\'\].*\n?', '', content, flags=re.MULTILINE)
content = re.sub(r'^\s*\.\.sourceOrderId = data\[\'sourceOrderId\'\].*\n?', '', content, flags=re.MULTILINE)
content = re.sub(r'^\s*\.\.itemId = data\[\'itemId\'\].*\n?', '', content, flags=re.MULTILINE)
content = re.sub(r'^\s*\.\.parentInvoiceId = data\[\'parentInvoiceId\'\].*\n?', '', content, flags=re.MULTILINE)
content = re.sub(r'^\s*\.\.purchaseId = data\[\'purchaseId\'\].*\n?', '', content, flags=re.MULTILINE)

# 2. Add missing itemUuid to serializers
content = re.sub(r'(\'itemName\': item\.itemName,)', r'\1\n          \'itemUuid\': _safeGetLinkUuid(item.item),', content)
content = re.sub(r'(\'itemName\': item\.itemName,\s*\'hsnCode\': item\.hsnCode,)', r'\1\n          \'itemUuid\': _safeGetLinkUuid(item.item),', content)
content = re.sub(r'(\'itemName\': item\.itemName,\s*\'hsnCode\': item\.hsnCode,\s*\'quantity\': item\.quantity,)', r'\1\n          \'itemUuid\': _safeGetLinkUuid(item.item),', content)

# 3. Fix _relinkAllRelations
content = re.sub(r'if \(parent == null && item\.parentInvoiceId != null\)', 'if (parent == null && (item.parentInvoiceUuid == null || item.parentInvoiceUuid!.isEmpty) && item.parentInvoiceId != null)', content)
content = re.sub(r'if \(parent == null && item\.purchaseId != null\)', 'if (parent == null && (item.purchaseUuid == null || item.purchaseUuid!.isEmpty) && item.purchaseId != null)', content)
content = re.sub(r'if \(parent == null && item\.orderId != null\)', 'if (parent == null && (item.orderUuid == null || item.orderUuid!.isEmpty) && item.orderId != null)', content)

# 4. Remove poison itemId assignments from embedded items reconstruction
content = re.sub(r'^\s*\.\.itemId = itemMap\[\'itemId\'\].*\n?', '', content, flags=re.MULTILINE)

# 5. Link item.value using itemUuid for embedded items
def replace_inv(m):
    return "                final iUuid = itemMap['itemUuid'] as String?;\n                if (iUuid != null && iUuid.isNotEmpty) {\n                  invItem.item.value = await isar.items.filter().uuidEqualTo(iUuid).findFirst();\n                }\n" + m.group(1) + "\n                try { await invItem.item.save(); } catch (_) {}"

def replace_pur(m):
    return "                final iUuid = itemMap['itemUuid'] as String?;\n                if (iUuid != null && iUuid.isNotEmpty) {\n                  purItem.item.value = await isar.items.filter().uuidEqualTo(iUuid).findFirst();\n                }\n" + m.group(1) + "\n                try { await purItem.item.save(); } catch (_) {}"

def replace_ord(m):
    return "                final iUuid = itemMap['itemUuid'] as String?;\n                if (iUuid != null && iUuid.isNotEmpty) {\n                  ordItem.item.value = await isar.items.filter().uuidEqualTo(iUuid).findFirst();\n                }\n" + m.group(1) + "\n                try { await ordItem.item.save(); } catch (_) {}"

def replace_cn(m):
    return "                final iUuid = itemMap['itemUuid'] as String?;\n                if (iUuid != null && iUuid.isNotEmpty) {\n                  cnItem.item.value = await isar.items.filter().uuidEqualTo(iUuid).findFirst();\n                }\n" + m.group(1) + "\n                try { await cnItem.item.save(); } catch (_) {}"

def replace_dn(m):
    return "                final iUuid = itemMap['itemUuid'] as String?;\n                if (iUuid != null && iUuid.isNotEmpty) {\n                  dnItem.item.value = await isar.items.filter().uuidEqualTo(iUuid).findFirst();\n                }\n" + m.group(1) + "\n                try { await dnItem.item.save(); } catch (_) {}"

content = re.sub(r'(\s+await isar\.writeTxn\(\(\) async \{\s+await isar\.invoiceItems\.put\(invItem\);\s+\}\);)', replace_inv, content)
content = re.sub(r'(\s+await isar\.writeTxn\(\(\) async \{\s+await isar\.purchaseItems\.put\(purItem\);\s+\}\);)', replace_pur, content)
content = re.sub(r'(\s+await isar\.writeTxn\(\(\) async \{\s+await isar\.orderItems\.put\(ordItem\);\s+\}\);)', replace_ord, content)
content = re.sub(r'(\s+await isar\.writeTxn\(\(\) async \{\s+await isar\.creditNoteItems\.put\(cnItem\);\s+try \{ await cnItem\.creditNote\.save\(\); \} catch \(_\) \{\}\s+\}\);)', replace_cn, content)
content = re.sub(r'(\s+await isar\.writeTxn\(\(\) async \{\s+await isar\.debitNoteItems\.put\(dnItem\);\s+try \{ await dnItem\.debitNote\.save\(\); \} catch \(_\) \{\}\s+\}\);)', replace_dn, content)


with open('lib/core/services/sync_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

