import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/invoice_repository.dart';
import 'package:business_sahaj_erp/data/repositories/invoice_repository_impl.dart';
import 'package:business_sahaj_erp/core/services/outstanding_service.dart';
import 'package:business_sahaj_erp/core/services/gst_service.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/features/orders/presentation/providers/order_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:isar/isar.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return InvoiceRepositoryImpl(isar, prefs);
});

final outstandingServiceProvider = Provider<OutstandingService>((ref) {
  final partyRepo = ref.watch(partyRepositoryProvider);
  return OutstandingService(partyRepo);
});

// Direct Invoice Cart state structure
class InvoiceCart {
  final Party? selectedParty;
  final List<CartItemState> items;
  final bool isGstInclusive;
  final double discountPercent;
  final double discountAmount;
  final String invoiceType; // Tax Invoice, Retail Invoice, Cash Invoice, Credit Invoice
  final double paidAmount;
  final DateTime dueDate;
  final String remarks;
  final double? customRoundOff;

  InvoiceCart({
    this.selectedParty,
    this.items = const [],
    this.isGstInclusive = true,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.invoiceType = 'Tax Invoice',
    this.paidAmount = 0.0,
    this.remarks = '',
    this.customRoundOff,
    DateTime? dueDate,
  }) : dueDate = dueDate ?? DateTime.now().add(const Duration(days: 15)); // Default 15 days credit

  InvoiceCart copyWith({
    Party? selectedParty,
    List<CartItemState>? items,
    bool? isGstInclusive,
    double? discountPercent,
    double? discountAmount,
    String? invoiceType,
    double? paidAmount,
    DateTime? dueDate,
    String? remarks,
    double? customRoundOff,
  }) {
    return InvoiceCart(
      selectedParty: selectedParty ?? this.selectedParty,
      items: items ?? this.items,
      isGstInclusive: isGstInclusive ?? this.isGstInclusive,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      invoiceType: invoiceType ?? this.invoiceType,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      remarks: remarks ?? this.remarks,
      customRoundOff: customRoundOff ?? this.customRoundOff,
    );
  }
}


// State Notifier for Direct Invoice Creator
class InvoiceCartNotifier extends StateNotifier<InvoiceCart> {
  final GstService _gstService = GstService();

  InvoiceCartNotifier() : super(InvoiceCart());

  void setParty(Party? party) {
    state = state.copyWith(selectedParty: party);
  }

  void addItem(Item item, {double qty = 1.0}) {
    final rate = item.sellRate ?? 0.0;
    final gst = item.gstRate ?? 18.0;
    final defaultUnit = item.primaryUnitName ?? item.unit.value?.shortName ?? item.unit.value?.unitName ?? 'PCS';

    final newItem = CartItemState(
      item: item,
      quantity: qty,
      unit: defaultUnit,
      rate: rate,
      gstPercent: gst,
    );

    state = state.copyWith(items: [...state.items, newItem]);
  }

  void updateItemAt(
    int index, {
    double? quantity,
    double? freeQuantity,
    String? unit,
    double? rate,
    double? discountPercent,
    double? discountAmount,
    String? batchNumber,
    String? expiryDate,
    String? mfgDate,
  }) {
    if (index < 0 || index >= state.items.length) return;

    final current = state.items[index];

    double finalDiscPercent = discountPercent ?? current.discountPercent;
    double finalDiscAmount = discountAmount ?? current.discountAmount;

    if (discountPercent != null) {
      final targetRate = rate ?? current.rate;
      final targetQty = quantity ?? current.quantity;
      finalDiscAmount = (targetRate * targetQty) * (discountPercent / 100.0);
    } else if (discountAmount != null) {
      final targetRate = rate ?? current.rate;
      final targetQty = quantity ?? current.quantity;
      final totalBase = targetRate * targetQty;
      finalDiscPercent = totalBase > 0 ? (discountAmount / totalBase) * 100.0 : 0.0;
    }

    final updated = current.copyWith(
      quantity: quantity,
      freeQuantity: freeQuantity,
      unit: unit,
      rate: rate,
      discountPercent: finalDiscPercent,
      discountAmount: finalDiscAmount,
      batchNumber: batchNumber,
      expiryDate: expiryDate,
      mfgDate: mfgDate,
    );


    final updatedList = List<CartItemState>.from(state.items);
    updatedList[index] = updated;
    state = state.copyWith(items: updatedList);
  }

  void updateItem(
    String itemUuid, {
    double? quantity,
    double? freeQuantity,
    String? unit,
    double? rate,
    double? discountPercent,
    double? discountAmount,
  }) {
    final index = state.items.indexWhere((element) => element.item.uuid == itemUuid);
    if (index == -1) return;
    updateItemAt(
      index,
      quantity: quantity,
      freeQuantity: freeQuantity,
      unit: unit,
      rate: rate,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
    );
  }

  void removeItemAt(int index) {
    if (index < 0 || index >= state.items.length) return;
    final updatedList = List<CartItemState>.from(state.items);
    updatedList.removeAt(index);
    state = state.copyWith(items: updatedList);
  }

  void removeItem(String itemUuid) {
    state = state.copyWith(
      items: state.items.where((element) => element.item.uuid != itemUuid).toList(),
    );
  }

  void toggleGstInclusive(bool val) {
    state = state.copyWith(isGstInclusive: val);
  }

  void setType(String type) {
    state = state.copyWith(invoiceType: type);
  }

  void setPaidAmount(double amt) {
    state = state.copyWith(paidAmount: amt);
  }

  void setDueDate(DateTime date) {
    state = state.copyWith(dueDate: date);
  }

  void setRemarks(String remarks) {
    state = state.copyWith(remarks: remarks);
  }

  void setCustomRoundOff(double? val) {
    state = InvoiceCart(
      selectedParty: state.selectedParty,
      items: state.items,
      isGstInclusive: state.isGstInclusive,
      discountPercent: state.discountPercent,
      discountAmount: state.discountAmount,
      invoiceType: state.invoiceType,
      paidAmount: state.paidAmount,
      dueDate: state.dueDate,
      remarks: state.remarks,
      customRoundOff: val,
    );
  }

  void setDiscounts(double? percent, double? amount) {
    state = state.copyWith(
      discountPercent: percent ?? state.discountPercent,
      discountAmount: amount ?? state.discountAmount,
    );
  }

  void loadInvoice({
    required Party party,
    required Invoice invoice,
    required List<CartItemState> items,
    bool isGstInclusive = false,
  }) {
    final double sub = invoice.subtotal ?? 0.0;
    final double discAmt = invoice.discountAmount ?? 0.0;
    final double discPct = sub > 0 ? (discAmt / sub * 100) : 0.0;
    state = InvoiceCart(
      selectedParty: party,
      items: items,
      isGstInclusive: isGstInclusive,
      discountPercent: discPct,
      discountAmount: discAmt,
      invoiceType: invoice.invoiceType ?? 'Tax Invoice',
      paidAmount: invoice.paidAmount ?? 0.0,
      dueDate: invoice.dueDate ?? DateTime.now(),
      remarks: invoice.remarks ?? '',
      customRoundOff: invoice.roundOff,
    );
  }

  void clear() {
    state = InvoiceCart();
  }

  Map<String, double> calculateTotals(String? companyGst) {
    double subtotal = 0.0;
    double totalGst = 0.0;
    double totalDiscount = 0.0;

    final partyGst = state.selectedParty?.gstNumber;
    final partyState = state.selectedParty?.state;

    for (var cartItem in state.items) {
      final res = _gstService.calculateTax(
        rate: cartItem.rate,
        quantity: cartItem.quantity,
        gstRatePercent: cartItem.gstPercent,
        isInclusive: state.isGstInclusive,
        itemDiscountAmount: cartItem.discountAmount,
        companyGst: companyGst,
        partyGst: partyGst,
        partyState: partyState,
      );

      subtotal += res.taxableAmount;
      totalGst += res.gstAmount;
      totalDiscount += cartItem.discountAmount;
    }

    // Apply Order Level Discount
    double orderDiscountVal = state.discountAmount;
    if (state.discountPercent > 0) {
      orderDiscountVal = (subtotal + totalGst) * (state.discountPercent / 100.0);
    }
    totalDiscount += orderDiscountVal;

    final double rawGrandTotal = (subtotal + totalGst) - orderDiscountVal;
    final double roundOff = state.customRoundOff ?? (rawGrandTotal.roundToDouble() - rawGrandTotal);
    final double roundedGrandTotal = rawGrandTotal + roundOff;
    final double pending = roundedGrandTotal - state.paidAmount;

    return {
      'subtotal': subtotal,
      'discountAmount': totalDiscount,
      'totalGST': totalGst,
      'roundOff': roundOff,
      'grandTotal': roundedGrandTotal < 0 ? 0.0 : roundedGrandTotal,
      'pendingAmount': pending < 0 ? 0.0 : pending,
    };
  }
}


final invoiceCartProvider = StateNotifierProvider<InvoiceCartNotifier, InvoiceCart>((ref) {
  return InvoiceCartNotifier();
});

// Search & Filter State
class InvoiceSearchFilter {
  final String query;
  final String paymentStatus; // 'All', 'Unpaid', 'Partially Paid', 'Paid', 'Cancelled'
  final DateTimeRange? dateRange;
  final int? partyId;
  final String invoiceType; // 'All', 'Tax Invoice', 'Retail Invoice', 'Cash Invoice', 'Credit Invoice'
  final String sortBy; // 'Date', 'Amount High-Low', 'Amount Low-High', 'Due Date'
  final int limit;

  const InvoiceSearchFilter({
    this.query = '',
    this.paymentStatus = 'All',
    this.dateRange,
    this.partyId,
    this.invoiceType = 'All',
    this.sortBy = 'Date',
    this.limit = 50,
  });

  InvoiceSearchFilter copyWith({
    String? query,
    String? paymentStatus,
    DateTimeRange? dateRange,
    int? partyId,
    String? invoiceType,
    String? sortBy,
    int? limit,
  }) {
    return InvoiceSearchFilter(
      query: query ?? this.query,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      dateRange: dateRange ?? this.dateRange,
      partyId: partyId ?? this.partyId,
      invoiceType: invoiceType ?? this.invoiceType,
      sortBy: sortBy ?? this.sortBy,
      limit: limit ?? this.limit,
    );
  }
}

final invoiceSearchFilterProvider = StateProvider<InvoiceSearchFilter>((ref) => const InvoiceSearchFilter());

// Helper to build the base query for both list and totals
QueryBuilder<Invoice, Invoice, QAfterSortBy> _buildInvoiceQuery(Isar isar, InvoiceSearchFilter filter) {
  var qb = isar.invoices.filter().isDeletedEqualTo(false);
  
  if (filter.query.trim().isNotEmpty) {
    final q = filter.query.trim().toLowerCase();
    qb = qb.and().group((q2) => q2
      .invoiceNumberContains(q, caseSensitive: false)
      .or()
      .partyNameContains(q, caseSensitive: false)
      .or()
      .remarksContains(q, caseSensitive: false)
    );
  }
  
  if (filter.paymentStatus != 'All') {
    qb = qb.paymentStatusEqualTo(filter.paymentStatus);
  }
  
  if (filter.invoiceType != 'All') {
    qb = qb.invoiceTypeEqualTo(filter.invoiceType);
  }
  
  if (filter.partyId != null) {
    qb = qb.partyIdEqualTo(filter.partyId);
  }
  
  if (filter.dateRange != null) {
    qb = qb.and().invoiceDateBetween(
      filter.dateRange!.start.subtract(const Duration(days: 1)),
      filter.dateRange!.end.add(const Duration(days: 1))
    );
  }

  // Sort
  switch (filter.sortBy) {
    case 'Date':
      return qb.sortByInvoiceDateDesc();
    case 'Amount High-Low':
      return qb.sortByGrandTotalDesc();
    case 'Amount Low-High':
      return qb.sortByGrandTotal();
    case 'Due Date':
      return qb.sortByDueDateDesc();
    default:
      return qb.sortByInvoiceDateDesc();
  }
}

// Filtered Invoices Provider (Paginated for UI)
final filteredInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final filter = ref.watch(invoiceSearchFilterProvider);
  final isar = ref.watch(isarProvider);
  
  final qb = _buildInvoiceQuery(isar, filter);
  return await qb.limit(filter.limit).findAll();
});

class InvoiceTotals {
  final int count;
  final double totalSales;
  final double totalBalanceDue;
  const InvoiceTotals(this.count, this.totalSales, this.totalBalanceDue);
}

// Provider for accurate totals without loading full DB objects into RAM
final invoiceTotalsProvider = FutureProvider<InvoiceTotals>((ref) async {
  final filter = ref.watch(invoiceSearchFilterProvider);
  final isar = ref.watch(isarProvider);
  
  final qb = _buildInvoiceQuery(isar, filter);
  
  // Isar property fetching is highly optimized and avoids deserializing full objects
  final count = await qb.count();
  final grandTotals = await qb.grandTotalProperty().findAll();
  final pendingAmounts = await qb.pendingAmountProperty().findAll();
  
  final totalSales = grandTotals.whereType<double>().fold(0.0, (sum, val) => sum + val);
  final totalBalanceDue = pendingAmounts.whereType<double>().fold(0.0, (sum, val) => sum + val);
  
  return InvoiceTotals(count, totalSales, totalBalanceDue);
});
