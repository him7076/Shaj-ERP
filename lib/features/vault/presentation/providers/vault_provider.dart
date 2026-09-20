import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/features/vault/domain/models/vault_item.dart';
import 'package:business_sahaj_erp/features/vault/data/repositories/vault_repository.dart';

final vaultItemsProvider = StateNotifierProvider<VaultNotifier, List<VaultItem>>((ref) {
  final repository = ref.watch(vaultRepositoryProvider);
  return VaultNotifier(repository);
});

class VaultNotifier extends StateNotifier<List<VaultItem>> {
  final VaultRepository _repository;

  VaultNotifier(this._repository) : super([]) {
    _loadItems();
  }

  void _loadItems() {
    state = _repository.getItems();
  }

  Future<void> saveItem(VaultItem item) async {
    await _repository.saveItem(item);
    _loadItems();
  }

  Future<void> deleteItem(String id) async {
    await _repository.deleteItem(id);
    _loadItems();
  }
}
