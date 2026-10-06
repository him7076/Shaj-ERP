import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HsnSearchResult {
  final String hsnCode;
  final String description;
  final double gstRate;

  HsnSearchResult({
    required this.hsnCode,
    required this.description,
    required this.gstRate,
  });
}

class HsnSearchModal extends StatefulWidget {
  final String initialQuery;

  const HsnSearchModal({Key? key, this.initialQuery = ''}) : super(key: key);

  static Future<HsnSearchResult?> show(BuildContext context, {String initialQuery = ''}) {
    return showModalBottomSheet<HsnSearchResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HsnSearchModal(initialQuery: initialQuery),
    );
  }

  @override
  State<HsnSearchModal> createState() => _HsnSearchModalState();
}

class _HsnSearchModalState extends State<HsnSearchModal> {
  late TextEditingController _searchController;
  bool _isLoading = false;
  List<HsnSearchResult> _results = [];

  // In-memory global cache of full online GST HSN database (12,000+ entries)
  static List<HsnSearchResult>? _globalHsnCache;

  // Curated list of top common categories
  static final List<HsnSearchResult> _topFallbackList = [
    HsnSearchResult(hsnCode: '19053100', description: 'Sweet Biscuits, Wafers, Waffles, Crisps & Bakery Confectionery', gstRate: 18.0),
    HsnSearchResult(hsnCode: '19059010', description: 'Pastries, Cakes, Baked Goods, Cookies & Sweet Products', gstRate: 18.0),
    HsnSearchResult(hsnCode: '19059090', description: 'Bread, Buns, Toast, Pizza Base, Rusks & General Bakery Products', gstRate: 5.0),
    HsnSearchResult(hsnCode: '18063100', description: 'Chocolates, Chocolate Bars, Cocoa Preparations & Sweet Snacks', gstRate: 18.0),
    HsnSearchResult(hsnCode: '21069099', description: 'Food Preparations, Namkeen, Bhujia, Ready-to-Eat Snacks & Sweets', gstRate: 18.0),
    HsnSearchResult(hsnCode: '84713010', description: 'Computers, Laptops, Processors & Data Processing Devices', gstRate: 18.0),
    HsnSearchResult(hsnCode: '85171300', description: 'Mobile Phones, Smartphones, Telephones & Cellular Devices', gstRate: 18.0),
    HsnSearchResult(hsnCode: '84433290', description: 'Printers, Scanners, Multifunction Copiers & Cartridges', gstRate: 18.0),
    HsnSearchResult(hsnCode: '94033010', description: 'Wooden & Metal Office Furniture, Desks, Cabinets (Fixed Asset)', gstRate: 18.0),
    HsnSearchResult(hsnCode: '94013000', description: 'Swivel Chairs, Office Seats & Ergonomic Seating (Fixed Asset)', gstRate: 18.0),
    HsnSearchResult(hsnCode: '84151010', description: 'Air Conditioners, Split ACs, Window AC Units & HVAC (Fixed Asset)', gstRate: 28.0),
    HsnSearchResult(hsnCode: '84181010', description: 'Refrigerators, Commercial Freezers & Cooling Equipment', gstRate: 18.0),
    HsnSearchResult(hsnCode: '85285200', description: 'LED Monitors, Displays, Televisions & Projectors', gstRate: 18.0),
    HsnSearchResult(hsnCode: '87032191', description: 'Motor Cars, Passenger Vehicles, Automobiles (Fixed Asset)', gstRate: 28.0),
    HsnSearchResult(hsnCode: '87112019', description: 'Motorcycles, Scooters & Two-Wheelers (Fixed Asset)', gstRate: 28.0),
    HsnSearchResult(hsnCode: '87042190', description: 'Goods Trucks, Delivery Vans & Commercial Vehicles', gstRate: 28.0),
    HsnSearchResult(hsnCode: '84798999', description: 'Industrial Machinery, Plant Equipment & Mechanical Tools', gstRate: 18.0),
    HsnSearchResult(hsnCode: '85044090', description: 'Inverters, UPS, Electric Transformers & Power Adapters', gstRate: 18.0),
    HsnSearchResult(hsnCode: '25232910', description: 'Portland Cement, Hydraulic Building Cement', gstRate: 28.0),
    HsnSearchResult(hsnCode: '72142090', description: 'TMT Steel Bars, Iron Rods, Reinforcement Construction Steel', gstRate: 18.0),
    HsnSearchResult(hsnCode: '62034200', description: 'Mens Shirts, Trousers, Suits, Readymade Apparel', gstRate: 12.0),
    HsnSearchResult(hsnCode: '62046200', description: 'Womens Dresses, Sarees, Suits, Readymade Garments', gstRate: 12.0),
    HsnSearchResult(hsnCode: '61091000', description: 'Cotton T-Shirts, Vests, Knitwear Garments', gstRate: 5.0),
    HsnSearchResult(hsnCode: '64039990', description: 'Footwear, Leather Shoes, Boots, Sandals & Slippers', gstRate: 12.0),
    HsnSearchResult(hsnCode: '30049099', description: 'Medicines, Pharmaceutical Formulations, Tablets & Syrups', gstRate: 12.0),
    HsnSearchResult(hsnCode: '04012000', description: 'Fresh Milk, Unbranded Cream & Dairy Liquid', gstRate: 0.0),
    HsnSearchResult(hsnCode: '04021010', description: 'Skimmed Milk Powder, Condensed Milk, Ghee & Butter', gstRate: 12.0),
    HsnSearchResult(hsnCode: '10063010', description: 'Basmati Rice, Polished Rice & Grains', gstRate: 5.0),
    HsnSearchResult(hsnCode: '10019910', description: 'Wheat, Wheat Flour (Atta), Maida & Sooji', gstRate: 5.0),
    HsnSearchResult(hsnCode: '17011490', description: 'Refined Sugar, Cane Sugar, Jaggery (Gur)', gstRate: 5.0),
    HsnSearchResult(hsnCode: '15079010', description: 'Edible Cooking Oils, Soybean Oil, Mustard Oil, Sunflower Oil', gstRate: 5.0),
    HsnSearchResult(hsnCode: '22021010', description: 'Aerated Waters, Soft Drinks, Energy Drinks & Beverages', gstRate: 28.0),
    HsnSearchResult(hsnCode: '998311', description: 'IT Consulting, Software Development & Technical SAC Services', gstRate: 18.0),
    HsnSearchResult(hsnCode: '995411', description: 'Building Construction & Real Estate Civil Works SAC Services', gstRate: 18.0),
    HsnSearchResult(hsnCode: '998713', description: 'Maintenance, Repairs & Equipment Servicing SAC Expenses', gstRate: 18.0),
    HsnSearchResult(hsnCode: '996511', description: 'Goods Freight Transport, Logistics & Cargo Shipping SAC', gstRate: 5.0),
  ];

  static double _inferGstRate(String hsnCode) {
    if (hsnCode.startsWith('87') || hsnCode.startsWith('8415') || hsnCode.startsWith('2523') || hsnCode.startsWith('2202')) {
      return 28.0;
    }
    if (hsnCode.startsWith('61') || hsnCode.startsWith('62') || hsnCode.startsWith('64') || hsnCode.startsWith('3004') || hsnCode.startsWith('0402') || hsnCode.startsWith('4820') || hsnCode.startsWith('9608')) {
      return 12.0;
    }
    if (hsnCode.startsWith('10') || hsnCode.startsWith('1701') || hsnCode.startsWith('15') || hsnCode.startsWith('9965') || hsnCode.startsWith('3002')) {
      return 5.0;
    }
    if (hsnCode.startsWith('0401') || hsnCode.startsWith('07') || hsnCode.startsWith('08')) {
      return 0.0;
    }
    return 18.0;
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _loadOnlineDatasetAndSearch(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOnlineDatasetAndSearch(String query) async {
    setState(() => _isLoading = true);

    if (_globalHsnCache == null || _globalHsnCache!.isEmpty) {
      try {
        final url = Uri.parse('https://raw.githubusercontent.com/karthi-21/HSN-Code-Package/main/data/hsn_codes.json');
        final response = await http.get(url).timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          final List dynamicList = jsonDecode(response.body);
          final loaded = <HsnSearchResult>[];
          for (var item in dynamicList) {
            if (item is Map) {
              final code = item['code']?.toString() ?? '';
              final desc = item['description']?.toString() ?? '';
              if (code.isNotEmpty && desc.isNotEmpty) {
                loaded.add(HsnSearchResult(
                  hsnCode: code,
                  description: desc,
                  gstRate: _inferGstRate(code),
                ));
              }
            }
          }
          if (loaded.isNotEmpty) {
            _globalHsnCache = loaded;
          }
        }
      } catch (_) {
        // Fallback gracefully to curated dataset if offline or network error
      }
    }

    _filterResults(query);
  }

  void _filterResults(String query) {
    final cleanQ = query.trim().toLowerCase();
    final dataset = _globalHsnCache ?? _topFallbackList;

    List<HsnSearchResult> matches = [];

    if (cleanQ.isEmpty) {
      matches = List.from(_topFallbackList);
    } else {
      // Split query terms for multi-word search (e.g. "biscuit sweet", "cake bakery")
      final terms = cleanQ.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

      matches = dataset.where((item) {
        final codeLower = item.hsnCode.toLowerCase();
        final descLower = item.description.toLowerCase();

        return terms.every((term) => codeLower.contains(term) || descLower.contains(term));
      }).take(100).toList();

      // If multi-word search returned 0 items, try matching any single term
      if (matches.isEmpty && terms.length > 1) {
        matches = dataset.where((item) {
          final codeLower = item.hsnCode.toLowerCase();
          final descLower = item.description.toLowerCase();
          return terms.any((term) => codeLower.contains(term) || descLower.contains(term));
        }).take(100).toList();
      }
    }

    // Always include top fallback matches if relevant
    if (cleanQ.isNotEmpty) {
      for (var top in _topFallbackList) {
        if (top.description.toLowerCase().contains(cleanQ) || top.hsnCode.contains(cleanQ)) {
          if (!matches.any((m) => m.hsnCode == top.hsnCode)) {
            matches.insert(0, top);
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _results = matches;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.travel_explore_rounded, color: Colors.blue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live GST HSN Portal Search',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Instant search over 12,000+ official Indian GST HSN & SAC codes',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type item name (e.g. Biscuit, Cake, Laptop, Cement, Shirt)...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterResults('');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => _filterResults(val),
              onSubmitted: (val) => _filterResults(val),
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Loading live online GST HSN database...', style: TextStyle(fontSize: 12, color: Colors.blue)),
                ],
              ),
            ),

          // Results list
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: theme.colorScheme.outline),
                          const SizedBox(height: 12),
                          Text('No HSN code found for "${_searchController.text}"', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          const Text('Try typing product keywords like "biscuit", "cake", "electronics", or "garments".', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.hsnCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        title: Text(
                          item.description,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Estimated GST Rate: ${item.gstRate}%',
                          style: const TextStyle(fontSize: 11.5, color: Colors.teal, fontWeight: FontWeight.bold),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.pop(context, item);
                          },
                          child: const Text('Use HSN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        onTap: () {
                          Navigator.pop(context, item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
