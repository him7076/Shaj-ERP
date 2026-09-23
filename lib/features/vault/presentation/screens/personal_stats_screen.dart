import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/features/vault/presentation/providers/personal_stats_provider.dart';
import 'package:business_sahaj_erp/features/vault/presentation/providers/vault_provider.dart';
import 'package:business_sahaj_erp/core/utils/currency_format.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';

class PersonalStatsScreen extends ConsumerStatefulWidget {
  const PersonalStatsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PersonalStatsScreen> createState() => _PersonalStatsScreenState();
}

class _PersonalStatsScreenState extends ConsumerState<PersonalStatsScreen> {
  final Map<String, Color> _categoryColors = {};
  final List<Color> _availableColors = [
    const Color(0xFF4ADE80), // Green
    const Color(0xFFF87171), // Red
    const Color(0xFF818CF8), // Indigo
    const Color(0xFFFBBF24), // Yellow
    const Color(0xFFA78BFA), // Purple
    const Color(0xFF38BDF8), // Light Blue
    const Color(0xFFFB923C), // Orange
  ];

  Color _getColorForCategory(String category, int index) {
    if (_categoryColors.containsKey(category)) return _categoryColors[category]!;
    final color = _availableColors[index % _availableColors.length];
    _categoryColors[category] = color;
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personalStatsStateProvider);
    final notifier = ref.read(personalStatsStateProvider.notifier);
    final dataAsync = ref.watch(personalStatsDataProvider);

    const bgColor = Color(0xFF18181B); // Dark background
    const cardColor = Color(0xFF27272A); // Darker card

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, ref),
            _buildTypeToggle(state, notifier),
            _buildTimeFilters(state, notifier),
            Expanded(
              child: dataAsync.when(
                data: (data) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      _buildChartSection(state, notifier, data, cardColor),
                      const SizedBox(height: 16),
                      _buildLegendSection(state, notifier, data, cardColor),
                      const SizedBox(height: 16),
                      if (state.selectedCategory != null)
                        _buildTransactionsSection(state, notifier, data, cardColor),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/dashboard'),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildVaultToggleBtn('BUSINESS', false, ref),
                _buildVaultToggleBtn('PERSONAL', true, ref),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Color(0xFFE879F9)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildVaultToggleBtn(String text, bool isPersonal, WidgetRef ref) {
    final isSelected = ref.watch(vaultModeProvider) == (isPersonal ? VaultMode.personal : VaultMode.business);
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          ref.read(vaultModeProvider.notifier).setMode(isPersonal ? VaultMode.personal : VaultMode.business);
          context.go('/dashboard');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE879F9) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(PersonalStatsState state, PersonalStatsNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => notifier.setType('Expense'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: state.type == 'Expense' ? const Color(0xFF3F3F46) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Expenses',
                      style: TextStyle(
                        color: state.type == 'Expense' ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => notifier.setType('Income'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: state.type == 'Income' ? const Color(0xFF3F3F46) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Income',
                      style: TextStyle(
                        color: state.type == 'Income' ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilters(PersonalStatsState state, PersonalStatsNotifier notifier) {
    final filters = ['TODAY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'CUSTOM'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = state.timeRange == f;
            return GestureDetector(
              onTap: () async {
                if (f == 'CUSTOM') {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF818CF8),
                            onPrimary: Colors.white,
                            surface: Color(0xFF27272A),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (range != null) {
                    notifier.setTimeRange(f, customRange: range);
                  }
                } else {
                  notifier.setTimeRange(f);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChartSection(PersonalStatsState state, PersonalStatsNotifier notifier, PersonalStatsData data, Color cardColor) {
    if (data.categoryTotals.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No data for selected period', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // Prepare chart data
    final entries = data.categoryTotals.entries.toList();
    int index = 0;
    
    String? hoverCategory;
    if (state.selectedCategory != null && data.categoryTotals.containsKey(state.selectedCategory)) {
      hoverCategory = state.selectedCategory;
    }

    final sections = entries.map((e) {
      final isTouched = e.key == hoverCategory;
      final radius = isTouched ? 30.0 : 25.0;
      final color = _getColorForCategory(e.key, index++);
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '',
        radius: radius,
        badgeWidget: null,
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                          return;
                        }
                        final touchIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        if (touchIndex >= 0 && touchIndex < entries.length) {
                          final selectedKey = entries[touchIndex].key;
                          if (event.runtimeType != FlPanEndEvent && event.runtimeType != FlLongPressEnd) {
                             notifier.selectCategory(selectedKey);
                          }
                        }
                      },
                    ),
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    sections: sections,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currencyFormat.format(data.totalAmount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'TOTAL',
                      style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hoverCategory != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3F3F46),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$hoverCategory : ${currencyFormat.format(data.categoryTotals[hoverCategory]!)} (${(data.categoryTotals[hoverCategory]! / data.totalAmount * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildLegendSection(PersonalStatsState state, PersonalStatsNotifier notifier, PersonalStatsData data, Color cardColor) {
    if (data.categoryTotals.isEmpty) return const SizedBox();

    final entries = data.categoryTotals.entries.toList();
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final e = entries[index];
          final color = _getColorForCategory(e.key, index);
          final isSelected = state.selectedCategory == e.key;

          return GestureDetector(
            onTap: () {
               notifier.selectCategory(isSelected ? null : e.key);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3F3F46) : Colors.transparent,
                borderRadius: isSelected ? BorderRadius.circular(12) : BorderRadius.zero,
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    currencyFormat.format(e.value),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsSection(PersonalStatsState state, PersonalStatsNotifier notifier, PersonalStatsData data, Color cardColor) {
    final filtered = data.allTransactions.where((t) {
      final cat = t.categoryName?.isNotEmpty == true ? t.categoryName! : 'Other';
      return cat == state.selectedCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.folder, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Filters: ${state.selectedCategory}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            TextButton(
              onPressed: () => notifier.selectCategory(null),
              child: const Text('Clear Filter', style: TextStyle(color: Color(0xFF818CF8))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          const Text('No transactions found.', style: TextStyle(color: Colors.grey))
        else
          ...filtered.map((t) {
             final isExpense = t.transactionType == 'Expense' || t.transactionType == 'Payment';
             final dateStr = t.transactionDate != null ? DateFormat('dd MMM yy').format(t.transactionDate!) : '';
             final accStr = t.paymentMode ?? 'Cash';
             
             return Container(
               margin: const EdgeInsets.only(bottom: 8),
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: cardColor,
                 borderRadius: BorderRadius.circular(16),
               ),
               child: Row(
                 crossAxisAlignment: CrossAxisAlignment.center,
                 children: [
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           t.remarks?.isNotEmpty == true ? t.remarks! : (t.transactionType ?? 'Entry'),
                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                         const SizedBox(height: 4),
                         Text(
                           '$accStr • $dateStr',
                           style: const TextStyle(color: Colors.grey, fontSize: 12),
                         ),
                       ],
                     ),
                   ),
                   Text(
                     '${isExpense ? '-' : ''}${currencyFormat.format(t.amount ?? 0)}',
                     style: TextStyle(
                       color: isExpense ? const Color(0xFFF87171) : const Color(0xFF4ADE80),
                       fontWeight: FontWeight.bold,
                       fontSize: 16,
                     ),
                   ),
                 ],
               ),
             );
          }).toList(),
      ],
    );
  }
}
