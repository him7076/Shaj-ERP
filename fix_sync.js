const fs = require('fs');
let content = fs.readFileSync('lib/core/services/sync_service.dart', 'utf8');

// Serialization
const t1 = "'accountName': entity.accountName,";
const r1 = "'accountName': entity.accountName,\n        'printOnInvoice': entity.printOnInvoice,";

if (content.includes(t1)) {
    content = content.replace(t1, r1);
}

// Deserialization
const t2 = "isPersonalVault: data['isPersonalVault'] ?? false,";
const r2 = "isPersonalVault: data['isPersonalVault'] ?? false,\n            ..printOnInvoice = data['printOnInvoice'] ?? false,";

// Wait, the Isar model uses cascading setter for deserialization? Let's check how BankAccount is deserialized.
fs.writeFileSync('fix_sync.js', content);
