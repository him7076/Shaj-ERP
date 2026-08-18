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

      // Ignore metadata lines
      final lower = trimmed.toLowerCase();
      if (lower.startsWith('shop:') ||
          lower.startsWith('mob') ||
          lower.startsWith('order id:') ||
          lower.startsWith('salesrep:') ||
          lower.startsWith('date:') ||
          lower.startsWith('amount:') ||
          lower.startsWith('location:') ||
          lower.startsWith('items:')) {
        continue;
      }

      // Comprehensive regex for quantity patterns:
      // e.g. (Quantity: 144), (Qty: 144), (Qty - 144), (144 Pcs), (Quantity 144), Qty: 144, etc.
      final qtyRegex = RegExp(
        r'\(?\s*(?:Quantity|Qty|Quant|Qnty|Pcs|Pcs\.|Box|Carton|Cartons)?\s*[:=\-]?\s*(\d+)\s*(?:pcs|pcs\.|box|cartons|ctn|units)?\s*\)?',
        caseSensitive: false,
      );

      // Explicit pattern for bracketed or tagged quantity: (Quantity: 144) or (Qty: 144) or (144 Pcs) or Qty: 144
      final taggedQtyMatch = RegExp(
        r'(?:\(\s*(?:Quantity|Qty|Quant|Qnty)?\s*[:=\-]?\s*(\d+)\s*(?:pcs|pcs\.|box|cartons|ctn|units)?\s*\)|\b(?:Quantity|Qty|Quant|Qnty)\s*[:=\-]?\s*(\d+))',
        caseSensitive: false,
      ).firstMatch(trimmed);

      if (taggedQtyMatch != null) {
        final qtyStr = taggedQtyMatch.group(1) ?? taggedQtyMatch.group(2) ?? '1';
        final qtyVal = int.tryParse(qtyStr) ?? 1;

        // Clean raw line to extract item description
        String desc = trimmed.replaceFirst(RegExp(r'^\d+[\.\)\-]\s*'), '');
        desc = desc.replaceAll(RegExp(r'(?:\(\s*(?:Quantity|Qty|Quant|Qnty)?\s*[:=\-]?\s*\d+\s*(?:pcs|pcs\.|box|cartons|ctn|units)?\s*\)|\b(?:Quantity|Qty|Quant|Qnty)\s*[:=\-]?\s*\d+)', caseSensitive: false), '').trim();
        // Remove trailing dash/colon/comma left dangling
        desc = desc.replaceAll(RegExp(r'[\s:\-,]+$'), '').trim();

        if (desc.isNotEmpty) {
          items.add(ParsedWhatsappOrderItem(
            rawLine: trimmed,
            itemDescription: desc,
            quantity: qtyVal,
          ));
          continue;
        }
      }

      // Fallback 1: Match line ending with bracketed number e.g. "Creamland Strawberry (144)" or "Creamland Strawberry (144 Pcs)"
      final bracketedQtyMatch = RegExp(r'^(.*?)\s*\(\s*(\d+)\s*(?:pcs|pcs\.|box|units)?\s*\)\s*$', caseSensitive: false).firstMatch(trimmed);
      if (bracketedQtyMatch != null) {
        String desc = bracketedQtyMatch.group(1)?.replaceFirst(RegExp(r'^\d+[\.\)\-]\s*'), '').trim() ?? '';
        final qtyVal = int.tryParse(bracketedQtyMatch.group(2) ?? '1') ?? 1;
        desc = desc.replaceAll(RegExp(r'[\s:\-,]+$'), '').trim();

        if (desc.isNotEmpty) {
          items.add(ParsedWhatsappOrderItem(
            rawLine: trimmed,
            itemDescription: desc,
            quantity: qtyVal,
          ));
          continue;
        }
      }

      // Fallback 2: Match numbered list lines like "1. Item Name - 10" or "1) Item Name 10" or "1. Item Name 10"
      final numberedMatch = RegExp(r'^\d+[\.\)\-]\s*(.+?)(?:\s*[\-:]\s*|\s+)(\d+)\s*$', caseSensitive: false).firstMatch(trimmed);
      if (numberedMatch != null) {
        final desc = numberedMatch.group(1)?.replaceAll(RegExp(r'[\s:\-,]+$'), '').trim() ?? '';
        final qtyVal = int.tryParse(numberedMatch.group(2) ?? '1') ?? 1;

        if (desc.isNotEmpty && !desc.toLowerCase().startsWith('mob') && !desc.toLowerCase().startsWith('shop') && !desc.toLowerCase().startsWith('date')) {
          items.add(ParsedWhatsappOrderItem(
            rawLine: trimmed,
            itemDescription: desc,
            quantity: qtyVal,
          ));
          continue;
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
