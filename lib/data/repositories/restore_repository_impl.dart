import 'package:business_sahaj_erp/domain/models/backup_metadata.dart';
import 'package:business_sahaj_erp/domain/repositories/restore_repository.dart';
import 'package:business_sahaj_erp/core/services/restore_service.dart';

class RestoreRepositoryImpl implements RestoreRepository {
  final RestoreService _restoreService;

  RestoreRepositoryImpl(this._restoreService);

  @override
  Future<BackupMetadata> validate(
    String filePath, {
    String? password,
  }) {
    return _restoreService.validateBackup(filePath, password: password);
  }

  @override
  Future<void> restore(
    String filePath, {
    String? password,
    bool restoreParties = true,
    bool restoreItems = true,
    bool restoreOrders = true,
    bool restoreInvoices = true,
    bool restoreSettings = true,
    String duplicateStrategy = 'replace',
  }) {
    return _restoreService.restoreBackup(
      filePath,
      password: password,
      restoreParties: restoreParties,
      restoreItems: restoreItems,
      restoreOrders: restoreOrders,
      restoreInvoices: restoreInvoices,
      restoreSettings: restoreSettings,
      duplicateStrategy: duplicateStrategy,
    );
  }
}
