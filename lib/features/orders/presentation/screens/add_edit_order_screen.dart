import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:business_sahaj_erp/features/orders/presentation/providers/order_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/screens/add_edit_party_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_item_sheet.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/utils/distance_calculator.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';

class AddEditOrderScreen extends ConsumerStatefulWidget {
  final String? orderUuid;

  const AddEditOrderScreen({Key? key, this.orderUuid}) : super(key: key);

  @override
  ConsumerState<AddEditOrderScreen> createState() => _AddEditOrderScreenState();
}

class _AddEditOrderScreenState extends ConsumerState<AddEditOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  Position? _currentPosition;
  bool _loadingLocation = false;
  bool _isSaving = false;

  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _discountPercentController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();

  Order? _existingOrder;
  DateTime _orderDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).clear();
      if (widget.orderUuid != null) {
        _loadExistingOrder();
      } else {
        _fetchGPSLocation();
      }
    });
  }

  Future<void> _loadExistingOrder() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final order = await repo.getByUuid(widget.orderUuid!);
      if (order != null) {
        try { await order.party.load(); } catch (_) {}
        try { await order.orderItems.load(); } catch (_) {}

        _existingOrder = order;
        _remarksController.text = order.remarks ?? '';
        _discountController.text = order.discountAmount?.toString() ?? '';
        _discountPercentController.text = order.discountPercent?.toString() ?? '';
        if (order.orderDate != null) {
          _orderDate = order.orderDate!;
        }

        final cart = ref.read(cartProvider.notifier);
        cart.setParty(order.party.value);
        cart.toggleGstInclusive(true);
        cart.setOrderDiscounts(order.discountPercent, order.discountAmount);

        for (var orderItem in order.orderItems) {
          try { await orderItem.item.load(); } catch (_) {}
          if (orderItem.item.value != null) {
            cart.addItem(orderItem.item.value!, qty: orderItem.quantity ?? 0.0);
            cart.updateItem(
              orderItem.item.value!.uuid!,
              freeQuantity: orderItem.freeQuantity,
              rate: orderItem.rate,
              discountAmount: orderItem.discountAmount,
              discountPercent: orderItem.discountPercent,
            );
          }
        }
      }
    } catch (e) {
      logger.error('Failed to load existing order into cart', e);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _fetchGPSLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final gps = ref.read(gpsServiceProvider);
      final pos = await gps.getCurrentLocation();
      setState(() {
        _currentPosition = pos;
      });
      logger.info('Captured location coordinates: ${pos.latitude}, ${pos.longitude}');
    } catch (e) {
      logger.error('Failed to capture location coordinates', e);
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _discountController.dispose();
    _discountPercentController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  Future<void> _saveOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first.')),
      );
      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add at least one item.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final authState = ref.read(authProvider);
      final userEmail = authState.email ?? 'salesman@sahaj.com';

      final repo = ref.read(orderRepositoryProvider);
      final companySettings = await ref.read(databaseServiceProvider).isar.settings.where().findFirst();
      final companyGst = companySettings?.companyGST;

      final totals = ref.read(cartProvider.notifier).calculateTotals(companyGst);

      final order = _existingOrder ?? Order();
      if (_existingOrder == null) {
        order.orderNumber = await repo.generateNextOrderNumber();
        order.status = 'Pending';
        order.createdBy = userEmail;
      } else {
        order.editedBy = userEmail;
        order.editTime = DateTime.now();
      }

      order.orderDate = _orderDate;
      order.partyId = cart.selectedParty!.id;
      order.partyName = cart.selectedParty!.partyName;
      order.mobileNumber = cart.selectedParty!.mobileNumber;
      order.gstNumber = cart.selectedParty!.gstNumber;
      
      if (_currentPosition != null) {
        order.latitude = _currentPosition!.latitude;
        order.longitude = _currentPosition!.longitude;
        order.locationAddress = await ref.read(gpsServiceProvider).reverseGeocode(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            );
      }

      order.subtotal = totals['subtotal'];
      order.discountAmount = totals['discountAmount'];
      order.discountPercent = double.tryParse(_discountPercentController.text) ?? 0.0;
      order.totalGST = totals['totalGST'];
      order.roundOff = totals['roundOff'];
      order.grandTotal = totals['grandTotal'];
      order.remarks = _remarksController.text.trim();

      order.party.value = cart.selectedParty;

      final List<OrderItem> orderItems = cart.items.map((cartItem) {
        final orderItem = OrderItem()
          ..itemId = cartItem.item.id
          ..itemName = cartItem.item.itemName
          ..hsnCode = cartItem.item.hsnCode
          ..quantity = cartItem.quantity
          ..freeQuantity = cartItem.freeQuantity
          ..rate = cartItem.rate
          ..discountAmount = cartItem.discountAmount
          ..discountPercent = cartItem.discountPercent
          ..taxableAmount = cartItem.quantity * cartItem.rate - cartItem.discountAmount
          ..gstPercent = cartItem.gstPercent
          ..gstAmount = cartItem.gstPercent * cartItem.rate * 0.01
          ..totalAmount = cartItem.quantity * cartItem.rate - cartItem.discountAmount;

        orderItem.item.value = cartItem.item;
        return orderItem;
      }).toList();

      await repo.saveOrder(order, orderItems);

      ref.invalidate(filteredOrdersProvider);
      ref.invalidate(dashboardAnalyticsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sales Order #${order.orderNumber} recorded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.error('Failed to save Sales Order', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save order: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (_isSaving) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPartyAndHeaderCard(theme),
        const SizedBox(height: 16),
        _buildProductSearchAndCatalog(theme),
        const SizedBox(height: 16),
        _buildCartItemsTable(theme, cart),
      ],
    );

    final summaryContent = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Order settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('GST Inclusive Pricing'),
              value: cart.isGstInclusive,
              onChanged: (val) {
                ref.read(cartProvider.notifier).toggleGstInclusive(val);
              },
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _discountPercentController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Disc %', border: OutlineInputBorder()),
                    onChanged: (val) {
                      final double? pct = double.tryParse(val);
                      ref.read(cartProvider.notifier).setOrderDiscounts(pct, null);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Disc Amt (₹)', border: OutlineInputBorder()),
                    onChanged: (val) {
                      final double? amt = double.tryParse(val);
                      ref.read(cartProvider.notifier).setOrderDiscounts(null, amt);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'Remarks / Terms', border: OutlineInputBorder()),
            ),
            const Divider(height: 32),
            _buildTotalsSummaryPanel(theme),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: Text(widget.orderUuid != null ? 'Update Sales Order' : 'Save Sales Order'),
              onPressed: _saveOrder,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orderUuid != null ? 'Edit Sales Order' : 'Record Sales Order'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: mainContent),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: summaryContent),
                ],
              )
            : Column(
                children: [
                  mainContent,
                  const SizedBox(height: 16),
                  summaryContent,
                ],
              ),
      ),
    );
  }

  Widget _buildPartyAndHeaderCard(ThemeData theme) {
    final partiesAsync = ref.watch(partiesListProvider);
    final cart = ref.watch(cartProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Billing Party Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: partiesAsync.when(
                    data: (parties) {
                      final customerParties = parties.where((p) => p.partyType != 'Supplier').toList();
                      return DropdownButtonFormField<Party>(
                        value: cart.selectedParty != null && customerParties.any((p) => p.uuid == cart.selectedParty!.uuid)
                            ? customerParties.firstWhere((p) => p.uuid == cart.selectedParty!.uuid)
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Select Customer Account',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_pin),
                        ),
                        items: customerParties.map((p) {
                          return DropdownMenuItem<Party>(value: p, child: Text(p.partyName ?? ''));
                        }).toList(),
                        onChanged: (party) {
                          ref.read(cartProvider.notifier).setParty(party);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading customers: $e'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.person_add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddEditPartyScreen()),
                    ).then((_) => ref.invalidate(partiesListProvider));
                  },
                ),
              ],
            ),
            if (cart.selectedParty != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GST: ${cart.selectedParty!.gstNumber ?? "Unregistered"} | City: ${cart.selectedParty!.city ?? "N/A"} | Current Outstanding: ₹${cart.selectedParty!.outstandingBalance?.toStringAsFixed(2) ?? "0.00"}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _orderDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null) {
                        setState(() => _orderDate = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Order Date', border: OutlineInputBorder()),
                      child: Text(DateFormat('dd-MM-yyyy').format(_orderDate)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSearchAndCatalog(ThemeData theme) {
    final itemsAsync = ref.watch(filteredItemsProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search & Add Products', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: itemsAsync.when(
                    data: (items) {
                      return Autocomplete<Item>(
                        displayStringForOption: (item) => '${item.itemName ?? "Unnamed"} (Stock: ${item.currentStock?.toInt() ?? 0})',
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return items.take(20);
                          }
                          final query = textEditingValue.text.toLowerCase();
                          return items.where((item) {
                            final name = item.itemName?.toLowerCase() ?? '';
                            final code = item.itemCode?.toLowerCase() ?? '';
                            return name.contains(query) || code.contains(query);
                          });
                        },
                        optionsMaxHeight: 300,
                        onSelected: (item) {
                          ref.read(cartProvider.notifier).addItem(item);
                          FocusScope.of(context).unfocus();
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 300, maxWidth: 500),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final item = options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(Icons.inventory_2_outlined, size: 20, color: theme.colorScheme.primary),
                                      title: Text(item.itemName ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      subtitle: Text(
                                        'Code: ${item.itemCode ?? "N/A"} | Price: ₹${item.sellRate?.toStringAsFixed(2) ?? "0"} | Stock: ${item.currentStock?.toInt() ?? 0}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      onTap: () => onSelected(item),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Type product name to add...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading products: $e'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final newlyCreated = await AddItemSheet.show(context);
                    if (newlyCreated != null) {
                      ref.read(cartProvider.notifier).addItem(newlyCreated);
                      ref.invalidate(filteredItemsProvider);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsTable(ThemeData theme, OrderCart cart) {
    if (cart.items.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No product lines added yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Billing Cart lines', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cart.items.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final cartItem = cart.items[index];
                return OrderCartItemRow(
                  cartItem: cartItem,
                  isGstInclusive: cart.isGstInclusive,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsSummaryPanel(ThemeData theme) {
    final cart = ref.watch(cartProvider);
    return FutureBuilder<Settings?>(
      future: ref.read(databaseServiceProvider).isar.settings.where().findFirst(),
      builder: (context, snapshot) {
        final companyGst = snapshot.data?.companyGST;
        final totals = ref.read(cartProvider.notifier).calculateTotals(companyGst);

        final cleanCompany = companyGst?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
        final cleanParty = cart.selectedParty?.gstNumber?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
        final isLocal = cleanCompany.length >= 2 && cleanParty.length >= 2 && cleanCompany.substring(0, 2) == cleanParty.substring(0, 2);

        final totalGst = totals['totalGST'] ?? 0.0;
        final cgst = isLocal ? totalGst / 2.0 : 0.0;
        final sgst = isLocal ? totalGst / 2.0 : 0.0;
        final igst = isLocal ? 0.0 : totalGst;

        return Column(
          children: [
            _buildSummaryRow('Subtotal (Taxable Value)', totals['subtotal']!, theme),
            _buildSummaryRow('Discounts Total', -totals['discountAmount']!, theme),
            if (isLocal) ...[
              _buildSummaryRow('CGST (9%)', cgst, theme),
              _buildSummaryRow('SGST (9%)', sgst, theme),
            ] else ...[
              _buildSummaryRow('IGST (18%)', igst, theme),
            ],
            _buildSummaryRow('Round Off', totals['roundOff']!, theme),
            const Divider(),
            _buildSummaryRow('GRAND TOTAL', totals['grandTotal']!, theme, isBold: true),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double val, ThemeData theme, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 15 : 13,
            ),
          ),
          Text(
            '₹${val.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 15 : 13,
              color: isBold ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderCartItemRow extends ConsumerStatefulWidget {
  final CartItemState cartItem;
  final bool isGstInclusive;
  const OrderCartItemRow({Key? key, required this.cartItem, required this.isGstInclusive}) : super(key: key);

  @override
  ConsumerState<OrderCartItemRow> createState() => _OrderCartItemRowState();
}

class _OrderCartItemRowState extends ConsumerState<OrderCartItemRow> {
  late TextEditingController _qtyController;
  late TextEditingController _freeQtyController;
  late TextEditingController _rateExclController;
  late TextEditingController _rateInclController;
  late TextEditingController _discPercentController;
  late TextEditingController _discAmountController;

  bool _isUpdatingLocally = false;

  @override
  void initState() {
    super.initState();
    final item = widget.cartItem;
    final gstPct = item.gstPercent;
    
    final double rateExcl = widget.isGstInclusive 
        ? item.rate / (1 + gstPct / 100.0) 
        : item.rate;
    final double rateIncl = widget.isGstInclusive 
        ? item.rate 
        : item.rate * (1 + gstPct / 100.0);

    _qtyController = TextEditingController(text: item.quantity.toInt().toString());
    _freeQtyController = TextEditingController(text: item.freeQuantity.toInt().toString());
    _rateExclController = TextEditingController(text: rateExcl.toStringAsFixed(2));
    _rateInclController = TextEditingController(text: rateIncl.toStringAsFixed(2));
    _discPercentController = TextEditingController(text: item.discountPercent.toString());
    _discAmountController = TextEditingController(text: item.discountAmount.toString());
  }
  
  @override
  void didUpdateWidget(OrderCartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isUpdatingLocally) return;
    
    final item = widget.cartItem;
    final gstPct = item.gstPercent;
    
    final double rateExcl = widget.isGstInclusive 
        ? item.rate / (1 + gstPct / 100.0) 
        : item.rate;
    final double rateIncl = widget.isGstInclusive 
        ? item.rate 
        : item.rate * (1 + gstPct / 100.0);

    _updateIfChanged(_qtyController, item.quantity.toInt().toString());
    _updateIfChanged(_freeQtyController, item.freeQuantity.toInt().toString());
    _updateIfChanged(_rateExclController, rateExcl.toStringAsFixed(2));
    _updateIfChanged(_rateInclController, rateIncl.toStringAsFixed(2));
    _updateIfChanged(_discPercentController, item.discountPercent.toString());
    _updateIfChanged(_discAmountController, item.discountAmount.toString());
  }

  void _updateIfChanged(TextEditingController controller, String value) {
    if (controller.text != value && double.tryParse(controller.text) != double.tryParse(value)) {
      controller.text = value;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _freeQtyController.dispose();
    _rateExclController.dispose();
    _rateInclController.dispose();
    _discPercentController.dispose();
    _discAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.cartItem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.item.itemName ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                ref.read(cartProvider.notifier).removeItem(item.item.uuid!);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? qty = double.tryParse(val);
                  if (qty != null && qty >= 0) {
                    ref.read(cartProvider.notifier).updateItem(item.item.uuid!, quantity: qty);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _freeQtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Free Qty', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? qty = double.tryParse(val);
                  if (qty != null) {
                    ref.read(cartProvider.notifier).updateItem(item.item.uuid!, freeQuantity: qty);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _rateExclController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Rate Excl (₹)', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? excl = double.tryParse(val);
                  if (excl == null) return;
                  
                  final gstPct = item.gstPercent;
                  final incl = excl * (1 + gstPct / 100.0);
                  
                  _isUpdatingLocally = true;
                  _rateInclController.text = incl.toStringAsFixed(2);
                  
                  final targetRate = widget.isGstInclusive ? incl : excl;
                  ref.read(cartProvider.notifier).updateItem(
                    item.item.uuid!,
                    rate: targetRate,
                  );
                  _isUpdatingLocally = false;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _rateInclController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Rate Incl (₹)', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? incl = double.tryParse(val);
                  if (incl == null) return;
                  
                  final gstPct = item.gstPercent;
                  final excl = incl / (1 + gstPct / 100.0);
                  
                  _isUpdatingLocally = true;
                  _rateExclController.text = excl.toStringAsFixed(2);
                  
                  final targetRate = widget.isGstInclusive ? incl : excl;
                  ref.read(cartProvider.notifier).updateItem(
                    item.item.uuid!,
                    rate: targetRate,
                  );
                  _isUpdatingLocally = false;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _discPercentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Disc %', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? pct = double.tryParse(val);
                  if (pct != null) {
                    ref.read(cartProvider.notifier).updateItem(item.item.uuid!, discountPercent: pct);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _discAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Disc Amt (₹)', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? amt = double.tryParse(val);
                  if (amt != null) {
                    ref.read(cartProvider.notifier).updateItem(item.item.uuid!, discountAmount: amt);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'GST Tax %', isDense: true, border: OutlineInputBorder()),
                child: Text('${item.gstPercent.toInt()}%'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
