import 'package:business_sahaj_erp/core/errors/exceptions.dart';

class GstCalculationResult {
  final double taxableAmount;
  final double gstRate;
  final double gstAmount;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalAmount;

  const GstCalculationResult({
    required this.taxableAmount,
    required this.gstRate,
    required this.gstAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalAmount,
  });

  factory GstCalculationResult.zero() {
    return const GstCalculationResult(
      taxableAmount: 0.0,
      gstRate: 0.0,
      gstAmount: 0.0,
      cgst: 0.0,
      sgst: 0.0,
      igst: 0.0,
      totalAmount: 0.0,
    );
  }
}

class GstService {
  /// Evaluates whether the transaction is Local (CGST+SGST) or Interstate (IGST)
  /// by comparing the first 2 digits (state code) of Company and Party GSTINs,
  /// or checking state names if GSTIN is missing.
  bool isIntrastate(String? companyGst, String? partyGst, {String? partyState}) {
    if (companyGst == null) return true; // Default to local
    
    final cleanCompany = companyGst.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleanCompany.length < 2) return true;
    final companyStateCode = cleanCompany.substring(0, 2);

    if (partyGst != null && partyGst.trim().replaceAll(RegExp(r'\s+'), '').length >= 2) {
      final cleanParty = partyGst.trim().replaceAll(RegExp(r'\s+'), '');
      final partyStateCode = cleanParty.substring(0, 2);
      return companyStateCode == partyStateCode;
    }

    if (partyState != null && partyState.trim().isNotEmpty) {
      final companyStateName = _getStateNameByCode(companyStateCode);
      if (companyStateName != null) {
        return _compareStates(companyStateName, partyState);
      }
    }

    return true; // Default to local if no other info is available
  }

  String? _getStateNameByCode(String code) {
    const codes = {
      '01': 'Jammu and Kashmir',
      '02': 'Himachal Pradesh',
      '03': 'Punjab',
      '04': 'Chandigarh',
      '05': 'Uttarakhand',
      '06': 'Haryana',
      '07': 'Delhi',
      '08': 'Rajasthan',
      '09': 'Uttar Pradesh',
      '10': 'Bihar',
      '11': 'Sikkim',
      '12': 'Arunachal Pradesh',
      '13': 'Nagaland',
      '14': 'Manipur',
      '15': 'Mizoram',
      '16': 'Tripura',
      '17': 'Meghalaya',
      '18': 'Assam',
      '19': 'West Bengal',
      '20': 'Jharkhand',
      '21': 'Odisha',
      '22': 'Chhattisgarh',
      '23': 'Madhya Pradesh',
      '24': 'Gujarat',
      '25': 'Daman and Diu',
      '26': 'Dadra and Nagar Haveli',
      '27': 'Maharashtra',
      '29': 'Karnataka',
      '30': 'Goa',
      '31': 'Lakshadweep',
      '32': 'Kerala',
      '33': 'Tamil Nadu',
      '34': 'Puducherry',
      '35': 'Andaman and Nicobar Islands',
      '36': 'Telangana',
      '37': 'Andhra Pradesh',
      '38': 'Ladakh',
    };
    return codes[code];
  }

  bool _compareStates(String s1, String s2) {
    String clean(String s) {
      return s.toLowerCase()
              .replaceAll('and', '')
              .replaceAll('&', '')
              .replaceAll(RegExp(r'\s+'), '');
    }
    return clean(s1) == clean(s2);
  }

  /// Calculates GST components for a line item
  GstCalculationResult calculateTax({
    required double rate,
    required double quantity,
    required double gstRatePercent,
    required bool isInclusive,
    required double itemDiscountAmount, // discount amount already deducted from price
    String? companyGst,
    String? partyGst,
    String? partyState,
  }) {
    try {
      if (rate < 0 || quantity < 0 || gstRatePercent < 0 || itemDiscountAmount < 0) {
        throw const GSTException('Invalid negative parameters provided for GST calculations.');
      }

      double taxableAmount;
      double gstAmount;
      double totalAmount;

      if (isInclusive) {
        // Inclusive Tax: Total price is constant, calculate taxable base
        final rawTotal = (rate * quantity) - itemDiscountAmount;
        totalAmount = rawTotal < 0 ? 0.0 : rawTotal;
        taxableAmount = totalAmount / (1 + (gstRatePercent / 100));
        gstAmount = totalAmount - taxableAmount;
      } else {
        // Exclusive Tax: Base rate is constant, add tax on top
        final rawBase = (rate * quantity) - itemDiscountAmount;
        taxableAmount = rawBase < 0 ? 0.0 : rawBase;
        gstAmount = taxableAmount * (gstRatePercent / 100);
        totalAmount = taxableAmount + gstAmount;
      }

      // CGST/SGST/IGST split
      double cgst = 0.0;
      double sgst = 0.0;
      double igst = 0.0;

      if (gstRatePercent > 0) {
        if (isIntrastate(companyGst, partyGst, partyState: partyState)) {
          cgst = gstAmount / 2.0;
          sgst = gstAmount / 2.0;
        } else {
          igst = gstAmount;
        }
      }

      return GstCalculationResult(
        taxableAmount: taxableAmount,
        gstRate: gstRatePercent,
        gstAmount: gstAmount,
        cgst: cgst,
        sgst: sgst,
        igst: igst,
        totalAmount: totalAmount,
      );
    } catch (e) {
      throw GSTException('GST Calculation failure: $e');
    }
  }
}
