import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/services/daily_limit_service.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/plan_limit_dialog.dart';
import 'package:hamro_pasal/features/subscription/data/services/subscription_manager.dart';
import 'package:hamro_pasal/features/tools/presentation/screens/label_print_models.dart';
import 'package:hamro_pasal/features/tools/presentation/screens/label_pdf_builder.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hamro_pasal/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:hamro_pasal/features/inventory/data/models/product_model.dart';
import 'package:hamro_pasal/features/invoices/data/services/invoice_settings_service.dart';

class ThermalLabelScreen extends ConsumerStatefulWidget {
  const ThermalLabelScreen({super.key});

  @override
  ConsumerState<ThermalLabelScreen> createState() => _ThermalLabelScreenState();
}

class _ThermalLabelScreenState extends ConsumerState<ThermalLabelScreen> {
  LabelType _activeType = LabelType.productLabel;
  PrinterBrand _activeBrand = PrinterBrand.generic;
  int _presetIndex = 1; // default to medium/first preset

  // Custom size controls
  final _customWCtrl = TextEditingController(text: '80');
  final _customHCtrl = TextEditingController(text: '50');

  // Common/Product inputs
  final _productNameCtrl = TextEditingController(text: 'Organic Green Tea');
  final _shopNameCtrl = TextEditingController(text: 'Hamro Pasal Shop');
  final _brandNameCtrl = TextEditingController(text: 'Organic Nepal');
  final _priceCtrl = TextEditingController(text: '450');
  final _codeValueCtrl = TextEditingController(text: '978020137962');
  BarcodeMode _codeMode = BarcodeMode.qr;

  // Shipping label inputs
  final _shipFromCtrl = TextEditingController(text: 'Ram Shrestha');
  final _shipFromAddrCtrl = TextEditingController(text: 'New Road, Kathmandu');
  final _shipFromPhoneCtrl = TextEditingController(text: '9841234567');
  final _shipToCtrl = TextEditingController(text: 'Hari Tamang');
  final _shipToAddrCtrl = TextEditingController(text: 'Lakeside, Pokhara');
  final _shipToPhoneCtrl = TextEditingController(text: '9807654321');
  final _shipOrderNoCtrl = TextEditingController(text: 'HP-90412');
  final _shipWeightCtrl = TextEditingController(text: '1.2 kg');
  final _shipNotesCtrl = TextEditingController(text: 'Fragile. Handle with care.');

  // Receipt inputs
  final _receiptSubtotalCtrl = TextEditingController(text: '1200');
  final _receiptDiscountCtrl = TextEditingController(text: '100');
  final _receiptTaxCtrl = TextEditingController(text: '143');
  final _receiptTotalCtrl = TextEditingController(text: '1243');
  final _receiptFooterCtrl = TextEditingController(text: 'Follow us on Instagram!');
  final List<Map<String, String>> _receiptItems = [
    {'name': 'Chowmein Packet', 'qty': '2', 'price': '300'},
    {'name': 'Brown Bread Large', 'qty': '1', 'price': '150'},
    {'name': 'Clarified Butter 1L', 'qty': '1', 'price': '750'},
  ];

  // Receipt customization controls (shifted from Thermal Receipt settings)
  late TextEditingController _receiptTitleCtrl;
  late TextEditingController _receiptPrefixCtrl;
  late TextEditingController _receiptPanCtrl;
  bool _showReceiptTax = true;
  bool _showReceiptDiscount = true;
  bool _showReceiptAddress = true;
  bool _showReceiptPAN = true;
  bool _showReceiptPhone = true;

  bool _printing = false;
  String _lastProductName = 'Organic Green Tea';

  @override
  void initState() {
    super.initState();
    final invoiceSettings = ref.read(invoiceSettingsProvider);
    _receiptTitleCtrl = TextEditingController(text: invoiceSettings.title);
    _receiptPrefixCtrl = TextEditingController(text: invoiceSettings.prefix);
    _receiptPanCtrl = TextEditingController(text: '601245678');
    _showReceiptTax = invoiceSettings.showTax;
    _showReceiptDiscount = invoiceSettings.showDiscount;
    _showReceiptAddress = invoiceSettings.showAddress;
    _showReceiptPAN = invoiceSettings.showPAN;
    _showReceiptPhone = invoiceSettings.showPhone;

    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _activeType = LabelType.values[prefs.getInt('thermal_active_type') ?? LabelType.productLabel.index];
        _activeBrand = PrinterBrand.values[prefs.getInt('thermal_active_brand') ?? PrinterBrand.generic.index];
        _presetIndex = prefs.getInt('thermal_preset_index') ?? 1;
        _customWCtrl.text = prefs.getString('thermal_custom_w') ?? '80';
        _customHCtrl.text = prefs.getString('thermal_custom_h') ?? '50';
        
        _productNameCtrl.text = prefs.getString('thermal_prod_name') ?? 'Organic Green Tea';
        _lastProductName = _productNameCtrl.text;
        _shopNameCtrl.text = prefs.getString('thermal_shop_name') ?? 'Hamro Pasal Shop';
        _brandNameCtrl.text = prefs.getString('thermal_brand_name') ?? 'Organic Nepal';
        _priceCtrl.text = prefs.getString('thermal_price') ?? '450';
        _codeValueCtrl.text = prefs.getString('thermal_code_val') ?? '978020137962';
        _codeMode = BarcodeMode.values[prefs.getInt('thermal_code_mode') ?? BarcodeMode.qr.index];

        _shipFromCtrl.text = prefs.getString('thermal_ship_from') ?? 'Ram Shrestha';
        _shipFromAddrCtrl.text = prefs.getString('thermal_ship_from_addr') ?? 'New Road, Kathmandu';
        _shipFromPhoneCtrl.text = prefs.getString('thermal_ship_from_phone') ?? '9841234567';
        _shipToCtrl.text = prefs.getString('thermal_ship_to') ?? 'Hari Tamang';
        _shipToAddrCtrl.text = prefs.getString('thermal_ship_to_addr') ?? 'Lakeside, Pokhara';
        _shipToPhoneCtrl.text = prefs.getString('thermal_ship_to_phone') ?? '9807654321';
        _shipOrderNoCtrl.text = prefs.getString('thermal_ship_ord_no') ?? 'HP-90412';
        _shipWeightCtrl.text = prefs.getString('thermal_ship_wt') ?? '1.2 kg';
        _shipNotesCtrl.text = prefs.getString('thermal_ship_notes') ?? 'Fragile. Handle with care.';

        _receiptSubtotalCtrl.text = prefs.getString('thermal_rec_sub') ?? '1200';
        _receiptDiscountCtrl.text = prefs.getString('thermal_rec_disc') ?? '100';
        _receiptTaxCtrl.text = prefs.getString('thermal_rec_tax') ?? '143';
        _receiptTotalCtrl.text = prefs.getString('thermal_rec_tot') ?? '1243';
        _receiptFooterCtrl.text = prefs.getString('thermal_rec_foot') ?? 'Follow us on Instagram!';

        _receiptTitleCtrl.text = prefs.getString('thermal_rec_title') ?? _receiptTitleCtrl.text;
        _receiptPrefixCtrl.text = prefs.getString('thermal_rec_prefix') ?? _receiptPrefixCtrl.text;
        _receiptPanCtrl.text = prefs.getString('thermal_rec_pan') ?? _receiptPanCtrl.text;
        _showReceiptTax = prefs.getBool('thermal_rec_show_tax') ?? _showReceiptTax;
        _showReceiptDiscount = prefs.getBool('thermal_rec_show_disc') ?? _showReceiptDiscount;
        _showReceiptAddress = prefs.getBool('thermal_rec_show_addr') ?? _showReceiptAddress;
        _showReceiptPAN = prefs.getBool('thermal_rec_show_pan') ?? _showReceiptPAN;
        _showReceiptPhone = prefs.getBool('thermal_rec_show_phone') ?? _showReceiptPhone;
      });
    } catch (e) {
      debugPrint('Failed to load thermal settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('thermal_active_type', _activeType.index);
      await prefs.setInt('thermal_active_brand', _activeBrand.index);
      await prefs.setInt('thermal_preset_index', _presetIndex);
      await prefs.setString('thermal_custom_w', _customWCtrl.text);
      await prefs.setString('thermal_custom_h', _customHCtrl.text);

      await prefs.setString('thermal_prod_name', _productNameCtrl.text);
      await prefs.setString('thermal_shop_name', _shopNameCtrl.text);
      await prefs.setString('thermal_brand_name', _brandNameCtrl.text);
      await prefs.setString('thermal_price', _priceCtrl.text);
      await prefs.setString('thermal_code_val', _codeValueCtrl.text);
      await prefs.setInt('thermal_code_mode', _codeMode.index);

      await prefs.setString('thermal_ship_from', _shipFromCtrl.text);
      await prefs.setString('thermal_ship_from_addr', _shipFromAddrCtrl.text);
      await prefs.setString('thermal_ship_from_phone', _shipFromPhoneCtrl.text);
      await prefs.setString('thermal_ship_to', _shipToCtrl.text);
      await prefs.setString('thermal_ship_to_addr', _shipToAddrCtrl.text);
      await prefs.setString('thermal_ship_to_phone', _shipToPhoneCtrl.text);
      await prefs.setString('thermal_ship_ord_no', _shipOrderNoCtrl.text);
      await prefs.setString('thermal_ship_wt', _shipWeightCtrl.text);
      await prefs.setString('thermal_ship_notes', _shipNotesCtrl.text);

      await prefs.setString('thermal_rec_sub', _receiptSubtotalCtrl.text);
      await prefs.setString('thermal_rec_disc', _receiptDiscountCtrl.text);
      await prefs.setString('thermal_rec_tax', _receiptTaxCtrl.text);
      await prefs.setString('thermal_rec_tot', _receiptTotalCtrl.text);
      await prefs.setString('thermal_rec_foot', _receiptFooterCtrl.text);

      await prefs.setString('thermal_rec_title', _receiptTitleCtrl.text);
      await prefs.setString('thermal_rec_prefix', _receiptPrefixCtrl.text);
      await prefs.setString('thermal_rec_pan', _receiptPanCtrl.text);
      await prefs.setBool('thermal_rec_show_tax', _showReceiptTax);
      await prefs.setBool('thermal_rec_show_disc', _showReceiptDiscount);
      await prefs.setBool('thermal_rec_show_addr', _showReceiptAddress);
      await prefs.setBool('thermal_rec_show_pan', _showReceiptPAN);
      await prefs.setBool('thermal_rec_show_phone', _showReceiptPhone);

      // Shift/Save to global invoice custom settings
      final settings = ref.read(invoiceSettingsProvider);
      final updated = settings.copyWith(
        title: _receiptTitleCtrl.text.trim(),
        prefix: _receiptPrefixCtrl.text.trim().toUpperCase(),
        footerNote: _receiptFooterCtrl.text.trim(),
        showTax: _showReceiptTax,
        showDiscount: _showReceiptDiscount,
        showAddress: _showReceiptAddress,
        showPhone: _showReceiptPhone,
        showPAN: _showReceiptPAN,
      );
      await ref.read(invoiceSettingsProvider.notifier).updateSettings(updated);
    } catch (e) {
      debugPrint('Failed to save thermal settings: $e');
    }
  }

  void _showInventoryPicker() {
    final inventoryAsync = ref.read(inventoryProvider);
    inventoryAsync.when(
      data: (products) {
        if (products.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active products found in inventory. Please add products first.')),
          );
          return;
        }

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return _InventorySearchSheet(
              products: products,
              onSelect: (product) {
                setState(() {
                  _productNameCtrl.text = product.name;
                  _lastProductName = product.name;
                  _priceCtrl.text = product.sellingPrice.toStringAsFixed(0);
                  
                  // Auto-populate barcode value
                  final bValue = product.barcode ?? product.sku ?? '';
                  _codeValueCtrl.text = bValue;

                  // Auto select mode based on barcode pattern
                  if (bValue.isNotEmpty) {
                    if (RegExp(r'^\d{13}$').hasMatch(bValue)) {
                      _codeMode = BarcodeMode.ean13;
                    } else if (RegExp(r'^[a-zA-Z0-9\-]{3,32}$').hasMatch(bValue)) {
                      _codeMode = BarcodeMode.code128;
                    } else {
                      _codeMode = BarcodeMode.qr;
                    }
                  } else {
                    // Fallback to QR with product name if barcode is empty
                    _codeValueCtrl.text = product.name;
                    _codeMode = BarcodeMode.qr;
                  }
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading inventory, please wait...')),
        );
      },
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load inventory: $e')),
        );
      },
    );
  }

  @override
  void dispose() {
    _customWCtrl.dispose();
    _customHCtrl.dispose();
    _productNameCtrl.dispose();
    _shopNameCtrl.dispose();
    _brandNameCtrl.dispose();
    _priceCtrl.dispose();
    _codeValueCtrl.dispose();
    _shipFromCtrl.dispose();
    _shipFromAddrCtrl.dispose();
    _shipFromPhoneCtrl.dispose();
    _shipToCtrl.dispose();
    _shipToAddrCtrl.dispose();
    _shipToPhoneCtrl.dispose();
    _shipOrderNoCtrl.dispose();
    _shipWeightCtrl.dispose();
    _shipNotesCtrl.dispose();
    _receiptSubtotalCtrl.dispose();
    _receiptDiscountCtrl.dispose();
    _receiptTaxCtrl.dispose();
    _receiptTotalCtrl.dispose();
    _receiptFooterCtrl.dispose();
    _receiptTitleCtrl.dispose();
    _receiptPrefixCtrl.dispose();
    _receiptPanCtrl.dispose();
    super.dispose();
  }

  // ── Plan verification ──────────────────────────────────────────
  Future<bool> _verifyPlanAccess() async {
    final subState = ref.read(subscriptionManagerProvider);
    final plan = subState.planCode;

    if (plan == 'basic') {
      if (!mounted) return false;
      await PlanLimitDialog.showDiamondFeatureRequired(
        context,
        featureName: 'Thermal Printing Hub',
      );
      return false;
    }

    if (plan == 'gold') {
      final result = await DailyLimitService.instance.checkLimit(plan, 'thermal_print');
      if (!result.allowed) {
        if (!mounted) return false;
        await PlanLimitDialog.showDailyLimitReached(
          context,
          planCode: plan,
          action: 'thermal_print',
          limit: result.limit!,
          used: result.used,
        );
        return false;
      }
    }
    return true;
  }

  // Width & height in mm
  double get _labelWidth {
    final presets = _activeBrand.presets;
    if (_presetIndex >= presets.length) return 80.0;
    final preset = presets[_presetIndex];
    if (preset.isCustom) {
      return double.tryParse(_customWCtrl.text) ?? 80.0;
    }
    return preset.widthMm;
  }

  double get _labelHeight {
    final presets = _activeBrand.presets;
    if (_presetIndex >= presets.length) return 50.0;
    final preset = presets[_presetIndex];
    if (preset.isCustom) {
      return double.tryParse(_customHCtrl.text) ?? 50.0;
    }
    return preset.heightMm;
  }

  // ── Print Dispatcher ──────────────────────────────────────────
  Future<void> _triggerPrint() async {
    if (!await _verifyPlanAccess()) return;
    setState(() => _printing = true);

    try {
      late Uint8List pdfBytes;
      final w = _labelWidth;
      final h = _labelHeight;

      switch (_activeType) {
        case LabelType.productLabel:
          pdfBytes = await LabelPdfBuilder.productLabel(
            productName: _productNameCtrl.text,
            shopName: _shopNameCtrl.text,
            brandName: _brandNameCtrl.text,
            price: _priceCtrl.text,
            codeValue: _codeValueCtrl.text,
            codeMode: _codeMode,
            wMm: w,
            hMm: h,
          );
          break;
        case LabelType.barcodeSticker:
          pdfBytes = await LabelPdfBuilder.barcodeSticker(
            itemName: _productNameCtrl.text,
            codeValue: _codeValueCtrl.text,
            codeMode: _codeMode,
            price: _priceCtrl.text,
            wMm: w,
            hMm: h,
          );
          break;
        case LabelType.qrLabel:
          pdfBytes = await LabelPdfBuilder.qrLabel(
            title: _productNameCtrl.text,
            qrData: _codeValueCtrl.text,
            subtitle: _brandNameCtrl.text,
            wMm: w,
            hMm: h,
          );
          break;
        case LabelType.shippingLabel:
          pdfBytes = await LabelPdfBuilder.shippingLabel(
            fromName: _shipFromCtrl.text,
            fromAddress: _shipFromAddrCtrl.text,
            fromPhone: _shipFromPhoneCtrl.text,
            toName: _shipToCtrl.text,
            toAddress: _shipToAddrCtrl.text,
            toPhone: _shipToPhoneCtrl.text,
            orderNo: _shipOrderNoCtrl.text,
            weight: _shipWeightCtrl.text,
            notes: _shipNotesCtrl.text,
            codeValue: _codeValueCtrl.text,
            codeMode: _codeMode,
            wMm: w,
            hMm: h,
          );
          break;
        case LabelType.receipt:
          pdfBytes = await LabelPdfBuilder.receipt(
            shopName: _shopNameCtrl.text,
            address: _shipFromAddrCtrl.text,
            phone: _shipFromPhoneCtrl.text,
            pan: _receiptPanCtrl.text,
            title: _receiptTitleCtrl.text,
            prefix: _receiptPrefixCtrl.text,
            showAddress: _showReceiptAddress,
            showPhone: _showReceiptPhone,
            showPAN: _showReceiptPAN,
            showTax: _showReceiptTax,
            showDiscount: _showReceiptDiscount,
            items: _receiptItems,
            subtotal: _receiptSubtotalCtrl.text,
            discount: _receiptDiscountCtrl.text,
            tax: _receiptTaxCtrl.text,
            total: _receiptTotalCtrl.text,
            paymentMethod: 'Cash',
            footer: _receiptFooterCtrl.text,
            wMm: w,
            hMm: h,
          );
          break;
      }

      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
      await _saveSettings();

      final plan = ref.read(subscriptionManagerProvider).planCode;
      if (plan == 'gold') {
        await DailyLimitService.instance.increment(plan, 'thermal_print');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize print dialog: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  // ── Render 1D/2D Barcode Preview ────────────────────────────────
  Widget _buildCodeWidgetPreview() {
    final val = _codeValueCtrl.text.trim().isEmpty ? 'HamroPasal' : _codeValueCtrl.text.trim();
    if (_codeMode == BarcodeMode.qr) {
      return QrImageView(
        data: val,
        version: QrVersions.auto,
        size: 72,
        backgroundColor: Colors.white,
      );
    }
    final isEan = _codeMode == BarcodeMode.ean13;
    final cleanVal = isEan
        ? val.replaceAll(RegExp(r'[^0-9]'), '').padLeft(13, '0').substring(0, 13)
        : val;

    return BarcodeWidget(
      barcode: isEan ? Barcode.ean13() : Barcode.code128(),
      data: cleanVal,
      width: 110,
      height: 42,
      drawText: true,
      style: const TextStyle(fontSize: 8, color: Colors.black),
      color: Colors.black,
      backgroundColor: Colors.white,
    );
  }

  // ── Layout & UI Rendering ─────────────────────────────────────────
  IconData _getLabelTypeIcon(LabelType type) {
    switch (type) {
      case LabelType.productLabel:
        return Icons.label_outline_rounded;
      case LabelType.barcodeSticker:
        return Icons.qr_code_scanner_rounded;
      case LabelType.qrLabel:
        return Icons.qr_code_rounded;
      case LabelType.shippingLabel:
        return Icons.local_shipping_outlined;
      case LabelType.receipt:
        return Icons.receipt_long_outlined;
    }
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  'Thermal Label Hub Customizer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Design, preview, and print barcodes, stickers, shipping labels, and mini receipts.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.05, end: 0);
  }

  Widget _buildPrinterSizingCard(bool isDark) {
    return _CardSection(
      title: 'Printer Sizing & Brand',
      icon: Icons.settings_input_hdmi_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Printer Brand Support', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PrinterBrand.values.map((brand) {
              final active = _activeBrand == brand;
              return ChoiceChip(
                label: Text(brand.name),
                selected: active,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _activeBrand = brand;
                      _presetIndex = 0; // reset to first preset of this brand
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Size Presets & Medium', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_activeBrand.presets.length, (index) {
              final preset = _activeBrand.presets[index];
              return ChoiceChip(
                label: Text(preset.name),
                selected: _presetIndex == index,
                onSelected: (val) {
                  if (val) {
                    setState(() => _presetIndex = index);
                  }
                },
              );
            }),
          ),
          if (_activeBrand.presets[_presetIndex].isCustom) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _customWCtrl,
                    label: 'Width (mm)',
                    icon: Icons.width_normal_rounded,
                    numOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: _customHCtrl,
                    label: 'Height (mm)',
                    icon: Icons.height_rounded,
                    numOnly: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate(delay: 50.ms).fadeIn();
  }

  Widget _buildLabelTypeCard(bool isDark) {
    return _CardSection(
      title: 'Label Template & Mode',
      icon: Icons.layers_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Document Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LabelType.values.map((type) {
              final active = _activeType == type;
              return ChoiceChip(
                avatar: Icon(_getLabelTypeIcon(type), size: 16),
                label: Text(type.title),
                selected: active,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _activeType = type;
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn();
  }

  Widget _buildContentDetailsCard(bool isDark) {
    return _CardSection(
      title: 'Label Content & Metadata',
      icon: Icons.edit_note_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentInputs(),
        ],
      ),
    ).animate(delay: 150.ms).fadeIn();
  }

  Widget _buildActionsRow(bool isDark, String plan) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (plan == 'gold')
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FutureBuilder<LimitCheckResult>(
              future: DailyLimitService.instance.checkLimit('gold', 'thermal_print'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final check = snapshot.data!;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.print_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Text('${check.remaining} thermal prints remaining today',
                          style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                );
              },
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _printing ? null : _triggerPrint,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _printing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.print_rounded),
            label: Text(_printing ? 'Launching Print Dialog…' : 'Print Label / Sticker',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          plan == 'diamond'
              ? '💎 Unlimited printing on Diamond subscription'
              : plan == 'gold'
                  ? '🥇 Gold plan limits: 10 daily prints'
                  : '🔒 Upgrade to print on your thermal printer',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildPreviewContent(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility, size: 18, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Live Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1.5),
              boxShadow: AppTheme.cardShadow(Colors.black, opacity: 0.08),
            ),
            padding: const EdgeInsets.all(16),
            child: _buildStickerPreviewLayout(),
          ),
        ).animate().fadeIn(delay: 80.ms),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subState = ref.watch(subscriptionManagerProvider);
    final plan = subState.planCode;

    final isMobile = kIsWeb
        ? (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android)
        : (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thermal Label Printer')),
        body: _buildMobileBlockedView(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.print_rounded, size: 22, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Thermal Label Hub'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: plan == 'diamond'
                  ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D4EDD)])
                  : const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              plan == 'diamond' ? '💎 Diamond' : plan == 'gold' ? '🥇 Gold' : '🆓 Free',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 950;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 6,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildBanner(),
                      const SizedBox(height: 16),
                      _buildPrinterSizingCard(isDark),
                      const SizedBox(height: 16),
                      _buildLabelTypeCard(isDark),
                      const SizedBox(height: 16),
                      _buildContentDetailsCard(isDark),
                      const SizedBox(height: 24),
                      _buildActionsRow(isDark, plan),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: SingleChildScrollView(
                        child: _buildPreviewContent(isDark),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildBanner(),
                  const SizedBox(height: 16),
                  _buildPrinterSizingCard(isDark),
                  const SizedBox(height: 16),
                  _buildLabelTypeCard(isDark),
                  const SizedBox(height: 16),
                  _buildContentDetailsCard(isDark),
                  const SizedBox(height: 24),
                  _buildPreviewContent(isDark),
                  const SizedBox(height: 24),
                  _buildActionsRow(isDark, plan),
                  const SizedBox(height: 40),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildContentInputs() {
    switch (_activeType) {
      case LabelType.productLabel:
        return Column(
          children: [
            _textField(
              controller: _productNameCtrl,
              label: 'Product Name',
              icon: Icons.inventory_2_outlined,
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                tooltip: 'Select from Inventory',
                onPressed: _showInventoryPicker,
              ),
            ),
            const SizedBox(height: 12),
            _textField(controller: _shopNameCtrl, label: 'Shop Name', icon: Icons.storefront),
            const SizedBox(height: 12),
            _textField(controller: _brandNameCtrl, label: 'Brand Name', icon: Icons.branding_watermark_outlined),
            const SizedBox(height: 12),
            _textField(controller: _priceCtrl, label: 'Price (Rs.)', icon: Icons.currency_rupee, numOnly: true),
            const SizedBox(height: 12),
            _buildBarcodeConfig(),
          ],
        );
      case LabelType.barcodeSticker:
        return Column(
          children: [
            _textField(
              controller: _productNameCtrl,
              label: 'Product/Item Name',
              icon: Icons.inventory_2_outlined,
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                tooltip: 'Select from Inventory',
                onPressed: _showInventoryPicker,
              ),
            ),
            const SizedBox(height: 12),
            _textField(controller: _priceCtrl, label: 'Price', icon: Icons.currency_rupee, numOnly: true),
            const SizedBox(height: 12),
            _buildBarcodeConfig(),
          ],
        );
      case LabelType.qrLabel:
        return Column(
          children: [
            _textField(
              controller: _productNameCtrl,
              label: 'Label Title',
              icon: Icons.title_rounded,
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                tooltip: 'Select from Inventory',
                onPressed: _showInventoryPicker,
              ),
            ),
            const SizedBox(height: 12),
            _textField(controller: _codeValueCtrl, label: 'QR Payload / URL / Code', icon: Icons.link_rounded),
            const SizedBox(height: 12),
            _textField(controller: _brandNameCtrl, label: 'Footer Subtitle', icon: Icons.subtitles_rounded),
          ],
        );
      case LabelType.shippingLabel:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('From Detail', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _textField(controller: _shipFromCtrl, label: 'Sender Name', icon: Icons.person_outline),
            const SizedBox(height: 10),
            _textField(controller: _shipFromAddrCtrl, label: 'Sender Address', icon: Icons.location_on_outlined),
            const SizedBox(height: 10),
            _textField(controller: _shipFromPhoneCtrl, label: 'Sender Phone', icon: Icons.phone_outlined, numOnly: true),
            const SizedBox(height: 16),
            const Text('To Detail', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _textField(controller: _shipToCtrl, label: 'Recipient Name', icon: Icons.person),
            const SizedBox(height: 10),
            _textField(controller: _shipToAddrCtrl, label: 'Recipient Address', icon: Icons.location_on),
            const SizedBox(height: 10),
            _textField(controller: _shipToPhoneCtrl, label: 'Recipient Phone', icon: Icons.phone, numOnly: true),
            const SizedBox(height: 16),
            const Text('Parcel & Tracking Info', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _textField(controller: _shipOrderNoCtrl, label: 'Order No', icon: Icons.confirmation_number_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _textField(controller: _shipWeightCtrl, label: 'Weight', icon: Icons.monitor_weight_outlined)),
              ],
            ),
            const SizedBox(height: 10),
            _textField(controller: _shipNotesCtrl, label: 'Delivery Notes', icon: Icons.note_alt_outlined),
            const SizedBox(height: 12),
            _buildBarcodeConfig(),
          ],
        );
      case LabelType.receipt:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _textField(controller: _shopNameCtrl, label: 'Shop/Business Name', icon: Icons.storefront),
            const SizedBox(height: 10),
            _textField(controller: _shipFromAddrCtrl, label: 'Shop Address', icon: Icons.location_on_outlined),
            const SizedBox(height: 10),
            _textField(controller: _shipFromPhoneCtrl, label: 'Shop Contact No', icon: Icons.phone_outlined, numOnly: true),
            const SizedBox(height: 16),
            const Text('Items Sold', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildReceiptItemsList(),
            const SizedBox(height: 16),
            const Text('Totals', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _textField(controller: _receiptSubtotalCtrl, label: 'Subtotal', icon: Icons.calculate, numOnly: true)),
                const SizedBox(width: 10),
                Expanded(child: _textField(controller: _receiptDiscountCtrl, label: 'Discount', icon: Icons.price_change, numOnly: true)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _textField(controller: _receiptTaxCtrl, label: 'Tax', icon: Icons.percent, numOnly: true)),
                const SizedBox(width: 10),
                Expanded(child: _textField(controller: _receiptTotalCtrl, label: 'Final Total', icon: Icons.monetization_on, numOnly: true)),
              ],
            ),
            const SizedBox(height: 12),
            _textField(controller: _receiptFooterCtrl, label: 'Receipt Footer Note', icon: Icons.chat_bubble_outline),
            
            const Divider(height: 32),
            const Text('Receipt Layout Customization', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 12),
            _textField(controller: _receiptTitleCtrl, label: 'Receipt Title (e.g. BILL INVOICE)', icon: Icons.title_rounded),
            const SizedBox(height: 10),
            _textField(controller: _receiptPrefixCtrl, label: 'Invoice Prefix (e.g. INV)', icon: Icons.vpn_key_rounded),
            const SizedBox(height: 10),
            _textField(controller: _receiptPanCtrl, label: 'Business PAN/VAT', icon: Icons.badge_outlined, numOnly: true),
            const SizedBox(height: 16),
            const Text('Visibility Toggles', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SwitchListTile.adaptive(
              title: const Text('Show Business Address', style: TextStyle(fontSize: 13)),
              value: _showReceiptAddress,
              onChanged: (v) => setState(() => _showReceiptAddress = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile.adaptive(
              title: const Text('Show Business Phone', style: TextStyle(fontSize: 13)),
              value: _showReceiptPhone,
              onChanged: (v) => setState(() => _showReceiptPhone = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile.adaptive(
              title: const Text('Show Business PAN/VAT', style: TextStyle(fontSize: 13)),
              value: _showReceiptPAN,
              onChanged: (v) => setState(() => _showReceiptPAN = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile.adaptive(
              title: const Text('Show Tax Section', style: TextStyle(fontSize: 13)),
              value: _showReceiptTax,
              onChanged: (v) => setState(() => _showReceiptTax = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile.adaptive(
              title: const Text('Show Discount Row', style: TextStyle(fontSize: 13)),
              value: _showReceiptDiscount,
              onChanged: (v) => setState(() => _showReceiptDiscount = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        );
    }
  }

  Widget _buildBarcodeConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: BarcodeMode.values.map((mode) {
            final active = _codeMode == mode;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(mode.label),
                selected: active,
                onSelected: (val) {
                  if (val) setState(() => _codeMode = mode);
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        _textField(
          controller: _codeValueCtrl,
          label: _codeMode == BarcodeMode.qr ? 'QR Code Value / Link' : 'Barcode Numeric/Alphanumeric Code',
          icon: Icons.qr_code,
        ),
      ],
    );
  }

  Widget _buildReceiptItemsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          ..._receiptItems.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${item['name']}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${item['qty']}x', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Text('Rs.${item['price']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        _receiptItems.removeAt(idx);
                        _recalculateReceiptTotals();
                      });
                    },
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 36),
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              foregroundColor: AppTheme.primaryColor,
              elevation: 0,
            ),
            icon: const Icon(Icons.add_shopping_cart, size: 14),
            label: const Text('Add Demo Item', style: TextStyle(fontSize: 12)),
            onPressed: () {
              setState(() {
                _receiptItems.add({'name': 'Premium Rice 1kg', 'qty': '1', 'price': '220'});
                _recalculateReceiptTotals();
              });
            },
          ),
        ],
      ),
    );
  }

  void _recalculateReceiptTotals() {
    double sub = 0;
    for (var it in _receiptItems) {
      final q = double.tryParse(it['qty'] ?? '0') ?? 0;
      final p = double.tryParse(it['price'] ?? '0') ?? 0;
      sub += q * p;
    }
    final disc = double.tryParse(_receiptDiscountCtrl.text) ?? 0;
    final tax = sub * 0.13; // 13% VAT
    final tot = sub - disc + tax;

    _receiptSubtotalCtrl.text = sub.toStringAsFixed(0);
    _receiptTaxCtrl.text = tax.toStringAsFixed(0);
    _receiptTotalCtrl.text = tot.toStringAsFixed(0);
  }

  Widget _buildStickerPreviewLayout() {
    switch (_activeType) {
      case LabelType.productLabel:
        return Column(
          children: [
            if (_shopNameCtrl.text.isNotEmpty)
              Text(_shopNameCtrl.text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13)),
            if (_brandNameCtrl.text.isNotEmpty)
              Text(_brandNameCtrl.text, style: const TextStyle(color: Colors.black54, fontSize: 10)),
            const Divider(color: Colors.black12, thickness: 1),
            const SizedBox(height: 4),
            Text(_productNameCtrl.text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            _buildCodeWidgetPreview(),
            if (_priceCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Rs. ${_priceCtrl.text}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
            ],
            const SizedBox(height: 6),
            Text('${_labelWidth.toStringAsFixed(0)}x${_labelHeight.toStringAsFixed(0)} mm (${_activeBrand.name})',
                style: const TextStyle(color: Colors.black38, fontSize: 9)),
          ],
        );
      case LabelType.barcodeSticker:
        return Column(
          children: [
            Text(_productNameCtrl.text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            _buildCodeWidgetPreview(),
            if (_priceCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Rs. ${_priceCtrl.text}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
            ],
            const SizedBox(height: 6),
            Text('${_labelWidth.toStringAsFixed(0)}x${_labelHeight.toStringAsFixed(0)} mm', style: const TextStyle(color: Colors.black38, fontSize: 9)),
          ],
        );
      case LabelType.qrLabel:
        return Column(
          children: [
            Text(_productNameCtrl.text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            _buildCodeWidgetPreview(),
            const SizedBox(height: 8),
            Text(_brandNameCtrl.text, style: const TextStyle(color: Colors.black54, fontSize: 10), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(_codeValueCtrl.text, style: const TextStyle(color: Colors.black38, fontSize: 9), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          ],
        );
      case LabelType.shippingLabel:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SHIPPING LABEL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11)),
                Text(_shipOrderNoCtrl.text, style: const TextStyle(color: Colors.black54, fontSize: 10)),
              ],
            ),
            const Divider(color: Colors.black26),
            const Text('FROM:', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
            Text('${_shipFromCtrl.text} (${_shipFromPhoneCtrl.text})', style: const TextStyle(color: Colors.black87, fontSize: 10)),
            Text(_shipFromAddrCtrl.text, style: const TextStyle(color: Colors.black54, fontSize: 9)),
            const SizedBox(height: 6),
            const Divider(color: Colors.black12),
            const Text('TO:', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
            Text(_shipToCtrl.text, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(_shipToAddrCtrl.text, style: const TextStyle(color: Colors.black87, fontSize: 10)),
            Text('Ph: ${_shipToPhoneCtrl.text}', style: const TextStyle(color: Colors.black87, fontSize: 10)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Wt: ${_shipWeightCtrl.text}', style: const TextStyle(color: Colors.black87, fontSize: 9)),
                Text('Note: ${_shipNotesCtrl.text}', style: const TextStyle(color: Colors.black54, fontSize: 8), overflow: TextOverflow.ellipsis),
              ],
            ),
            if (_codeValueCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(child: _buildCodeWidgetPreview()),
            ],
          ],
        );
      case LabelType.receipt:
        return Column(
          children: [
            Text(_shopNameCtrl.text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14), textAlign: TextAlign.center),
            if (_showReceiptAddress && _shipFromAddrCtrl.text.isNotEmpty)
              Text(_shipFromAddrCtrl.text, style: const TextStyle(color: Colors.black54, fontSize: 10), textAlign: TextAlign.center),
            if (_showReceiptPhone && _shipFromPhoneCtrl.text.isNotEmpty)
              Text('Tel: ${_shipFromPhoneCtrl.text}', style: const TextStyle(color: Colors.black54, fontSize: 10), textAlign: TextAlign.center),
            if (_showReceiptPAN && _receiptPanCtrl.text.isNotEmpty)
              Text('PAN: ${_receiptPanCtrl.text}', style: const TextStyle(color: Colors.black54, fontSize: 10), textAlign: TextAlign.center),
            const Divider(color: Colors.black38),
            Text(
              '${_receiptTitleCtrl.text.isEmpty ? "TAX INVOICE" : _receiptTitleCtrl.text.toUpperCase()} : ${_receiptPrefixCtrl.text.isEmpty ? "INV" : _receiptPrefixCtrl.text.toUpperCase()}-0001',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
              textAlign: TextAlign.center,
            ),
            const Divider(color: Colors.black38),
            const SizedBox(height: 4),
            ..._receiptItems.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${it['qty']}x ${it['name']}', style: const TextStyle(color: Colors.black87, fontSize: 10)),
                      Text('Rs.${it['price']}', style: const TextStyle(color: Colors.black87, fontSize: 10)),
                    ],
                  ),
                )),
            const Divider(color: Colors.black26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(color: Colors.black54, fontSize: 10)),
                Text('Rs.${_receiptSubtotalCtrl.text}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
              ],
            ),
            if (_showReceiptDiscount)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount', style: TextStyle(color: Colors.black54, fontSize: 10)),
                  Text('-Rs.${_receiptDiscountCtrl.text}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                ],
              ),
            if (_showReceiptTax)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax (13%)', style: TextStyle(color: Colors.black54, fontSize: 10)),
                  Text('Rs.${_receiptTaxCtrl.text}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                ],
              ),
            const Divider(color: Colors.black, thickness: 1.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('Rs.${_receiptTotalCtrl.text}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            if (_receiptFooterCtrl.text.isNotEmpty)
              Text(_receiptFooterCtrl.text, style: TextStyle(color: Colors.black.withValues(alpha: 0.48), fontSize: 8), textAlign: TextAlign.center),
            const Text('--- Thank you for shopping ---', style: TextStyle(color: Colors.black54, fontSize: 9)),
          ],
        );
    }
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool numOnly = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: numOnly ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      onChanged: (val) {
        if (controller == _productNameCtrl) {
          if (_codeValueCtrl.text.isEmpty || _codeValueCtrl.text == _lastProductName) {
            _codeValueCtrl.text = val;
          }
          _lastProductName = val;
        }
        setState(() {});
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildMobileBlockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.glowShadow(AppTheme.primaryColor, opacity: 0.3),
              ),
              child: const Icon(Icons.desktop_windows_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Desktop & Web Only Feature', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              'Thermal Label printing requires hardware printer setups like Xprinter, TSC, Zebra or Epson thermal rolls usually connected over USB or network to a computer.\n\nPlease open this application on your Windows, Mac or Web browser to generate & print stickers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}

class _InventorySearchSheet extends StatefulWidget {
  final List<Product> products;
  final ValueChanged<Product> onSelect;

  const _InventorySearchSheet({
    required this.products,
    required this.onSelect,
  });

  @override
  State<_InventorySearchSheet> createState() => _InventorySearchSheetState();
}

class _InventorySearchSheetState extends State<_InventorySearchSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) {
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          (p.sku?.toLowerCase().contains(q) ?? false) ||
          (p.barcode?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Product from Inventory',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _query = val),
            decoration: const InputDecoration(
              hintText: 'Search by name, SKU or barcode...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No matching products found.'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final product = filtered[i];
                      return ListTile(
                        onTap: () => widget.onSelect(product),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor),
                        ),
                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          'SKU: ${product.sku ?? "N/A"} · Barcode: ${product.barcode ?? "N/A"}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Text(
                          'Rs. ${product.sellingPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

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
