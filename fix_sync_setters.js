const fs = require('fs');
let content = fs.readFileSync('lib/core/services/sync_service.dart', 'utf-8');

const entities = [
  'Party', 'Item', 'Invoice', 'Order', 'Purchase', 'Expense', 'ExpenseItem',
  'StockAdjustment', 'CreditNote', 'WhatsAppMapping', 'DebitNote', 'Transaction',
  'Category', 'Unit', 'Brand', 'Settings', 'User', 'BankAccount', 'Task', 'Machinery'
];

let setters = `
  void _setEntityUuid(String entityType, dynamic entity, String? value) {
    switch (entityType) {
${entities.map(e => `      case '${e}': (entity as ${e}).uuid = value; break;`).join('\n')}
    }
  }

  void _setEntityCreatedAt(String entityType, dynamic entity, DateTime value) {
    switch (entityType) {
${entities.map(e => `      case '${e}': (entity as ${e}).createdAt = value; break;`).join('\n')}
    }
  }

  void _setEntityUpdatedAt(String entityType, dynamic entity, DateTime value) {
    switch (entityType) {
${entities.map(e => `      case '${e}': (entity as ${e}).updatedAt = value; break;`).join('\n')}
    }
  }

  void _setEntityIsDeleted(String entityType, dynamic entity, bool value) {
    switch (entityType) {
${entities.map(e => `      case '${e}': (entity as ${e}).isDeleted = value; break;`).join('\n')}
    }
  }

  void _setEntityVersion(String entityType, dynamic entity, int value) {
    switch (entityType) {
${entities.map(e => `      case '${e}': (entity as ${e}).version = value; break;`).join('\n')}
    }
  }
`;

content = content.replace('void _setEntityIsSynced', setters + '\n  void _setEntityIsSynced');

content = content.replace(/_getEntityUuid\(entityType, entity\) = (.*?);/g, '_setEntityUuid(entityType, entity, $1);');
content = content.replace(/_getEntityCreatedAt\(entityType, entity\) = ([\s\S]*?);/g, '_setEntityCreatedAt(entityType, entity, $1);');
content = content.replace(/_getEntityUpdatedAt\(entityType, entity\) = ([\s\S]*?);/g, '_setEntityUpdatedAt(entityType, entity, $1);');
content = content.replace(/_getEntityIsDeleted\(entityType, entity\) = (.*?);/g, '_setEntityIsDeleted(entityType, entity, $1);');
content = content.replace(/_getEntityVersion\(entityType, entity\) = (.*?);/g, '_setEntityVersion(entityType, entity, $1);');

fs.writeFileSync('lib/core/services/sync_service.dart', content);
