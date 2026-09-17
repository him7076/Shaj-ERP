import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:business_sahaj_erp/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  Future<void> migrateLegacyItemsToParentDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final hasMigrated = prefs.getBool('has_migrated_items_to_parents') ?? false;
    
    if (hasMigrated) {
      logger.info('Migration already completed previously.');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      logger.warning('User not authenticated, cannot run migration.');
      return;
    }
    
    final companyId = prefs.getString('company_id') ?? user.uid;
    
    try {
      logger.info('Starting legacy items migration to parent documents...');
      
      // 1. Migrate Invoice Items
      await _migrateCollection(
        companyId: companyId,
        parentCollection: 'invoices',
        childCollection: 'invoice_items',
        parentKeyField: 'uuid',
        childRefField: 'parentInvoiceUuid',
      );

      // 2. Migrate Order Items
      await _migrateCollection(
        companyId: companyId,
        parentCollection: 'orders',
        childCollection: 'order_items',
        parentKeyField: 'uuid',
        childRefField: 'orderUuid',
      );

      await prefs.setBool('has_migrated_items_to_parents', true);
      logger.info('Legacy items migration completed successfully.');
    } catch (e) {
      logger.severe('Migration failed: $e');
    }
  }

  Future<void> _migrateCollection({
    required String companyId,
    required String parentCollection,
    required String childCollection,
    required String parentKeyField,
    required String childRefField,
  }) async {
    logger.info('Migrating $childCollection into $parentCollection...');
    
    // Fetch all child items
    final childQuery = await _firestore
        .collection(childCollection)
        .where('companyId', isEqualTo: companyId)
        .get();

    if (childQuery.docs.isEmpty) {
      logger.info('No items found in $childCollection to migrate.');
      return;
    }

    // Group children by parent reference
    final Map<String, List<Map<String, dynamic>>> groupedChildren = {};
    for (var doc in childQuery.docs) {
      final data = doc.data();
      final parentRef = data[childRefField] as String?;
      if (parentRef != null && parentRef.isNotEmpty) {
        data['uuid'] = data['uuid'] ?? doc.id; // ensure uuid exists
        groupedChildren.putIfAbsent(parentRef, () => []).add(data);
      }
    }

    logger.info('Found ${groupedChildren.length} unique parents in $childCollection to migrate.');

    // Update parents in batches
    final batch = _firestore.batch();
    int batchCount = 0;
    
    for (var entry in groupedChildren.entries) {
      final parentRef = entry.key;
      final children = entry.value;

      final parentQuery = await _firestore
          .collection(parentCollection)
          .where('companyId', isEqualTo: companyId)
          .where(parentKeyField, isEqualTo: parentRef)
          .limit(1)
          .get();

      if (parentQuery.docs.isNotEmpty) {
        final parentDoc = parentQuery.docs.first;
        batch.update(parentDoc.reference, {
          'items': children,
        });
        batchCount++;

        // Commit batch every 400 operations to avoid limit (500)
        if (batchCount >= 400) {
          await batch.commit();
          logger.info('Committed batch of 400 $parentCollection updates.');
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
      logger.info('Committed final batch of $batchCount $parentCollection updates.');
    }
    
    // Optional: We can delete the old collections here, but to be safe and avoid hitting quota,
    // we can just leave them since we no longer read from them via sync loop (only as legacy fallback).
  }
}
