import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';

// Stream provider for the synchronization state.
final syncStateProvider = StreamProvider<SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStateStream;
});

// A helper provider to check if a sync is currently in progress.
final isSyncingProvider = Provider<bool>((ref) {
  final syncStateAsync = ref.watch(syncStateProvider);
  return syncStateAsync.maybeWhen(
    data: (state) => state.status == SyncStatus.syncing,
    orElse: () => false,
  );
});
