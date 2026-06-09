import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/l10n/app_strings.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/features/invoices/data/services/invoice_settings_service.dart';
import 'package:hamro_pasal/features/subscription/data/services/subscription_manager.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _invoice;
  Map<String, dynamic>? _business;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final businessId = prefs.getString(AppConstants.kSelectedBusinessId);

      final results = await Future.wait([
        _supabase
            .from('invoices')
            .select('*, invoice_items(*)')
            .eq('id', widget.invoiceId)
            .single(),
        if (businessId != null)
          _supabase
              .from('businesses')
              .select('name, address, phone, email, pan_number')
              .eq('id', businessId)
              .maybeSingle(),
      ]);

      if (mounted) {
        final inv = results[0] as Map<String, dynamic>;
        setState(() {
          _invoice = inv;
          _items = ((inv['invoice_items'] as List?) ?? [])
              .cast<Map<String, dynamic>>();
          if (results.length > 1) {
            _business = results[1];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Failed to load: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Mark as Paid ─────────────────────────────────────────────
  Future<void> _markAsPaid() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.markAsPaid),
        content: Text('${context.l10n.markAsPaid}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.confirm)),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final total = (_invoice!['total_amount'] as num).toDouble();
      await _supabase.from('invoices').update({
        'status': 'paid',
        'paid_amount': total,
      }).eq('id', widget.invoiceId);
      await _load();
      if (mounted) {
        AppSnackbar.show(context, '✅ Invoice marked as paid!', isSuccess: true);
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Failed: $e', isError: true);
    }
  }

  // ── PDF Generation ────────────────────────────────────────────
  Future<void> _printInvoice() async {
    if (_invoice == null) return;
    setState(() => _isPrinting = true);
    try {
      final pdf = pw.Document();
      final fmt = NumberFormat('#,##,##0.00');
      final dateFmt = DateFormat('dd MMM yyyy');
      final inv = _invoice!;
      final biz = _business;

      final invoiceDate = DateTime.parse(inv['invoice_date'] as String);
      final dueDate = inv['due_date'] != null
          ? DateTime.parse(inv['due_date'] as String)
          : null;

      final total = (inv['total_amount'] as num).toDouble();
      final paid = (inv['paid_amount'] as num?)?.toDouble() ?? 0;
      final subtotal = (inv['subtotal'] as num).toDouble();
      final tax = (inv['tax_amount'] as num?)?.toDouble() ?? 0;
      final discount = (inv['discount_amount'] as num?)?.toDouble() ?? 0;

      final settings = ref.read(invoiceSettingsProvider);
      final primaryColorHex = settings.themeColorHex.replaceFirst('#', '');
      final primaryColor = PdfColor.fromHex(primaryColorHex);
      final lightGrey = PdfColor.fromHex('F5F5F5');
      final darkText = PdfColor.fromHex('212121');
      final greyText = PdfColor.fromHex('757575');

      PdfPageFormat pageFormat;
      double marginValue;
      switch (settings.printTemplate) {
        case 'a5':
          pageFormat = PdfPageFormat.a5;
          marginValue = 24;
          break;
        case 'thermal_58':
          pageFormat = const PdfPageFormat(58 * PdfPageFormat.mm, 240 * PdfPageFormat.mm);
          marginValue = 12;
          break;
        case 'thermal_80':
          pageFormat = const PdfPageFormat(80 * PdfPageFormat.mm, 320 * PdfPageFormat.mm);
          marginValue = 16;
          break;
        case 'a4':
        default:
          pageFormat = PdfPageFormat.a4;
          marginValue = 32;
          break;
      }

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.all(marginValue),
          build: (ctx) {
            final isThermal = settings.printTemplate.startsWith('thermal_');
            if (isThermal) {
              final is58mm = settings.printTemplate == 'thermal_58';
              final lineCharCount = is58mm ? 36 : 48;
              final dividerText = '-' * lineCharCount;
              final textFont = pw.Font.courier();
              
              pw.Widget thermalRow(String label, String value, {bool isBold = false}) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(label, style: pw.TextStyle(font: textFont, fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
                    pw.Text(value, style: pw.TextStyle(font: textFont, fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
                  ],
                );
              }

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    biz?['name'] as String? ?? 'Business',
                    style: pw.TextStyle(
                      font: textFont,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (biz?['address'] != null)
                    pw.Text(biz!['address'] as String,
                        style: pw.TextStyle(font: textFont, fontSize: 8), textAlign: pw.TextAlign.center),
                  if (biz?['phone'] != null)
                    pw.Text('Tel: ${biz!['phone']}',
                        style: pw.TextStyle(font: textFont, fontSize: 8), textAlign: pw.TextAlign.center),
                  if (biz?['email'] != null)
                    pw.Text(biz!['email'] as String,
                        style: pw.TextStyle(font: textFont, fontSize: 8), textAlign: pw.TextAlign.center),
                  if (biz?['pan_number'] != null)
                    pw.Text('PAN: ${biz!['pan_number']}',
                        style: pw.TextStyle(font: textFont, fontSize: 8), textAlign: pw.TextAlign.center),
                  
                  pw.Text(dividerText, style: pw.TextStyle(font: textFont, fontSize: 8)),
                  
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${settings.title.toUpperCase()}: #${inv['invoice_number']}',
                          style: pw.TextStyle(font: textFont, fontWeight: pw.FontWeight.bold, fontSize: 8),
                        ),
                        pw.Text('Date: ${dateFmt.format(invoiceDate)}',
                            style: pw.TextStyle(font: textFont, fontSize: 8)),
                        if (dueDate != null)
                          pw.Text('Due Date: ${dateFmt.format(dueDate)}',
                              style: pw.TextStyle(font: textFont, fontSize: 8)),
                        pw.Text('Status: ${(inv['status'] as String).toUpperCase()}',
                            style: pw.TextStyle(font: textFont, fontSize: 8)),
                        pw.Text('Bill To: ${inv['party_name'] as String? ?? "Walk-in Customer"}',
                            style: pw.TextStyle(font: textFont, fontSize: 8)),
                      ],
                    ),
                  ),
                  
                  pw.Text(dividerText, style: pw.TextStyle(font: textFont, fontSize: 8)),
                  
                  // 3-column table
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text('ITEM', style: pw.TextStyle(font: textFont, fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text('QTY x PRICE', style: pw.TextStyle(font: textFont, fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text('TOTAL', style: pw.TextStyle(font: textFont, fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  ..._items.map((item) {
                    final qty = (item['quantity'] as num).toDouble();
                    final unitP = (item['unit_price'] as num).toDouble();
                    final totalP = (item['total_price'] as num).toDouble();
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 1),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 5,
                            child: pw.Text(item['product_name'] as String? ?? '', style: pw.TextStyle(font: textFont, fontSize: 8)),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text('${qty.toStringAsFixed(0)} x ${unitP.toStringAsFixed(0)}', style: pw.TextStyle(font: textFont, fontSize: 8), textAlign: pw.TextAlign.center),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(fmt.format(totalP), style: pw.TextStyle(font: textFont, fontSize: 8), textAlign: pw.TextAlign.right),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  pw.Text(dividerText, style: pw.TextStyle(font: textFont, fontSize: 8)),
                  
                  thermalRow('Subtotal:', fmt.format(subtotal)),
                  if (tax > 0) thermalRow('Tax:', '+${fmt.format(tax)}'),
                  if (discount > 0) thermalRow('Discount:', '-${fmt.format(discount)}'),
                  
                  pw.Text(dividerText, style: pw.TextStyle(font: textFont, fontSize: 8)),
                  thermalRow('GRAND TOTAL:', '${AppConstants.currencySymbol} ${fmt.format(total)}', isBold: true),
                  thermalRow('Paid Amount:', '${AppConstants.currencySymbol} ${fmt.format(paid)}'),
                  if (paid < total)
                    thermalRow('Amount Due:', '${AppConstants.currencySymbol} ${fmt.format(total - paid)}', isBold: true),
                  
                  pw.Text(dividerText, style: pw.TextStyle(font: textFont, fontSize: 8)),
                  
                  if (settings.footerNote.isNotEmpty) ...[
                    pw.Text(settings.footerNote, style: pw.TextStyle(font: textFont, fontSize: 8), textAlign: pw.TextAlign.center),
                    pw.SizedBox(height: 4),
                  ],
                  if (ref.read(subscriptionManagerProvider).planCode == 'basic')
                    pw.Text('Powered by Hamro Pasal', style: pw.TextStyle(font: textFont, fontSize: 7, fontStyle: pw.FontStyle.italic), textAlign: pw.TextAlign.center),
                ],
              );
            }

            // Fallback: A4/A5 PDF layout
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          biz?['name'] as String? ?? 'Business',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        if (biz?['address'] != null)
                          pw.Text(biz!['address'] as String,
                              style: pw.TextStyle(color: greyText, fontSize: 10)),
                        if (biz?['phone'] != null)
                          pw.Text('Tel: ${biz!['phone']}',
                              style: pw.TextStyle(color: greyText, fontSize: 10)),
                        if (biz?['email'] != null)
                          pw.Text(biz!['email'] as String,
                              style: pw.TextStyle(color: greyText, fontSize: 10)),
                        if (biz?['pan_number'] != null)
                          pw.Text('PAN: ${biz!['pan_number']}',
                              style: pw.TextStyle(color: greyText, fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(settings.title.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: greyText,
                            )),
                        pw.SizedBox(height: 4),
                        pw.Text('#${inv['invoice_number']}',
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: darkText)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(color: primaryColor, thickness: 2),
                pw.SizedBox(height: 12),

                // ── Bill To & Dates ─────────────────────────
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILL TO',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: greyText)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            inv['party_name'] as String? ?? 'Walk-in Customer',
                            style: pw.TextStyle(
                                fontSize: 13, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _pdfDateRow('Invoice Date', dateFmt.format(invoiceDate),
                            darkText, greyText),
                        if (dueDate != null)
                          _pdfDateRow('Due Date', dateFmt.format(dueDate),
                              darkText, greyText),
                        _pdfDateRow(
                          'Status',
                          (inv['status'] as String).toUpperCase(),
                          inv['status'] == 'paid'
                              ? PdfColor.fromHex('2E7D32')
                              : PdfColor.fromHex('C62828'),
                          greyText,
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // ── Items Table ─────────────────────────────
                pw.Table(
                  border: pw.TableBorder.all(
                      color: PdfColor.fromHex('E0E0E0'), width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(4),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: primaryColor),
                      children: [
                        _pdfCell('ITEM', isHeader: true),
                        _pdfCell('QTY',
                            isHeader: true, align: pw.TextAlign.center),
                        _pdfCell('UNIT PRICE',
                            isHeader: true, align: pw.TextAlign.right),
                        _pdfCell('TOTAL',
                            isHeader: true, align: pw.TextAlign.right),
                      ],
                    ),
                    // Items
                    ..._items.asMap().entries.map((e) {
                      final item = e.value;
                      final bg = e.key.isOdd ? lightGrey : PdfColors.white;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: bg),
                        children: [
                          _pdfCell(item['product_name'] as String? ?? ''),
                          _pdfCell(
                            (item['quantity'] as num).toStringAsFixed(0),
                            align: pw.TextAlign.center,
                          ),
                          _pdfCell(
                            '${AppConstants.currencySymbol} ${fmt.format((item['unit_price'] as num).toDouble())}',
                            align: pw.TextAlign.right,
                          ),
                          _pdfCell(
                            '${AppConstants.currencySymbol} ${fmt.format((item['total_price'] as num).toDouble())}',
                            align: pw.TextAlign.right,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 12),

                // ── Totals ──────────────────────────────────
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.SizedBox(
                    width: 220,
                    child: pw.Column(
                      children: [
                        _pdfTotalRow(
                            'Subtotal',
                            '${AppConstants.currencySymbol} ${fmt.format(subtotal)}',
                            darkText,
                            greyText),
                        if (tax > 0)
                          _pdfTotalRow(
                              'Tax',
                              '+${AppConstants.currencySymbol} ${fmt.format(tax)}',
                              darkText,
                              greyText),
                        if (discount > 0)
                          _pdfTotalRow(
                              'Discount',
                              '-${AppConstants.currencySymbol} ${fmt.format(discount)}',
                              darkText,
                              greyText),
                        pw.Divider(color: greyText),
                        _pdfTotalRow(
                          'TOTAL',
                          '${AppConstants.currencySymbol} ${fmt.format(total)}',
                          primaryColor,
                          primaryColor,
                          isBold: true,
                          fontSize: 13,
                        ),
                        if (paid > 0)
                          _pdfTotalRow(
                            'Paid Amount',
                            '${AppConstants.currencySymbol} ${fmt.format(paid)}',
                            darkText,
                            greyText,
                          ),
                        if (paid > 0 && paid < total)
                          _pdfTotalRow(
                            'Amount Due',
                            '${AppConstants.currencySymbol} ${fmt.format(total - paid)}',
                            PdfColor.fromHex('C62828'),
                            PdfColor.fromHex('C62828'),
                            isBold: true,
                          ),
                      ],
                    ),
                  ),
                ),

                if (inv['notes'] != null &&
                    (inv['notes'] as String).isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text('Notes',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.SizedBox(height: 4),
                  pw.Text(inv['notes'] as String,
                      style: pw.TextStyle(color: greyText, fontSize: 10)),
                ],

                pw.Spacer(),
                pw.Divider(color: PdfColor.fromHex('E0E0E0')),
                pw.Center(
                  child: pw.Text(settings.footerNote,
                      style: pw.TextStyle(color: greyText, fontSize: 10)),
                ),
                if (ref.read(subscriptionManagerProvider).planCode == 'basic') ...[
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Text('Powered by Hamro Pasal',
                        style: pw.TextStyle(color: greyText, fontSize: 8, fontStyle: pw.FontStyle.italic)),
                  ),
                ],
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (_) => pdf.save());
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Print failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  // ── PDF helpers ───────────────────────────────────────────────
  pw.Widget _pdfCell(String text,
      {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _pdfDateRow(
      String label, String value, PdfColor valueColor, PdfColor labelColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('$label:  ',
              style: pw.TextStyle(fontSize: 10, color: labelColor)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: valueColor)),
        ],
      ),
    );
  }

  pw.Widget _pdfTotalRow(
      String label, String value, PdfColor valueColor, PdfColor labelColor,
      {bool isBold = false, double fontSize = 11}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: fontSize,
                  color: labelColor,
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: fontSize,
                  color: valueColor,
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_invoice == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.invoice)),
        body: const Center(child: Text('Invoice not found')),
      );
    }

    final inv = _invoice!;
    final fmt = NumberFormat('#,##,##0.00');
    final dateFmt = DateFormat('dd MMM yyyy');
    final invoiceDate = DateTime.parse(inv['invoice_date'] as String);
    final dueDate = inv['due_date'] != null
        ? DateTime.parse(inv['due_date'] as String)
        : null;
    final total = (inv['total_amount'] as num).toDouble();
    final paid = (inv['paid_amount'] as num?)?.toDouble() ?? 0;
    final subtotal = (inv['subtotal'] as num).toDouble();
    final tax = (inv['tax_amount'] as num?)?.toDouble() ?? 0;
    final discount = (inv['discount_amount'] as num?)?.toDouble() ?? 0;
    final status = inv['status'] as String;
    final isPaid = status == 'paid';

    final statusColor = isPaid
        ? AppTheme.successColor
        : status == 'partial'
            ? AppTheme.warningColor
            : AppTheme.errorColor;
    final statusLabel = isPaid
        ? 'Paid'
        : status == 'partial'
            ? 'Partial'
            : 'Unpaid';

    return Scaffold(
      appBar: AppBar(
        title: Text('#${inv['invoice_number']}'),
        actions: [
          if (!isPaid)
            TextButton.icon(
              onPressed: _markAsPaid,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(context.l10n.markAsPaid),
              style:
                  TextButton.styleFrom(foregroundColor: AppTheme.successColor),
            ),
          IconButton(
            onPressed: _isPrinting ? null : _printInvoice,
            icon: _isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.print_outlined),
            tooltip: 'Print / Download PDF',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Status banner ─────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                      isPaid
                          ? Icons.check_circle_rounded
                          : Icons.pending_outlined,
                      color: statusColor,
                      size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(statusLabel,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700)),
                        if (!isPaid && total - paid > 0)
                          Text(
                              'Due: ${AppConstants.currencySymbol} ${fmt.format(total - paid)}',
                              style:
                                  TextStyle(color: statusColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('${AppConstants.currencySymbol} ${fmt.format(total)}',
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 16),

            // ── Invoice meta card ─────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text('Invoice Details',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ]),
                    const Divider(height: 20),
                    _MetaRow('Invoice #', '#${inv['invoice_number']}'),
                    if (inv['party_name'] != null)
                      _MetaRow('Customer', inv['party_name'] as String),
                    _MetaRow('Invoice Date', dateFmt.format(invoiceDate)),
                    if (dueDate != null)
                      _MetaRow('Due Date', dateFmt.format(dueDate)),
                    if (_business?['name'] != null)
                      _MetaRow('Business', _business!['name'] as String),
                  ],
                ),
              ),
            ).animate(delay: 80.ms).fadeIn(),

            const SizedBox(height: 16),

            // ── Line items card ───────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text('Items',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ]),
                    const Divider(height: 20),
                    // table header
                    const Row(children: [
                      Expanded(
                          flex: 4,
                          child: Text('Item',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(
                          flex: 1,
                          child: Text('Qty',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12),
                              textAlign: TextAlign.center)),
                      Expanded(
                          flex: 2,
                          child: Text('Price',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12),
                              textAlign: TextAlign.right)),
                    ]),
                    const SizedBox(height: 8),
                    ..._items.asMap().entries.map((e) {
                      final item = e.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: AppTheme.lightBorder, width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 4,
                                child: Text(
                                    item['product_name'] as String? ?? '')),
                            Expanded(
                                flex: 1,
                                child: Text(
                                  (item['quantity'] as num).toStringAsFixed(0),
                                  textAlign: TextAlign.center,
                                )),
                            Expanded(
                                flex: 2,
                                child: Text(
                                  '${AppConstants.currencySymbol} ${fmt.format((item['total_price'] as num).toDouble())}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                )),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ).animate(delay: 140.ms).fadeIn(),

            const SizedBox(height: 16),

            // ── Totals card ───────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _TotalRow('Subtotal',
                        '${AppConstants.currencySymbol} ${fmt.format(subtotal)}'),
                    if (tax > 0)
                      _TotalRow('Tax',
                          '+${AppConstants.currencySymbol} ${fmt.format(tax)}',
                          color: AppTheme.warningColor),
                    if (discount > 0)
                      _TotalRow('Discount',
                          '-${AppConstants.currencySymbol} ${fmt.format(discount)}',
                          color: AppTheme.successColor),
                    const Divider(height: 16),
                    _TotalRow('Total',
                        '${AppConstants.currencySymbol} ${fmt.format(total)}',
                        isBold: true,
                        fontSize: 16,
                        color: AppTheme.primaryColor),
                    if (paid > 0)
                      _TotalRow('Paid',
                          '${AppConstants.currencySymbol} ${fmt.format(paid)}',
                          color: AppTheme.successColor),
                    if (total - paid > 0 && !isPaid)
                      _TotalRow('Amount Due',
                          '${AppConstants.currencySymbol} ${fmt.format(total - paid)}',
                          isBold: true, color: AppTheme.errorColor),
                  ],
                ),
              ),
            ).animate(delay: 200.ms).fadeIn(),

            if (inv['notes'] != null &&
                (inv['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notes',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(inv['notes'] as String,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ).animate(delay: 260.ms).fadeIn(),
            ],

            const SizedBox(height: 24),

            // ── Print button ──────────────────────────────
            ElevatedButton.icon(
              onPressed: _isPrinting ? null : _printInvoice,
              icon: _isPrinting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.print_rounded),
              label: Text(
                  _isPrinting ? 'Preparing PDF...' : 'Print / Download PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ).animate(delay: 300.ms).fadeIn(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.lightTextHint)),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final double fontSize;
  final Color? color;
  const _TotalRow(this.label, this.value,
      {this.isBold = false, this.fontSize = 13, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
                  color: color ?? AppTheme.lightTextSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }
}
