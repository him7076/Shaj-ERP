import 'dart:convert';
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

/// Model representing custom WhatsApp item mapping rule
class WhatsAppItemMapping {
  final String rawItemLine;
  final String itemUuid;
  final double pcsPerBundle; // e.g. 12 Pcs = 1 Bundle (Secondary Unit)
  final double pcsPerCarton; // e.g. 72 Pcs = 1 Carton (Primary Unit)
  final double customRate;   // Override WhatsApp sale rate

  WhatsAppItemMapping({
    required this.rawItemLine,
    required this.itemUuid,
    this.pcsPerBundle = 1.0,
    this.pcsPerCarton = 1.0,
    this.customRate = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'rawItemLine': rawItemLine,
        'itemUuid': itemUuid,
        'pcsPerBundle': pcsPerBundle,
        'pcsPerCarton': pcsPerCarton,
        'customRate': customRate,
      };

  factory WhatsAppItemMapping.fromJson(Map<String, dynamic> json) => WhatsAppItemMapping(
        rawItemLine: json['rawItemLine'] ?? '',
        itemUuid: json['itemUuid'] ?? '',
        pcsPerBundle: (json['pcsPerBundle'] as num?)?.toDouble() ?? 1.0,
        pcsPerCarton: (json['pcsPerCarton'] as num?)?.toDouble() ?? 1.0,
        customRate: (json['customRate'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Model representing party mapping rule
class WhatsAppPartyMapping {
  final String rawShopName;
  final String partyUuid;

  WhatsAppPartyMapping({
    required this.rawShopName,
    required this.partyUuid,
  });

  Map<String, dynamic> toJson() => {
        'rawShopName': rawShopName,
        'partyUuid': partyUuid,
      };

  factory WhatsAppPartyMapping.fromJson(Map<String, dynamic> json) => WhatsAppPartyMapping(
        rawShopName: json['rawShopName'] ?? '',
        partyUuid: json['partyUuid'] ?? '',
      );
}

/// Result of 3-Tier Multi-Unit conversion engine
class ConvertedUnitResult {
  final String unitName;
  final bool isSecondaryUnit;
  final double convertedQuantity;
  final double effectiveRate;

  ConvertedUnitResult({
    required this.unitName,
    required this.isSecondaryUnit,
    required this.convertedQuantity,
    required this.effectiveRate,
  });
}

class WhatsappMappingService {
  final Isar _isar;
  final SharedPreferences _prefs;

  static const String _partyKey = 'wa_party_mappings_v2';
  static const String _itemKey = 'wa_item_mappings_v2';

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

  // --- PARTY MAPPING METHODS ---

  List<WhatsAppPartyMapping> getAllPartyMappings() {
    final rawJson = _prefs.getString(_partyKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List list = jsonDecode(rawJson);
      return list.map((e) => WhatsAppPartyMapping.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePartyMapping(String rawShop, String partyUuid) async {
    if (rawShop.trim().isEmpty || partyUuid.isEmpty) return;
    final cleanShop = rawShop.trim().toLowerCase();

    // Legacy fallback key
    final legacyKey = 'wa_party_map_$cleanShop';
    await _prefs.setString(legacyKey, partyUuid);

    // JSON Index List
    final list = getAllPartyMappings();
    final existingIndex = list.indexWhere((m) => m.rawShopName.trim().toLowerCase() == cleanShop);
    final newMapping = WhatsAppPartyMapping(rawShopName: rawShop.trim(), partyUuid: partyUuid);

    if (existingIndex >= 0) {
      list[existingIndex] = newMapping;
    } else {
      list.add(newMapping);
    }

    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await _prefs.setString(_partyKey, encoded);
  }

  Future<void> deletePartyMapping(String rawShop) async {
    final cleanShop = rawShop.trim().toLowerCase();
    await _prefs.remove('wa_party_map_$cleanShop');

    final list = getAllPartyMappings();
    list.removeWhere((m) => m.rawShopName.trim().toLowerCase() == cleanShop);
    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await _prefs.setString(_partyKey, encoded);
  }

  Future<Party?> matchParty({String? shopName, String? mobileNumber}) async {
    final allParties = await _isar.partys.filter().isDeletedEqualTo(false).findAll();
    if (allParties.isEmpty) return null;

    // 1. Mobile number exact / suffix match
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

    // 2. Persistent party mapping
    if (shopName != null && shopName.trim().isNotEmpty) {
      final cleanShop = shopName.trim().toLowerCase();
      final partyMappings = getAllPartyMappings();
      final mapped = partyMappings.firstWhereOrNull((m) => m.rawShopName.trim().toLowerCase() == cleanShop);
      if (mapped != null) {
        final party = allParties.firstWhereOrNull((p) => p.uuid == mapped.partyUuid);
        if (party != null) return party;
      }

      final legacyUuid = _prefs.getString('wa_party_map_$cleanShop');
      if (legacyUuid != null && legacyUuid.isNotEmpty) {
        final party = allParties.firstWhereOrNull((p) => p.uuid == legacyUuid);
        if (party != null) return party;
      }
    }

    // 3. String similarity match
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

  // --- ITEM MAPPING METHODS ---

  List<WhatsAppItemMapping> getAllItemMappings() {
    final rawJson = _prefs.getString(_itemKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List list = jsonDecode(rawJson);
      return list.map((e) => WhatsAppItemMapping.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  WhatsAppItemMapping? getItemMapping(String rawItemLine) {
    final cleanLine = rawItemLine.trim().toLowerCase();
    final list = getAllItemMappings();
    final match = list.firstWhereOrNull((m) => m.rawItemLine.trim().toLowerCase() == cleanLine);
    if (match != null) return match;

    final legacyUuid = _prefs.getString('wa_item_map_$cleanLine');
    if (legacyUuid != null && legacyUuid.isNotEmpty) {
      return WhatsAppItemMapping(rawItemLine: rawItemLine, itemUuid: legacyUuid);
    }
    return null;
  }

  Future<void> saveItemMapping(WhatsAppItemMapping mapping) async {
    if (mapping.rawItemLine.trim().isEmpty || mapping.itemUuid.isEmpty) return;
    final cleanLine = mapping.rawItemLine.trim().toLowerCase();

    // Legacy fallback key
    await _prefs.setString('wa_item_map_$cleanLine', mapping.itemUuid);

    // JSON Index List
    final list = getAllItemMappings();
    final existingIndex = list.indexWhere((m) => m.rawItemLine.trim().toLowerCase() == cleanLine);

    if (existingIndex >= 0) {
      list[existingIndex] = mapping;
    } else {
      list.add(mapping);
    }

    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await _prefs.setString(_itemKey, encoded);
  }

  Future<void> deleteItemMapping(String rawItemLine) async {
    final cleanLine = rawItemLine.trim().toLowerCase();
    await _prefs.remove('wa_item_map_$cleanLine');

    final list = getAllItemMappings();
    list.removeWhere((m) => m.rawItemLine.trim().toLowerCase() == cleanLine);
    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await _prefs.setString(_itemKey, encoded);
  }

  Future<Item?> matchItem(String rawItemLine) async {
    final allItems = await _isar.items.filter().isDeletedEqualTo(false).findAll();
    if (allItems.isEmpty) return null;

    final mapping = getItemMapping(rawItemLine);
    if (mapping != null) {
      final savedItem = allItems.firstWhereOrNull((i) => i.uuid == mapping.itemUuid);
      if (savedItem != null) return savedItem;
    }

    // String similarity on itemName
    final cleanLine = rawItemLine.trim().toLowerCase();
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

  // --- SMART 3-TIER MULTI-UNIT CONVERSION ENGINE ---

  ConvertedUnitResult convertWhatsAppPcsToErpUnit(
    Item item,
    double rawPcsQty,
    WhatsAppItemMapping? mapping,
  ) {
    final primaryName = item.primaryUnitName ?? item.unit.value?.shortName ?? 'Carton';
    final secondaryName = item.secondaryUnit ?? 'Bundle';

    final double pcsPerCarton = (mapping != null && mapping.pcsPerCarton > 0)
        ? mapping.pcsPerCarton
        : (item.conversionFactor != null && item.conversionFactor! > 0 ? item.conversionFactor! : 1.0);

    final double pcsPerBundle = (mapping != null && mapping.pcsPerBundle > 0) ? mapping.pcsPerBundle : 1.0;

    final double defaultRate = item.sellRate ?? 0.0;
    final double baseCartonRate = (mapping != null && mapping.customRate > 0) ? mapping.customRate : defaultRate;

    // a. Check Carton (Primary Unit) divisible
    if (pcsPerCarton > 0 && (rawPcsQty % pcsPerCarton == 0)) {
      return ConvertedUnitResult(
        unitName: primaryName,
        isSecondaryUnit: false,
        convertedQuantity: rawPcsQty / pcsPerCarton,
        effectiveRate: baseCartonRate,
      );
    }

    // b. Check Bundle (Secondary Unit) divisible
    if (pcsPerBundle > 0 && (rawPcsQty % pcsPerBundle == 0)) {
      final double bundleRate = pcsPerCarton > 0 ? (baseCartonRate / pcsPerCarton * pcsPerBundle) : baseCartonRate;
      return ConvertedUnitResult(
        unitName: secondaryName,
        isSecondaryUnit: true,
        convertedQuantity: rawPcsQty / pcsPerBundle,
        effectiveRate: bundleRate,
      );
    }

    // c. Fallback to Secondary Unit / Pcs
    final double fallbackQty = pcsPerBundle > 0 ? (rawPcsQty / pcsPerBundle) : rawPcsQty;
    final double unitRate = pcsPerCarton > 0 ? (baseCartonRate / pcsPerCarton) : baseCartonRate;

    return ConvertedUnitResult(
      unitName: secondaryName,
      isSecondaryUnit: true,
      convertedQuantity: fallbackQty,
      effectiveRate: unitRate,
    );
  }
}

final whatsappMappingServiceProvider = Provider<WhatsappMappingService>((ref) {
  final isar = ref.watch(isarProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return WhatsappMappingService(isar, prefs);
});
