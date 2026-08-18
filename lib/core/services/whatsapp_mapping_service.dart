import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

extension IterableNullSafety<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class WhatsappMappingService {
  final Isar _isar;
  final SharedPreferences _prefs;

  WhatsappMappingService(this._isar, this._prefs);

  /// Calculate string similarity (Dice coefficient & token overlap) between 0.0 and 1.0
  static double calculateSimilarity(String s1, String s2) {
    final a = s1.trim().toLowerCase();
    final b = s2.trim().toLowerCase();
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a.contains(b) || b.contains(a)) return 0.85;

    final wordsA = a.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    final wordsB = b.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    if (wordsA.isEmpty || wordsB.isEmpty) return 0.0;

    int matches = 0;
    for (var w1 in wordsA) {
      for (var w2 in wordsB) {
        if (w1 == w2 || w1.contains(w2) || w2.contains(w1)) {
          matches++;
          break;
        }
      }
    }
    return (2.0 * matches) / (wordsA.length + wordsB.length);
  }

  /// Match party by mobile number, saved SharedPreferences key, or fuzzy name similarity
  Future<Party?> matchParty({String? shopName, String? mobileNumber}) async {
    final allParties = await _isar.partys.filter().isDeletedEqualTo(false).findAll();
    if (allParties.isEmpty) return null;

    // 1. Exact or suffix match by Mobile Number
    if (mobileNumber != null && mobileNumber.trim().isNotEmpty) {
      final cleanMob = mobileNumber.replaceAll(RegExp(r'\D'), '');
      if (cleanMob.isNotEmpty) {
        for (var p in allParties) {
          final pMob = (p.mobileNumber ?? '').replaceAll(RegExp(r'\D'), '');
          if (pMob.isNotEmpty && (pMob == cleanMob || pMob.endsWith(cleanMob) || cleanMob.endsWith(pMob))) {
            return p;
          }
        }
      }
    }

    // 2. Check SharedPreferences for saved key: wa_party_map_<rawShopName>
    if (shopName != null && shopName.trim().isNotEmpty) {
      final key = 'wa_party_map_${shopName.trim().toLowerCase()}';
      final savedUuid = _prefs.getString(key);
      if (savedUuid != null && savedUuid.isNotEmpty) {
        final savedParty = allParties.firstWhereOrNull((p) => p.uuid == savedUuid);
        if (savedParty != null) return savedParty;
      }
    }

    // 3. String similarity on partyName
    if (shopName != null && shopName.trim().isNotEmpty) {
      Party? bestMatch;
      double highestScore = 0.0;

      for (var p in allParties) {
        final pName = p.partyName ?? '';
        final score = calculateSimilarity(shopName, pName);
        if (score > highestScore && score >= 0.35) {
          highestScore = score;
          bestMatch = p;
        }
      }
      return bestMatch;
    }

    return null;
  }

  /// Match Item by saved SharedPreferences key or fuzzy name similarity
  Future<Item?> matchItem(String rawItemLine) async {
    final allItems = await _isar.items.filter().isDeletedEqualTo(false).findAll();
    if (allItems.isEmpty) return null;

    final cleanLine = rawItemLine.trim().toLowerCase();

    // 1. Check SharedPreferences for saved key: wa_item_map_<rawItemLine>
    final key = 'wa_item_map_$cleanLine';
    final savedUuid = _prefs.getString(key);
    if (savedUuid != null && savedUuid.isNotEmpty) {
      final savedItem = allItems.firstWhereOrNull((i) => i.uuid == savedUuid);
      if (savedItem != null) return savedItem;
    }

    // 2. String similarity on itemName
    Item? bestMatch;
    double highestScore = 0.0;

    for (var item in allItems) {
      final itemName = item.itemName ?? '';
      final score = calculateSimilarity(cleanLine, itemName);
      if (score > highestScore && score >= 0.25) {
        highestScore = score;
        bestMatch = item;
      }
    }

    return bestMatch;
  }

  /// Save party mapping preference in SharedPreferences
  Future<void> savePartyMapping(String rawShop, String partyUuid) async {
    if (rawShop.trim().isEmpty || partyUuid.isEmpty) return;
    final key = 'wa_party_map_${rawShop.trim().toLowerCase()}';
    await _prefs.setString(key, partyUuid);
  }

  /// Save item mapping preference in SharedPreferences
  Future<void> saveItemMapping(String rawItemLine, String itemUuid) async {
    if (rawItemLine.trim().isEmpty || itemUuid.isEmpty) return;
    final key = 'wa_item_map_${rawItemLine.trim().toLowerCase()}';
    await _prefs.setString(key, itemUuid);
  }
}

final whatsappMappingServiceProvider = Provider<WhatsappMappingService>((ref) {
  final isar = ref.watch(isarProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return WhatsappMappingService(isar, prefs);
});
