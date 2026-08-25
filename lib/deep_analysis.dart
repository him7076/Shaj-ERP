import 'dart:io';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbService = DatabaseService();
  await dbService.init();
  final isar = dbService.isar;

  print('=== DEEP ANALYSIS: ALL TRANSACTIONS ===');
  
  final qStart = DateTime(2000, 1, 1);
  final qEnd = DateTime(2100, 1, 1);

  // 1. Raw count without any filters
  final allTxns = await isar.transactions.where().findAll();
  final allInvoices = await isar.invoices.where().findAll();
  
  print('1. Raw Database Counts (Unfiltered):');
  print('   Transactions Collection: ${allTxns.length}');
  print('   Invoices Collection: ${allInvoices.length}');

  if (allTxns.isEmpty && allInvoices.isEmpty) {
    print('\nWARNING: Database is completely empty! No data exists.');
    exit(0);
  }

  // 2. Check isDeleted properties manually
  int txnsWithNullDeleted = 0;
  for (var t in allTxns) {
    // In Dart, t.isDeleted is bool, but let's query the DB specifically
  }
  
  // 3. Test exact UI Provider Query for Invoices (Sales)
  print('\n2. Testing Exact UI Query Logic (Sales Invoices)...');
  try {
    final qb = isar.invoices.filter()
        .isDeletedEqualTo(false)
        .and().group((q) => q
            .invoiceDateBetween(qStart, qEnd)
            .or()
            .group((q2) => q2.invoiceDateIsNull().and().createdAtBetween(qStart, qEnd)));
            
    final results = await qb.sortByInvoiceDateDesc().findAll();
    print('   SUCCESS: UI Query returned ${results.length} sales invoices.');
    
    // Check discrepancy
    if (results.length < allInvoices.length) {
      print('   DISCREPANCY DETECTED: ${allInvoices.length - results.length} invoices are hidden!');
      
      // Let's find exactly why they are hidden
      final deletedFilter = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
      print('     -> Filter isDeleted==false yields: ${deletedFilter.length}');
      
      final dateFilter = await isar.invoices.filter().invoiceDateBetween(qStart, qEnd).findAll();
      print('     -> Filter date yields: ${dateFilter.length}');
    }
    
  } catch (e, stack) {
    print('   CRASH DETECTED IN INVOICES QUERY:');
    print('   Exception: $e');
    print('   $stack');
  }

  // 4. Test exact UI Provider Query for Transactions
  print('\n3. Testing Exact UI Query Logic (Transactions)...');
  try {
    final qb = isar.transactions.filter()
        .isDeletedEqualTo(false)
        .and().group((q) => q
            .transactionDateBetween(qStart, qEnd)
            .or()
            .group((q2) => q2.transactionDateIsNull().and().createdAtBetween(qStart, qEnd)));
            
    final results = await qb.sortByTransactionDateDesc().findAll();
    print('   SUCCESS: UI Query returned ${results.length} raw transactions.');
    
    if (results.length < allTxns.length) {
      print('   DISCREPANCY DETECTED: ${allTxns.length - results.length} txns are hidden!');
    }
  } catch (e, stack) {
    print('   CRASH DETECTED IN TRANSACTIONS QUERY:');
    print('   Exception: $e');
    print('   $stack');
  }

  exit(0);
}
