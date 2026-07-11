import 'package:business_sahaj_erp/domain/models/backup_metadata.dart';

abstract class RestoreRepository {
  Future<BackupMetadata> validate(
    String filePath, {
    String? password,
  });

  Future<void> restore(
    String filePath, {
    String? password,
    bool restoreParties = true,
    bool restoreItems = true,
    bool restoreOrders = true,
    bool restoreInvoices = true,
    bool restoreSettings = true,
    String duplicateStrategy = 'replace',
  });
}
