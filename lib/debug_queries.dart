import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbService = DatabaseService();
  await dbService.init();
  final isar = dbService.isar;

  // 1. Check All Transactions
  print('--- Checking Transactions ---');
  final qStart = DateTime(2000, 1, 1);
  final qEnd = DateTime(2100, 1, 1);
  final txns = await isar.transactions.filter()
      .isDeletedEqualTo(false)
      .and().group((q) => q.transactionDateBetween(qStart, qEnd).or().group((q2) => q2.transactionDateIsNull().and().createdAtBetween(qStart, qEnd)))
      .findAll();
  print('Total raw transactions (Receipts/Payments etc): ${txns.length}');

  final invoices = await isar.invoices.filter()
      .isDeletedEqualTo(false)
      .and().group((q) => q.invoiceDateBetween(qStart, qEnd).or().group((q2) => q2.invoiceDateIsNull().and().createdAtBetween(qStart, qEnd)))
      .findAll();
  print('Total sales invoices: ${invoices.length}');

  if (invoices.isNotEmpty) {
      print('Sample invoice: ID=${invoices.first.id}, UUID=${invoices.first.uuid}, Date=${invoices.first.invoiceDate}');
  }

  // 2. Check Item Details for Sales Invoices
  print('\n--- Checking Item Details (InvoiceItems) ---');
  final items = await isar.items.where().findAll();
  print('Total Items: ${items.length}');
  
  if (items.isNotEmpty) {
    for (var item in items.take(3)) {
      final itemName = item.itemName?.trim().toLowerCase() ?? '';
      
      final invItemsMatches = await isar.invoiceItems
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .group((q) {
            if (itemName.isNotEmpty) {
              return q.itemIdEqualTo(item.id).or().itemNameContains(itemName, caseSensitive: false);
            }
            return q.itemIdEqualTo(item.id);
          })
          .findAll();
          
      print('Item: ${item.itemName} (ID: ${item.id}) -> Found ${invItemsMatches.length} InvoiceItems.');
      
      if (invItemsMatches.isNotEmpty) {
         for (var ii in invItemsMatches) {
             print('   -> InvoiceItem ID=${ii.id}, parentInvID=${ii.parentInvoiceId}, parentInvUUID=${ii.parentInvoiceUuid}');
         }
      }
    }
  }

  exit(0);
}
