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

  InvoiceCart({
    this.selectedParty,
    this.items = const [],
    this.isGstInclusive = true,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.invoiceType = 'Tax Invoice',
    this.paidAmount = 0.0,
    this.remarks = '',
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
    final existingIndex = state.items.indexWhere((element) => element.item.uuid == item.uuid);
    if (existingIndex != -1) {
      final current = state.items[existingIndex];
      updateItem(item.uuid!, quantity: current.quantity + qty);
      return;
    }

    final rate = item.sellRate ?? 0.0;
    final gst = item.gstRate ?? 18.0;

    final newItem = CartItemState(
      item: item,
      quantity: qty,
      rate: rate,
      gstPercent: gst,
    );

    state = state.copyWith(items: [...state.items, newItem]);
  }

  void updateItem(
    String itemUuid, {
    double? quantity,
    double? freeQuantity,
    double? rate,
    double? discountPercent,
    double? discountAmount,
  }) {
    final index = state.items.indexWhere((element) => element.item.uuid == itemUuid);
    if (index == -1) return;

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
      rate: rate,
      discountPercent: finalDiscPercent,
      discountAmount: finalDiscAmount,
    );

    final updatedList = List<CartItemState>.from(state.items);
    updatedList[index] = updated;
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
  }) {
    final double sub = invoice.subtotal ?? 0.0;
    final double discAmt = invoice.discountAmount ?? 0.0;
    final double discPct = sub > 0 ? (discAmt / sub * 100) : 0.0;
    state = InvoiceCart(
      selectedParty: party,
      items: items,
      isGstInclusive: true,
      discountPercent: discPct,
      discountAmount: discAmt,
      invoiceType: invoice.invoiceType ?? 'Tax Invoice',
      paidAmount: invoice.paidAmount ?? 0.0,
      dueDate: invoice.dueDate ?? DateTime.now(),
      remarks: invoice.remarks ?? '',
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
    final double roundedGrandTotal = rawGrandTotal.roundToDouble();
    final double roundOff = roundedGrandTotal - rawGrandTotal;
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

  const InvoiceSearchFilter({
    this.query = '',
    this.paymentStatus = 'All',
    this.dateRange,
    this.partyId,
    this.invoiceType = 'All',
    this.sortBy = 'Date',
  });

  InvoiceSearchFilter copyWith({
    String? query,
    String? paymentStatus,
    DateTimeRange? dateRange,
    int? partyId,
    String? invoiceType,
    String? sortBy,
  }) {
    return InvoiceSearchFilter(
      query: query ?? this.query,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      dateRange: dateRange ?? this.dateRange,
      partyId: partyId ?? this.partyId,
      invoiceType: invoiceType ?? this.invoiceType,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final invoiceSearchFilterProvider = StateProvider<InvoiceSearchFilter>((ref) => const InvoiceSearchFilter());

// Filtered Invoices Provider
final filteredInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final filter = ref.watch(invoiceSearchFilterProvider);
  final repo = ref.watch(invoiceRepositoryProvider);

  var list = await repo.searchInvoices(filter.query);

  // Load party links
  for (var invoice in list) {
    try { await invoice.party.load(); } catch (_) {}
    try { await invoice.invoiceItems.load(); } catch (_) {}
  }

  // Filter Payment Status
  if (filter.paymentStatus != 'All') {
    list = list.where((i) => i.paymentStatus == filter.paymentStatus).toList();
  }

  // Filter Invoice Type
  if (filter.invoiceType != 'All') {
    list = list.where((i) => i.invoiceType == filter.invoiceType).toList();
  }

  // Filter Party
  if (filter.partyId != null) {
    list = list.where((i) => (kIsWeb ? i.partyId : i.party.value?.id) == filter.partyId).toList();
  }

  // Filter Date Range
  if (filter.dateRange != null) {
    list = list.where((i) {
      if (i.invoiceDate == null) return false;
      return i.invoiceDate!.isAfter(filter.dateRange!.start.subtract(const Duration(days: 1))) &&
          i.invoiceDate!.isBefore(filter.dateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  // Sort
  switch (filter.sortBy) {
    case 'Date':
      list.sort((a, b) => (b.invoiceDate ?? DateTime.now()).compareTo(a.invoiceDate ?? DateTime.now()));
      break;
    case 'Amount High-Low':
      list.sort((a, b) => (b.grandTotal ?? 0.0).compareTo(a.grandTotal ?? 0.0));
      break;
    case 'Amount Low-High':
      list.sort((a, b) => (a.grandTotal ?? 0.0).compareTo(b.grandTotal ?? 0.0));
      break;
    case 'Due Date':
      list.sort((a, b) {
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      break;
  }

  return list;
});
