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
  String? _errorMessage;

  // Master local offline dataset of standard GST HSN/SAC codes
  static final List<HsnSearchResult> _defaultHsnList = [
    HsnSearchResult(hsnCode: '8471', description: 'Computers, Laptops, Processors & Data Processing Equipment', gstRate: 18.0),
    HsnSearchResult(hsnCode: '8517', description: 'Mobile Phones, Smartphones, Telephones & Networking Devices', gstRate: 18.0),
    HsnSearchResult(hsnCode: '8443', description: 'Printers, Scanners, Multifunction Copiers & Inkjet Cartridges', gstRate: 18.0),
    HsnSearchResult(hsnCode: '9403', description: 'Wooden & Metal Furniture, Desks, Chairs, Cabinets, Fixed Asset Furniture', gstRate: 18.0),
    HsnSearchResult(hsnCode: '9401', description: 'Seats, Office Chairs, Sofa Sets & Fixed Asset Seating', gstRate: 18.0),
    HsnSearchResult(hsnCode: '8415', description: 'Air Conditioners, Split ACs, Window ACs, HVAC Systems', gstRate: 28.0),
    HsnSearchResult(hsnCode: '8418', description: 'Refrigerators, Freezers & Cooling Equipment', gstRate: 18.0),
    HsnSearchResult(hsnCode: '8528', description: 'Monitors, Televisions, LED Displays & Projectors', gstRate: 18.0),
    HsnSearchResult(hsnCode: '8703', description: 'Motor Cars, Passenger Vehicles, Automobiles (Fixed Asset)', gstRate: 28.0),
    HsnSearchResult(hsnCode: '8711', description: 'Motorcycles, Scooters, Two-Wheelers', gstRate: 28.0),
    HsnSearchResult(hsnCode: '8704', description: 'Goods Trucks, Delivery Vans, Cargo Vehicles', gstRate: 28.0),
    HsnSearchResult(hsnCode: '8479', description: 'Industrial Machinery, Mechanical Appliances, Heavy Equipment', gstRate: 18.0),
    HsnSearchResult(hsnCode: '8504', description: 'Transformers, Electric Inverters, UPS, Power Adapters', gstRate: 18.0),
    HsnSearchResult(hsnCode: '8501', description: 'Electric Motors, Generators & Alternators', gstRate: 18.0),
    HsnSearchResult(hsnCode: '2523', description: 'Portland Cement, Hydraulic Cement, Building Construction Materials', gstRate: 28.0),
    HsnSearchResult(hsnCode: '7214', description: 'TMT Steel Bars, Iron Rods, Reinforcement Construction Steel', gstRate: 18.0),
    HsnSearchResult(hsnCode: '6203', description: 'Mens Shirts, Trousers, Suits, Readymade Garments', gstRate: 12.0),
    HsnSearchResult(hsnCode: '6204', description: 'Womens Dresses, Sarees, Suits, Readymade Apparel', gstRate: 12.0),
    HsnSearchResult(hsnCode: '6109', description: 'T-Shirts, Singlets, Cotton Knit Vests', gstRate: 5.0),
    HsnSearchResult(hsnCode: '6403', description: 'Footwear, Leather Shoes, Boots, Sandals', gstRate: 12.0),
    HsnSearchResult(hsnCode: '3004', description: 'Medicines, Pharmaceutical Products, Tablets, Capsules', gstRate: 12.0),
    HsnSearchResult(hsnCode: '3002', description: 'Vaccines, Sera, Blood Fractions, Medical Biologics', gstRate: 5.0),
    HsnSearchResult(hsnCode: '9018', description: 'Medical Instruments, Surgical Equipment, Diagnostic Apparatus', gstRate: 12.0),
    HsnSearchResult(hsnCode: '0401', description: 'Fresh Milk, Dairy Products, Cream (Unbranded)', gstRate: 0.0),
    HsnSearchResult(hsnCode: '0402', description: 'Packaged Milk Powder, Condensed Milk, Butter, Ghee', gstRate: 12.0),
    HsnSearchResult(hsnCode: '1006', description: 'Rice, Basmati Rice, Paddy Grains', gstRate: 5.0),
    HsnSearchResult(hsnCode: '1001', description: 'Wheat, Meslin, Flour (Atta), Maida', gstRate: 5.0),
    HsnSearchResult(hsnCode: '1701', description: 'Cane Sugar, Refined Sugar, Jaggery', gstRate: 5.0),
    HsnSearchResult(hsnCode: '1507', description: 'Edible Cooking Oils, Soybean Oil, Mustard Oil, Sunflower Oil', gstRate: 5.0),
    HsnSearchResult(hsnCode: '2106', description: 'Food Preparations, Health Supplements, Snacks, Spices', gstRate: 18.0),
    HsnSearchResult(hsnCode: '2202', description: 'Soft Drinks, Aerated Mineral Water, Energy Beverages', gstRate: 28.0),
    HsnSearchResult(hsnCode: '3926', description: 'Plastic Articles, Polybags, Plastic Hardware & Containers', gstRate: 18.0),
    HsnSearchResult(hsnCode: '4819', description: 'Carton Boxes, Packaging Paper Containers, Corrugated Sheets', gstRate: 18.0),
    HsnSearchResult(hsnCode: '4820', description: 'Registers, Account Books, Notebooks, Stationery', gstRate: 12.0),
    HsnSearchResult(hsnCode: '9608', description: 'Pens, Ballpoint Pens, Markers, Writing Instruments', gstRate: 12.0),
    HsnSearchResult(hsnCode: '9983', description: 'Professional, Technical & IT Consulting Services (SAC Code)', gstRate: 18.0),
    HsnSearchResult(hsnCode: '9954', description: 'Construction & Real Estate Building Work Services (SAC Code)', gstRate: 18.0),
    HsnSearchResult(hsnCode: '9987', description: 'Maintenance, Repair & Servicing Expenses (SAC Code)', gstRate: 18.0),
    HsnSearchResult(hsnCode: '9965', description: 'Goods Transport Services, Freight & Logistics (SAC Code)', gstRate: 5.0),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _performSearch(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final cleanQ = query.trim().toLowerCase();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    List<HsnSearchResult> matchingLocal = [];
    if (cleanQ.isEmpty) {
      matchingLocal = List.from(_defaultHsnList);
    } else {
      matchingLocal = _defaultHsnList.where((item) {
        final codeMatch = item.hsnCode.contains(cleanQ);
        final descMatch = item.description.toLowerCase().contains(cleanQ);
        return codeMatch || descMatch;
      }).toList();
    }

    // Attempt live online search via public HSN GST Lookup API
    List<HsnSearchResult> onlineResults = [];
    if (cleanQ.isNotEmpty) {
      try {
        final url = Uri.parse('https://api.postalpincode.in/hsn/search?q=${Uri.encodeComponent(cleanQ)}');
        final response = await http.get(url).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            for (var obj in data) {
              if (obj is Map<String, dynamic>) {
                final hsn = obj['hsn']?.toString() ?? obj['code']?.toString() ?? '';
                final desc = obj['description']?.toString() ?? obj['name']?.toString() ?? '';
                final gst = double.tryParse(obj['gst']?.toString() ?? '18') ?? 18.0;
                if (hsn.isNotEmpty) {
                  onlineResults.add(HsnSearchResult(hsnCode: hsn, description: desc, gstRate: gst));
                }
              }
            }
          }
        }
      } catch (_) {
        // Fallback silently to comprehensive local dataset
      }
    }

    final combined = <HsnSearchResult>[];
    final seen = <String>{};

    for (var r in [...onlineResults, ...matchingLocal]) {
      if (seen.add(r.hsnCode)) {
        combined.add(r);
      }
    }

    if (mounted) {
      setState(() {
        _results = combined.isNotEmpty ? combined : matchingLocal;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.82,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header handle & title
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
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.search, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Online HSN / SAC Finder',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Search HSN code by item name or category',
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

          // Search Input Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type item name (e.g. Laptop, Cement, Shirt, Furniture)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => _performSearch(val),
              onSubmitted: (val) => _performSearch(val),
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: LinearProgressIndicator(),
            ),

          // Results List
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.manage_search_rounded, size: 48, color: theme.colorScheme.outline),
                          const SizedBox(height: 12),
                          Text('No HSN codes found for "${_searchController.text}"', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          const Text('Try typing a general category like "Equipment", "Garments", or "Computers".', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.hsnCode,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontSize: 14,
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
                          'Standard GST Rate: ${item.gstRate}%',
                          style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.pop(context, item);
                          },
                          child: const Text('Select', style: TextStyle(fontSize: 12)),
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
