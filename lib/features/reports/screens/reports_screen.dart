import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

final _fmt = NumberFormat('#,##0.00', 'en_US');

final reportsProvider = FutureProvider<_ReportData>((ref) async {
  final userId = SupabaseService.instance.currentUserId!;
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final sales = await SupabaseService.instance.getSales(userId, from: monthStart);
  final expenses = await SupabaseService.instance.getExpenses(userId);

  double monthRevenue = 0;
  final dailyRevenue = <String, double>{};
  for (final s in sales) {
    monthRevenue += (s['total'] as num).toDouble();
    final date = s['ad_date'] as String;
    dailyRevenue[date] = (dailyRevenue[date] ?? 0) + (s['total'] as num).toDouble();
  }

  final monthExpenses = expenses
      .where((e) {
        final d = DateTime.tryParse(e['ad_date'] as String? ?? '');
        return d != null && d.isAfter(monthStart);
      })
      .fold<double>(0, (s, e) => s + (e['amount'] as num).toDouble());

  return _ReportData(
    monthRevenue: monthRevenue,
    monthExpenses: monthExpenses,
    netProfit: monthRevenue - monthExpenses,
    totalBills: sales.length,
    dailyRevenue: dailyRevenue,
  );
});

class _ReportData {
  final double monthRevenue;
  final double monthExpenses;
  final double netProfit;
  final int totalBills;
  final Map<String, double> dailyRevenue;

  _ReportData({
    required this.monthRevenue,
    required this.monthExpenses,
    required this.netProfit,
    required this.totalBills,
    required this.dailyRevenue,
  });
}

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportsProvider);
    final month = DateFormat('MMMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: () {}),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$month Summary',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // Summary cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _SummaryCard('Revenue', 'NPR ${_fmt.format(data.monthRevenue)}',
                      Icons.trending_up_rounded, AppColors.success),
                  _SummaryCard('Expenses', 'NPR ${_fmt.format(data.monthExpenses)}',
                      Icons.trending_down_rounded, AppColors.error),
                  _SummaryCard('Net Profit', 'NPR ${_fmt.format(data.netProfit)}',
                      Icons.account_balance_rounded,
                      data.netProfit >= 0 ? AppColors.primary : AppColors.error),
                  _SummaryCard('Total Bills', '${data.totalBills}',
                      Icons.receipt_long_rounded, AppColors.accent),
                ],
              ),
              const SizedBox(height: 24),

              // Chart
              if (data.dailyRevenue.isNotEmpty) ...[
                Text('Daily Sales (This Month)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: _SalesBarChart(dailyRevenue: data.dailyRevenue),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ]),
          ],
        ),
      );
}

class _SalesBarChart extends StatelessWidget {
  final Map<String, double> dailyRevenue;
  const _SalesBarChart({required this.dailyRevenue});

  @override
  Widget build(BuildContext context) {
    final sorted = dailyRevenue.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final bars = sorted.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
              toY: e.value.value,
              color: AppColors.primary,
              width: 12,
              borderRadius: BorderRadius.circular(4)),
        ],
      );
    }).toList();

    return BarChart(BarChartData(
      barGroups: bars,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              if (v.toInt() < sorted.length) {
                final day = sorted[v.toInt()].key.split('-').last;
                return Text(day,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary));
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
    ));
  }
}
