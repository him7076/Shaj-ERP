import 'package:business_sahaj_erp/domain/models/backup_history_entry.dart';
import 'package:business_sahaj_erp/domain/repositories/backup_repository.dart';
import 'package:business_sahaj_erp/core/services/backup_service.dart';

class BackupRepositoryImpl implements BackupRepository {
  final BackupService _backupService;

  BackupRepositoryImpl(this._backupService);

  @override
  Future<BackupHistoryEntry> performBackup({
    String? password,
    bool includeImages = true,
    bool uploadToCloud = false,
  }) {
    return _backupService.createBackup(
      password: password,
      includeImages: includeImages,
      uploadToCloud: uploadToCloud,
    );
  }

  @override
  Future<List<BackupHistoryEntry>> getHistory() {
    return _backupService.getBackupHistory();
  }

  @override
  Future<void> removeBackup(BackupHistoryEntry entry) {
    return _backupService.deleteBackup(entry);
  }

  @override
  Future<void> autoCleanup() {
    return _backupService.autoCleanupBackups();
  }
}
