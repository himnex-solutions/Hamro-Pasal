import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/features/subscription/data/services/subscription_manager.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/l10n/app_strings.dart';

class ReportSummary {
  final double totalSales;
  final double totalPurchases;
  final double totalExpenses;
  final double netProfit;
  final List<Map<String, dynamic>> topProducts;
  const ReportSummary({
    this.totalSales = 0,
    this.totalPurchases = 0,
    this.totalExpenses = 0,
    this.netProfit = 0,
    this.topProducts = const [],
  });
}

enum ReportPeriod { today, week, month, custom }

final reportProvider =
    AsyncNotifierProvider.family<ReportNotifier, ReportSummary, ReportPeriod>(
        () {
  return ReportNotifier();
});

class ReportNotifier extends FamilyAsyncNotifier<ReportSummary, ReportPeriod> {
  @override
  Future<ReportSummary> build(ReportPeriod arg) => _fetch(arg);

  Future<ReportSummary> _fetch(ReportPeriod period) async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
    if (businessId == null) return const ReportSummary();

    final now = DateTime.now();
    DateTime start;
    switch (period) {
      case ReportPeriod.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case ReportPeriod.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case ReportPeriod.month:
        start = DateTime(now.year, now.month, 1);
        break;
      case ReportPeriod.custom:
        start = DateTime(now.year, now.month, 1);
        break;
    }

    final supabase = Supabase.instance.client;
    final txRes = await supabase
        .from('transactions')
        .select('type, amount')
        .eq('business_id', businessId)
        .gte('transaction_date', start.toIso8601String());

    double sales = 0, purchases = 0, expenses = 0;
    for (final tx in txRes as List) {
      final amount = (tx['amount'] as num).toDouble();
      switch (tx['type'] as String) {
        case 'sale':
          sales += amount;
          break;
        case 'purchase':
          purchases += amount;
          break;
        case 'expense':
          expenses += amount;
          break;
      }
    }

    // Fetch general expenses from expenses table for the period
    final expRes = await supabase
        .from('expenses')
        .select('amount')
        .eq('business_id', businessId)
        .gte('expense_date', start.toIso8601String());

    for (final exp in expRes as List) {
      expenses += (exp['amount'] as num).toDouble();
    }

    // Top products by qty sold
    final itemsRes = await supabase
        .from('transaction_items')
        .select('product_name, quantity, total_price')
        .gte('created_at', start.toIso8601String())
        .order('quantity', ascending: false)
        .limit(5);
    final topProducts = (itemsRes as List).cast<Map<String, dynamic>>();

    return ReportSummary(
      totalSales: sales,
      totalPurchases: purchases,
      totalExpenses: expenses,
      netProfit: sales - purchases - expenses,
      topProducts: topProducts,
    );
  }
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.month;

  Future<void> _exportPdf(ReportSummary report) async {
    final manager = ref.read(subscriptionManagerProvider.notifier);
    if (manager.currentSubscriptionPlan == 'basic') {
      AppSnackbar.show(
        context,
        context.l10n.reportPremiumMsg,
        isError: true,
      );
      context.push(AppRoutes.subscription);
      return;
    }

    try {
      final pdf = pw.Document();
      final fmt = NumberFormat('#,##,##0.00');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Hamro Pasal — Business Performance Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 16),
                pw.Text('Profit & Loss Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Total Sales: Rs. ${fmt.format(report.totalSales)}'),
                pw.Text('Total Purchases: Rs. ${fmt.format(report.totalPurchases)}'),
                pw.Text('Total Expenses: Rs. ${fmt.format(report.totalExpenses)}'),
                pw.Divider(),
                pw.Text('Net Profit: Rs. ${fmt.format(report.netProfit)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 24),
                if (report.topProducts.isNotEmpty) ...[
                  pw.Text('Top Selling Products', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Product Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty Sold', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Sales', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        ]
                      ),
                      ...report.topProducts.map((p) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p['product_name'] as String)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p['quantity'].toString())),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rs. ${fmt.format(p['total_price'])}')),
                        ]
                      )),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (_) => pdf.save());
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Failed to export PDF: $e', isError: true);
      }
    }
  }

  Future<void> _exportExcel(ReportSummary report) async {
    final manager = ref.read(subscriptionManagerProvider.notifier);
    if (!manager.checkFeatureAccess('excel_export')) {
      AppSnackbar.show(
        context,
        context.l10n.excelPremiumMsg,
        isError: true,
      );
      context.push(AppRoutes.subscription);
      return;
    }

    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet.appendRow([xl.TextCellValue('Hamro Pasal — Business Performance Report')]);
      sheet.appendRow([xl.TextCellValue('Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}')]);
      sheet.appendRow([]);

      sheet.appendRow([xl.TextCellValue('Profit & Loss Summary')]);
      sheet.appendRow([xl.TextCellValue('Metric'), xl.TextCellValue('Amount (Rs.)')]);
      sheet.appendRow([xl.TextCellValue('Total Sales'), xl.DoubleCellValue(report.totalSales)]);
      sheet.appendRow([xl.TextCellValue('Total Purchases'), xl.DoubleCellValue(report.totalPurchases)]);
      sheet.appendRow([xl.TextCellValue('Total Expenses'), xl.DoubleCellValue(report.totalExpenses)]);
      sheet.appendRow([xl.TextCellValue('Net Profit'), xl.DoubleCellValue(report.netProfit)]);
      sheet.appendRow([]);

      if (report.topProducts.isNotEmpty) {
        sheet.appendRow([xl.TextCellValue('Top Selling Products')]);
        sheet.appendRow([xl.TextCellValue('Product Name'), xl.TextCellValue('Qty Sold'), xl.TextCellValue('Total Sales (Rs.)')]);
        for (final p in report.topProducts) {
          sheet.appendRow([
            xl.TextCellValue(p['product_name'] as String),
            xl.DoubleCellValue((p['quantity'] as num).toDouble()),
            xl.DoubleCellValue((p['total_price'] as num).toDouble()),
          ]);
        }
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/business_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx').create();
        await file.writeAsBytes(fileBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Hamro Pasal Business Report',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Failed to export Excel: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportProvider(_period));

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ReportPeriod.values.map((p) {
                  final labels = {
                    ReportPeriod.today: 'Today',
                    ReportPeriod.week: 'This Week',
                    ReportPeriod.month: 'This Month',
                    ReportPeriod.custom: 'Custom',
                  };
                  final isSelected = p == _period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(labels[p]!),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _period = p),
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.lightTextSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (report) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // P&L Summary
                    Text('Profit & Loss',
                            style: Theme.of(context).textTheme.titleLarge)
                        .animate()
                        .fadeIn(),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = constraints.maxWidth > 600 ? 4 : 2;
                        final ratio = constraints.maxWidth > 600 ? 1.6 : 1.35;
                        return GridView.count(
                          crossAxisCount: cols,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: ratio,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _ReportCard('Total Sales', report.totalSales,
                                AppTheme.successColor, Icons.trending_up_rounded),
                            _ReportCard('Total Purchases', report.totalPurchases,
                                AppTheme.infoColor, Icons.shopping_bag_outlined),
                            _ReportCard('Total Expenses', report.totalExpenses,
                                AppTheme.errorColor, Icons.wallet_outlined),
                            _ReportCard(
                                'Net Profit',
                                report.netProfit,
                                report.netProfit >= 0
                                    ? AppTheme.accentColor
                                    : AppTheme.errorColor,
                                report.netProfit >= 0
                                    ? Icons.emoji_events_outlined
                                    : Icons.sentiment_dissatisfied_outlined),
                          ],
                        );
                      },
                    ).animate(delay: 50.ms).fadeIn().slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 24),

                    // Top products
                    if (report.topProducts.isNotEmpty) ...[
                      Text('Top Selling Products',
                              style: Theme.of(context).textTheme.titleLarge)
                          .animate(delay: 100.ms)
                          .fadeIn(),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppTheme.darkBorder
                                  : Colors.white,
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).cardTheme.color ?? Colors.white,
                              (Theme.of(context).cardTheme.color ??
                                      Colors.white)
                                  .withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: report.topProducts.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final p = report.topProducts[i];
                              return ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text('${i + 1}',
                                        style: const TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                title: Text(p['product_name'] as String),
                                subtitle: Text('Qty: ${p['quantity']}'),
                                trailing: Text(
                                  '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0').format(p['total_price'])}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.successColor),
                                ),
                              );
                            },
                          ),
                        ),
                      ).animate(delay: 150.ms).fadeIn(),
                    ],

                    const SizedBox(height: 24),

                    // Export buttons
                    Text('Export Reports',
                            style: Theme.of(context).textTheme.titleLarge)
                        .animate(delay: 200.ms)
                        .fadeIn(),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                            onPressed: () => _exportPdf(report),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Export PDF')),
                        OutlinedButton.icon(
                            onPressed: () => _exportExcel(report),
                            icon: const Icon(Icons.table_chart_outlined),
                            label: const Text('Export Excel')),
                      ],
                    ).animate(delay: 250.ms).fadeIn(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  const _ReportCard(this.title, this.amount, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    final isNeg = amount < 0;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : Colors.white,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardTheme.color ?? Colors.white,
            (Theme.of(context).cardTheme.color ?? Colors.white)
                .withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${isNeg ? '-' : ''}${AppConstants.currencySymbol} ${NumberFormat('#,##,##0').format(amount.abs())}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: color, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
