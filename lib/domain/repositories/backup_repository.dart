import 'package:business_sahaj_erp/domain/models/backup_history_entry.dart';

abstract class BackupRepository {
  Future<BackupHistoryEntry> performBackup({
    String? password,
    bool includeImages = true,
    bool uploadToCloud = false,
  });

  Future<List<BackupHistoryEntry>> getHistory();

  Future<void> removeBackup(BackupHistoryEntry entry);

  Future<void> autoCleanup();
}
