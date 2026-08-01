import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/services/network_service.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';
import 'package:business_sahaj_erp/core/services/firebase_service.dart';
import 'package:business_sahaj_erp/core/services/storage_service.dart';
import 'package:business_sahaj_erp/core/services/sync_queue_service.dart';
import 'package:business_sahaj_erp/core/services/sync_manager.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

// Repositories
import 'package:business_sahaj_erp/domain/repositories/sync_queue_repository.dart';
import 'package:business_sahaj_erp/data/repositories/sync_queue_repository_impl.dart';
import 'package:business_sahaj_erp/domain/repositories/item_repository.dart';
import 'package:business_sahaj_erp/data/repositories/item_repository_impl.dart';
import 'package:business_sahaj_erp/domain/repositories/bank_account_repository.dart';
import 'package:business_sahaj_erp/data/repositories/bank_account_repository_impl.dart';
import 'package:business_sahaj_erp/domain/repositories/credit_note_repository.dart';
import 'package:business_sahaj_erp/data/repositories/credit_note_repository_impl.dart';
import 'package:business_sahaj_erp/domain/repositories/debit_note_repository.dart';
import 'package:business_sahaj_erp/data/repositories/debit_note_repository_impl.dart';

// Logger provider
final loggerProvider = Provider<LoggerService>((ref) {
  return logger;
});

// Network Service provider (Dio wrapper)
final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});

// Database Service provider (Isar DB wrapper)
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Active Firm ID provider
final activeFirmIdProvider = StateProvider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('active_firm_id') ?? 'firm_default';
});

// Isar Provider that reacts to active firm switches
final isarProvider = Provider<Isar>((ref) {
  ref.watch(activeFirmIdProvider);
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.isar;
});

// Firebase Service Provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FirebaseService(prefs);
});

// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return StorageService(firebaseService);
});

// Sync Queue Service Provider
final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SyncQueueService(dbService);
});

// Sync Service provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final queueService = ref.watch(syncQueueServiceProvider);
  final dbService = ref.watch(databaseServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  final syncService = SyncService(firebaseService, queueService, dbService, prefs);
  ref.onDispose(() => syncService.dispose());
  return syncService;
});

// Sync Manager Provider
final syncManagerProvider = Provider<SyncManager>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final queueService = ref.watch(syncQueueServiceProvider);

  final manager = SyncManager(syncService, queueService);
  ref.onDispose(() => manager.dispose());
  return manager;
});

// Sync Queue Repository Provider
final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return SyncQueueRepositoryImpl(isar);
});

// Item Repository Provider
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return ItemRepositoryImpl(isar);
});

// Bank Account Repository Provider
final bankAccountRepositoryProvider = Provider<BankAccountRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return BankAccountRepositoryImpl(isar);
});

// Credit Note Repository Provider
final creditNoteRepositoryProvider = Provider<CreditNoteRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return CreditNoteRepositoryImpl(isar);
});

// Debit Note Repository Provider
final debitNoteRepositoryProvider = Provider<DebitNoteRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return DebitNoteRepositoryImpl(isar);
});

// Bank Accounts List Provider
final bankAccountsListProvider = FutureProvider<List<BankAccount>>((ref) async {
  final repo = ref.watch(bankAccountRepositoryProvider);
  return await repo.getAll();
});
