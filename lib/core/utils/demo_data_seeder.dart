import 'dart:math';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/brand_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';

class DemoDataSeeder {
  static String _generateUuid() {
    final random = Random();
    final segments = <String>[];
    for (var i = 0; i < 4; i++) {
      segments.add(random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    }
    return segments.join('-');
  }

  static Future<void> seedDemoData(DatabaseService db) async {
    await db.isar.writeTxn(() async {
      // 1. Categories
      final lighting = Category()
        ..uuid = _generateUuid()
        ..categoryName = 'Lighting'
        ..description = 'LED bulbs, tube lights, panel lights';
      final appliances = Category()
        ..uuid = _generateUuid()
        ..categoryName = 'Appliances'
        ..description = 'Ceiling fans, exhaust fans, irons';
      final wiring = Category()
        ..uuid = _generateUuid()
        ..categoryName = 'Wiring'
        ..description = 'Electric wires, conduits, casing';
      
      await db.isar.categorys.putAll([lighting, appliances, wiring]);

      // 2. Brands
      final syska = Brand()
        ..uuid = _generateUuid()
        ..brandName = 'Syska';
      final havells = Brand()
        ..uuid = _generateUuid()
        ..brandName = 'Havells';
      final finolex = Brand()
        ..uuid = _generateUuid()
        ..brandName = 'Finolex';

      await db.isar.brands.putAll([syska, havells, finolex]);

      // 3. Units
      final pcs = Unit()
        ..uuid = _generateUuid()
        ..unitName = 'Pieces'
        ..shortName = 'PCS';
      final box = Unit()
        ..uuid = _generateUuid()
        ..unitName = 'Boxes'
        ..shortName = 'BOX';
      final meters = Unit()
        ..uuid = _generateUuid()
        ..unitName = 'Meters'
        ..shortName = 'MTR';

      await db.isar.units.putAll([pcs, box, meters]);

      // 4. Items (Products)
      final bulb = Item()
        ..uuid = _generateUuid()
        ..itemName = 'LED Bulb 9W'
        ..itemCode = 'ITM001'
        ..buyRate = 60.0
        ..sellRate = 90.0
        ..wholesaleRate = 80.0
        ..mrp = 100.0
        ..currentStock = 120.0
        ..openingStock = 120.0
        ..reorderLevel = 10.0
        ..gstApplicable = true
        ..gstRate = 18.0
        ..barcode = '8901234567890';

      final fan = Item()
        ..uuid = _generateUuid()
        ..itemName = 'Havells Fan 48"'
        ..itemCode = 'ITM002'
        ..buyRate = 1500.0
        ..sellRate = 2100.0
        ..wholesaleRate = 1850.0
        ..mrp = 2400.0
        ..currentStock = 25.0
        ..openingStock = 25.0
        ..reorderLevel = 5.0
        ..gstApplicable = true
        ..gstRate = 18.0
        ..barcode = '8901234567891';

      final wire = Item()
        ..uuid = _generateUuid()
        ..itemName = 'Finolex Wire 1.5sqmm'
        ..itemCode = 'ITM003'
        ..buyRate = 800.0
        ..sellRate = 1200.0
        ..wholesaleRate = 1050.0
        ..mrp = 1400.0
        ..currentStock = 40.0
        ..openingStock = 40.0
        ..reorderLevel = 8.0
        ..gstApplicable = true
        ..gstRate = 18.0
        ..barcode = '8901234567892';

      await db.isar.items.putAll([bulb, fan, wire]);

      // 5. Parties
      final customer1 = Party()
        ..uuid = _generateUuid()
        ..partyName = 'Krishna Electronics'
        ..partyCode = 'CUS0001'
        ..partyType = 'Customer'
        ..mobileNumber = '9876543210'
        ..gstNumber = '27AAAJD8239A1Z2'
        ..city = 'Mumbai'
        ..state = 'Maharashtra'
        ..openingBalance = 14200.0
        ..balanceType = 'Dr';

      final customer2 = Party()
        ..uuid = _generateUuid()
        ..partyName = 'Shree Traders'
        ..partyCode = 'WHL0001'
        ..partyType = 'Wholesaler'
        ..mobileNumber = '9922334455'
        ..gstNumber = '27AAAST8903B2Z5'
        ..city = 'Pune'
        ..state = 'Maharashtra'
        ..openingBalance = 45000.0
        ..balanceType = 'Dr';

      final customer3 = Party()
        ..uuid = _generateUuid()
        ..partyName = 'Balaji Wholesalers'
        ..partyCode = 'SUP0001'
        ..partyType = 'Supplier'
        ..mobileNumber = '8888877777'
        ..city = 'Surat'
        ..state = 'Gujarat'
        ..openingBalance = 25000.0
        ..balanceType = 'Cr';

      await db.isar.partys.putAll([customer1, customer2, customer3]);

      // 6. Orders
      final order1 = Order()
        ..uuid = _generateUuid()
        ..orderNumber = 'ORD-2026-0001'
        ..orderDate = DateTime.now().subtract(const Duration(days: 1))
        ..partyName = 'Krishna Electronics'
        ..partyId = customer1.id
        ..status = 'Confirmed'
        ..grandTotal = 8000.0;
      await db.isar.orders.put(order1);

      final orderItem1 = OrderItem()
        ..uuid = _generateUuid()
        ..itemName = 'LED Bulb 9W'
        ..quantity = 100.0
        ..rate = 80.0
        ..totalAmount = 8000.0;
      orderItem1.order.value = order1;
      await db.isar.orderItems.put(orderItem1);
      await orderItem1.order.save();

      // 7. Invoices
      final invoice1 = Invoice()
        ..uuid = _generateUuid()
        ..invoiceNumber = 'INV-2026-0001'
        ..invoiceDate = DateTime.now()
        ..partyName = 'Shree Traders'
        ..partyId = customer2.id
        ..grandTotal = 12390.0
        ..paymentStatus = 'Paid'
        ..isSynced = false;
      await db.isar.invoices.put(invoice1);

      final invoiceItem1 = InvoiceItem()
        ..uuid = _generateUuid()
        ..itemName = 'Havells Fan 48"'
        ..quantity = 5.0
        ..rate = 2100.0
        ..gstRate = 18.0
        ..gstAmount = 1890.0
        ..taxableAmount = 10500.0
        ..totalAmount = 12390.0;
      invoiceItem1.invoice.value = invoice1;
      await db.isar.invoiceItems.put(invoiceItem1);
      await invoiceItem1.invoice.save();

      // 8. Purchases
      final purchase1 = Purchase()
        ..uuid = _generateUuid()
        ..purchaseNumber = 'PUR-2026-0001'
        ..purchaseDate = DateTime.now().subtract(const Duration(days: 2))
        ..partyName = 'Balaji Wholesalers'
        ..partyId = customer3.id
        ..subtotal = 60000.0
        ..discountAmount = 2000.0
        ..taxableAmount = 58000.0
        ..totalGST = 10440.0
        ..grandTotal = 68440.0
        ..remarks = 'Bulk lighting order';
      await db.isar.collection<Purchase>().put(purchase1);

      final purchaseItem1 = PurchaseItem()
        ..uuid = _generateUuid()
        ..itemName = 'LED Bulb 9W'
        ..quantity = 1000.0
        ..rate = 60.0
        ..taxableAmount = 60000.0
        ..gstRate = 18.0
        ..gstAmount = 10800.0
        ..totalAmount = 70800.0;
      purchaseItem1.purchase.value = purchase1;
      await db.isar.collection<PurchaseItem>().put(purchaseItem1);
      await purchaseItem1.purchase.save();

      // 9. Expenses
      final expense1 = Expense()
        ..uuid = _generateUuid()
        ..category = 'Rent'
        ..amount = 12000.0
        ..expenseDate = DateTime.now().subtract(const Duration(days: 5))
        ..paymentMode = 'Bank Transfer'
        ..remarks = 'Office rent for June';
      
      final expense2 = Expense()
        ..uuid = _generateUuid()
        ..category = 'Tea & Snacks'
        ..amount = 450.0
        ..expenseDate = DateTime.now()
        ..paymentMode = 'UPI'
        ..remarks = 'Staff evening snacks';
      
      final expense3 = Expense()
        ..uuid = _generateUuid()
        ..category = 'Utilities'
        ..amount = 2500.0
        ..expenseDate = DateTime.now().subtract(const Duration(days: 1))
        ..paymentMode = 'UPI'
        ..remarks = 'Electricity bill';

      await db.isar.collection<Expense>().putAll([expense1, expense2, expense3]);
    });
  }
}
