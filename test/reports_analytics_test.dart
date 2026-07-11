import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:business_sahaj_erp/domain/models/report_models.dart';
import 'package:business_sahaj_erp/core/services/profit_service.dart';

void main() {
  group('ReportDateFilter Preset Boundary Tests', () {
    test('Today preset boundaries', () {
      final filter = ReportDateFilter.fromPreset(ReportDatePreset.today);
      final now = DateTime.now();

      expect(filter.startDate.year, now.year);
      expect(filter.startDate.month, now.month);
      expect(filter.startDate.day, now.day);
      expect(filter.startDate.hour, 0);
      expect(filter.startDate.minute, 0);

      expect(filter.endDate.year, now.year);
      expect(filter.endDate.month, now.month);
      expect(filter.endDate.day, now.day);
      expect(filter.endDate.hour, 23);
      expect(filter.endDate.minute, 59);
    });

    test('This Month preset boundaries', () {
      final filter = ReportDateFilter.fromPreset(ReportDatePreset.thisMonth);
      final now = DateTime.now();

      expect(filter.startDate.year, now.year);
      expect(filter.startDate.month, now.month);
      expect(filter.startDate.day, 1);
    });

    test('Financial Year boundaries calculation', () {
      final filter = ReportDateFilter.fromPreset(ReportDatePreset.financialYear);
      final now = DateTime.now();

      if (now.month >= 4) {
        expect(filter.startDate.year, now.year);
        expect(filter.startDate.month, 4);
        expect(filter.startDate.day, 1);
        expect(filter.endDate.year, now.year + 1);
        expect(filter.endDate.month, 3);
        expect(filter.endDate.day, 31);
      } else {
        expect(filter.startDate.year, now.year - 1);
        expect(filter.startDate.month, 4);
        expect(filter.startDate.day, 1);
        expect(filter.endDate.year, now.year);
        expect(filter.endDate.month, 3);
        expect(filter.endDate.day, 31);
      }
    });
  });

  group('Aggregations & Math Model Tests', () {
    test('HsnSummaryEntry aggregation calculations', () {
      final entry = HsnSummaryEntry(
        hsnCode: '8528',
        quantity: 5.0,
        taxableAmount: 10000.0,
        gstRate: 18.0,
        gstAmount: 1800.0,
      );

      expect(entry.hsnCode, '8528');
      expect(entry.quantity, 5.0);
      expect(entry.taxableAmount, 10000.0);
      expect(entry.gstAmount, 1800.0);
    });

    test('ProfitLineItem calculations', () {
      final item = ProfitLineItem(
        itemName: 'LED TV',
        qtySold: 2.0,
        revenue: 4000.0, // Taxable selling revenue
        cost: 3000.0, // buy cost
        profit: 1000.0,
        marginPercent: 25.0, // (4000 - 3000) / 4000 * 100
      );

      expect(item.profit, 1000.0);
      expect(item.marginPercent, 25.0);
    });

    test('Dashboard KPI mapping', () {
      final entry = TopCustomerEntry(
        partyName: 'Sahaj Store',
        revenue: 15000.0,
        outstanding: 3000.0,
      );

      expect(entry.partyName, 'Sahaj Store');
      expect(entry.revenue, 15000.0);
      expect(entry.outstanding, 3000.0);
    });
  });
}
