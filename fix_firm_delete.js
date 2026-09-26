const fs = require('fs');
const path = require('path');

// 1. Update DatabaseService
const dbServiceFile = path.join(__dirname, 'lib/core/services/database_service.dart');
let dbContent = fs.readFileSync(dbServiceFile, 'utf8');

if (!dbContent.includes('Future<void> deleteFirmData')) {
    const importIo = "import 'dart:io';\n";
    if (!dbContent.includes(importIo)) {
        dbContent = importIo + dbContent;
    }
    
    const dbInjection = `
  /// Deletes the local Isar database files for a specific firm
  Future<void> deleteFirmData(String firmId) async {
    try {
      if (kIsWeb) return;
      
      final instance = Isar.getInstance(firmId);
      if (instance != null && instance.isOpen) {
        await instance.close();
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File('\${dir.path}/$firmId.isar');
      final lockFile = File('\${dir.path}/$firmId.isar.lock');
      
      if (await dbFile.exists()) await dbFile.delete();
      if (await lockFile.exists()) await lockFile.delete();
      logger.info('Deleted local database files for firm $firmId');
    } catch (e) {
      logger.error('Failed to delete firm data', e);
    }
  }
`;
    dbContent = dbContent.replace(/Future<void> clearDatabase\(\) async \{/, dbInjection + '\n  Future<void> clearDatabase() async {');
    fs.writeFileSync(dbServiceFile, dbContent, 'utf8');
}

// 2. Update SyncService
const syncServiceFile = path.join(__dirname, 'lib/core/services/sync_service.dart');
let syncContent = fs.readFileSync(syncServiceFile, 'utf8');

if (!syncContent.includes('Future<void> clearCloudDataForFirm')) {
    const syncInjection = `
  /// Deletes all documents belonging to a specific firm from Firestore (Hard Delete)
  Future<void> clearCloudDataForFirm(String firmId) async {
    await _firebaseService.ensureAuthenticated();
    if (!_firebaseService.isAuthenticated) return;

    final companyId = _firebaseService.companyId;
    logger.info('Wiping all remote Firestore documents for firm: $firmId');

    final entityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
      'Purchase', 'PurchaseItem', 'Expense', 'Transaction', 'BankAccount',
      'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem', 'WhatsAppMapping', 'Task', 'Machinery'
    ];

    for (var entityType in entityTypes) {
      final collectionName = _getFirestoreCollection(entityType);
      QuerySnapshot? querySnapshot;

      try {
        querySnapshot = await _firebaseService.firestore
            .collection(collectionName)
            .where('companyId', isEqualTo: companyId)
            .where('firmId', isEqualTo: firmId)
            .get();
      } catch (e1) {
        try {
          querySnapshot = await _firebaseService.firestore
              .collection(collectionName)
              .where('firmId', isEqualTo: firmId)
              .get();
        } catch (_) {}
      }

      if (querySnapshot != null && querySnapshot.docs.isNotEmpty) {
        try {
          for (var i = 0; i < querySnapshot.docs.length; i += 450) {
            final chunk = querySnapshot.docs.skip(i).take(450);
            final batch = _firebaseService.firestore.batch();
            for (var doc in chunk) {
              batch.delete(doc.reference); // Hard delete
            }
            await batch.commit();
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } catch (e) {
          logger.error('Failed to hard delete chunk for $entityType', e);
        }
      }
    }
    
    // Also delete the firm document itself
    try {
       await _firebaseService.firestore.collection('firms').doc(firmId).delete();
    } catch (_) {}
  }
`;
    syncContent = syncContent.replace(/Future<void> clearCloudDataForActiveFirm\(\) async \{/, syncInjection + '\n  Future<void> clearCloudDataForActiveFirm() async {');
    fs.writeFileSync(syncServiceFile, syncContent, 'utf8');
}

// 3. Update Settings Screen
const settingsFile = path.join(__dirname, 'lib/features/settings/presentation/screens/settings_screen.dart');
let settingsContent = fs.readFileSync(settingsFile, 'utf8');

const oldCode = `              try {
                await ref.read(syncServiceProvider).deleteRemoteFirm(firmId);
              } catch (_) {}`;
              
const newCode = `              try {
                // Delete all cloud data for the firm completely
                await ref.read(syncServiceProvider).clearCloudDataForFirm(firmId);
                // Also delete local data for this firm completely
                await ref.read(databaseServiceProvider).deleteFirmData(firmId);
              } catch (e) {
                 debugPrint('Error deleting firm data completely: $e');
              }`;

if (settingsContent.includes(oldCode)) {
    settingsContent = settingsContent.replace(oldCode, newCode);
    fs.writeFileSync(settingsFile, settingsContent, 'utf8');
}

console.log('Fixed firm hard deletion logic.');
