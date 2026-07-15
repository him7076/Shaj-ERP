import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/web_mock_isar.dart';
import 'package:business_sahaj_erp/core/services/hsn_service.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebMockIsar Database Tests', () {
    test('Should put and get items from WebMockIsar', () async {
      final mockIsar = WebMockIsar();
      final IsarCollection<Item> itemsCollection = mockIsar.collection<Item>();

      final testItem = Item()
        ..uuid = 'test-item-uuid-1'
        ..itemName = 'Test Electric Bulb'
        ..sellRate = 120.0
        ..isDeleted = false;

      // Save item
      final id = await itemsCollection.put(testItem);
      expect(id, greaterThan(0));

      // Get item by ID
      final retrieved = await itemsCollection.get(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.itemName, equals('Test Electric Bulb'));
      expect(retrieved.sellRate, equals(120.0));
    });

    test('Should filter items based on name search conditions in WebMockQueryBuilder', () async {
      final mockIsar = WebMockIsar();
      final IsarCollection<Item> itemsCollection = mockIsar.collection<Item>();

      await itemsCollection.put(Item()
        ..uuid = 'item-1'
        ..itemName = 'Syska LED Bulb'
        ..isDeleted = false);

      await itemsCollection.put(Item()
        ..uuid = 'item-2'
        ..itemName = 'Havells Fan'
        ..isDeleted = false);

      // Find all items
      final allItems = await itemsCollection.where().findAll();
      expect(allItems.length, greaterThanOrEqualTo(2));

      // Filter by name containing 'Bulb'
      final bulbItems = await itemsCollection.filter().itemNameContains('Bulb').findAll();
      expect(bulbItems.any((item) => item.itemName == 'Syska LED Bulb'), isTrue);
      expect(bulbItems.any((item) => item.itemName == 'Havells Fan'), isFalse);
    });

    test('Should support Party collections and operations correctly', () async {
      final mockIsar = WebMockIsar();
      final IsarCollection<Party> partyCollection = mockIsar.collection<Party>();

      final customer = Party()
        ..uuid = 'party-uuid-1'
        ..partyName = 'Vardhaman Traders'
        ..mobileNumber = '9876543210'
        ..isDeleted = false;

      await partyCollection.put(customer);

      final queryResult = await partyCollection.filter().partyNameContains('Vardhaman').findFirst();
      expect(queryResult, isNotNull);
      expect(queryResult!.mobileNumber, equals('9876543210'));
    });

    test('Should support Purchase and Expense operations correctly', () async {
      final mockIsar = WebMockIsar();
      final IsarCollection<Purchase> purchaseCollection = mockIsar.collection<Purchase>();
      final IsarCollection<Expense> expenseCollection = mockIsar.collection<Expense>();

      final purchase = Purchase()
        ..uuid = 'pur-uuid-123'
        ..purchaseNumber = 'PUR-0001'
        ..partyName = 'Syska Supplier'
        ..grandTotal = 45000.0;
      await purchaseCollection.put(purchase);

      final retrievedPur = await purchaseCollection.filter().purchaseNumberEqualTo('PUR-0001').findFirst();
      expect(retrievedPur, isNotNull);
      expect(retrievedPur!.partyName, equals('Syska Supplier'));

      final expense = Expense()
        ..uuid = 'exp-uuid-123'
        ..category = 'Rent'
        ..amount = 15000.0;
      await expenseCollection.put(expense);

      final retrievedExp = await expenseCollection.filter().categoryEqualTo('Rent').findFirst();
      expect(retrievedExp, isNotNull);
      expect(retrievedExp!.amount, equals(15000.0));
    });
  });

  group('HsnService Online Auto-suggestion Tests', () {
    test('Should fetch online HSN suggestions from public repository', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final hsnService = HsnService(prefs);

      // Trigger online lookup
      final results = await hsnService.searchOnlineHsn('construction');
      
      expect(results, isNotEmpty);
      expect(results.first.hsnCode, isNotEmpty);
      expect(results.first.description, contains('Construction'));
    });
  });
}
