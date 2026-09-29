const fs = require('fs');
const path = 'c:\\Users\\lenovo\\Desktop\\Shaj ERP\\lib\\core\\services\\sync_service.dart';
let content = fs.readFileSync(path, 'utf8');

function replaceBetween(startStr, endStr, newContent) {
    const startIdx = content.indexOf(startStr);
    if (startIdx === -1) { console.log('Could not find:', startStr.substring(0, 50)); return false; }
    const endIdx = content.indexOf(endStr, startIdx);
    if (endIdx === -1) { console.log('Could not find end:', endStr); return false; }
    content = content.substring(0, startIdx) + newContent + content.substring(endIdx + endStr.length);
    return true;
}

// 1. Purge Local DB
replaceBetween(
    'try {\r\n      // 1. Clear ALL sync timestamps (main + per-entity)',
    'await DemoDataSeeder.seedStandardUnits(_dbService);',
    `try {
      // 1. Clear ALL sync timestamps (main + per-entity) so incremental filter is FULLY disabled.
      final activeFirmId = _dbService.activeFirmId;
      await _prefs.remove('\${AppConstants.keyLastSyncTime}_$activeFirmId');
      await _prefs.remove(AppConstants.keyLastSyncTime);

      // Clear all firm-specific per-entity timestamps to force full fresh download
      final allEntityTypes = [
        'Category', 'Unit', 'Brand', 'Party', 'Item',
        'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
        'Purchase', 'PurchaseItem', 'Expense', 'ExpenseItem', 'Transaction',
        'BankAccount', 'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem',
        'StockAdjustment', 'WhatsAppMapping', 'Task', 'Machinery'
      ];
      for (final et in allEntityTypes) {
        await _prefs.remove('last_cloud_sync_timestamp_$et');
        await _prefs.remove('last_cloud_sync_timestamp_\${activeFirmId}_$et');
      }
      logger.info('Cleared all entity-level sync timestamps for firm: $activeFirmId — forcing full fresh download.');

      // 2. PURGE local database completely before downloading fresh cloud data.
      //    This prevents conflict resolution from blocking cloud records.
      //    On "Sync Data from Cloud", user intent is CLEAR: reset local, get fresh cloud copy.
      logger.info('Purging local Isar database for firm: $activeFirmId before fresh cloud download...');
      await _dbService.clearDatabase();
      logger.info('Local database purged successfully. Ready for fresh cloud download.');

      // 3. Re-seed standard commercial units in local DB
      await DemoDataSeeder.seedStandardUnits(_dbService);`
);

// Note: checking CRLF vs LF. Let's make it robust by using regex for finding the block or normalizing content.
// A more robust replacement:
content = content.replace(
    /try \{\s*\/\/\ 1\.\ Clear ALL sync timestamps.*?\/\/ 3\.\ Re-seed standard commercial units in local DB\s*await DemoDataSeeder\.seedStandardUnits\(_dbService\);/s,
    `try {
      // 1. Clear ALL sync timestamps (main + per-entity) so incremental filter is FULLY disabled.
      final activeFirmId = _dbService.activeFirmId;
      await _prefs.remove('\${AppConstants.keyLastSyncTime}_$activeFirmId');
      await _prefs.remove(AppConstants.keyLastSyncTime);

      // Clear all firm-specific per-entity timestamps to force full fresh download
      final allEntityTypes = [
        'Category', 'Unit', 'Brand', 'Party', 'Item',
        'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
        'Purchase', 'PurchaseItem', 'Expense', 'ExpenseItem', 'Transaction',
        'BankAccount', 'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem',
        'StockAdjustment', 'WhatsAppMapping', 'Task', 'Machinery'
      ];
      for (final et in allEntityTypes) {
        await _prefs.remove('last_cloud_sync_timestamp_$et');
        await _prefs.remove('last_cloud_sync_timestamp_\${activeFirmId}_$et');
      }
      logger.info('Cleared all entity-level sync timestamps for firm: $activeFirmId — forcing full fresh download.');

      // 2. PURGE local database completely before downloading fresh cloud data.
      logger.info('Purging local Isar database for firm: $activeFirmId before fresh cloud download...');
      await _dbService.clearDatabase();
      logger.info('Local database purged successfully. Ready for fresh cloud download.');

      // 3. Re-seed standard commercial units in local DB
      await DemoDataSeeder.seedStandardUnits(_dbService);`
);


// 2 & 3. Pagination and Docs length
content = content.replace(
    /\/\/\ Step 1:\ Compound query.*?\n\s*for\s*\(\s*int\s+d\s*=\s*0;\s*d\s*<\s*querySnapshot\.docs\.length;\s*d\+\+\s*\)\s*\{/s,
    `// Step 1: Paginated compound query (companyId + firmId + filterCutoff)
        List<dynamic> allDocs = [];
        try {
          var baseQuery = _firebaseService.firestore
              .collection(collectionName)
              .where('companyId', isEqualTo: companyId)
              .where('firmId', isEqualTo: activeFirmId);

          if (filterCutoff != null) {
            baseQuery = baseQuery.where('updatedAt', isGreaterThan: filterCutoff.toUtc().toIso8601String());
          }

          dynamic lastDoc;
          bool hasMore = true;
          while (hasMore) {
            var pageQuery = baseQuery.limit(500);
            if (lastDoc != null) {
              pageQuery = pageQuery.startAfterDocument(lastDoc);
            }
            final pageSnapshot = await pageQuery.get().timeout(const Duration(seconds: 60));
            if (pageSnapshot.docs.isEmpty) {
              hasMore = false;
            } else {
              allDocs.addAll(pageSnapshot.docs);
              lastDoc = pageSnapshot.docs.last;
              if (pageSnapshot.docs.length < 500) {
                hasMore = false;
              }
              await Future.delayed(const Duration(milliseconds: 50));
            }
          }
        } catch (e1) {
          logger.warning('Primary paginated query failed for $entityType: $e1. Trying firmId-only query...');
        }

        // Step 2: Fallback to firmId-only paginated query
        if (allDocs.isEmpty) {
          try {
            var firmBaseQuery = _firebaseService.firestore
                .collection(collectionName)
                .where('firmId', isEqualTo: activeFirmId);
            if (filterCutoff != null) {
              firmBaseQuery = firmBaseQuery.where('updatedAt', isGreaterThan: filterCutoff.toUtc().toIso8601String());
            }
            
            dynamic lastDoc;
            bool hasMore = true;
            while (hasMore) {
              var pageQuery = firmBaseQuery.limit(500);
              if (lastDoc != null) {
                pageQuery = pageQuery.startAfterDocument(lastDoc);
              }
              final pageSnapshot = await pageQuery.get().timeout(const Duration(seconds: 60));
              if (pageSnapshot.docs.isEmpty) {
                hasMore = false;
              } else {
                allDocs.addAll(pageSnapshot.docs);
                lastDoc = pageSnapshot.docs.last;
                if (pageSnapshot.docs.length < 500) hasMore = false;
                await Future.delayed(const Duration(milliseconds: 50));
              }
            }
          } catch (e2) {
            logger.warning('Firm-only paginated query also failed for $entityType: $e2. Skipping.');
          }
        }

        if (allDocs.isEmpty) {
          logger.info('  No documents found for $entityType (companyId=$companyId, firmId=$activeFirmId).');
          continue;
        }

        logger.info('  Found \${allDocs.length} documents for $entityType — processing...');
        await prefs.setString(timestampKey, DateTime.now().toUtc().toIso8601String());

        for (int d = 0; d < allDocs.length; d++) {`
);

// 4A. CreditNote Upload Map
content = content.replace(
    /case\s+'CreditNote':\s*final\s+e\s*=\s*entity\s*as\s*CreditNote;\s*return\s*baseMap\.\.addAll\(\{.*?partyUuid':\s*e\.party\.value\?\.uuid,\s*\}\);/s,
    `case 'CreditNote':
        final e = entity as CreditNote;
        final isarRefCN = _dbService.isar;
        final cnItemsQuery = isarRefCN.creditNoteItems.filter().isDeletedEqualTo(false).and().group((q) {
          var sq = q.parentCreditNoteIdEqualTo(e.id);
          if (e.uuid != null && e.uuid!.isNotEmpty) {
            sq = sq.or().creditNoteUuidEqualTo(e.uuid!);
          }
          return sq;
        });
        List rawCNItems = [];
        try { rawCNItems = await cnItemsQuery.findAll(); } catch (_) {}

        final cnItemsMapList = rawCNItems.map((item) => {
          'uuid': item.uuid,
          'itemId': item.itemId,
          'itemName': item.itemName,
          'hsnCode': item.hsnCode,
          'quantity': item.quantity,
          'freeQuantity': item.freeQuantity,
          'rate': item.rate,
          'discount': item.discount,
          'taxableAmount': item.taxableAmount,
          'gstRate': item.gstRate,
          'gstAmount': item.gstAmount,
          'totalAmount': item.totalAmount,
          'itemUuid': item.item.value?.uuid,
        }).toList();

        return baseMap..addAll({
          'creditNoteNumber': e.creditNoteNumber,
          'creditNoteDate': e.creditNoteDate?.toIso8601String(),
          'originalInvoiceNumber': e.originalInvoiceNumber,
          'originalInvoiceUuid': e.originalInvoiceUuid,
          'partyId': e.partyId,
          'partyName': e.partyName,
          'gstNumber': e.gstNumber,
          'address': e.address,
          'subtotal': e.subtotal,
          'discountAmount': e.discountAmount,
          'taxableAmount': e.taxableAmount,
          'cgstAmount': e.cgstAmount,
          'sgstAmount': e.sgstAmount,
          'igstAmount': e.igstAmount,
          'totalGST': e.totalGST,
          'roundOff': e.roundOff,
          'grandTotal': e.grandTotal,
          'remarks': e.remarks,
          'createdBy': e.createdBy,
          'partyUuid': e.party.value?.uuid,
          'items': cnItemsMapList,
        });`
);

// 4B. DebitNote Upload Map
content = content.replace(
    /case\s+'DebitNote':\s*final\s+e\s*=\s*entity\s*as\s*DebitNote;\s*return\s*baseMap\.\.addAll\(\{.*?partyUuid':\s*e\.party\.value\?\.uuid,\s*\}\);/s,
    `case 'DebitNote':
        final e = entity as DebitNote;
        final isarRefDN = _dbService.isar;
        final dnItemsQuery = isarRefDN.debitNoteItems.filter().isDeletedEqualTo(false).and().group((q) {
          var sq = q.parentDebitNoteIdEqualTo(e.id);
          if (e.uuid != null && e.uuid!.isNotEmpty) {
            sq = sq.or().debitNoteUuidEqualTo(e.uuid!);
          }
          return sq;
        });
        List rawDNItems = [];
        try { rawDNItems = await dnItemsQuery.findAll(); } catch (_) {}

        final dnItemsMapList = rawDNItems.map((item) => {
          'uuid': item.uuid,
          'itemId': item.itemId,
          'itemName': item.itemName,
          'hsnCode': item.hsnCode,
          'quantity': item.quantity,
          'freeQuantity': item.freeQuantity,
          'rate': item.rate,
          'discount': item.discount,
          'taxableAmount': item.taxableAmount,
          'gstRate': item.gstRate,
          'gstAmount': item.gstAmount,
          'totalAmount': item.totalAmount,
          'itemUuid': item.item.value?.uuid,
        }).toList();

        return baseMap..addAll({
          'debitNoteNumber': e.debitNoteNumber,
          'debitNoteDate': e.debitNoteDate?.toIso8601String(),
          'originalPurchaseNumber': e.originalPurchaseNumber,
          'originalPurchaseUuid': e.originalPurchaseUuid,
          'partyId': e.partyId,
          'partyName': e.partyName,
          'gstNumber': e.gstNumber,
          'address': e.address,
          'subtotal': e.subtotal,
          'discountAmount': e.discountAmount,
          'taxableAmount': e.taxableAmount,
          'cgstAmount': e.cgstAmount,
          'sgstAmount': e.sgstAmount,
          'igstAmount': e.igstAmount,
          'totalGST': e.totalGST,
          'roundOff': e.roundOff,
          'grandTotal': e.grandTotal,
          'remarks': e.remarks,
          'createdBy': e.createdBy,
          'partyUuid': e.party.value?.uuid,
          'items': dnItemsMapList,
        });`
);

// 5. Remove separate line item uploads
content = content.replace(
    /await\s+processEnqueuing<InvoiceItem>\(.*?\);\n?/g,
    `// REMOVED: InvoiceItem uploaded separately\n`
);
content = content.replace(
    /await\s+processEnqueuing<PurchaseItem>\(.*?\);\n?/g,
    `// REMOVED: PurchaseItem uploaded separately\n`
);
content = content.replace(
    /await\s+processEnqueuing<OrderItem>\(.*?\);\n?/g,
    `// REMOVED: OrderItem uploaded separately\n`
);
content = content.replace(
    /await\s+processEnqueuing<CreditNoteItem>\(.*?\);\n?/g,
    `// REMOVED: CreditNoteItem uploaded separately\n`
);
content = content.replace(
    /await\s+processEnqueuing<DebitNoteItem>\(.*?\);\n?/g,
    `// REMOVED: DebitNoteItem uploaded separately\n`
);

// 6. Sync Conflict Log Writes
content = content.replace(
    /Future<void>\s+_logConflictEvent\([\s\S]*?try\s*\{\s*await\s+_firebaseService\.firestore\.collection\('sync_logs'\)\.add\(\{[\s\S]*?\}\);\s*\}\s*catch\s*\(e\)\s*\{\s*logger\.error\('Failed to write conflict log entry to Firestore',\s*e\);\s*\}/,
    `Future<void> _logConflictEvent(
    String entityType,
    String uuid,
    int remoteVersion,
    int localVersion,
    String resolution,
  ) async {
    // Store conflict logs locally only to save Firebase writes (Free Plan)
    try {
      final logMsg = '[\$resolution] \${DateTime.now().toIso8601String()}: \$entityType (\$uuid) Remote v\$remoteVersion vs Local v\$localVersion';
      logger.info('Sync Conflict: \$logMsg');
      // Save to local prefs only — not Firestore
      final existingLogs = _prefs.getStringList('sync_conflict_logs') ?? [];
      existingLogs.add(logMsg);
      // Keep only last 100 conflict logs to prevent prefs bloat
      if (existingLogs.length > 100) {
        await _prefs.setStringList('sync_conflict_logs', existingLogs.sublist(existingLogs.length - 100));
      } else {
        await _prefs.setStringList('sync_conflict_logs', existingLogs);
      }
    } catch (e) {
      logger.error('Failed to write conflict log', e);
    }`
);

fs.writeFileSync(path, content);
console.log("SUCCESS");
