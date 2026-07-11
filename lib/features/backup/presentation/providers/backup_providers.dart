import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/domain/models/backup_history_entry.dart';
import 'package:business_sahaj_erp/domain/models/backup_metadata.dart';
import 'package:business_sahaj_erp/domain/repositories/backup_repository.dart';
import 'package:business_sahaj_erp/domain/repositories/restore_repository.dart';
import 'package:business_sahaj_erp/data/repositories/backup_repository_impl.dart';
import 'package:business_sahaj_erp/data/repositories/restore_repository_impl.dart';
import 'package:business_sahaj_erp/core/services/compression_service.dart';
import 'package:business_sahaj_erp/core/services/encryption_service.dart';
import 'package:business_sahaj_erp/core/services/google_drive_service.dart';
import 'package:business_sahaj_erp/core/services/backup_service.dart';
import 'package:business_sahaj_erp/core/services/restore_service.dart';

// --- Services & Repositories Providers ---

final compressionServiceProvider = Provider<CompressionService>((ref) {
  return CompressionService();
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final compService = ref.watch(compressionServiceProvider);
  final encService = ref.watch(encryptionServiceProvider);
  final driveService = ref.watch(googleDriveServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return BackupService(dbService, compService, encService, driveService, prefs);
});

final restoreServiceProvider = Provider<RestoreService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final compService = ref.watch(compressionServiceProvider);
  final encService = ref.watch(encryptionServiceProvider);
  return RestoreService(dbService, compService, encService);
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return BackupRepositoryImpl(backupService);
});

final restoreRepositoryProvider = Provider<RestoreRepository>((ref) {
  final restoreService = ref.watch(restoreServiceProvider);
  return RestoreRepositoryImpl(restoreService);
});

// --- State Notifiers ---

// 1. Backup History Notifier
class BackupHistoryNotifier extends StateNotifier<AsyncValue<List<BackupHistoryEntry>>> {
  final BackupRepository _repository;

  BackupHistoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = const AsyncValue.loading();
    try {
      final history = await _repository.getHistory();
      state = AsyncValue.data(history);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<BackupHistoryEntry> triggerBackup({
    String? password,
    bool includeImages = true,
    bool uploadToCloud = false,
  }) async {
    try {
      final entry = await _repository.performBackup(
        password: password,
        includeImages: includeImages,
        uploadToCloud: uploadToCloud,
      );
      await loadHistory();
      return entry;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBackup(BackupHistoryEntry entry) async {
    try {
      await _repository.removeBackup(entry);
      await loadHistory();
    } catch (e) {
      rethrow;
    }
  }
}

final backupHistoryNotifierProvider =
    StateNotifierProvider<BackupHistoryNotifier, AsyncValue<List<BackupHistoryEntry>>>((ref) {
  final repository = ref.watch(backupRepositoryProvider);
  return BackupHistoryNotifier(repository);
});

// 2. Google Drive Auth and Sync State Notifier
class GoogleDriveState {
  final bool isSignedIn;
  final bool isSimulation;
  final String? userEmail;
  final bool isLoading;
  final List<BackupHistoryEntry> cloudBackups;
  final String? errorMessage;

  GoogleDriveState({
    required this.isSignedIn,
    required this.isSimulation,
    this.userEmail,
    required this.isLoading,
    required this.cloudBackups,
    this.errorMessage,
  });

  GoogleDriveState copyWith({
    bool? isSignedIn,
    bool? isSimulation,
    String? userEmail,
    bool? isLoading,
    List<BackupHistoryEntry>? cloudBackups,
    String? errorMessage,
  }) {
    return GoogleDriveState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      isSimulation: isSimulation ?? this.isSimulation,
      userEmail: userEmail ?? this.userEmail,
      isLoading: isLoading ?? this.isLoading,
      cloudBackups: cloudBackups ?? this.cloudBackups,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class GoogleDriveNotifier extends StateNotifier<GoogleDriveState> {
  final GoogleDriveService _driveService;

  GoogleDriveNotifier(this._driveService)
      : super(GoogleDriveState(
          isSignedIn: _driveService.isSignedIn,
          isSimulation: _driveService.isSimulationActive,
          userEmail: _driveService.currentUser?.email,
          isLoading: false,
          cloudBackups: [],
        )) {
    if (state.isSignedIn) {
      fetchCloudBackups();
    }
  }

  Future<void> login() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _driveService.signIn();
      state = state.copyWith(
        isSignedIn: _driveService.isSignedIn,
        isSimulation: _driveService.isSimulationActive,
        userEmail: _driveService.currentUser?.email,
        isLoading: false,
      );
      await fetchCloudBackups();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _driveService.signOut();
      state = GoogleDriveState(
        isSignedIn: false,
        isSimulation: _driveService.isSimulationActive,
        userEmail: null,
        isLoading: false,
        cloudBackups: [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> fetchCloudBackups() async {
    if (!state.isSignedIn) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final driveFiles = await _driveService.listBackups();
      final List<BackupHistoryEntry> list = driveFiles.map((f) {
        return BackupHistoryEntry(
          backupName: f.name ?? 'UnknownCloudBackup',
          date: f.createdTime ?? DateTime.now(),
          size: int.tryParse(f.size ?? '0') ?? 0,
          location: f.id ?? '',
          isCloud: true,
          isEncrypted: f.name?.contains('encrypted') ?? false, // heuristic or metadata based
        );
      }).toList();

      state = state.copyWith(cloudBackups: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> uploadLocalFile(File file, String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _driveService.uploadBackup(file, name);
      await fetchCloudBackups();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> downloadCloudFile(String fileId, String destPath) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _driveService.downloadBackup(fileId, destPath);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> deleteCloudFile(String fileId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _driveService.deleteBackup(fileId);
      await fetchCloudBackups();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

final googleDriveNotifierProvider =
    StateNotifierProvider<GoogleDriveNotifier, GoogleDriveState>((ref) {
  final service = ref.watch(googleDriveServiceProvider);
  return GoogleDriveNotifier(service);
});

// 3. Restore Progress Notifier
enum RestoreStatus { idle, validating, extracting, restoring, success, failure }

class RestoreProgressState {
  final RestoreStatus status;
  final String message;
  final BackupMetadata? metadata;
  final double progress; // 0.0 to 1.0

  RestoreProgressState({
    required this.status,
    required this.message,
    this.metadata,
    required this.progress,
  });

  RestoreProgressState copyWith({
    RestoreStatus? status,
    String? message,
    BackupMetadata? metadata,
    double? progress,
  }) {
    return RestoreProgressState(
      status: status ?? this.status,
      message: message ?? this.message,
      metadata: metadata ?? this.metadata,
      progress: progress ?? this.progress,
    );
  }
}

class RestoreProgressNotifier extends StateNotifier<RestoreProgressState> {
  final RestoreRepository _repository;
  final GoogleDriveService _driveService;

  RestoreProgressNotifier(this._repository, this._driveService)
      : super(RestoreProgressState(
          status: RestoreStatus.idle,
          message: 'Ready for restoration',
          progress: 0.0,
        ));

  void reset() {
    state = RestoreProgressState(
      status: RestoreStatus.idle,
      message: 'Ready for restoration',
      progress: 0.0,
    );
  }

  Future<BackupMetadata> validateFile(String path, {String? password}) async {
    state = state.copyWith(status: RestoreStatus.validating, message: 'Validating backup header...');
    try {
      final meta = await _repository.validate(path, password: password);
      state = state.copyWith(status: RestoreStatus.idle, metadata: meta, progress: 0.3);
      return meta;
    } catch (e) {
      state = state.copyWith(status: RestoreStatus.failure, message: 'Validation failed: $e');
      rethrow;
    }
  }

  Future<void> runRestore({
    required String filePath,
    String? password,
    bool restoreParties = true,
    bool restoreItems = true,
    bool restoreOrders = true,
    bool restoreInvoices = true,
    bool restoreSettings = true,
    String duplicateStrategy = 'replace',
  }) async {
    state = state.copyWith(
      status: RestoreStatus.restoring,
      message: 'Ingesting records into database...',
      progress: 0.5,
    );

    try {
      await _repository.restore(
        filePath,
        password: password,
        restoreParties: restoreParties,
        restoreItems: restoreItems,
        restoreOrders: restoreOrders,
        restoreInvoices: restoreInvoices,
        restoreSettings: restoreSettings,
        duplicateStrategy: duplicateStrategy,
      );

      state = state.copyWith(
        status: RestoreStatus.success,
        message: 'Database restored successfully! Restarting connection...',
        progress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        status: RestoreStatus.failure,
        message: 'Restore failed: $e',
        progress: 0.0,
      );
      rethrow;
    }
  }

  Future<void> restoreFromDrive({
    required String driveFileId,
    required String filename,
    String? password,
    bool restoreParties = true,
    bool restoreItems = true,
    bool restoreOrders = true,
    bool restoreInvoices = true,
    bool restoreSettings = true,
    String duplicateStrategy = 'replace',
  }) async {
    state = state.copyWith(
      status: RestoreStatus.extracting,
      message: 'Downloading backup from Google Drive...',
      progress: 0.2,
    );

    final tempDir = await getTemporaryDirectory();
    final localDownloadPath = '${tempDir.path}/download_$filename';

    try {
      // Download
      await _driveService.downloadBackup(driveFileId, localDownloadPath);

      // Validate
      await validateFile(localDownloadPath, password: password);

      // Restore
      await runRestore(
        filePath: localDownloadPath,
        password: password,
        restoreParties: restoreParties,
        restoreItems: restoreItems,
        restoreOrders: restoreOrders,
        restoreInvoices: restoreInvoices,
        restoreSettings: restoreSettings,
        duplicateStrategy: duplicateStrategy,
      );

      // Cleanup
      final file = File(localDownloadPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      state = state.copyWith(
        status: RestoreStatus.failure,
        message: 'Restore from Google Drive failed: $e',
        progress: 0.0,
      );
      // Cleanup temp download on error
      final file = File(localDownloadPath);
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }
}

final restoreProgressNotifierProvider =
    StateNotifierProvider<RestoreProgressNotifier, RestoreProgressState>((ref) {
  final repository = ref.watch(restoreRepositoryProvider);
  final driveService = ref.watch(googleDriveServiceProvider);
  return RestoreProgressNotifier(repository, driveService);
});
