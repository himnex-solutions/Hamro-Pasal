import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/sale.dart';

final _fmt = NumberFormat('#,##0.00', 'en_US');

class ReceiptScreen extends ConsumerWidget {
  final Map<String, dynamic> saleData;
  const ReceiptScreen({super.key, required this.saleData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final items = (saleData['sale_items'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print',
            onPressed: () => _printReceipt(context, profile, items),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Shop header
                    const Icon(Icons.storefront_rounded,
                        size: 40, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(
                      profile?.pasalName ?? 'Hamro Pasal',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (profile?.address != null)
                      Text(profile!.address,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center),
                    if (profile?.panNumber != null)
                      Text('PAN: ${profile!.panNumber}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.black26),
                    const SizedBox(height: 8),

                    // Bill info
                    _InfoRow('Bill No', saleData['bill_number']?.toString() ?? '-'),
                    _InfoRow('Date', saleData['ad_date']?.toString() ?? '-'),
                    _InfoRow('Payment',
                        (saleData['payment_method'] ?? 'cash').toString().toUpperCase()),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.black26),

                    // Items header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Expanded(
                          flex: 3,
                          child: Text('Item',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary)),
                        ),
                        Text('Qty',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: Text('Amount',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary),
                              textAlign: TextAlign.right),
                        ),
                      ]),
                    ),
                    const Divider(color: Colors.black12),

                    // Items
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                  item['product_name']?.toString() ?? '',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ),
                            Text('${item['quantity']}',
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: Text(
                                  'NPR ${_fmt.format(item['total'] ?? 0)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.right),
                            ),
                          ]),
                        )),

                    const Divider(height: 24, color: Colors.black26),

                    // Totals
                    _InfoRow('Subtotal',
                        'NPR ${_fmt.format(saleData['subtotal'] ?? 0)}'),
                    if ((saleData['discount'] ?? 0) > 0)
                      _InfoRow('Discount',
                          '- NPR ${_fmt.format(saleData['discount'] ?? 0)}',
                          valueColor: AppColors.error),
                    if ((saleData['tax'] ?? 0) > 0)
                      _InfoRow(
                          'VAT', 'NPR ${_fmt.format(saleData['tax'] ?? 0)}'),

                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                          Text(
                              'NPR ${_fmt.format(saleData['total'] ?? 0)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.black12),
                    const SizedBox(height: 8),
                    Text('Thank you for shopping!',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                    Text('Powered by Hamro Pasal',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textHint),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('New Sale'),
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52)),
        ),
      ),
    );
  }

  Future<void> _printReceipt(BuildContext context,
      dynamic profile, List<dynamic> items) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(profile?.pasalName ?? 'Hamro Pasal',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(profile?.address ?? ''),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Bill: ${saleData['bill_number']}'),
              pw.Text(saleData['ad_date']?.toString() ?? ''),
            ],
          ),
          pw.Divider(),
          ...items.map((item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${item['product_name']} x${item['quantity']}'),
                  pw.Text('NPR ${_fmt.format(item['total'] ?? 0)}'),
                ],
              )),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('NPR ${_fmt.format(saleData['total'] ?? 0)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Center(child: pw.Text('Thank you!')),
        ],
      ),
    ));
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: valueColor)),
          ],
        ),
      );
}
