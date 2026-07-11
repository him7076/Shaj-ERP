import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:business_sahaj_erp/domain/models/report_models.dart';

class ChartService {
  /// Maps DailySalesPoint list to FlSpot list for Line Charts
  List<FlSpot> mapToLineSpots(List<DailySalesPoint> points) {
    if (points.isEmpty) return [];

    // Sort chronologically
    final sortedPoints = List<DailySalesPoint>.from(points)
      ..sort((a, b) => a.date.compareTo(b.date));

    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedPoints[i].salesAmount));
    }
    return spots;
  }

  /// Maps TopProductEntry list to BarChartGroupData list for Bar Charts
  List<BarChartGroupData> mapToBarGroups(List<TopProductEntry> products) {
    final List<BarChartGroupData> groups = [];
    
    // Limit to top 5 products to prevent chart crowding
    final limitProducts = products.take(5).toList();

    for (int i = 0; i < limitProducts.length; i++) {
      final product = limitProducts[i];
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: product.revenue,
              color: Colors.blueAccent,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }
    return groups;
  }

  /// Maps TopCustomerEntry list to PieChartSectionData list for Pie/Doughnut Charts
  List<PieChartSectionData> mapToPieSections(List<TopCustomerEntry> customers) {
    final List<PieChartSectionData> sections = [];
    
    // Take top 5 and group others
    final topCustomers = customers.take(4).toList();
    final double totalRevenue = customers.fold(0.0, (sum, c) => sum + c.revenue);

    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.blueGrey,
    ];

    double displayedRevenue = 0.0;

    for (int i = 0; i < topCustomers.length; i++) {
      final cust = topCustomers[i];
      displayedRevenue += cust.revenue;

      final double percentage = totalRevenue > 0 ? (cust.revenue / totalRevenue) * 100 : 0.0;

      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: cust.revenue,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _buildPieBadge(cust.partyName, colors[i % colors.length]),
          badgePositionPercentageOffset: 1.25,
        ),
      );
    }

    // Add 'Others' segment if remaining
    if (totalRevenue > displayedRevenue) {
      final double othersRevenue = totalRevenue - displayedRevenue;
      final double percentage = (othersRevenue / totalRevenue) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[4],
          value: othersRevenue,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _buildPieBadge('Others', colors[4]),
          badgePositionPercentageOffset: 1.25,
        ),
      );
    }

    return sections;
  }

  Widget _buildPieBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label.length > 8 ? '${label.substring(0, 7)}..' : label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
