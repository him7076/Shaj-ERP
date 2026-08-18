class ParsedWhatsappOrderItem {
  final String rawLine;
  final String itemDescription;
  final int quantity;

  ParsedWhatsappOrderItem({
    required this.rawLine,
    required this.itemDescription,
    required this.quantity,
  });
}

class ParsedWhatsappOrder {
  final String? shopName;
  final String? mobileNumber;
  final String? orderId;
  final String? salesRep;
  final String? dateStr;
  final double? messageAmount;
  final double? latitude;
  final double? longitude;
  final String? locationUrl;
  final List<ParsedWhatsappOrderItem> items;

  ParsedWhatsappOrder({
    this.shopName,
    this.mobileNumber,
    this.orderId,
    this.salesRep,
    this.dateStr,
    this.messageAmount,
    this.latitude,
    this.longitude,
    this.locationUrl,
    required this.items,
  });
}

class WhatsappOrderParser {
  static ParsedWhatsappOrder parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return ParsedWhatsappOrder(items: []);
    }

    // a. Shop Name: Shop\s*:\s*(.+)
    final shopMatch = RegExp(r'Shop\s*:\s*(.+)', caseSensitive: false).firstMatch(rawText);
    final shopName = shopMatch?.group(1)?.trim();

    // b. Mobile Number: Mob(?:ile)?\s*No\.?\s*:\s*(\d+)
    final mobileMatch = RegExp(r'Mob(?:ile)?\s*No\.?\s*:\s*(\d+)', caseSensitive: false).firstMatch(rawText);
    final mobileNumber = mobileMatch?.group(1)?.trim();

    // c. Order ID: Order\s*Id\s*:\s*(.+)', caseSensitive: false
    final orderIdMatch = RegExp(r'Order\s*Id\s*:\s*(.+)', caseSensitive: false).firstMatch(rawText);
    final orderId = orderIdMatch?.group(1)?.trim();

    // d. SalesRep Name: SalesRep\s*:\s*(.+)
    final salesRepMatch = RegExp(r'SalesRep\s*:\s*(.+)', caseSensitive: false).firstMatch(rawText);
    final salesRep = salesRepMatch?.group(1)?.trim();

    // e. Date: Date\s*:\s*(.+)
    final dateMatch = RegExp(r'Date\s*:\s*(.+)', caseSensitive: false).firstMatch(rawText);
    final dateStr = dateMatch?.group(1)?.trim();

    // g. Message Amount: Amount\s*:\s*([\d.]+)
    final amountMatch = RegExp(r'Amount\s*:\s*([\d.]+)', caseSensitive: false).firstMatch(rawText);
    final messageAmount = double.tryParse(amountMatch?.group(1) ?? '');

    // h. Location URL: Extract Google Maps URL & lat/lng
    final locUrlMatch = RegExp(r'(https?://[^\s]+)', caseSensitive: false).firstMatch(rawText);
    final locationUrl = locUrlMatch?.group(1)?.trim();

    double? latitude;
    double? longitude;
    if (locationUrl != null) {
      final latLngMatch = RegExp(r'(?:query|q)=([\d.-]+),([\d.-]+)').firstMatch(locationUrl);
      if (latLngMatch != null) {
        latitude = double.tryParse(latLngMatch.group(1) ?? '');
        longitude = double.tryParse(latLngMatch.group(2) ?? '');
      }
    }

    // f. Items List: Extract item lines
    final items = <ParsedWhatsappOrderItem>[];
    final lines = rawText.split('\n');

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Match item line with quantity pattern e.g. "(Quantity: 144)" or "Qty: 144"
      final qtyMatch = RegExp(r'\(?\s*(?:Quantity|Qty)\s*:\s*(\d+)\s*\)?', caseSensitive: false).firstMatch(trimmed);

      if (qtyMatch != null) {
        final qtyVal = int.tryParse(qtyMatch.group(1) ?? '1') ?? 1;

        // Clean raw line to extract item description
        String desc = trimmed.replaceFirst(RegExp(r'^\d+[\.\)\-]\s*'), '');
        desc = desc.replaceAll(RegExp(r'\(?\s*(?:Quantity|Qty)\s*:\s*\d+\s*\)?', caseSensitive: false), '').trim();

        if (desc.isNotEmpty) {
          items.add(ParsedWhatsappOrderItem(
            rawLine: trimmed,
            itemDescription: desc,
            quantity: qtyVal,
          ));
        }
      } else {
        // Fallback for numbered list lines like "1. Item Name - 10" or "1) Item Name 10"
        final numberedMatch = RegExp(r'^\d+[\.\)\-]\s*(.+?)\s+(\d+)\s*$', caseSensitive: false).firstMatch(trimmed);
        if (numberedMatch != null) {
          final desc = numberedMatch.group(1)?.trim() ?? '';
          final qtyVal = int.tryParse(numberedMatch.group(2) ?? '1') ?? 1;
          // Avoid matching metadata lines like Date or Mob No
          if (desc.isNotEmpty && !desc.toLowerCase().startsWith('mob') && !desc.toLowerCase().startsWith('shop') && !desc.toLowerCase().startsWith('date')) {
            items.add(ParsedWhatsappOrderItem(
              rawLine: trimmed,
              itemDescription: desc,
              quantity: qtyVal,
            ));
          }
        }
      }
    }

    return ParsedWhatsappOrder(
      shopName: shopName,
      mobileNumber: mobileNumber,
      orderId: orderId,
      salesRep: salesRep,
      dateStr: dateStr,
      messageAmount: messageAmount,
      latitude: latitude,
      longitude: longitude,
      locationUrl: locationUrl,
      items: items,
    );
  }
}
