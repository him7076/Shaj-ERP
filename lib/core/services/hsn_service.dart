import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
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
  
  List<HsnModel> _cachedOnlineHsnCodes = [];
  bool _isFetchingOnlineHsn = false;

  HsnService(this.prefs);

  // Seeded common HSN codes in India
  static const List<HsnModel> _seededHsnCodes = [
    HsnModel(hsnCode: '620342', description: 'Shirt / Pant / Trousers / Jeans / Cotton Garments', gstRate: 5.0),
    HsnModel(hsnCode: '620462', description: 'Women Tops / Dress / Sarees / Kurtis / Apparel', gstRate: 5.0),
    HsnModel(hsnCode: '610910', description: 'Cotton T-Shirts & Polo Vests', gstRate: 5.0),
    HsnModel(hsnCode: '851713', description: 'Smartphones / Mobile Handsets / Accessories', gstRate: 18.0),
    HsnModel(hsnCode: '852872', description: 'LED TV & Monitors (Electronic)', gstRate: 18.0),
    HsnModel(hsnCode: '847130', description: 'Personal Computers, Laptops & Tablets', gstRate: 18.0),
    HsnModel(hsnCode: '850440', description: 'Inverters, UPS & Static Converters', gstRate: 18.0),
    HsnModel(hsnCode: '851660', description: 'Electric Ovens, Mixers, Cookers & Appliances', gstRate: 18.0),
    HsnModel(hsnCode: '252329', description: 'Portland Cement & Building Construction', gstRate: 28.0),
    HsnModel(hsnCode: '690721', description: 'Ceramic Floor Tiles & Bathroom Fittings', gstRate: 18.0),
    HsnModel(hsnCode: '170114', description: 'Sugar, Jaggery & Sweeteners', gstRate: 5.0),
    HsnModel(hsnCode: '090210', description: 'Green Tea & CTC Tea Leaves', gstRate: 5.0),
    HsnModel(hsnCode: '090121', description: 'Coffee Powder & Beans', gstRate: 5.0),
    HsnModel(hsnCode: '190531', description: 'Sweet Biscuits, Cookies & Wafers', gstRate: 18.0),
    HsnModel(hsnCode: '151219', description: 'Sunflower & Edible Cooking Oils', gstRate: 5.0),
    HsnModel(hsnCode: '340111', description: 'Toilet Soaps & Bath Bars', gstRate: 18.0),
    HsnModel(hsnCode: '340220', description: 'Washing Powder & Detergent Liquids', gstRate: 18.0),
    HsnModel(hsnCode: '300490', description: 'Medicines, Tablets, Syrups & Pharma Capsules', gstRate: 12.0),
    HsnModel(hsnCode: '940360', description: 'Wooden & Steel Furniture, Chairs & Tables', gstRate: 18.0),
    HsnModel(hsnCode: '482010', description: 'Registers, Notebooks & Office Stationery', gstRate: 12.0),
    HsnModel(hsnCode: '640399', description: 'Leather Shoes, Footwear & Chappals', gstRate: 18.0),
    HsnModel(hsnCode: '854449', description: 'Electric Cables, Wires & Wiring Accessories', gstRate: 18.0),
    HsnModel(hsnCode: '391723', description: 'PVC Pipes, Tubes & Plumbing Fittings', gstRate: 18.0),
    HsnModel(hsnCode: '731815', description: 'Iron Nuts, Bolts, Screws & Hardware Items', gstRate: 18.0),
    HsnModel(hsnCode: '320910', description: 'Paints, Wall Emulsions, Primer & Varnishes', gstRate: 18.0),
    HsnModel(hsnCode: '040120', description: 'Fresh Packed Milk, Curd & Paneer', gstRate: 5.0),
    HsnModel(hsnCode: '040510', description: 'Butter & Desi Ghee', gstRate: 12.0),
    HsnModel(hsnCode: '100630', description: 'Basmati Rice & Pulses', gstRate: 5.0),
    HsnModel(hsnCode: '110100', description: 'Wheat Flour / Atta / Maida', gstRate: 5.0),
    HsnModel(hsnCode: '721420', description: 'TMT Steel Bars, Iron Rods & Beams', gstRate: 18.0),
    HsnModel(hsnCode: '841370', description: 'Water Submersible Pumps & Motors', gstRate: 18.0),
    HsnModel(hsnCode: '850720', description: 'Lead Acid Storage Batteries & Solar Panels', gstRate: 28.0),
    HsnModel(hsnCode: '870899', description: 'Automobile & Bike Spare Parts', gstRate: 28.0),
    HsnModel(hsnCode: '210690', description: 'Namkeen, Snacks, Wafers & Packaged Foods', gstRate: 12.0),
    HsnModel(hsnCode: '330499', description: 'Cosmetics, Creams, Face Wash & Lotions', gstRate: 18.0),
    HsnModel(hsnCode: '950300', description: 'Children Toys & Board Games', gstRate: 12.0),
    HsnModel(hsnCode: '998313', description: 'IT Software, Development & Digital Services', gstRate: 18.0),
  ];

  /// Returns the static seeded common HSN codes
  List<HsnModel> getCommonHsnCodes() {
    return _seededHsnCodes;
  }

  /// Fetches HSN codes from online repository and updates suggestions cache
  Future<List<HsnModel>> fetchOnlineHsnCodes() async {
    if (_cachedOnlineHsnCodes.isNotEmpty) {
      return _cachedOnlineHsnCodes;
    }
    if (_isFetchingOnlineHsn) {
      return [];
    }
    
    _isFetchingOnlineHsn = true;
    try {
      final dio = Dio();
      final response = await dio.get('https://raw.githubusercontent.com/crusher95/hsn-sac-gst-json/master/hsn_all.json');
      if (response.statusCode == 200) {
        final List<dynamic> rawList = response.data is String 
            ? json.decode(response.data as String) as List<dynamic>
            : response.data as List<dynamic>;
            
        final List<HsnModel> parsedList = [];
        for (var item in rawList) {
          final hsnStr = item['hsn'] as String? ?? '';
          final descStr = item['description'] as String? ?? '';
          
          double gst = 18.0;
          if (hsnStr.startsWith('99')) {
            gst = 18.0;
          } else if (descStr.toLowerCase().contains('exempt') || descStr.toLowerCase().contains('nil')) {
            gst = 0.0;
          } else if (descStr.toLowerCase().contains('sugar') || descStr.toLowerCase().contains('tea') || descStr.toLowerCase().contains('cereal')) {
            gst = 5.0;
          } else if (descStr.toLowerCase().contains('shoe') || descStr.toLowerCase().contains('textile') || descStr.toLowerCase().contains('apparel')) {
            gst = 12.0;
          }
          
          parsedList.add(HsnModel(
            hsnCode: hsnStr,
            description: descStr,
            gstRate: gst,
          ));
        }
        _cachedOnlineHsnCodes = parsedList;
      }
    } catch (_) {
      // Fallback silently if offline or blocked
    } finally {
      _isFetchingOnlineHsn = false;
    }
    return _cachedOnlineHsnCodes.isNotEmpty ? _cachedOnlineHsnCodes : _seededHsnCodes;
  }

  /// Searches through seeded, online and recently used HSN codes based on query/item name
  Future<List<HsnModel>> searchOnlineHsn(String query) async {
    try {
      final list = await fetchOnlineHsnCodes();
      if (query.trim().isEmpty) {
        return _seededHsnCodes;
      }
      final cleanQuery = query.trim().toLowerCase();
      
      final results = list.where((item) {
        return item.hsnCode.contains(cleanQuery) ||
            item.description.toLowerCase().contains(cleanQuery);
      }).toList();

      return results.take(10).toList();
    } catch (e) {
      throw InvalidHSNException('Failed to search HSN codes: $e');
    }
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
      return [];
    }
  }

  /// Adds a code to the recently used list
  Future<void> addToRecent(HsnModel code) async {
    try {
      final recents = getRecentlyUsed();
      recents.removeWhere((item) => item.hsnCode == code.hsnCode);
      recents.insert(0, code);

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
