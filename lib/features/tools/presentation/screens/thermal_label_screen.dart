import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_saoji/core/services/daily_limit_service.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/core/widgets/plan_limit_dialog.dart';
import 'package:smart_saoji/core/constants/app_constants.dart';
import 'package:smart_saoji/features/subscription/data/services/subscription_manager.dart';
import 'package:smart_saoji/features/tools/presentation/screens/label_print_models.dart';
import 'package:smart_saoji/features/tools/presentation/screens/label_pdf_builder.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_saoji/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:smart_saoji/features/inventory/data/models/product_model.dart';
import 'package:smart_saoji/features/invoices/data/services/invoice_settings_service.dart';
import 'package:intl/intl.dart';

class ThermalLabelScreen extends ConsumerStatefulWidget {
  const ThermalLabelScreen({super.key});

  @override
  ConsumerState<ThermalLabelScreen> createState() => _ThermalLabelScreenState();
}

class _ThermalLabelScreenState extends ConsumerState<ThermalLabelScreen> with SingleTickerProviderStateMixin {
  LabelType _activeType = LabelType.productLabel;
  PrinterBrand _activeBrand = PrinterBrand.generic;
  int _presetIndex = 1; // default to medium/first preset

  // Custom size controls
  final _customWCtrl = TextEditingController(text: '80');
  final _customHCtrl = TextEditingController(text: '50');

  // Common/Product inputs
  final _productNameCtrl = TextEditingController(text: 'Organic Green Tea');
  final _shopNameCtrl = TextEditingController(text: 'Smart Saoji Shop');
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
  final _receiptSubtotalCtrl = TextEditingController(text: '0');
  final _receiptDiscountPctCtrl = TextEditingController(text: '0'); // discount %
  final _receiptDiscountAmtCtrl = TextEditingController(text: '0'); // calculated
  final _receiptTaxCtrl = TextEditingController(text: '0');
  final _receiptTotalCtrl = TextEditingController(text: '0');
  final _receiptFooterCtrl = TextEditingController(text: 'Thank you for your business!');
  final List<Map<String, String>> _receiptItems = [];
  final List<Map<String, TextEditingController>> _receiptItemCtrls = [];

  // Business info (read-only, fetched from DB)
  String _businessPAN = '';
  String _businessAddress = '';
  String _businessPhone = '';
  String _businessName = '';

  // Product search cache from inventory
  List<Map<String, dynamic>> _inventoryProducts = [];

  // Receipt customization controls (shifted from Thermal Receipt settings)
  late TextEditingController _receiptTitleCtrl;
  late TextEditingController _receiptPrefixCtrl;
  bool _showReceiptTax = true;
  bool _showReceiptDiscount = true;
  bool _showReceiptAddress = true;
  bool _showReceiptPAN = true;
  bool _showReceiptPhone = true;
  String _receiptPaymentMethod = 'Cash';

  bool _printing = false;
  String _lastProductName = 'Organic Green Tea';

  // History tab variables
  List<Map<String, dynamic>> _receiptHistory = [];
  bool _isLoadingHistory = false;
  String _historySearchQuery = '';
  String _historyFilterMethod = 'All'; // All, Cash, Bank QR, Esewa
  String _historyFilterRange = 'Today'; // Today, This Week, This Month, Custom
  DateTimeRange? _historyCustomRange;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final invoiceSettings = ref.read(invoiceSettingsProvider);
    _receiptTitleCtrl = TextEditingController(text: invoiceSettings.title);
    _receiptPrefixCtrl = TextEditingController(text: invoiceSettings.prefix);
    _showReceiptTax = invoiceSettings.showTax;
    _showReceiptDiscount = invoiceSettings.showDiscount;
    _showReceiptAddress = invoiceSettings.showAddress;
    _showReceiptPAN = invoiceSettings.showPAN;
    _showReceiptPhone = invoiceSettings.showPhone;

    // Always pre-load these so they are ready when user switches to Receipt
    _fetchBusinessProfile();
    _fetchInventoryProducts();

    _loadSavedSettings();
    _fetchHistory();
  }

  Future<void> _fetchBusinessProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final memberRow = await supabase
          .from('business_members')
          .select('business_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      final businessId = memberRow?['business_id'] as String?;
      if (businessId != null) {
        final biz = await supabase
            .from('businesses')
            .select('name, phone, address, pan_number')
            .eq('id', businessId)
            .maybeSingle();
        if (biz != null && mounted) {
          setState(() {
            _businessName = biz['name'] as String? ?? '';
            _businessAddress = biz['address'] as String? ?? '';
            _businessPhone = biz['phone'] as String? ?? '';
            _businessPAN = biz['pan_number'] as String? ?? '';
            // Sync to existing controllers for PDF builder
            _shopNameCtrl.text = _businessName;
            _shipFromAddrCtrl.text = _businessAddress;
            _shipFromPhoneCtrl.text = _businessPhone;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching business profile: $e');
    }
  }

  Future<void> _fetchInventoryProducts() async {
    try {
      final supabase = Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();
      final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
      if (businessId == null) return;

      final rows = await supabase
          .from('products')
          .select('name, sku, selling_price, unit')
          .eq('business_id', businessId)
          .eq('is_active', true)
          .order('name');

      if (mounted) {
        setState(() {
          _inventoryProducts = (rows as List)
              .map((r) => {
                    'name': r['name'] as String? ?? '',
                    'sku': r['sku'] as String? ?? '',
                    'price': (r['selling_price'] as num?)?.toDouble() ?? 0.0,
                    'unit': r['unit'] as String? ?? 'Pc',
                  })
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
    }
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
        _shopNameCtrl.text = prefs.getString('thermal_shop_name') ?? 'Smart Saoji Shop';
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

        _receiptSubtotalCtrl.text = prefs.getString('thermal_rec_sub') ?? '0';
        _receiptDiscountPctCtrl.text = prefs.getString('thermal_rec_disc_pct') ?? '0';
        _receiptTaxCtrl.text = prefs.getString('thermal_rec_tax') ?? '0';
        _receiptTotalCtrl.text = prefs.getString('thermal_rec_tot') ?? '0';
        _receiptFooterCtrl.text = prefs.getString('thermal_rec_foot') ?? 'Thank you for your business!';

        _receiptTitleCtrl.text = prefs.getString('thermal_rec_title') ?? _receiptTitleCtrl.text;
        _receiptPrefixCtrl.text = prefs.getString('thermal_rec_prefix') ?? _receiptPrefixCtrl.text;
        _showReceiptTax = prefs.getBool('thermal_rec_show_tax') ?? _showReceiptTax;
        _showReceiptDiscount = prefs.getBool('thermal_rec_show_disc') ?? _showReceiptDiscount;
        _showReceiptAddress = prefs.getBool('thermal_rec_show_addr') ?? _showReceiptAddress;
        _showReceiptPAN = prefs.getBool('thermal_rec_show_pan') ?? _showReceiptPAN;
        _showReceiptPhone = prefs.getBool('thermal_rec_show_phone') ?? _showReceiptPhone;
        _receiptPaymentMethod = prefs.getString('thermal_rec_payment_method') ?? 'Cash';
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
      await prefs.setString('thermal_rec_disc_pct', _receiptDiscountPctCtrl.text);
      await prefs.setString('thermal_rec_tax', _receiptTaxCtrl.text);
      await prefs.setString('thermal_rec_tot', _receiptTotalCtrl.text);
      await prefs.setString('thermal_rec_foot', _receiptFooterCtrl.text);

      await prefs.setString('thermal_rec_title', _receiptTitleCtrl.text);
      await prefs.setString('thermal_rec_prefix', _receiptPrefixCtrl.text);
      await prefs.setBool('thermal_rec_show_tax', _showReceiptTax);
      await prefs.setBool('thermal_rec_show_disc', _showReceiptDiscount);
      await prefs.setBool('thermal_rec_show_addr', _showReceiptAddress);
      await prefs.setBool('thermal_rec_show_pan', _showReceiptPAN);
      await prefs.setBool('thermal_rec_show_phone', _showReceiptPhone);
      await prefs.setString('thermal_rec_payment_method', _receiptPaymentMethod);

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
    _tabController.dispose();
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
    _receiptDiscountPctCtrl.dispose();
    _receiptDiscountAmtCtrl.dispose();
    _receiptTaxCtrl.dispose();
    _receiptTotalCtrl.dispose();
    _receiptFooterCtrl.dispose();
    for (var ctrls in _receiptItemCtrls) {
      ctrls['name']?.dispose();
      ctrls['qty']?.dispose();
      ctrls['price']?.dispose();
    }
    _receiptTitleCtrl.dispose();
    _receiptPrefixCtrl.dispose();
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

      String receiptNo = '';
      if (_activeType == LabelType.receipt) {
        receiptNo = _generateReceiptNumber();
      }

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
            shopName: _businessName,
            address: _businessAddress,
            phone: _businessPhone,
            pan: _businessPAN,
            title: _receiptTitleCtrl.text,
            prefix: _receiptPrefixCtrl.text,
            receiptNumber: receiptNo,
            showAddress: _showReceiptAddress,
            showPhone: _showReceiptPhone,
            showPAN: _showReceiptPAN,
            showTax: _showReceiptTax,
            showDiscount: _showReceiptDiscount,
            items: _receiptItems,
            subtotal: _receiptSubtotalCtrl.text,
            discount: _receiptDiscountAmtCtrl.text,
            tax: _receiptTaxCtrl.text,
            total: _receiptTotalCtrl.text,
            paymentMethod: _receiptPaymentMethod,
            footer: _receiptFooterCtrl.text,
            wMm: w,
            hMm: h,
          );
          break;
      }

      final printed = await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
      await _saveSettings();

      if (printed && _activeType == LabelType.receipt) {
        await _saveReceiptToDatabase(
          receiptNumber: receiptNo,
          title: _receiptTitleCtrl.text.isEmpty ? 'TAX INVOICE' : _receiptTitleCtrl.text,
          subtotal: double.tryParse(_receiptSubtotalCtrl.text) ?? 0.0,
          discount: double.tryParse(_receiptDiscountAmtCtrl.text) ?? 0.0,
          tax: double.tryParse(_receiptTaxCtrl.text) ?? 0.0,
          total: double.tryParse(_receiptTotalCtrl.text) ?? 0.0,
          paymentMethod: _receiptPaymentMethod,
          footer: _receiptFooterCtrl.text,
          items: _receiptItems,
        );
        _fetchHistory();
      }

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
    final val = _codeValueCtrl.text.trim().isEmpty ? 'SmartSaoji' : _codeValueCtrl.text.trim();
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
                    if (type == LabelType.receipt) {
                      _fetchBusinessProfile();
                      if (_inventoryProducts.isEmpty) _fetchInventoryProducts();
                    }
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Designer', icon: Icon(Icons.design_services_rounded, size: 20)),
            Tab(text: 'Print History & Statements', icon: Icon(Icons.history_rounded, size: 20)),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Designer View
          LayoutBuilder(
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
          // Tab 2: Print History & Statements View
          _buildPrintHistoryTab(isDark),
        ],
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
            // ── Business Info Card (all read-only from DB) ──
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storefront_rounded, size: 16, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Registered Business (Read-Only)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow(Icons.store_outlined, 'Business Name', _businessName.isEmpty ? 'Loading...' : _businessName),
                  const SizedBox(height: 8),
                  _infoRow(Icons.location_on_outlined, 'Address', _businessAddress.isEmpty ? 'Not set' : _businessAddress),
                  const SizedBox(height: 8),
                  _infoRow(Icons.phone_outlined, 'Phone', _businessPhone.isEmpty ? 'Not set' : _businessPhone),
                  const SizedBox(height: 8),
                  _infoRow(Icons.badge_outlined, 'PAN/VAT', _businessPAN.isEmpty ? 'Not set' : _businessPAN),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Items Sold ──
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, size: 16),
                const SizedBox(width: 8),
                const Text('Items Sold', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_inventoryProducts.isEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.sync, size: 14),
                    label: const Text('Load Inventory', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _fetchInventoryProducts();
                      _fetchBusinessProfile();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _buildReceiptItemsList(),

            const SizedBox(height: 20),

            // ── Totals Section (premium card) ──
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calculate_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Bill Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('Rs. ${_receiptSubtotalCtrl.text}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 16),
                  // Discount %
                  Row(
                    children: [
                      const Text('Discount:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _receiptDiscountPctCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: '0',
                            suffixText: '%',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (_) => _recalculateReceiptTotals(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('= Rs. ${_receiptDiscountAmtCtrl.text}', style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('VAT (13% fixed):', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('Rs. ${_receiptTaxCtrl.text}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange)),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GRAND TOTAL:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                        'Rs. ${_receiptTotalCtrl.text}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'Cash',
                        label: Text('Cash'),
                        icon: Icon(Icons.money_rounded, size: 16),
                      ),
                      ButtonSegment<String>(
                        value: 'Bank QR',
                        label: Text('Bank QR'),
                        icon: Icon(Icons.qr_code_scanner_rounded, size: 16),
                      ),
                      ButtonSegment<String>(
                        value: 'Esewa',
                        label: Text('Esewa'),
                        icon: Icon(Icons.account_balance_wallet_rounded, size: 16),
                      ),
                    ],
                    selected: {_receiptPaymentMethod},
                    onSelectionChanged: (Set<String> selected) {
                      setState(() {
                        _receiptPaymentMethod = selected.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _textField(controller: _receiptFooterCtrl, label: 'Receipt Footer Note', icon: Icons.chat_bubble_outline),

            const Divider(height: 32),
            const Text('Receipt Layout Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 12),
            _textField(controller: _receiptTitleCtrl, label: 'Receipt Title (e.g. TAX INVOICE)', icon: Icons.title_rounded),
            const SizedBox(height: 10),
            _textField(controller: _receiptPrefixCtrl, label: 'Invoice Prefix (e.g. INV)', icon: Icons.vpn_key_rounded),
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
              title: const Text('Show PAN/VAT No.', style: TextStyle(fontSize: 13)),
              value: _showReceiptPAN,
              onChanged: (v) => setState(() => _showReceiptPAN = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile.adaptive(
              title: const Text('Show VAT Row', style: TextStyle(fontSize: 13)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Column headers
        if (_receiptItemCtrls.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4, right: 52),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text('Item (Name or SKU)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text('Qty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text('Rate (Rs)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                ),
              ],
            ),
          ),
        // Item rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _receiptItemCtrls.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (context, idx) {
            final ctrls = _receiptItemCtrls[idx];
            return Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Product search autocomplete ──
                  Expanded(
                    flex: 5,
                    child: Autocomplete<Map<String, dynamic>>(
                      displayStringForOption: (p) => p['name'] as String,
                      optionsBuilder: (textEditingValue) {
                        final query = textEditingValue.text.trim().toLowerCase();
                        if (query.isEmpty) return const Iterable.empty();
                        return _inventoryProducts.where((p) {
                          final name = (p['name'] as String).toLowerCase();
                          final sku = (p['sku'] as String).toLowerCase();
                          return name.contains(query) || sku.contains(query);
                        });
                      },
                      onSelected: (product) {
                        setState(() {
                          ctrls['price']?.text = (product['price'] as double).toStringAsFixed(2);
                          _receiptItems[idx]['name'] = product['name'] as String;
                          _receiptItems[idx]['price'] = (product['price'] as double).toStringAsFixed(2);
                          _recalculateReceiptTotals();
                        });
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(10),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 320),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, i) {
                                  final p = options.elementAt(i);
                                  return InkWell(
                                    onTap: () => onSelected(p),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              if ((p['sku'] as String).isNotEmpty) ...[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  margin: const EdgeInsets.only(right: 8),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text('SKU: ${p['sku']}', style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor)),
                                                ),
                                              ],
                                              Text('Rs. ${(p['price'] as double).toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: ctrl,
                          focusNode: focusNode,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: _inventoryProducts.isEmpty
                                ? 'Loading inventory...'
                                : 'Type name or SKU to search',
                            prefixIcon: const Icon(Icons.search_rounded, size: 15),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            _receiptItems[idx]['name'] = val;
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ── Qty ──
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: ctrls['qty'],
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: '1',
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        _receiptItems[idx]['qty'] = val;
                        _recalculateReceiptTotals();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ── Rate ──
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: ctrls['price'],
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: '0',
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        _receiptItems[idx]['price'] = val;
                        _recalculateReceiptTotals();
                      },
                    ),
                  ),
                  // ── Delete ──
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        ctrls['name']?.dispose();
                        ctrls['qty']?.dispose();
                        ctrls['price']?.dispose();
                        _receiptItemCtrls.removeAt(idx);
                        _receiptItems.removeAt(idx);
                        _recalculateReceiptTotals();
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 38),
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            foregroundColor: AppTheme.primaryColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
          label: const Text('Add Item', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          onPressed: () {
            setState(() {
              _receiptItemCtrls.add({
                'name': TextEditingController(text: ''),
                'qty': TextEditingController(text: '1'),
                'price': TextEditingController(text: '0'),
              });
              _receiptItems.add({'name': '', 'qty': '1', 'price': '0'});
              _recalculateReceiptTotals();
            });
          },
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  void _recalculateReceiptTotals() {
    double sub = 0;
    for (var it in _receiptItems) {
      final q = double.tryParse(it['qty'] ?? '0') ?? 0;
      final p = double.tryParse(it['price'] ?? '0') ?? 0;
      sub += q * p;
    }
    final discPct = double.tryParse(_receiptDiscountPctCtrl.text) ?? 0;
    final discAmt = sub * discPct / 100;
    final afterDiscount = sub - discAmt;
    final tax = afterDiscount * 0.13; // fixed 13% VAT on post-discount amount
    final tot = afterDiscount + tax;

    setState(() {
      _receiptSubtotalCtrl.text = sub.toStringAsFixed(2);
      _receiptDiscountAmtCtrl.text = discAmt.toStringAsFixed(2);
      _receiptTaxCtrl.text = tax.toStringAsFixed(2);
      _receiptTotalCtrl.text = tot.toStringAsFixed(2);
    });
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
            Text(_businessName.isEmpty ? 'Your Business Name' : _businessName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14), textAlign: TextAlign.center),
            if (_showReceiptAddress && _businessAddress.isNotEmpty)
              Text(_businessAddress, style: const TextStyle(color: Colors.black54, fontSize: 10), textAlign: TextAlign.center),
            if (_showReceiptPhone && _businessPhone.isNotEmpty)
              Text('Tel: $_businessPhone', style: const TextStyle(color: Colors.black54, fontSize: 10), textAlign: TextAlign.center),
            if (_showReceiptPAN && _businessPAN.isNotEmpty)
              Text('PAN: $_businessPAN', style: const TextStyle(color: Colors.black54, fontSize: 10), textAlign: TextAlign.center),
            const Divider(color: Colors.black38),
            Text(
              '${_receiptTitleCtrl.text.isEmpty ? "TAX INVOICE" : _receiptTitleCtrl.text.toUpperCase()} : ${_receiptPrefixCtrl.text.isEmpty ? "INV" : _receiptPrefixCtrl.text.toUpperCase()}-0001',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
              textAlign: TextAlign.center,
            ),
            const Divider(color: Colors.black38),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(4.5), // Name
                1: FlexColumnWidth(1.5), // Qty
                2: FlexColumnWidth(2.0), // Rate
                3: FlexColumnWidth(2.0), // Amount
              },
              children: [
                // Table Header
                const TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text('Item', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text('Qty', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8), textAlign: TextAlign.right),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text('Rate', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8), textAlign: TextAlign.right),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text('Amount', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8), textAlign: TextAlign.right),
                    ),
                  ],
                ),
                // Table Rows
                ..._receiptItems.map((it) {
                  final qty = double.tryParse(it['qty'] ?? '1') ?? 1;
                  final rate = double.tryParse(it['price'] ?? '0') ?? 0;
                  final totalAmt = qty * rate;
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(it['name'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 8)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(qty.toStringAsFixed(0), style: const TextStyle(color: Colors.black87, fontSize: 8), textAlign: TextAlign.right),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(rate.toStringAsFixed(2), style: const TextStyle(color: Colors.black87, fontSize: 8), textAlign: TextAlign.right),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(totalAmt.toStringAsFixed(2), style: const TextStyle(color: Colors.black87, fontSize: 8), textAlign: TextAlign.right),
                      ),
                    ],
                  );
                }),
              ],
            ),
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
                  Text('-Rs.${_receiptDiscountAmtCtrl.text}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
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
            if (_receiptPaymentMethod.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Paid by', style: TextStyle(color: Colors.black54, fontSize: 8)),
                  Text(_receiptPaymentMethod, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 8)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Text('--- Thank You For Your Visit ! ---', style: TextStyle(color: Colors.black54, fontSize: 9)),
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
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: numOnly ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      onChanged: (val) {
        if (controller == _productNameCtrl) {
          if (_codeValueCtrl.text.isEmpty || _codeValueCtrl.text == _lastProductName) {
            _codeValueCtrl.text = val;
          }
          _lastProductName = val;
        }
        if (onChanged != null) {
          onChanged(val);
        }
        setState(() {});
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: readOnly ? true : null,
        fillColor: readOnly ? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100) : null,
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

  // ── History & Statements Helper Methods ───────────────────────────
  String _generateReceiptNumber() {
    final prefix = _receiptPrefixCtrl.text.trim().isEmpty ? 'INV' : _receiptPrefixCtrl.text.trim().toUpperCase();
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final rand = (DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    return '$prefix-$dateStr-$rand';
  }

  Future<void> _saveReceiptToDatabase({
    required String receiptNumber,
    required String title,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required String paymentMethod,
    required String footer,
    required List<Map<String, String>> items,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();
      final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
      if (businessId == null) return;

      await supabase.from('thermal_receipts').insert({
        'business_id': businessId,
        'receipt_number': receiptNumber,
        'title': title,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'payment_method': paymentMethod,
        'footer': footer,
        'items': items,
      });
      debugPrint('Receipt saved successfully to database');
    } catch (e) {
      debugPrint('Failed to save receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save print record to database: ${e.toString().contains("42P01") ? "Please run the database migration first!" : e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final supabase = Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();
      final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
      if (businessId == null) {
        setState(() => _isLoadingHistory = false);
        return;
      }

      final response = await supabase
          .from('thermal_receipts')
          .select('*')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
          
      if (mounted) {
        setState(() {
          _receiptHistory = List<Map<String, dynamic>>.from(response as List);
        });
      }
    } catch (e) {
      debugPrint('Error fetching print history: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredReceiptHistory {
    return _receiptHistory.where((r) {
      // 1. Search Query
      final receiptNo = (r['receipt_number'] as String? ?? '').toLowerCase();
      final title = (r['title'] as String? ?? '').toLowerCase();
      
      String itemsStr = '';
      try {
        final list = r['items'] as List<dynamic>? ?? [];
        itemsStr = list.map((i) => i['name'] as String? ?? '').join(' ').toLowerCase();
      } catch (_) {}

      final matchesSearch = receiptNo.contains(_historySearchQuery.toLowerCase()) ||
          title.contains(_historySearchQuery.toLowerCase()) ||
          itemsStr.contains(_historySearchQuery.toLowerCase());
      if (!matchesSearch) return false;

      // 2. Payment Method
      if (_historyFilterMethod != 'All') {
        final pm = (r['payment_method'] as String? ?? 'Cash').toLowerCase();
        final target = _historyFilterMethod.toLowerCase();
        if (target == 'bank qr') {
          if (!pm.contains('bank') && !pm.contains('qr')) return false;
        } else {
          if (!pm.contains(target)) return false;
        }
      }

      // 3. Date Range
      if (r['created_at'] == null) return false;
      final createdAt = DateTime.parse(r['created_at'] as String).toLocal();
      final now = DateTime.now();

      switch (_historyFilterRange) {
        case 'Today':
          final startOfToday = DateTime(now.year, now.month, now.day);
          return createdAt.isAfter(startOfToday);
        case 'This Week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          return createdAt.isAfter(startOfWeekDay);
        case 'This Month':
          final startOfMonth = DateTime(now.year, now.month, 1);
          return createdAt.isAfter(startOfMonth);
        case 'Custom':
          if (_historyCustomRange == null) return true;
          final start = DateTime(_historyCustomRange!.start.year, _historyCustomRange!.start.month, _historyCustomRange!.start.day);
          final end = DateTime(_historyCustomRange!.end.year, _historyCustomRange!.end.month, _historyCustomRange!.end.day, 23, 59, 59);
          return createdAt.isAfter(start) && createdAt.isBefore(end);
        default:
          return true;
      }
    }).toList();
  }

  Map<String, double> get _historyStats {
    double totalSales = 0;
    double cashSales = 0;
    double qrSales = 0;
    double esewaSales = 0;

    for (var r in _filteredReceiptHistory) {
      final t = (r['total'] as num?)?.toDouble() ?? 0.0;
      totalSales += t;
      final pm = (r['payment_method'] as String? ?? 'Cash').toLowerCase();
      if (pm.contains('cash')) {
        cashSales += t;
      } else if (pm.contains('bank') || pm.contains('qr')) {
        qrSales += t;
      } else if (pm.contains('esewa')) {
        esewaSales += t;
      }
    }

    return {
      'count': _filteredReceiptHistory.length.toDouble(),
      'total': totalSales,
      'cash': cashSales,
      'qr': qrSales,
      'esewa': esewaSales,
    };
  }

  Future<void> _exportStatementPdf() async {
    try {
      String period = _historyFilterRange;
      if (period == 'Custom' && _historyCustomRange != null) {
        final startStr = DateFormat('dd MMM').format(_historyCustomRange!.start);
        final endStr = DateFormat('dd MMM yyyy').format(_historyCustomRange!.end);
        period = '$startStr - $endStr';
      }

      final pdfBytes = await LabelPdfBuilder.salesStatement(
        shopName: _businessName,
        address: _businessAddress,
        phone: _businessPhone,
        pan: _businessPAN,
        periodStr: period,
        receipts: _filteredReceiptHistory,
      );

      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } catch (e) {
      debugPrint('Error exporting statement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export statement: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reprintReceipt(Map<String, dynamic> r) async {
    try {
      final list = r['items'] as List<dynamic>? ?? [];
      final List<Map<String, String>> itemsList = list.map((item) {
        return {
          'name': item['name']?.toString() ?? '',
          'qty': item['qty']?.toString() ?? '1',
          'price': item['price']?.toString() ?? '0',
        };
      }).toList();

      final pdfBytes = await LabelPdfBuilder.receipt(
        shopName: _businessName,
        address: _businessAddress,
        phone: _businessPhone,
        pan: _businessPAN,
        title: r['title']?.toString() ?? 'TAX INVOICE',
        prefix: '',
        receiptNumber: r['receipt_number']?.toString() ?? 'INV-0001',
        showAddress: _showReceiptAddress,
        showPhone: _showReceiptPhone,
        showPAN: _showReceiptPAN,
        showTax: _showReceiptTax,
        showDiscount: _showReceiptDiscount,
        items: itemsList,
        subtotal: (r['subtotal'] as num?)?.toDouble().toString() ?? '0',
        discount: (r['discount'] as num?)?.toDouble().toString() ?? '0',
        tax: (r['tax'] as num?)?.toDouble().toString() ?? '0',
        total: (r['total'] as num?)?.toDouble().toString() ?? '0',
        paymentMethod: r['payment_method']?.toString() ?? 'Cash',
        footer: r['footer']?.toString() ?? '',
        wMm: 80.0,
        hMm: 150.0,
      );

      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } catch (e) {
      debugPrint('Error reprinting receipt: $e');
    }
  }

  Widget _buildPrintHistoryTab(bool isDark) {
    final stats = _historyStats;
    final filtered = _filteredReceiptHistory;
    final fmt = NumberFormat('#,##,##0.00');

    return Column(
      children: [
        // 1. Stats Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildHistoryStatCard(
                  title: 'Total Receipts',
                  value: '${stats['count']!.toInt()}',
                  icon: Icons.receipt_long_rounded,
                  color: Colors.blue,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildHistoryStatCard(
                  title: 'Total Sales',
                  value: 'Rs. ${fmt.format(stats['total'])}',
                  icon: Icons.trending_up_rounded,
                  color: AppTheme.primaryColor,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildHistoryStatCard(
                  title: 'Cash Sales',
                  value: 'Rs. ${fmt.format(stats['cash'])}',
                  icon: Icons.money_rounded,
                  color: Colors.green,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildHistoryStatCard(
                  title: 'Bank QR Sales',
                  value: 'Rs. ${fmt.format(stats['qr'])}',
                  icon: Icons.qr_code_scanner_rounded,
                  color: Colors.orange,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildHistoryStatCard(
                  title: 'Esewa Sales',
                  value: 'Rs. ${fmt.format(stats['esewa'])}',
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.purple,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // 2. Search & Filter Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Receipt No or items...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _historySearchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Payment Method filter
              DropdownButton<String>(
                value: _historyFilterMethod,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(12),
                items: ['All', 'Cash', 'Bank QR', 'Esewa'].map((val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _historyFilterMethod = val;
                    });
                  }
                },
              ),
              const SizedBox(width: 12),
              // Date filter
              DropdownButton<String>(
                value: _historyFilterRange,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(12),
                items: ['Today', 'This Week', 'This Month', 'Custom'].map((val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val == 'Custom' && _historyCustomRange != null
                        ? '${DateFormat('dd MMM').format(_historyCustomRange!.start)} - ${DateFormat('dd MMM').format(_historyCustomRange!.end)}'
                        : val),
                  );
                }).toList(),
                onChanged: (val) async {
                  if (val == 'Custom') {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _historyFilterRange = 'Custom';
                        _historyCustomRange = picked;
                      });
                    }
                  } else if (val != null) {
                    setState(() {
                      _historyFilterRange = val;
                      _historyCustomRange = null;
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
              // Download Statement Button
              ElevatedButton.icon(
                onPressed: filtered.isEmpty ? null : _exportStatementPdf,
                icon: const Icon(Icons.file_download_rounded, size: 18),
                label: const Text('Export Statement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),

        // 3. History List
        Expanded(
          child: _isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchHistory,
                  child: filtered.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Receipts Found',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try changing your filters or print a receipt in the Designer.',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final r = filtered[index];
                            final totalAmt = (r['total'] as num?)?.toDouble() ?? 0.0;
                            final date = r['created_at'] != null
                                ? DateTime.parse(r['created_at'] as String).toLocal()
                                : DateTime.now();
                            final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(date);
                            final payment = r['payment_method'] as String? ?? 'Cash';
                            final receiptNo = r['receipt_number'] as String? ?? 'REC-0001';

                            int itemsCount = 0;
                            String itemsPreview = '';
                            try {
                              final list = r['items'] as List<dynamic>? ?? [];
                              itemsCount = list.length;
                              itemsPreview = list.map((i) => '${i['name']} (${i['qty']})').join(', ');
                              if (itemsPreview.length > 50) {
                                itemsPreview = '${itemsPreview.substring(0, 47)}...';
                              }
                            } catch (_) {}

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _showReceiptDetailsSheet(r),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: (payment.toLowerCase().contains('cash')
                                                  ? Colors.green
                                                  : payment.toLowerCase().contains('esewa')
                                                      ? Colors.purple
                                                      : Colors.orange)
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          payment.toLowerCase().contains('cash')
                                              ? Icons.money_rounded
                                              : payment.toLowerCase().contains('esewa')
                                                  ? Icons.account_balance_wallet_rounded
                                                  : Icons.qr_code_scanner_rounded,
                                          color: payment.toLowerCase().contains('cash')
                                              ? Colors.green
                                              : payment.toLowerCase().contains('esewa')
                                                  ? Colors.purple
                                                  : Colors.orange,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  receiptNo,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                                Text(
                                                  'Rs. ${fmt.format(totalAmt)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: AppTheme.primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              dateStr,
                                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              itemsCount == 0 ? 'No items' : '$itemsCount item(s): $itemsPreview',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey[400] : Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(Icons.print_rounded, color: AppTheme.primaryColor),
                                        onPressed: () => _reprintReceipt(r),
                                        tooltip: 'Reprint Receipt',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showReceiptDetailsSheet(Map<String, dynamic> r) {
    final fmt = NumberFormat('#,##,##0.00');
    final date = r['created_at'] != null
        ? DateTime.parse(r['created_at'] as String).toLocal()
        : DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final payment = r['payment_method'] as String? ?? 'Cash';
    final items = r['items'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['receipt_number'] ?? 'INV-0001',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              const SizedBox(height: 8),

              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    final name = item['name']?.toString() ?? '';
                    final qty = double.tryParse(item['qty']?.toString() ?? '1') ?? 1.0;
                    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                    final itemTotal = qty * price;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(flex: 3, child: Text(name, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text('${qty.toInt()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text(price.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text(itemTotal.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 32),

              _sheetTotalRow('Subtotal', 'Rs. ${fmt.format(r['subtotal'] ?? 0.0)}'),
              if ((r['discount'] as num? ?? 0) > 0)
                _sheetTotalRow('Discount', '-Rs. ${fmt.format(r['discount'] ?? 0.0)}', color: Colors.green),
              if ((r['tax'] as num? ?? 0) > 0)
                _sheetTotalRow('Tax', 'Rs. ${fmt.format(r['tax'] ?? 0.0)}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    'Rs. ${fmt.format(r['total'] ?? 0.0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _sheetTotalRow('Paid via', payment, isBold: true),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _reprintReceipt(r);
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Reprint'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetTotalRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: isBold ? FontWeight.bold : null)),
          Text(value, style: TextStyle(fontSize: 13, color: color ?? Colors.grey[800], fontWeight: isBold ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}

// ── Original Mobile Blocked View ─────────────────────────────────

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
