import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/features/vault/domain/models/vault_item.dart';
import 'package:business_sahaj_erp/core/providers/shared_preferences_provider.dart';

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return VaultRepository(prefs);
});

class VaultRepository {
  final SharedPreferences _prefs;
  static const String _vaultKey = 'personal_vault_items';

  VaultRepository(this._prefs);

  List<VaultItem> getItems() {
    final String? data = _prefs.getString(_vaultKey);
    if (data == null || data.isEmpty) return [];
    
    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.map((e) => VaultItem.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveItem(VaultItem item) async {
    final items = getItems();
    final index = items.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      items[index] = item.copyWith(updatedAt: DateTime.now());
    } else {
      items.add(item);
    }
    await _saveAll(items);
  }

  Future<void> deleteItem(String id) async {
    final items = getItems();
    items.removeWhere((e) => e.id == id);
    await _saveAll(items);
  }

  Future<void> _saveAll(List<VaultItem> items) async {
    final List<Map<String, dynamic>> mapped = items.map((e) => e.toMap()).toList();
    await _prefs.setString(_vaultKey, json.encode(mapped));
  }
}
