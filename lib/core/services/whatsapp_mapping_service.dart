import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/whatsapp_mapping_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/core/services/sync_manager.dart';

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
  final String? rateUnit;    // Unit for custom rate (e.g. 'Carton', 'Bundle', 'PCS')
  final bool isTaxInclusive; // Whether customRate is inclusive of GST

  WhatsAppItemMapping({
    required this.rawItemLine,
    required this.itemUuid,
    this.pcsPerBundle = 1.0,
    this.pcsPerCarton = 1.0,
    this.customRate = 0.0,
    this.rateUnit,
    this.isTaxInclusive = false,
  });

  Map<String, dynamic> toJson() => {
        'rawItemLine': rawItemLine,
        'itemUuid': itemUuid,
        'pcsPerBundle': pcsPerBundle,
        'pcsPerCarton': pcsPerCarton,
        'customRate': customRate,
        'rateUnit': rateUnit,
        'isTaxInclusive': isTaxInclusive,
      };

  factory WhatsAppItemMapping.fromJson(Map<String, dynamic> json) => WhatsAppItemMapping(
        rawItemLine: json['rawItemLine'] ?? '',
        itemUuid: json['itemUuid'] ?? '',
        pcsPerBundle: (json['pcsPerBundle'] as num?)?.toDouble() ?? 1.0,
        pcsPerCarton: (json['pcsPerCarton'] as num?)?.toDouble() ?? 1.0,
        customRate: (json['customRate'] as num?)?.toDouble() ?? 0.0,
        rateUnit: json['rateUnit'] as String?,
        isTaxInclusive: json['isTaxInclusive'] as bool? ?? false,
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

/// Model representing salesman mapping rule
class WhatsAppSalesmanMapping {
  final String rawSalesmanName;
  final String targetSalesmanName;

  WhatsAppSalesmanMapping({
    required this.rawSalesmanName,
    required this.targetSalesmanName,
  });

  Map<String, dynamic> toJson() => {
        'rawSalesmanName': rawSalesmanName,
        'targetSalesmanName': targetSalesmanName,
      };

  factory WhatsAppSalesmanMapping.fromJson(Map<String, dynamic> json) => WhatsAppSalesmanMapping(
        rawSalesmanName: json['rawSalesmanName'] ?? '',
        targetSalesmanName: json['targetSalesmanName'] ?? '',
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
    try {
      final isarList = _isar.whatsAppMappings
          .filter()
          .mappingTypeEqualTo('Party')
          .and()
          .isDeletedEqualTo(false)
          .findAllSync();

      if (isarList.isNotEmpty) {
        return isarList
            .where((m) => m.rawKey != null && m.targetUuid != null)
            .map((m) => WhatsAppPartyMapping(
                  rawShopName: m.rawKey!,
                  partyUuid: m.targetUuid!,
                ))
            .toList();
      }
    } catch (_) {}

    // Fallback to SharedPreferences
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
    final cleanShop = rawShop.trim();
    final uuidGen = const Uuid();

    try {
      final existing = await _isar.whatsAppMappings
          .filter()
          .mappingTypeEqualTo('Party')
          .and()
          .rawKeyEqualTo(cleanShop, caseSensitive: false)
          .findFirst();

      final mapping = existing ??
          (WhatsAppMapping()
            ..uuid = uuidGen.v4()
            ..createdAt = DateTime.now());

      mapping
        ..mappingType = 'Party'
        ..rawKey = cleanShop
        ..targetUuid = partyUuid
        ..updatedAt = DateTime.now()
        ..isDeleted = false
        ..isSynced = false;

      await _isar.writeTxn(() async {
        await _isar.whatsAppMappings.put(mapping);

        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'WhatsAppMapping'
          ..entityId = mapping.id
          ..entityUuid = mapping.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await _isar.syncQueues.put(q);
      });
      SyncManager.triggerUpload();
    } catch (e) {
      print('Error saving WhatsApp party mapping to Isar: $e');
    }

    // Backup to SharedPreferences
    final list = getAllPartyMappings();
    final existingIndex = list.indexWhere((m) => m.rawShopName.trim().toLowerCase() == cleanShop.toLowerCase());
    final newMapping = WhatsAppPartyMapping(rawShopName: cleanShop, partyUuid: partyUuid);

    if (existingIndex >= 0) {
      list[existingIndex] = newMapping;
    } else {
      list.add(newMapping);
    }

    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await _prefs.setString(_partyKey, encoded);
    await _prefs.setString('wa_party_map_${cleanShop.toLowerCase()}', partyUuid);
  }

  Future<void> deletePartyMapping(String rawShop) async {
    final cleanShop = rawShop.trim();
    final uuidGen = const Uuid();

    try {
      final existing = await _isar.whatsAppMappings
          .filter()
          .mappingTypeEqualTo('Party')
          .and()
          .rawKeyEqualTo(cleanShop, caseSensitive: false)
          .findFirst();

      if (existing != null) {
        await _isar.writeTxn(() async {
          existing.isDeleted = true;
          existing.isSynced = false;
          existing.updatedAt = DateTime.now();
          await _isar.whatsAppMappings.put(existing);

          final q = SyncQueue()
            ..uuid = uuidGen.v4()
            ..entityType = 'WhatsAppMapping'
            ..entityId = existing.id
            ..entityUuid = existing.uuid
            ..operation = 'Delete'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await _isar.syncQueues.put(q);
        });
      }
    } catch (e) {
      print('Error deleting WhatsApp party mapping in Isar: $e');
    }

    await _prefs.remove('wa_party_map_${cleanShop.toLowerCase()}');
    final list = getAllPartyMappings();
    list.removeWhere((m) => m.rawShopName.trim().toLowerCase() == cleanShop.toLowerCase());
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

      // Check Isar DB first
      try {
        final isarMapping = await _isar.whatsAppMappings
            .filter()
            .mappingTypeEqualTo('Party')
            .and()
            .rawKeyEqualTo(shopName.trim(), caseSensitive: false)
            .and()
            .isDeletedEqualTo(false)
            .findFirst();

        if (isarMapping != null && isarMapping.targetUuid != null) {
          final party = allParties.firstWhereOrNull((p) => p.uuid == isarMapping.targetUuid);
          if (party != null) return party;
        }
      } catch (_) {}

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
    try {
      final isarList = _isar.whatsAppMappings
          .filter()
          .mappingTypeEqualTo('Item')
          .and()
          .isDeletedEqualTo(false)
          .findAllSync();

      if (isarList.isNotEmpty) {
        return isarList
            .where((m) => m.rawKey != null && m.targetUuid != null)
            .map((m) => WhatsAppItemMapping(
                  rawItemLine: m.rawKey!,
                  itemUuid: m.targetUuid!,
                  pcsPerBundle: m.pcsPerBundle ?? 1.0,
                  pcsPerCarton: m.pcsPerCarton ?? 1.0,
                  customRate: m.customRate ?? 0.0,
                  rateUnit: m.rateUnit,
                  isTaxInclusive: m.isTaxInclusive ?? false,
                ))
            .toList();
      }
    } catch (_) {}

    // Fallback to SharedPreferences
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
    final cleanLine = rawItemLine.trim();

    try {
      final isarMatch = _isar.whatsAppMappings
          .filter()
          .mappingTypeEqualTo('Item')
          .and()
          .rawKeyEqualTo(cleanLine, caseSensitive: false)
          .and()
          .isDeletedEqualTo(false)
          .findFirstSync();

      if (isarMatch != null && isarMatch.targetUuid != null) {
        return WhatsAppItemMapping(
          rawItemLine: isarMatch.rawKey ?? rawItemLine,
          itemUuid: isarMatch.targetUuid!,
          pcsPerBundle: isarMatch.pcsPerBundle ?? 1.0,
          pcsPerCarton: isarMatch.pcsPerCarton ?? 1.0,
          customRate: isarMatch.customRate ?? 0.0,
          rateUnit: isarMatch.rateUnit,
          isTaxInclusive: isarMatch.isTaxInclusive ?? false,
        );
      }
    } catch (_) {}

    final list = getAllItemMappings();
    final match = list.firstWhereOrNull((m) => m.rawItemLine.trim().toLowerCase() == cleanLine.toLowerCase());
    if (match != null) return match;

    final legacyUuid = _prefs.getString('wa_item_map_${cleanLine.toLowerCase()}');
    if (legacyUuid != null && legacyUuid.isNotEmpty) {
      return WhatsAppItemMapping(rawItemLine: rawItemLine, itemUuid: legacyUuid);
    }
    return null;
  }

  Future<void> saveItemMapping(WhatsAppItemMapping mapping) async {
    if (mapping.rawItemLine.trim().isEmpty || mapping.itemUuid.isEmpty) return;
    final cleanLine = mapping.rawItemLine.trim();
    final uuidGen = const Uuid();

    try {
      final existing = await _isar.whatsAppMappings
          .filter()
          .mappingTypeEqualTo('Item')
          .and()
          .rawKeyEqualTo(cleanLine, caseSensitive: false)
          .findFirst();

      final entity = existing ??
          (WhatsAppMapping()
            ..uuid = uuidGen.v4()
            ..createdAt = DateTime.now());

      entity
        ..mappingType = 'Item'
        ..rawKey = cleanLine
        ..targetUuid = mapping.itemUuid
        ..pcsPerBundle = mapping.pcsPerBundle
        ..pcsPerCarton = mapping.pcsPerCarton
        ..customRate = mapping.customRate
        ..rateUnit = mapping.rateUnit
        ..isTaxInclusive = mapping.isTaxInclusive
        ..updatedAt = DateTime.now()
        ..isDeleted = false
        ..isSynced = false;

      await _isar.writeTxn(() async {
        await _isar.whatsAppMappings.put(entity);

        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'WhatsAppMapping'
          ..entityId = entity.id
          ..entityUuid = entity.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await _isar.syncQueues.put(q);
      });
      SyncManager.triggerUpload();
    } catch (e) {
      print('Error saving WhatsApp item mapping to Isar: $e');
    }

    // Backup to SharedPreferences
    await _prefs.setString('wa_item_map_${cleanLine.toLowerCase()}', mapping.itemUuid);
    final list = getAllItemMappings();
    final existingIndex = list.indexWhere((m) => m.rawItemLine.trim().toLowerCase() == cleanLine.toLowerCase());

    if (existingIndex >= 0) {
      list[existingIndex] = mapping;
    } else {
      list.add(mapping);
    }

    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await _prefs.setString(_itemKey, encoded);
  }

  Future<void> deleteItemMapping(String rawItemLine) async {
    final cleanLine = rawItemLine.trim();
    final uuidGen = const Uuid();

    try {
      final existing = await _isar.whatsAppMappings
          .filter()
          .mappingTypeEqualTo('Item')
          .and()
          .rawKeyEqualTo(cleanLine, caseSensitive: false)
          .findFirst();

      if (existing != null) {
        await _isar.writeTxn(() async {
          existing.isDeleted = true;
          existing.isSynced = false;
          existing.updatedAt = DateTime.now();
          await _isar.whatsAppMappings.put(existing);

          final q = SyncQueue()
            ..uuid = uuidGen.v4()
            ..entityType = 'WhatsAppMapping'
            ..entityId = existing.id
            ..entityUuid = existing.uuid
            ..operation = 'Delete'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await _isar.syncQueues.put(q);
        });
      }
    } catch (e) {
      print('Error deleting WhatsApp item mapping in Isar: $e');
    }

    await _prefs.remove('wa_item_map_${cleanLine.toLowerCase()}');
    final list = getAllItemMappings();
    list.removeWhere((m) => m.rawItemLine.trim().toLowerCase() == cleanLine.toLowerCase());
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

  // --- SALESMAN MAPPING METHODS ---

  List<WhatsAppSalesmanMapping> getAllSalesmanMappings() {
    try {
      final isarList = _isar.whatsAppMappings
          .filter()
          .mappingTypeEqualTo('Salesman')
          .and()
          .isDeletedEqualTo(false)
          .findAllSync();

      if (isarList.isNotEmpty) {
        return isarList
            .where((m) => m.rawKey != null && m.targetUuid != null)
            .map((m) => WhatsAppSalesmanMapping(
                  rawSalesmanName: m.rawKey!,
                  targetSalesmanName: m.targetUuid!,
                ))
            .toList();
      }
    } catch (_) {}

    final rawJson = _prefs.getString('wa_salesman_mappings_v1');
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List list = jsonDecode(rawJson);
      return list.map((e) => WhatsAppSalesmanMapping.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  WhatsAppSalesmanMapping? getSalesmanMapping(String rawSalesmanName) {
    final cleanName = rawSalesmanName.trim();
    if (cleanName.isEmpty) return null;

    try {
      final isarMatch = _isar.whatsAppMappings
          .filter()
          .mappingTypeEqualTo('Salesman')
          .and()
          .rawKeyEqualTo(cleanName, caseSensitive: false)
          .and()
          .isDeletedEqualTo(false)
          .findFirstSync();

      if (isarMatch != null && isarMatch.targetUuid != null) {
        return WhatsAppSalesmanMapping(
          rawSalesmanName: isarMatch.rawKey ?? rawSalesmanName,
          targetSalesmanName: isarMatch.targetUuid!,
        );
      }
    } catch (_) {}

    final list = getAllSalesmanMappings();
    return list.firstWhereOrNull((m) => m.rawSalesmanName.trim().toLowerCase() == cleanName.toLowerCase());
  }

  Future<void> saveSalesmanMapping(String rawSalesmanName, String targetSalesmanName) async {
    if (rawSalesmanName.trim().isEmpty || targetSalesmanName.trim().isEmpty) return;
    final cleanRaw = rawSalesmanName.trim();
    final cleanTarget = targetSalesmanName.trim();
    final uuidGen = const Uuid();

    try {
      final existing = await _isar.whatsAppMappings
          .filter()
          .mappingTypeEqualTo('Salesman')
          .and()
          .rawKeyEqualTo(cleanRaw, caseSensitive: false)
          .findFirst();

      final entity = existing ??
          (WhatsAppMapping()
            ..uuid = uuidGen.v4()
            ..createdAt = DateTime.now());

      entity
        ..mappingType = 'Salesman'
        ..rawKey = cleanRaw
        ..targetUuid = cleanTarget
        ..updatedAt = DateTime.now()
        ..isDeleted = false
        ..isSynced = false;

      await _isar.writeTxn(() async {
        await _isar.whatsAppMappings.put(entity);

        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'WhatsAppMapping'
          ..entityId = entity.id
          ..entityUuid = entity.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await _isar.syncQueues.put(q);
      });
      SyncManager.triggerUpload();
    } catch (e) {
      print('Error saving WhatsApp salesman mapping to Isar: $e');
    }
  }

  Future<void> deleteSalesmanMapping(String rawSalesmanName) async {
    try {
      final match = await _isar.whatsAppMappings
          .filter()
          .mappingTypeEqualTo('Salesman')
          .and()
          .rawKeyEqualTo(rawSalesmanName.trim(), caseSensitive: false)
          .findFirst();

      if (match != null) {
        await _isar.writeTxn(() async {
          match.isDeleted = true;
          match.updatedAt = DateTime.now();
          match.isSynced = false;
          await _isar.whatsAppMappings.put(match);
        });
        SyncManager.triggerUpload();
      }
    } catch (_) {}
  }
}

final whatsappMappingServiceProvider = Provider<WhatsappMappingService>((ref) {
  final isar = ref.watch(isarProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return WhatsappMappingService(isar, prefs);
});
