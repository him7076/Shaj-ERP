import 'package:isar/isar.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/order_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';
import 'package:business_sahaj_erp/core/services/order_number_service.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class OrderRepositoryImpl extends BaseIsarRepository<Order> implements OrderRepository {
  final OrderNumberService _numberService;
  final SharedPreferences _prefs;

  OrderRepositoryImpl(Isar isar, this._prefs)
      : _numberService = OrderNumberService(isar),
        super(isar, 'Order');

  @override
  IsarCollection<Order> get collection => isar.collection<Order>();

  @override
  Future<List<Order>> searchOrders(String query) async {
    if (query.trim().isEmpty) {
      return await getAll();
    }

    try {
      final cleanQuery = query.trim();
      return await collection
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .group((q) => q
              .orderNumberContains(cleanQuery, caseSensitive: false)
              .or()
              .partyNameContains(cleanQuery, caseSensitive: false)
              .or()
              .mobileNumberContains(cleanQuery, caseSensitive: false))
          .findAll();
    } catch (e) {
      throw DatabaseException('Failed to search orders: $e');
    }
  }

  @override
  Future<String> generateNextOrderNumber() => _numberService.generateNextOrderNumber();

  @override
  Future<void> saveOrder(Order order, List<OrderItem> items) async {
    try {
      final isNew = order.id == Isar.autoIncrement;
      order.uuid ??= _generateUuid();
      order.createdAt = isNew ? DateTime.now() : order.createdAt;
      order.updatedAt = DateTime.now();
      order.isDeleted = false;
      order.isSynced = false;
      order.version = isNew ? 1 : order.version + 1;

      // Handle stock reservation setting check
      final reserveStock = _prefs.getBool('reserve_stock_on_order') ?? false;

      await isar.writeTxn(() async {
        // 1. Put the main Order record
        final orderId = await collection.put(order);
        order.id = orderId;

        // 2. Clear old items if editing to replace them
        if (!isNew) {
          final oldItems = await isar.orderItems
              .filter()
              .order((q) => q.idEqualTo(orderId))
              .findAll();
          
          for (var oldItem in oldItems) {
            oldItem.isDeleted = true;
            oldItem.isSynced = false;
            oldItem.updatedAt = DateTime.now();
            await isar.orderItems.put(oldItem);

            // If stock was reserved, release/restore it before applying new reservation
            if (reserveStock && oldItem.item.value != null) {
              final dbItem = oldItem.item.value!;
              dbItem.currentStock = (dbItem.currentStock ?? 0.0) + (oldItem.quantity ?? 0.0);
              await isar.items.put(dbItem);
            }
          }
        }

        // 3. Put new OrderItems
        for (var item in items) {
          item.uuid ??= _generateUuid();
          item.createdAt = isNew ? DateTime.now() : item.createdAt;
          item.updatedAt = DateTime.now();
          item.isDeleted = false;
          item.isSynced = false;
          item.version = isNew ? 1 : item.version + 1;

          await isar.orderItems.put(item);
          item.order.value = order;
          await item.order.save();

          // Deduct stock if reservation setting is enabled
          if (reserveStock && item.item.value != null) {
            final dbItem = item.item.value!;
            final double available = dbItem.currentStock ?? 0.0;
            final double requested = item.quantity ?? 0.0;

            if (available < requested) {
              throw StockException('Insufficient stock for item "${dbItem.itemName}". Available: $available, Requested: $requested');
            }

            dbItem.currentStock = available - requested;
            // Append stock log to item notes
            final log = '[${DateTime.now().toIso8601String().substring(0,19)}] RESERVED: -$requested | Bal: ${dbItem.currentStock} | Order #${order.orderNumber}';
            dbItem.notes = dbItem.notes == null || dbItem.notes!.isEmpty ? log : '$log\n${dbItem.notes}';
            
            await isar.items.put(dbItem);
          }
        }

        // 4. Save links association
        await order.orderItems.save();

        // 5. Add Sync Queue logs for Order
        final orderQueue = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'Order'
          ..entityId = orderId
          ..entityUuid = order.uuid
          ..operation = isNew ? 'Insert' : 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(orderQueue);

        // 6. Add Sync Queue logs for each OrderItem
        for (var item in items) {
          final itemQueue = SyncQueue()
            ..uuid = _generateUuid()
            ..entityType = 'OrderItem'
            ..entityId = item.id
            ..entityUuid = item.uuid
            ..operation = isNew ? 'Insert' : 'Update'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.syncQueues.put(itemQueue);
        }
      });

      logger.info('Order #${order.orderNumber} saved successfully. Reserve stock: $reserveStock');
    } catch (e) {
      throw DatabaseException('Failed to transaction-save order: $e');
    }
  }

  @override
  Future<void> cancelOrder(String orderUuid, String reason, String user) async {
    try {
      final order = await collection.filter().uuidEqualTo(orderUuid).findFirst();
      if (order == null) {
        throw RecordNotFoundException('Order not found for cancellation.');
      }

      final reserveStock = _prefs.getBool('reserve_stock_on_order') ?? false;

      order.status = 'Cancelled';
      order.cancelledBy = user;
      order.cancelledDate = DateTime.now();
      order.cancellationReason = reason;
      order.updatedAt = DateTime.now();
      order.version += 1;
      order.isSynced = false;

      await isar.writeTxn(() async {
        await collection.put(order);

        // If stock was reserved, restore it back to inventory
        if (reserveStock) {
          await order.orderItems.load();
          for (var item in order.orderItems) {
            await item.item.load();
            if (item.item.value != null) {
              final dbItem = item.item.value!;
              final double qty = item.quantity ?? 0.0;
              dbItem.currentStock = (dbItem.currentStock ?? 0.0) + qty;
              
              final log = '[${DateTime.now().toIso8601String().substring(0,19)}] RESTORED: +$qty | Bal: ${dbItem.currentStock} | Cancel Order #${order.orderNumber}';
              dbItem.notes = dbItem.notes == null || dbItem.notes!.isEmpty ? log : '$log\n${dbItem.notes}';
              
              await isar.items.put(dbItem);
            }
          }
        }

        // Log to sync queue
        final queueItem = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'Order'
          ..entityId = order.id
          ..entityUuid = order.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(queueItem);
      });

      logger.info('Order #${order.orderNumber} cancelled by $user.');
    } catch (e) {
      throw DatabaseException('Failed to cancel order: $e');
    }
  }

  String _generateUuid() {
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return '${DateTime.now().millisecondsSinceEpoch}-${parts.join("-")}';
  }
}
