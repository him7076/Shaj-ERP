import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbService = DatabaseService();
  await dbService.init();
  final isar = dbService.isar;

  final txns = await isar.transactions.filter().isDeletedEqualTo(false).linkedBillUuidIsNotNull().findAll();
  for (var t in txns) {
     if (t.linkedBillUuid!.isNotEmpty) {
        print('Txn ${t.transactionNumber}: linkedBillUuid="${t.linkedBillUuid}"');
     }
  }
}
