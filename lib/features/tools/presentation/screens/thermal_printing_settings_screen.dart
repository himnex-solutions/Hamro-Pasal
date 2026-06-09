import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_button.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/core/widgets/app_text_field.dart';
import 'package:hamro_pasal/features/invoices/data/services/invoice_settings_service.dart';

class ThermalPrintingSettingsScreen extends ConsumerStatefulWidget {
  const ThermalPrintingSettingsScreen({super.key});

  @override
  ConsumerState<ThermalPrintingSettingsScreen> createState() =>
      _ThermalPrintingSettingsScreenState();
}

class _ThermalPrintingSettingsScreenState
    extends ConsumerState<ThermalPrintingSettingsScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _footerCtrl;
  late TextEditingController _prefixCtrl;

  String _printTemplate = 'thermal_58'; // Defaulting to thermal template
  bool _showTax = true;
  bool _showDiscount = true;
  bool _showAddress = true;
  bool _showPAN = true;
  bool _showPhone = true;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(invoiceSettingsProvider);
    _titleCtrl = TextEditingController(text: settings.title);
    _footerCtrl = TextEditingController(text: settings.footerNote);
    _prefixCtrl = TextEditingController(text: settings.prefix);
    _showTax = settings.showTax;
    _showDiscount = settings.showDiscount;
    
    // Fallback if template is not thermal
    if (settings.printTemplate == 'thermal_58' ||
        settings.printTemplate == 'thermal_80') {
      _printTemplate = settings.printTemplate;
    } else {
      _printTemplate = 'thermal_58';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _footerCtrl.dispose();
    _prefixCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final settings = ref.read(invoiceSettingsProvider);
    final updated = settings.copyWith(
      title: _titleCtrl.text.trim(),
      footerNote: _footerCtrl.text.trim(),
      prefix: _prefixCtrl.text.trim().toUpperCase(),
      showTax: _showTax,
      showDiscount: _showDiscount,
      printTemplate: _printTemplate,
    );

    ref.read(invoiceSettingsProvider.notifier).updateSettings(updated);
    AppSnackbar.show(context, 'Thermal printer settings saved!', isSuccess: true);
  }

  // Helper method to print test receipt
  Future<void> _printTestReceipt() async {
    try {
      final pdf = pw.Document();
      final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      final is58mm = _printTemplate == 'thermal_58';
      
      final double width = (is58mm ? 58 : 80) * PdfPageFormat.mm;
      final double margin = is58mm ? 4 * PdfPageFormat.mm : 6 * PdfPageFormat.mm;
      final format = PdfPageFormat(width, double.infinity, marginAll: margin);

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'HAMRO PASAL TEST',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                ),
                pw.Text('Receipt Printing Service', style: const pw.TextStyle(fontSize: 8)),
                if (_showAddress) pw.Text('Kathmandu, Nepal', style: const pw.TextStyle(fontSize: 8)),
                if (_showPhone) pw.Text('Tel: +977-9800000000', style: const pw.TextStyle(fontSize: 8)),
                if (_showPAN) pw.Text('PAN: 609876543', style: const pw.TextStyle(fontSize: 8)),
                
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text('------------------------------------------', style: const pw.TextStyle(fontSize: 8)),
                ),

                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Test Bill: #TEST-0001', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Customer: Test Walk-in', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),

                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text('------------------------------------------', style: const pw.TextStyle(fontSize: 8)),
                ),

                // Table Items
                pw.Row(
                  children: [
                    pw.Expanded(flex: 5, child: pw.Text('Item Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Expanded(flex: 2, child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 3, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Expanded(flex: 5, child: pw.Text('Premium Apples', style: const pw.TextStyle(fontSize: 8))),
                    pw.Expanded(flex: 2, child: pw.Text('2 kg', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 3, child: pw.Text('Rs. 300', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Expanded(flex: 5, child: pw.Text('Fresh Oranges', style: const pw.TextStyle(fontSize: 8))),
                    pw.Expanded(flex: 2, child: pw.Text('1.5 kg', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 3, child: pw.Text('Rs. 180', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                  ],
                ),

                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text('------------------------------------------', style: const pw.TextStyle(fontSize: 8)),
                ),

                // Totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Rs. 480', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                if (_showTax)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('VAT (13%):', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Rs. 62.40', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                if (_showDiscount)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Discount:', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('-Rs. 20', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('GRAND TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text('Rs. 522.40', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ],
                ),

                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Text('------------------------------------------', style: const pw.TextStyle(fontSize: 8)),
                ),

                pw.Text(_footerCtrl.text.isEmpty ? 'Thank you!' : _footerCtrl.text,
                    style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 6),
                pw.Text('Powered by Hamro Pasal', style: pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic)),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
        name: 'thermal_test_receipt.pdf',
      );
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Print failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Printer Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _save,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Side: Workspace configuration panels
          Expanded(
            flex: 6,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Banner info
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.print_rounded, color: Color(0xFF10B981), size: 30),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thermal Layout customizer',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customize receipt styling, sizing and details printed on your thermal roll.',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.05, end: 0),

                // Card 1: Printer Paper Sizing
                _CardSection(
                  title: 'Printer Sizing & Roll',
                  icon: Icons.settings_input_hdmi_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select the width of your thermal paper roll (58mm or 80mm).',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'thermal_58', label: Text('58mm Roll')),
                          ButtonSegment(value: 'thermal_80', label: Text('80mm Roll')),
                        ],
                        selected: {_printTemplate},
                        onSelectionChanged: (val) {
                          setState(() => _printTemplate = val.first);
                        },
                      ),
                    ],
                  ),
                ).animate(delay: 50.ms).fadeIn(),

                const SizedBox(height: 16),

                // Card 2: Custom Text Details
                _CardSection(
                  title: 'Text & Label Customization',
                  icon: Icons.edit_note_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Receipt Invoice Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _titleCtrl,
                        hint: 'e.g. BILL INVOICE',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      const Text('Invoice Prefix', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _prefixCtrl,
                        hint: 'e.g. INV',
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      const Text('Receipt Footer Note', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _footerCtrl,
                        hint: 'Thank you for shopping!',
                        maxLines: 2,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ).animate(delay: 100.ms).fadeIn(),

                const SizedBox(height: 16),

                // Card 3: Visibility toggles
                _CardSection(
                  title: 'Receipt Detail Visibility',
                  icon: Icons.visibility_outlined,
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: const Text('Show Business Address'),
                        value: _showAddress,
                        onChanged: (v) => setState(() => _showAddress = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile.adaptive(
                        title: const Text('Show Business Phone'),
                        value: _showPhone,
                        onChanged: (v) => setState(() => _showPhone = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile.adaptive(
                        title: const Text('Show Business PAN/VAT'),
                        value: _showPAN,
                        onChanged: (v) => setState(() => _showPAN = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile.adaptive(
                        title: const Text('Show Tax Section'),
                        value: _showTax,
                        onChanged: (v) => setState(() => _showTax = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile.adaptive(
                        title: const Text('Show Discount Row'),
                        value: _showDiscount,
                        onChanged: (v) => setState(() => _showDiscount = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ).animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _printTestReceipt,
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('Print Test Receipt'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        label: 'Save Layout',
                        onPressed: _save,
                      ),
                    ),
                  ],
                ).animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 40),
              ],
            ),
          ),

          // Right Side: Live Simulated Receipt Preview
          Expanded(
            flex: 4,
            child: Container(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SingleChildScrollView(
                  child: _SimulatedReceipt(
                    title: _titleCtrl.text,
                    footer: _footerCtrl.text,
                    prefix: _prefixCtrl.text,
                    is58mm: _printTemplate == 'thermal_58',
                    showTax: _showTax,
                    showDiscount: _showDiscount,
                    showAddress: _showAddress,
                    showPhone: _showPhone,
                    showPAN: _showPAN,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CardSection Wrapper ──────────────────────────────────────────
class _CardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _CardSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF10B981), size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}

// ── Live Simulated Receipt UI ────────────────────────────────────
class _SimulatedReceipt extends StatelessWidget {
  final String title;
  final String footer;
  final String prefix;
  final bool is58mm;
  final bool showTax;
  final bool showDiscount;
  final bool showAddress;
  final bool showPhone;
  final bool showPAN;

  const _SimulatedReceipt({
    required this.title,
    required this.footer,
    required this.prefix,
    required this.is58mm,
    required this.showTax,
    required this.showDiscount,
    required this.showAddress,
    required this.showPhone,
    required this.showPAN,
  });

  @override
  Widget build(BuildContext context) {
    final nowStr = DateFormat('dd MMM yyyy, h:mm a').format(DateTime.now());

    return Container(
      width: is58mm ? 250 : 310,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top serrated paper design helper
          Container(
            height: 12,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE2E8F0), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'HAMRO PASAL STORE',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Receipt Sizing Demo',
                  style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black54),
                ),
                if (showAddress)
                  const Text('123 Bagbazar, Kathmandu',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black54)),
                if (showPhone)
                  const Text('Tel: +977-1-4223344',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black54)),
                if (showPAN)
                  const Text('PAN: 601245678',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black54)),
                
                const _DashedLine(),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${title.isEmpty ? "TAX INVOICE" : title.toUpperCase()}: #${prefix.isEmpty ? "INV" : prefix.toUpperCase()}-2026-0042',
                        style: const TextStyle(
                            fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text('Date: $nowStr',
                          style: const TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.black54)),
                      const Text('Customer: Walk-in Client',
                          style: TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.black54)),
                    ],
                  ),
                ),
                
                const _DashedLine(),

                // Header Table Row
                const Row(
                  children: [
                    Expanded(
                        flex: 5,
                        child: Text('ITEM',
                            style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black87))),
                    Expanded(
                        flex: 2,
                        child: Text('QTY',
                            style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black87),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 3,
                        child: Text('TOTAL',
                            style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black87),
                            textAlign: TextAlign.right)),
                  ],
                ),
                const SizedBox(height: 4),
                _buildReceiptItemRow('Organic Green Tea', '1', 'Rs. 250'),
                _buildReceiptItemRow('Wavy Potato Chips', '3', 'Rs. 180'),
                _buildReceiptItemRow('Premium Face Cream', '1', 'Rs. 890'),

                const _DashedLine(),

                // Totals panel
                _buildTotalRow('Subtotal:', 'Rs. 1320'),
                if (showTax) _buildTotalRow('VAT (13%):', 'Rs. 171.60'),
                if (showDiscount) _buildTotalRow('Discount (5%):', '-Rs. 66'),
                
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GRAND TOTAL:',
                      style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                    ),
                    Text(
                      'Rs. ${showTax ? (showDiscount ? "1425.60" : "1491.60") : (showDiscount ? "1254.00" : "1320.00")}',
                      style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                    ),
                  ],
                ),
                
                const _DashedLine(),

                Text(
                  footer.isEmpty ? 'Thank you for your business!' : footer,
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Powered by Hamro Pasal',
                  style: TextStyle(fontFamily: 'Courier', fontSize: 7, color: Colors.black38, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Bottom serrated paper design helper
          Container(
            height: 12,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFE2E8F0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptItemRow(String name, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              name,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              qty,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              price,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.black87),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.black54)),
          Text(amount, style: const TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.black87)),
        ],
      ),
    );
  }
}

// ── Dashed Divider Widget ────────────────────────────────────────
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 3.0;
          const dashHeight = 0.8;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black38),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
