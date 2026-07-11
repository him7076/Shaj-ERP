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
  /// by comparing the first 2 digits (state code) of Company and Party GSTINs.
  bool isIntrastate(String? companyGst, String? partyGst) {
    if (companyGst == null || partyGst == null) return true; // Default to local if missing
    
    final cleanCompany = companyGst.trim().replaceAll(RegExp(r'\s+'), '');
    final cleanParty = partyGst.trim().replaceAll(RegExp(r'\s+'), '');

    if (cleanCompany.length < 2 || cleanParty.length < 2) return true;

    // Check if the state code digits match
    return cleanCompany.substring(0, 2) == cleanParty.substring(0, 2);
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
        if (isIntrastate(companyGst, partyGst)) {
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
