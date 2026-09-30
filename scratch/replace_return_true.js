const fs = require('fs');
let c = fs.readFileSync('lib/features/backup/presentation/screens/data_repair_screen.dart', 'utf8');
c = c.replace(/return true;/g, `if (record is dynamic) { try { record.isDeleted = false; record.isSynced = false; } catch (_) {} }\n        return true;`);
fs.writeFileSync('lib/features/backup/presentation/screens/data_repair_screen.dart', c);
console.log('Replaced all return true;');
