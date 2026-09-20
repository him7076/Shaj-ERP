import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/data/local/collections/fixed_asset_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/fixed_asset_transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/fixed_asset_repository.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';

class FixedAssetRepositoryImpl implements FixedAssetRepository {
  final Isar isar;
  
  FixedAssetRepositoryImpl(this.isar);

  @override
  Future<void> purchaseAsset(FixedAsset asset, FixedAssetTransaction faTxn) async {
    try {
      await isar.writeTxn(() async {
        if (asset.uuid == null || asset.uuid!.isEmpty) {
          asset.uuid = const Uuid().v4();
        }
        
        await isar.fixedAssets.put(asset);

        faTxn.assetId = asset.id;
        faTxn.assetUuid = asset.uuid;
        faTxn.transactionType = 'Purchase';
        if (faTxn.uuid == null || faTxn.uuid!.isEmpty) {
          faTxn.uuid = const Uuid().v4();
        }

        await isar.fixedAssetTransactions.put(faTxn);
        
        // Also book to general Transaction ledger if there's payment involved
        if (faTxn.amount > 0) {
          final ledgerTxn = Transaction()
            ..uuid = const Uuid().v4()
            ..transactionNumber = 'FA-PUR-${DateTime.now().millisecondsSinceEpoch}'
            ..transactionDate = faTxn.transactionDate ?? DateTime.now()
            ..transactionType = 'Expense' // Treating FA Purchase as a capital expense payment out
            ..amount = faTxn.amount
            ..paymentMode = 'Bank' // Could be mapped from FA Txn
            ..remarks = 'Fixed Asset Purchase: ${asset.assetName}'
            ..referenceNumber = faTxn.uuid;
          
          await isar.transactions.put(ledgerTxn);
        }
      });
    } catch (e) {
      throw DatabaseException('Failed to purchase fixed asset: $e');
    }
  }

  @override
  Future<void> depreciateAsset(FixedAsset asset, FixedAssetTransaction faTxn) async {
    try {
      await isar.writeTxn(() async {
        asset.accumulatedDepreciation += faTxn.amount;
        asset.bookValue = asset.purchaseCost - asset.accumulatedDepreciation;
        asset.updatedAt = DateTime.now();
        await isar.fixedAssets.put(asset);

        faTxn.assetId = asset.id;
        faTxn.assetUuid = asset.uuid;
        faTxn.transactionType = 'Depreciation';
        if (faTxn.uuid == null || faTxn.uuid!.isEmpty) {
          faTxn.uuid = const Uuid().v4();
        }

        await isar.fixedAssetTransactions.put(faTxn);

        // Book depreciation expense to ledger
        final ledgerTxn = Transaction()
          ..uuid = const Uuid().v4()
          ..transactionNumber = 'FA-DEP-${DateTime.now().millisecondsSinceEpoch}'
          ..transactionDate = faTxn.transactionDate ?? DateTime.now()
          ..transactionType = 'Expense' 
          ..amount = faTxn.amount
          ..paymentMode = 'Non-Cash'
          ..remarks = 'Depreciation on ${asset.assetName}'
          ..referenceNumber = faTxn.uuid;
        
        await isar.transactions.put(ledgerTxn);
      });
    } catch (e) {
      throw DatabaseException('Failed to depreciate fixed asset: $e');
    }
  }

  @override
  Future<void> sellAsset(FixedAsset asset, FixedAssetTransaction faTxn) async {
    try {
      await isar.writeTxn(() async {
        asset.status = 'Sold';
        asset.updatedAt = DateTime.now();
        await isar.fixedAssets.put(asset);

        faTxn.assetId = asset.id;
        faTxn.assetUuid = asset.uuid;
        faTxn.transactionType = 'Disposal';
        if (faTxn.uuid == null || faTxn.uuid!.isEmpty) {
          faTxn.uuid = const Uuid().v4();
        }

        await isar.fixedAssetTransactions.put(faTxn);

        // Book receipt in ledger
        final ledgerTxn = Transaction()
          ..uuid = const Uuid().v4()
          ..transactionNumber = 'FA-SEL-${DateTime.now().millisecondsSinceEpoch}'
          ..transactionDate = faTxn.transactionDate ?? DateTime.now()
          ..transactionType = 'Other Income' 
          ..amount = faTxn.amount
          ..paymentMode = 'Bank'
          ..remarks = 'Sale of Fixed Asset: ${asset.assetName}'
          ..referenceNumber = faTxn.uuid;
        
        await isar.transactions.put(ledgerTxn);
      });
    } catch (e) {
      throw DatabaseException('Failed to sell fixed asset: $e');
    }
  }

  @override
  Future<List<FixedAsset>> getAllAssets() async {
    try {
      return await isar.fixedAssets.filter().isDeletedEqualTo(false).findAll();
    } catch (e) {
      throw DatabaseException('Failed to fetch fixed assets: $e');
    }
  }

  @override
  Future<List<FixedAssetTransaction>> getTransactionsForAsset(int assetId) async {
    try {
      return await isar.fixedAssetTransactions.filter().assetIdEqualTo(assetId).isDeletedEqualTo(false).sortByTransactionDateDesc().findAll();
    } catch (e) {
      throw DatabaseException('Failed to fetch FA transactions: $e');
    }
  }
}
