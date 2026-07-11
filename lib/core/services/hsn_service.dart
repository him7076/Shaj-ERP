import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';

class HsnModel {
  final String hsnCode;
  final String description;
  final double gstRate;
  final double cessRate;

  const HsnModel({
    required this.hsnCode,
    required this.description,
    required this.gstRate,
    this.cessRate = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'hsnCode': hsnCode,
        'description': description,
        'gstRate': gstRate,
        'cessRate': cessRate,
      };

  factory HsnModel.fromJson(Map<String, dynamic> json) {
    return HsnModel(
      hsnCode: json['hsnCode'] as String,
      description: json['description'] as String,
      gstRate: (json['gstRate'] as num).toDouble(),
      cessRate: (json['cessRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HsnModel &&
          runtimeType == other.runtimeType &&
          hsnCode == other.hsnCode;

  @override
  int get hashCode => hsnCode.hashCode;
}

class HsnService {
  final SharedPreferences prefs;
  static const String _recentHsnKey = 'recent_hsn_codes';

  HsnService(this.prefs);

  // Seeded common HSN codes in India
  static const List<HsnModel> _seededHsnCodes = [
    HsnModel(hsnCode: '852872', description: 'LED TV & Monitors (Electronic)', gstRate: 18.0),
    HsnModel(hsnCode: '847130', description: 'Personal Computers, Laptops & Tablets', gstRate: 18.0),
    HsnModel(hsnCode: '851713', description: 'Smartphones & Mobile Handsets', gstRate: 18.0),
    HsnModel(hsnCode: '850440', description: 'Inverters, UPS & Static Converters', gstRate: 18.0),
    HsnModel(hsnCode: '392410', description: 'Plastic Tableware, Kitchenware & Household articles', gstRate: 12.0),
    HsnModel(hsnCode: '090210', description: 'Green Tea (Not fermented)', gstRate: 5.0),
    HsnModel(hsnCode: '190531', description: 'Sweet Biscuits & Cookies', gstRate: 18.0),
    HsnModel(hsnCode: '220210', description: 'Aerated Waters / Soft Drinks', gstRate: 28.0, cessRate: 12.0),
    HsnModel(hsnCode: '841510', description: 'Air Conditioners (Window or Wall)', gstRate: 28.0),
    HsnModel(hsnCode: '482010', description: 'Registers, Account Books & Notebooks', gstRate: 12.0),
    HsnModel(hsnCode: '640399', description: 'Leather Footwear / Shoes', gstRate: 18.0),
    HsnModel(hsnCode: '300490', description: 'Allopathic Medicines / Medicaments', gstRate: 12.0),
  ];

  /// Returns the static seeded common HSN codes
  List<HsnModel> getCommonHsnCodes() {
    return _seededHsnCodes;
  }

  /// Searches through seeded and recently used HSN codes
  List<HsnModel> searchHsnCodes(String query) {
    try {
      if (query.trim().isEmpty) {
        return _seededHsnCodes;
      }
      final cleanQuery = query.trim().toLowerCase();
      
      // Filter seeded codes
      final filteredSeeded = _seededHsnCodes.where((item) {
        return item.hsnCode.contains(cleanQuery) ||
            item.description.toLowerCase().contains(cleanQuery);
      }).toList();

      // Retrieve recent codes and merge them (avoiding duplicates)
      final recents = getRecentlyUsed();
      final filteredRecents = recents.where((item) {
        final matches = item.hsnCode.contains(cleanQuery) ||
            item.description.toLowerCase().contains(cleanQuery);
        return matches && !filteredSeeded.contains(item);
      }).toList();

      return [...filteredSeeded, ...filteredRecents];
    } catch (e) {
      throw InvalidHSNException('Failed to search HSN codes: $e');
    }
  }

  /// Gets the recently used HSN codes from local storage
  List<HsnModel> getRecentlyUsed() {
    try {
      final jsonList = prefs.getStringList(_recentHsnKey);
      if (jsonList == null) return [];
      
      return jsonList
          .map((item) => HsnModel.fromJson(json.decode(item) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty if there's storage decoding issue
      return [];
    }
  }

  /// Adds a code to the recently used list
  Future<void> addToRecent(HsnModel code) async {
    try {
      final recents = getRecentlyUsed();
      // Remove if already exists to move it to the top
      recents.removeWhere((item) => item.hsnCode == code.hsnCode);
      recents.insert(0, code);

      // Keep only last 10 entries
      if (recents.length > 10) {
        recents.removeRange(10, recents.length);
      }

      final jsonList = recents.map((item) => json.encode(item.toJson())).toList();
      await prefs.setStringList(_recentHsnKey, jsonList);
    } catch (e) {
      throw InvalidHSNException('Failed to update recent HSN codes: $e');
    }
  }
}
