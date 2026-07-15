import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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

class AddEditOrderScreen extends ConsumerStatefulWidget {
  final String? orderUuid;

  const AddEditOrderScreen({Key? key, this.orderUuid}) : super(key: key);

  @override
  ConsumerState<AddEditOrderScreen> createState() => _AddEditOrderScreenState();
}

class _AddEditOrderScreenState extends ConsumerState<AddEditOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Page States
  Position? _currentPosition;
  bool _loadingLocation = false;
  bool _isSaving = false;

  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _discountPercentController = TextEditingController();

  Order? _existingOrder;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Clear cart for a fresh order, or load existing order if editing
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

        final cart = ref.read(cartProvider.notifier);
        cart.setParty(order.party.value);
        cart.toggleGstInclusive(true); // default inclusive
        cart.setOrderDiscounts(order.discountPercent, order.discountAmount);

        // Load items into cart
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
    _tabController.dispose();
    _remarksController.dispose();
    _discountController.dispose();
    _discountPercentController.dispose();
    super.dispose();
  }

  Future<void> _saveOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first.')),
      );
      _tabController.animateTo(0);
      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add at least one item.')),
      );
      _tabController.animateTo(1);
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

      // Create Order
      final order = _existingOrder ?? Order();
      if (_existingOrder == null) {
        order.orderNumber = await repo.generateNextOrderNumber();
        order.status = 'Pending'; // salesman creates in pending state
        order.createdBy = userEmail;
      } else {
        order.editedBy = userEmail;
        order.editTime = DateTime.now();
      }

      order.orderDate = DateTime.now();
      order.partyId = cart.selectedParty!.id;
      order.partyName = cart.selectedParty!.partyName;
      order.mobileNumber = cart.selectedParty!.mobileNumber;
      order.gstNumber = cart.selectedParty!.gstNumber;
      
      // Capture GPS location
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

      // Map cart items to OrderItems
      final List<OrderItem> orderItems = cart.items.map((cartItem) {
        final orderItem = OrderItem()
          ..itemId = cartItem.item.id
          ..itemName = cartItem.item.itemName
          ..hsnCode = cartItem.item.hsnCode
          ..quantity = cartItem.quantity
          ..freeQuantity = cartItem.freeQuantity
          ..unit = cartItem.item.unit.value?.shortName ?? 'PCS'
          ..rate = cartItem.rate
          ..discountPercent = cartItem.discountPercent
          ..discountAmount = cartItem.discountAmount
          ..gstPercent = cartItem.gstPercent
          ..gstAmount = cartItem.gstPercent * cartItem.rate * 0.01 // rough split
          ..totalAmount = cartItem.quantity * cartItem.rate - cartItem.discountAmount;

        orderItem.item.value = cartItem.item;
        return orderItem;
      }).toList();

      await repo.saveOrder(order, orderItems);

      // Refresh list
      ref.invalidate(filteredOrdersProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.orderNumber} saved successfully!'),
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
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orderUuid == null ? 'Create Sales Order' : 'Edit Sales Order'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '1. Customer', icon: Icon(Icons.person_outline)),
            Tab(text: '2. Select Items', icon: Icon(Icons.shopping_bag_outlined)),
            Tab(text: '3. Cart Review', icon: Icon(Icons.shopping_cart_outlined)),
          ],
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPartySelectionTab(),
                _buildProductCatalogTab(),
                _buildCartTab(),
              ],
            ),
    );
  }

  Widget _buildPartySelectionTab() {
    final theme = Theme.of(context);
    final partiesAsync = ref.watch(partiesListProvider);

    return partiesAsync.when(
      data: (parties) {
        // Sort parties nearest-first if GPS coordinates exist
        final List<Party> sortedParties = List.from(parties);
        if (_currentPosition != null) {
          sortedParties.sort((a, b) {
            final distA = DistanceCalculator.calculateDistanceInMeters(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              a.latitude ?? 0.0,
              a.longitude ?? 0.0,
            );
            final distB = DistanceCalculator.calculateDistanceInMeters(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              b.latitude ?? 0.0,
              b.longitude ?? 0.0,
            );
            return distA.compareTo(distB);
          });
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentPosition != null
                          ? 'GPS Captured. Nearest shops listed first.'
                          : 'GPS location pending...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _currentPosition != null ? Colors.green.shade800 : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_loadingLocation)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: _fetchGPSLocation,
                      tooltip: 'Capture GPS Location',
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: sortedParties.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final party = sortedParties[index];
                  final isSelected = ref.watch(cartProvider).selectedParty?.uuid == party.uuid;

                  double? distance;
                  if (_currentPosition != null && party.latitude != null && party.longitude != null) {
                    distance = DistanceCalculator.calculateDistanceInMeters(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      party.latitude!,
                      party.longitude!,
                    );
                  }

                  return ListTile(
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    title: Text(party.partyName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('GST: ${party.gstNumber ?? "Unregistered"} | Address: ${party.city ?? "N/A"}'),
                    leading: CircleAvatar(
                      child: Text(party.partyName?.substring(0, 1).toUpperCase() ?? ''),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (distance != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              DistanceCalculator.formatDistance(distance),
                              style: TextStyle(color: Colors.green.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (isSelected) const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    onTap: () {
                      ref.read(cartProvider.notifier).setParty(party);
                      _tabController.animateTo(1);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add New Customer Account'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditPartyScreen(),
                    ),
                  ).then((_) => ref.invalidate(partiesListProvider));
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load customers: $e')),
    );
  }

  Widget _buildProductCatalogTab() {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(filteredItemsProvider);
    final cart = ref.watch(cartProvider);

    return Column(
      children: [
        // Horizontal warning panel
        Container(
          padding: const EdgeInsets.all(10),
          color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
          child: Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cart Basket contains: ${cart.items.length} product lines.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: const Text('Review Cart'),
              ),
            ],
          ),
        ),
        Expanded(
          child: itemsAsync.when(
            data: (items) {
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final cartItem = cart.items.firstWhere(
                    (element) => element.item.uuid == item.uuid,
                    orElse: () => CartItemState(item: item, rate: 0, gstPercent: 0, quantity: 0),
                  );

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        // Left-side status indicator bullet
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (item.currentStock ?? 0.0) <= 0
                                ? Colors.red
                                : ((item.currentStock ?? 0.0) <= (item.reorderLevel ?? 0.0)
                                    ? Colors.orange
                                    : Colors.green),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Item Info (Expanded to take full remaining width)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName ?? '',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rate: ₹${item.sellRate?.toStringAsFixed(2)}  •  Stock: ${item.currentStock?.toInt()}  •  GST: ${item.gstRate?.toInt()}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // +/- quantity controller
                        _buildQuantityAdjuster(item, cartItem),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load items: $e')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add New Product Master'),
            onPressed: () async {
              final newlyCreated = await AddItemSheet.show(context);
              if (newlyCreated != null) {
                ref.read(cartProvider.notifier).addItem(newlyCreated);
                ref.invalidate(filteredItemsProvider);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityAdjuster(Item item, CartItemState cartItem) {
    final theme = Theme.of(context);
    if (cartItem.quantity == 0) {
      return ElevatedButton(
        onPressed: () {
          ref.read(cartProvider.notifier).addItem(item);
        },
        child: const Text('ADD'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () {
              ref.read(cartProvider.notifier).updateItem(
                    item.uuid!,
                    quantity: cartItem.quantity - 1,
                  );
              if (cartItem.quantity <= 1) {
                ref.read(cartProvider.notifier).removeItem(item.uuid!);
              }
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${cartItem.quantity.toInt()}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () {
              ref.read(cartProvider.notifier).updateItem(
                    item.uuid!,
                    quantity: cartItem.quantity + 1,
                  );
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ],
      ),
    );
  }

  Widget _buildCartTab() {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Items Review List', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cart.items.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final cartItem = cart.items[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cartItem.item.itemName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                ref.read(cartProvider.notifier).removeItem(cartItem.item.uuid!);
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Quantity modifier
                            Expanded(
                              child: TextFormField(
                                initialValue: cartItem.quantity.toInt().toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final double? qty = double.tryParse(val);
                                  if (qty != null && qty > 0) {
                                    ref.read(cartProvider.notifier).updateItem(cartItem.item.uuid!, quantity: qty);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Free quantity
                            Expanded(
                              child: TextFormField(
                                initialValue: cartItem.freeQuantity.toInt().toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Free Qty', isDense: true, border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final double? qty = double.tryParse(val);
                                  if (qty != null) {
                                    ref.read(cartProvider.notifier).updateItem(cartItem.item.uuid!, freeQuantity: qty);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Rate override
                            Expanded(
                              child: TextFormField(
                                initialValue: cartItem.rate.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Rate (₹)', isDense: true, border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final double? rateVal = double.tryParse(val);
                                  if (rateVal != null) {
                                    ref.read(cartProvider.notifier).updateItem(cartItem.item.uuid!, rate: rateVal);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Discount percent
                            Expanded(
                              child: TextFormField(
                                initialValue: cartItem.discountPercent.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Disc %', isDense: true, border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final double? pct = double.tryParse(val);
                                  if (pct != null) {
                                    ref.read(cartProvider.notifier).updateItem(cartItem.item.uuid!, discountPercent: pct);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Discount Amt
                            Expanded(
                              child: TextFormField(
                                initialValue: cartItem.discountAmount.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Disc Amt', isDense: true, border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final double? amt = double.tryParse(val);
                                  if (amt != null) {
                                    ref.read(cartProvider.notifier).updateItem(cartItem.item.uuid!, discountAmount: amt);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Order Level calculations
                Text('Order Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('GST Tax Inclusive Pricing'),
                  value: cart.isGstInclusive,
                  onChanged: (val) {
                    ref.read(cartProvider.notifier).toggleGstInclusive(val);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _discountPercentController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Order Discount %', border: OutlineInputBorder()),
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
                        decoration: const InputDecoration(labelText: 'Order Discount Amt (₹)', border: OutlineInputBorder()),
                        onChanged: (val) {
                          final double? amt = double.tryParse(val);
                          ref.read(cartProvider.notifier).setOrderDiscounts(null, amt);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(labelText: 'Remarks / Notes', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),

                // Grand Totals Summary Card
                _buildTotalsSummaryPanel(theme),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Submit Sales Order'),
            onPressed: _saveOrder,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSummaryPanel(ThemeData theme) {
    // We load company settings to split GST locally
    return FutureBuilder<Settings?>(
      future: ref.read(databaseServiceProvider).isar.settings.where().findFirst(),
      builder: (context, snapshot) {
        final companyGst = snapshot.data?.companyGST;
        final totals = ref.read(cartProvider.notifier).calculateTotals(companyGst);

        return Card(
          color: theme.colorScheme.primaryContainer.withOpacity(0.2),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal', totals['subtotal']!, theme),
                _buildSummaryRow('Discounts Total', -totals['discountAmount']!, theme),
                _buildSummaryRow('GST Tax', totals['totalGST']!, theme),
                _buildSummaryRow('Round Off', totals['roundOff']!, theme),
                const Divider(),
                _buildSummaryRow('GRAND TOTAL', totals['grandTotal']!, theme, isBold: true),
              ],
            ),
          ),
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
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            '₹${val.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: isBold ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
