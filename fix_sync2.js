const fs = require('fs');
let content = fs.readFileSync('lib/core/services/sync_service.dart', 'utf-8');

const entities = [
  'Party', 'Item', 'Invoice', 'Order', 'Purchase', 'Expense', 'ExpenseItem',
  'StockAdjustment', 'CreditNote', 'WhatsAppMapping', 'DebitNote', 'Transaction',
  'Category', 'Unit', 'Brand', 'Settings', 'User', 'BankAccount', 'Task', 'Machinery'
];

let helpers = `
  int _getEntityId(String entityType, dynamic entity) {
    switch (entityType) {
${entities.map(e => `      case '${e}': return (entity as ${e}).id;`).join('\n')}
      default: return 0;
    }
  }

  String? _getEntityUuid(String entityType, dynamic entity) {
    switch (entityType) {
${entities.map(e => `      case '${e}': return (entity as ${e}).uuid;`).join('\n')}
      default: return null;
    }
  }

  DateTime _getEntityCreatedAt(String entityType, dynamic entity) {
    switch (entityType) {
${entities.map(e => `      case '${e}': return (entity as ${e}).createdAt;`).join('\n')}
      default: return DateTime.now();
    }
  }

  DateTime _getEntityUpdatedAt(String entityType, dynamic entity) {
    switch (entityType) {
${entities.map(e => `      case '${e}': return (entity as ${e}).updatedAt;`).join('\n')}
      default: return DateTime.now();
    }
  }

  int _getEntityVersion(String entityType, dynamic entity) {
    switch (entityType) {
${entities.map(e => `      case '${e}': return (entity as ${e}).version;`).join('\n')}
      default: return 1;
    }
  }

  bool _getEntityIsDeleted(String entityType, dynamic entity) {
    switch (entityType) {
${entities.map(e => `      case '${e}': return (entity as ${e}).isDeleted;`).join('\n')}
      default: return false;
    }
  }

  bool _getEntityIsSynced(String entityType, dynamic entity) {
    switch (entityType) {
${entities.map(e => `      case '${e}': return (entity as ${e}).isSynced;`).join('\n')}
      default: return false;
    }
  }

  void _setEntityIsSynced(String entityType, dynamic entity, bool value) {
    switch (entityType) {
${entities.map(e => `      case '${e}': (entity as ${e}).isSynced = value; break;`).join('\n')}
    }
  }
`;

// Insert helpers before _mapEntityToMap
content = content.replace('Future<Map<String, dynamic>> _mapEntityToMap', helpers + '\n  Future<Map<String, dynamic>> _mapEntityToMap');

// Replace (entity as IsarModel).property with helpers
content = content.replace(/\(localRecord as IsarModel\)\.id/g, '_getEntityId(entityType, localRecord)');
content = content.replace(/\(localRecord as IsarModel\)\.version/g, '_getEntityVersion(entityType, localRecord)');
content = content.replace(/\(localRecord as IsarModel\)\.updatedAt/g, '_getEntityUpdatedAt(entityType, localRecord)');
content = content.replace(/\(localRecord as IsarModel\)\.isSynced/g, '_getEntityIsSynced(entityType, localRecord)');

content = content.replace(/\(entity as IsarModel\)\.uuid/g, '_getEntityUuid(entityType, entity)');
content = content.replace(/\(entity as IsarModel\)\.createdAt/g, '_getEntityCreatedAt(entityType, entity)');
content = content.replace(/\(entity as IsarModel\)\.updatedAt/g, '_getEntityUpdatedAt(entityType, entity)');
content = content.replace(/\(entity as IsarModel\)\.version/g, '_getEntityVersion(entityType, entity)');
content = content.replace(/\(entity as IsarModel\)\.isDeleted/g, '_getEntityIsDeleted(entityType, entity)');
content = content.replace(/\(entity as IsarModel\)\.isSynced = (.*?);/g, '_setEntityIsSynced(entityType, entity, $1);');
content = content.replace(/\(entity as IsarModel\)\.isSynced/g, '_getEntityIsSynced(entityType, entity)');

fs.writeFileSync('lib/core/services/sync_service.dart', content);
console.log('Added strict getter helpers successfully');
