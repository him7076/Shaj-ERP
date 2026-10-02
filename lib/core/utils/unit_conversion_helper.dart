import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';

class UnitConversionHelper {
  /// Robustly checks whether two unit names or codes refer to the same unit type,
  /// taking into account common unit aliases, plurals, and case differences.
  static bool areUnitsMatching(String? u1, String? u2) {
    if (u1 == null || u2 == null) return false;
    final s1 = u1.trim().toLowerCase();
    final s2 = u2.trim().toLowerCase();
    if (s1.isEmpty || s2.isEmpty) return false;
    if (s1 == s2) return true;

    const aliases = [
      {'pcs', 'pc', 'piece', 'pieces', 'nos', 'no', 'number', 'numbers', 'unit', 'units', 'unt', 'tbs'},
      {'box', 'boxes', 'boxs', 'crt', 'carton', 'cartons', 'pkt', 'pack', 'packs', 'case', 'cases', 'bundle', 'bdl', 'pac'},
      {'kg', 'kgs', 'kilogram', 'kilograms'},
      {'gm', 'gms', 'gram', 'grams', 'g'},
      {'ltr', 'ltrs', 'litre', 'litres', 'liter', 'liters', 'l'},
      {'mtr', 'mtrs', 'meter', 'meters', 'm'},
      {'bag', 'bags'},
      {'btl', 'bottle', 'bottles'},
      {'doz', 'dozen', 'dozens'},
      {'can', 'cans'},
      {'tub', 'tube', 'tubes'},
      {'set', 'sets'},
      {'rol', 'roll', 'rolls'},
    ];

    for (var group in aliases) {
      if (group.contains(s1) && group.contains(s2)) {
        return true;
      }
    }

    if (s1.length > 2 && s2.length > 2) {
      if (s1.startsWith(s2) || s2.startsWith(s1)) return true;
    }
    return false;
  }

  /// Converts a transaction quantity in [transactionUnit] into Primary Unit stock quantity for [item].
  ///
  /// Example:
  /// Primary Unit = BOX, Secondary Unit = PCS, Conversion Factor = 10.0 (1 BOX = 10 PCS).
  /// - 2 BOXES -> 2.0 BOXES
  /// - 20 PCS -> 20.0 / 10.0 = 2.0 BOXES
  static double toPrimaryQuantity(Item item, double qty, String? transactionUnit) {
    if (transactionUnit == null || transactionUnit.trim().isEmpty) return qty;
    final convFactor = item.conversionFactor ?? 1.0;

    final secUnit = item.secondaryUnit;
    final primUnit = item.primaryUnitName ?? item.unit.value?.shortName ?? item.unit.value?.unitName;

    // Check if unit matches Primary Unit
    if (areUnitsMatching(transactionUnit, primUnit)) {
      return qty;
    }

    // Check if unit matches Secondary Unit
    if (secUnit != null && secUnit.isNotEmpty && areUnitsMatching(transactionUnit, secUnit)) {
      return convFactor > 0 ? (qty / convFactor) : qty;
    }

    // Check Tertiary Unit if defined
    final terUnit = item.tertiaryUnit;
    final terConv = item.secondaryToTertiaryConversion ?? 1.0;
    if (terUnit != null && terUnit.isNotEmpty && areUnitsMatching(transactionUnit, terUnit)) {
      final totalConv = convFactor * terConv;
      return totalConv > 0 ? (qty / totalConv) : qty;
    }

    return qty;
  }

  /// Calculates unit rate for [targetUnit] given the primary unit rate [primaryRate].
  ///
  /// Example:
  /// Primary Unit = BOX (Rate = ₹100), Secondary Unit = PCS (Conversion = 10.0).
  /// Rate for PCS = ₹100 / 10.0 = ₹10.
  static double getRateForUnit(Item item, double primaryRate, String? targetUnit) {
    if (targetUnit == null || targetUnit.trim().isEmpty) return primaryRate;
    final convFactor = item.conversionFactor ?? 1.0;

    final secUnit = item.secondaryUnit;
    final primUnit = item.primaryUnitName ?? item.unit.value?.shortName ?? item.unit.value?.unitName;

    if (areUnitsMatching(targetUnit, primUnit)) {
      return primaryRate;
    }

    if (secUnit != null && secUnit.isNotEmpty && areUnitsMatching(targetUnit, secUnit)) {
      return convFactor > 0 ? (primaryRate / convFactor) : primaryRate;
    }

    final terUnit = item.tertiaryUnit;
    final terConv = item.secondaryToTertiaryConversion ?? 1.0;
    if (terUnit != null && terUnit.isNotEmpty && areUnitsMatching(targetUnit, terUnit)) {
      final totalConv = convFactor * terConv;
      return totalConv > 0 ? (primaryRate / totalConv) : primaryRate;
    }

    return primaryRate;
  }
}
