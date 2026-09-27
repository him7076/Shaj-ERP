const fs = require('fs');
let content = fs.readFileSync('lib/core/services/sync_service.dart', 'utf8');

const t1 = "            'currentBalance': e.currentBalance,";
const r1 = "            'currentBalance': e.currentBalance,\n            'isPersonalVault': e.isPersonalVault,\n            'printOnInvoice': e.printOnInvoice,";

const t2 = "            ..currentBalance = (data['currentBalance'] as num?)?.toDouble();";
const r2 = "            ..currentBalance = (data['currentBalance'] as num?)?.toDouble()\n            ..isPersonalVault = data['isPersonalVault'] ?? false\n            ..printOnInvoice = data['printOnInvoice'] ?? false;";

content = content.replace(t1, r1);
content = content.replace(t2, r2);
fs.writeFileSync('lib/core/services/sync_service.dart', content);
console.log('Fixed sync_service');
