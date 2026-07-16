import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/user_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/order_repository.dart';
import 'package:business_sahaj_erp/data/repositories/order_repository_impl.dart';
import 'package:business_sahaj_erp/core/services/gst_service.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:isar/isar.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return OrderRepositoryImpl(isar, prefs);
});

// Current User Role Provider
final currentUserRoleProvider = FutureProvider<String>((ref) async {
  final authState = ref.watch(authProvider);
  final email = authState.email;
  if (email == null) return 'Salesman'; // Default safety fallback

  final isar = ref.watch(isarProvider);
  final user = await isar.users.filter().emailEqualTo(email, caseSensitive: false).findFirst();
  return user?.role ?? 'Owner'; // default to Owner for testing or admin roles
});

// Cart item details state wrapper
class CartItemState {
  final Item item;
  final double quantity;
  final double freeQuantity;
  final double rate;
  final double discountPercent;
  final double discountAmount;
  final double gstPercent;

  const CartItemState({
    required this.item,
    this.quantity = 1.0,
    this.freeQuantity = 0.0,
    required this.rate,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    required this.gstPercent,
  });

  CartItemState copyWith({
    double? quantity,
    double? freeQuantity,
    double? rate,
    double? discountPercent,
    double? discountAmount,
    double? gstPercent,
  }) {
    return CartItemState(
      item: item,
      quantity: quantity ?? this.quantity,
      freeQuantity: freeQuantity ?? this.freeQuantity,
      rate: rate ?? this.rate,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      gstPercent: gstPercent ?? this.gstPercent,
    );
  }
}

// Order Cart Wrapper
class OrderCart {
  final Party? selectedParty;
  final List<CartItemState> items;
  final bool isGstInclusive;
  final double orderDiscountPercent;
  final double orderDiscountAmount;
  final String remarks;
  final String internalNotes;

  const OrderCart({
    this.selectedParty,
    this.items = const [],
    this.isGstInclusive = true,
    this.orderDiscountPercent = 0.0,
    this.orderDiscountAmount = 0.0,
    this.remarks = '',
    this.internalNotes = '',
  });

  OrderCart copyWith({
    Party? selectedParty,
    List<CartItemState>? items,
    bool? isGstInclusive,
    double? orderDiscountPercent,
    double? orderDiscountAmount,
    String? remarks,
    String? internalNotes,
  }) {
    return OrderCart(
      selectedParty: selectedParty ?? this.selectedParty,
      items: items ?? this.items,
      isGstInclusive: isGstInclusive ?? this.isGstInclusive,
      orderDiscountPercent: orderDiscountPercent ?? this.orderDiscountPercent,
      orderDiscountAmount: orderDiscountAmount ?? this.orderDiscountAmount,
      remarks: remarks ?? this.remarks,
      internalNotes: internalNotes ?? this.internalNotes,
    );
  }
}

// State Notifier for current shopping cart session
class CartNotifier extends StateNotifier<OrderCart> {
  final GstService _gstService = GstService();

  CartNotifier() : super(const OrderCart());

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

    // Compute discount amount if percent changes, or vice versa
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

  void setOrderDiscounts(double? percent, double? amount) {
    state = state.copyWith(
      orderDiscountPercent: percent ?? state.orderDiscountPercent,
      orderDiscountAmount: amount ?? state.orderDiscountAmount,
    );
  }

  void setRemarks(String remarks) {
    state = state.copyWith(remarks: remarks);
  }

  void clear() {
    state = const OrderCart();
  }

  // Calculate totals helper
  Map<String, double> calculateTotals(String? companyGst) {
    double subtotal = 0.0;
    double totalGst = 0.0;
    double totalDiscount = 0.0;

    final partyGst = state.selectedParty?.gstNumber;

    for (var cartItem in state.items) {
      final res = _gstService.calculateTax(
        rate: cartItem.rate,
        quantity: cartItem.quantity,
        gstRatePercent: cartItem.gstPercent,
        isInclusive: state.isGstInclusive,
        itemDiscountAmount: cartItem.discountAmount,
        companyGst: companyGst,
        partyGst: partyGst,
      );

      subtotal += res.taxableAmount;
      totalGst += res.gstAmount;
      totalDiscount += cartItem.discountAmount;
    }

    // Apply Order Level Discount
    double orderDiscountVal = state.orderDiscountAmount;
    if (state.orderDiscountPercent > 0) {
      orderDiscountVal = (subtotal + totalGst) * (state.orderDiscountPercent / 100.0);
    }
    totalDiscount += orderDiscountVal;

    final double rawGrandTotal = (subtotal + totalGst) - orderDiscountVal;
    final double roundedGrandTotal = rawGrandTotal.roundToDouble();
    final double roundOff = roundedGrandTotal - rawGrandTotal;

    return {
      'subtotal': subtotal,
      'discountAmount': totalDiscount,
      'totalGST': totalGst,
      'roundOff': roundOff,
      'grandTotal': roundedGrandTotal < 0 ? 0.0 : roundedGrandTotal,
    };
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, OrderCart>((ref) {
  return CartNotifier();
});

// Search & Filter State
class OrderSearchFilter {
  final String query;
  final String status; // 'All', 'Draft', 'Pending', 'Confirmed', 'Cancelled', 'Converted To Sale'
  final DateTimeRange? dateRange;
  final int? partyId;
  final String sortBy; // 'Recent', 'Amount High-Low', 'Amount Low-High'

  const OrderSearchFilter({
    this.query = '',
    this.status = 'All',
    this.dateRange,
    this.partyId,
    this.sortBy = 'Recent',
  });

  OrderSearchFilter copyWith({
    String? query,
    String? status,
    DateTimeRange? dateRange,
    int? partyId,
    String? sortBy,
  }) {
    return OrderSearchFilter(
      query: query ?? this.query,
      status: status ?? this.status,
      dateRange: dateRange ?? this.dateRange,
      partyId: partyId ?? this.partyId,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final orderSearchFilterProvider = StateProvider<OrderSearchFilter>((ref) => const OrderSearchFilter());

// Filtered Orders Provider
final filteredOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final filter = ref.watch(orderSearchFilterProvider);
  final repo = ref.watch(orderRepositoryProvider);

  var list = await repo.searchOrders(filter.query);

  // Load party links
  for (var order in list) {
    try { await order.party.load(); } catch (_) {}
    try { await order.orderItems.load(); } catch (_) {}
  }

  // Filter Status
  if (filter.status != 'All') {
    list = list.where((o) => o.status == filter.status).toList();
  }

  // Filter Party
  if (filter.partyId != null) {
    list = list.where((o) => (kIsWeb ? o.partyId : o.party.value?.id) == filter.partyId).toList();
  }

  // Filter Date Range
  if (filter.dateRange != null) {
    list = list.where((o) {
      if (o.orderDate == null) return false;
      return o.orderDate!.isAfter(filter.dateRange!.start.subtract(const Duration(days: 1))) &&
          o.orderDate!.isBefore(filter.dateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  // Sort
  switch (filter.sortBy) {
    case 'Recent':
      list.sort((a, b) => (b.orderDate ?? DateTime.now()).compareTo(a.orderDate ?? DateTime.now()));
      break;
    case 'Amount High-Low':
      list.sort((a, b) => (b.grandTotal ?? 0.0).compareTo(a.grandTotal ?? 0.0));
      break;
    case 'Amount Low-High':
      list.sort((a, b) => (a.grandTotal ?? 0.0).compareTo(b.grandTotal ?? 0.0));
      break;
  }

  return list;
});
