const fs = require('fs');
let content = fs.readFileSync('lib/core/services/sync_service.dart', 'utf-8');

const entities = [
  'Party', 'Item', 'Invoice', 'Order', 'Purchase', 'Expense', 'ExpenseItem',
  'StockAdjustment', 'CreditNote', 'WhatsAppMapping', 'DebitNote', 'Transaction',
  'Category', 'Unit', 'Brand', 'Settings', 'User', 'BankAccount', 'Task', 'Machinery'
];

let syncHelper = `
  bool _getEntityIsSynced(String entityType, dynamic entity) {
    switch (entityType) {
${entities.map(e => `      case '${e}': return (entity as ${e}).isSynced;`).join('\n')}
      default: return false;
    }
  }
`;

content = content.replace('int _getEntityId', syncHelper + '\n  int _getEntityId');
content = content.replace(/\(_getEntityVersion\(entityType, localRecord\) != 0 \/\* hack for isSynced getter \*\/\)/g, '_getEntityIsSynced(entityType, localRecord)');

fs.writeFileSync('lib/core/services/sync_service.dart', content);
