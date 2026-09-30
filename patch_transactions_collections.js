const fs = require('fs');
const path = 'lib/core/services/sync_service.dart';
let content = fs.readFileSync(path, 'utf8');

const oldGetCollection = `  String _getFirestoreCollection(String entityType) {
    switch (entityType) {
      case 'Party': return 'parties';
      case 'Item': return 'items';
      case 'Category': return 'categories';
      case 'Unit': return 'units';
      case 'Brand': return 'brands';
      case 'Order': return 'orders';
      case 'OrderItem': return 'order_items';
      case 'Invoice': return 'invoices';
      case 'InvoiceItem': return 'invoice_items';
      case 'Settings': return 'settings';
      case 'User': return 'users';
      case 'Purchase': return 'purchases';
      case 'PurchaseItem': return 'purchase_items';
      case 'Expense': return 'expenses';
      case 'ExpenseItem': return 'expense_items';
      case 'Transaction': return 'transactions';
      case 'BankAccount': return 'bank_accounts';`;

const newGetCollection = `  String _getFirestoreCollection(String entityType, [dynamic entity]) {
    switch (entityType) {
      case 'Party': return 'parties';
      case 'Item': return 'items';
      case 'Category': return 'categories';
      case 'Unit': return 'units';
      case 'Brand': return 'brands';
      case 'Order': return 'orders';
      case 'OrderItem': return 'order_items';
      case 'Invoice': return 'invoices';
      case 'InvoiceItem': return 'invoice_items';
      case 'Settings': return 'settings';
      case 'User': return 'users';
      case 'Purchase': return 'purchases';
      case 'PurchaseItem': return 'purchase_items';
      case 'Expense': return 'expenses';
      case 'ExpenseItem': return 'expense_items';
      case 'Transaction':
        if (entity != null) {
          final t = entity as Transaction;
          final type = t.transactionType?.toLowerCase().replaceAll(' ', '_') ?? 'unknown';
          return 'transactions_$type';
        }
        return 'transactions';
      // Sub-transaction types for downloading
      case 'Transaction_receipt': return 'transactions_receipt';
      case 'Transaction_payment': return 'transactions_payment';
      case 'Transaction_other_income': return 'transactions_other_income';
      case 'Transaction_credit_note': return 'transactions_credit_note';
      case 'Transaction_debit_note': return 'transactions_debit_note';
      case 'Transaction_transfer': return 'transactions_transfer';
      case 'Transaction_journal': return 'transactions_journal';
      case 'Transaction_unknown': return 'transactions_unknown';
      case 'BankAccount': return 'bank_accounts';`;

content = content.replace(oldGetCollection, newGetCollection);

// Update _uploadLocalUpdates to pass entity
const oldUploadCollection = `      final collectionName = _getFirestoreCollection(entityType);
      final docRef = _firebaseService.firestore.collection(collectionName).doc(entityIdStr);`;

const newUploadCollection = `      final collectionName = _getFirestoreCollection(entityType, entity);
      final docRef = _firebaseService.firestore.collection(collectionName).doc(entityIdStr);`;
content = content.replace(oldUploadCollection, newUploadCollection);

// Update entity lists to include the sub-transaction types
const oldEntityList1 = `    final allEntityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
      'Purchase', 'PurchaseItem', 'Expense', 'ExpenseItem', 'Transaction',
      'BankAccount', 'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem',
      'StockAdjustment', 'WhatsAppMapping', 'Task', 'Machinery'
    ];`;

const newEntityList1 = `    final allEntityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
      'Purchase', 'PurchaseItem', 'Expense', 'ExpenseItem', 
      'Transaction_receipt', 'Transaction_payment', 'Transaction_other_income', 
      'Transaction_credit_note', 'Transaction_debit_note', 'Transaction_transfer', 
      'Transaction_journal', 'Transaction_unknown',
      'BankAccount', 'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem',
      'StockAdjustment', 'WhatsAppMapping', 'Task', 'Machinery'
    ];`;

content = content.replaceAll(oldEntityList1, newEntityList1);

const oldEntityList2 = `    final entityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
      'Purchase', 'PurchaseItem', 'Expense', 'ExpenseItem', 'Transaction', 'BankAccount',
      'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem', 'WhatsAppMapping', 'Task', 'Machinery'
    ];`;

const newEntityList2 = `    final entityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
      'Purchase', 'PurchaseItem', 'Expense', 'ExpenseItem',
      'Transaction_receipt', 'Transaction_payment', 'Transaction_other_income', 
      'Transaction_credit_note', 'Transaction_debit_note', 'Transaction_transfer', 
      'Transaction_journal', 'Transaction_unknown',
      'BankAccount',
      'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem', 'WhatsAppMapping', 'Task', 'Machinery'
    ];`;
content = content.replaceAll(oldEntityList2, newEntityList2);

// Fix mapped entityType for downloading
const oldMapType = `          for (int d = 0; d < allDocs.length; d++) {
            if (kIsWeb ? (d % 5 == 0) : (d % 10 == 0)) await Future.delayed(Duration.zero);
            try {
              final doc = allDocs[d];
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) continue;
              final uuid = data['uuid'] as String?;
              if (uuid == null || uuid.isEmpty) continue;`;

const newMapType = `          for (int d = 0; d < allDocs.length; d++) {
            if (kIsWeb ? (d % 5 == 0) : (d % 10 == 0)) await Future.delayed(Duration.zero);
            try {
              final doc = allDocs[d];
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) continue;
              final uuid = data['uuid'] as String?;
              if (uuid == null || uuid.isEmpty) continue;
              
              String mappedEntityType = entityType;
              if (mappedEntityType.startsWith('Transaction_')) {
                mappedEntityType = 'Transaction';
              }`;
content = content.replaceAll(oldMapType, newMapType);

const oldSwitch = `            switch (entityType) {
              case 'Party': localRecord = await isar.partys.filter().uuidEqualTo(uuid).findFirst(); break;`;
              
const newSwitch = `            switch (mappedEntityType) {
              case 'Party': localRecord = await isar.partys.filter().uuidEqualTo(uuid).findFirst(); break;`;
content = content.replaceAll(oldSwitch, newSwitch);

const oldConflict1 = `              if (_getEntityIsSynced(entityType, localRecord) == false) {
                logger.info('Conflict: Local Wins (Unsynced Local Draft Lock) for $entityType UUID: $uuid. Keeping local draft.');
                await _logConflictEvent(entityType, uuid, data['version'] as int? ?? 1, _getEntityVersion(entityType, localRecord), 'Local Wins (Unsynced Draft Lock)');
                continue;
              }

              final localVersion = (_getEntityVersion(entityType, localRecord) as int?) ?? 1;
              final remoteVersion = data['version'] as int? ?? 1;
              final localUpdated = (_getEntityUpdatedAt(entityType, localRecord) as DateTime?) ?? DateTime.fromMillisecondsSinceEpoch(0);
              final remoteUpdated = DateTime.tryParse(data['updatedAt'] as String? ?? '') ?? DateTime.now();

              bool remoteWins = false;
              if (remoteVersion > localVersion) {
                remoteWins = true;
              } else if (remoteVersion == localVersion) {
                if (remoteUpdated.isAfter(localUpdated)) {
                  remoteWins = true;
                }
              }

              if (remoteWins) {
                logger.info('Conflict: Remote wins for $entityType UUID: $uuid. Overwriting local.');
                await _overwriteLocalRecord(entityType, _getEntityId(entityType, localRecord), data);
                await _logConflictEvent(entityType, uuid, remoteVersion, localVersion, 'Remote Wins');
              } else {
                logger.info('Conflict: Local wins for $entityType UUID: $uuid.');
                await _logConflictEvent(entityType, uuid, remoteVersion, localVersion, 'Local Wins');
              }
            } else {
              if (data['isDeleted'] == true) continue;
              await _insertLocalRecord(entityType, data);
            }`;

const newConflict1 = `              if (_getEntityIsSynced(mappedEntityType, localRecord) == false) {
                logger.info('Conflict: Local Wins (Unsynced Local Draft Lock) for $mappedEntityType UUID: $uuid. Keeping local draft.');
                await _logConflictEvent(mappedEntityType, uuid, data['version'] as int? ?? 1, _getEntityVersion(mappedEntityType, localRecord), 'Local Wins (Unsynced Draft Lock)');
                continue;
              }

              final localVersion = (_getEntityVersion(mappedEntityType, localRecord) as int?) ?? 1;
              final remoteVersion = data['version'] as int? ?? 1;
              final localUpdated = (_getEntityUpdatedAt(mappedEntityType, localRecord) as DateTime?) ?? DateTime.fromMillisecondsSinceEpoch(0);
              final remoteUpdated = DateTime.tryParse(data['updatedAt'] as String? ?? '') ?? DateTime.now();

              bool remoteWins = false;
              if (remoteVersion > localVersion) {
                remoteWins = true;
              } else if (remoteVersion == localVersion) {
                if (remoteUpdated.isAfter(localUpdated)) {
                  remoteWins = true;
                }
              }

              if (remoteWins) {
                logger.info('Conflict: Remote wins for $mappedEntityType UUID: $uuid. Overwriting local.');
                await _overwriteLocalRecord(mappedEntityType, _getEntityId(mappedEntityType, localRecord), data);
                await _logConflictEvent(mappedEntityType, uuid, remoteVersion, localVersion, 'Remote Wins');
              } else {
                logger.info('Conflict: Local wins for $mappedEntityType UUID: $uuid.');
                await _logConflictEvent(mappedEntityType, uuid, remoteVersion, localVersion, 'Local Wins');
              }
            } else {
              if (data['isDeleted'] == true) continue;
              await _insertLocalRecord(mappedEntityType, data);
            }`;
content = content.replaceAll(oldConflict1, newConflict1);

fs.writeFileSync(path, content, 'utf8');
console.log('Updated sync_service.dart');
