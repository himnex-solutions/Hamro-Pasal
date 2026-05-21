import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/constants/supabase_constants.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_button.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/core/widgets/app_text_field.dart';
import 'package:hamro_pasal/features/inventory/data/models/product_model.dart';
import 'package:hamro_pasal/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:hamro_pasal/core/services/daily_limit_service.dart';
import 'package:hamro_pasal/core/widgets/plan_limit_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:hamro_pasal/core/widgets/barcode_scanner_modal.dart';
import 'package:hamro_pasal/features/subscription/data/services/subscription_manager.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _minStockCtrl = TextEditingController(text: '5');
  String? _selectedUnit;
  bool _isLoading = false;
  File? _imageFile;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _costCtrl.dispose();
    _sellCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final manager = ref.read(subscriptionManagerProvider.notifier);
    final hasAccess = manager.checkFeatureAccess('barcode_scanner');

    if (!hasAccess) {
      PlanLimitDialog.showDiamondFeatureRequired(
        context,
        featureName: 'Barcode Scanning',
      );
      return;
    }

    final code = await BarcodeScannerModal.show(context);
    if (!mounted) return;
    if (code != null && code.isNotEmpty) {
      setState(() {
        _barcodeCtrl.text = code;
      });
      AppSnackbar.show(context, 'Barcode scanned: $code', isSuccess: true);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<String?> _uploadImage(String productId) async {
    if (_imageFile == null) return null;
    final supabase = Supabase.instance.client;
    final bytes = await _imageFile!.readAsBytes();
    final ext = _imageFile!.path.split('.').last;
    final path = '$productId.$ext';
    await supabase.storage
        .from(SupabaseConstants.productImagesBucket)
        .uploadBinary(path, bytes);
    return supabase.storage
        .from(SupabaseConstants.productImagesBucket)
        .getPublicUrl(path);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Product name is required', isError: true);
      return;
    }
    if (_sellCtrl.text.isEmpty) {
      AppSnackbar.show(context, 'Selling price is required', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final businessId =
          prefs.getString(AppConstants.kSelectedBusinessId) ?? '';

      // ── Subscription limit check ──────────────────────────
      final planCode = ref.read(subscriptionManagerProvider).planCode;
      final limitResult = await DailyLimitService.instance
          .checkLimit(planCode, 'products');
      if (!limitResult.allowed) {
        if (mounted) {
          await PlanLimitDialog.showDailyLimitReached(
            context,
            planCode: planCode,
            action: 'products',
            limit: limitResult.limit!,
            used: limitResult.used,
          );
        }
        return;
      }
      // ─────────────────────────────────────────────────────

      final productId = const Uuid().v4();
      final imageUrl = await _uploadImage(productId);
      final now = DateTime.now().toIso8601String();

      await Supabase.instance.client.from('products').insert({
        'id': productId,
        'business_id': businessId,
        'name': _nameCtrl.text.trim(),
        'sku': _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
        'barcode':
            _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        'unit': _selectedUnit,
        'cost_price': double.tryParse(_costCtrl.text) ?? 0,
        'selling_price': double.tryParse(_sellCtrl.text) ?? 0,
        'stock_quantity': double.tryParse(_stockCtrl.text) ?? 0,
        'min_stock_alert': double.tryParse(_minStockCtrl.text) ?? 5,
        'image_url': imageUrl,
        'is_active': true,
        'created_at': now,
        'updated_at': now,
      });

      // Increment daily counter on success
      await DailyLimitService.instance.increment(planCode, 'products');

      if (mounted) {
        ref.invalidate(inventoryProvider);
        AppSnackbar.show(context, 'Product added successfully!',
            isSuccess: true);
        context.pop();
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _imageFile != null
                            ? AppTheme.primaryColor
                            : AppTheme.lightBorder,
                        width: _imageFile != null ? 2 : 1),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AppTheme.primaryColor, size: 32),
                            SizedBox(height: 4),
                            Text('Add Image',
                                style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),

            _label(context, 'Product Name *'),
            AppTextField(
                controller: _nameCtrl,
                hint: 'e.g. Basmati Rice 1kg',
                prefixIcon: Icons.inventory_2_outlined),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _label(context, 'SKU'),
                      AppTextField(controller: _skuCtrl, hint: 'e.g. RICE001'),
                    ])),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _label(context, 'Barcode'),
                      AppTextField(
                          controller: _barcodeCtrl,
                          hint: 'Scan or enter',
                          keyboardType: TextInputType.number,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
                            onPressed: _scanBarcode,
                          )),
                    ])),
              ],
            ).animate(delay: 50.ms).fadeIn(),
            const SizedBox(height: 16),

            _label(context, 'Unit'),
            _UnitDropdown(
              selected: _selectedUnit,
              onChanged: (v) => setState(() => _selectedUnit = v),
            ).animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _label(context, 'Cost Price (Rs.) *'),
                      AppTextField(
                          controller: _costCtrl,
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.money_off_outlined),
                    ])),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _label(context, 'Selling Price (Rs.) *'),
                      AppTextField(
                          controller: _sellCtrl,
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.attach_money_rounded),
                    ])),
              ],
            ).animate(delay: 150.ms).fadeIn(),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _label(context, 'Opening Stock'),
                      AppTextField(
                          controller: _stockCtrl,
                          hint: '0',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.layers_outlined),
                    ])),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _label(context, 'Min Stock Alert'),
                      AppTextField(
                          controller: _minStockCtrl,
                          hint: '5',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.warning_amber_outlined),
                    ])),
              ],
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 32),

            AppButton(
              label: 'Add Product',
              onPressed: _save,
              isLoading: _isLoading,
              icon: Icons.add_box_rounded,
            ).animate(delay: 250.ms).fadeIn(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  final String? selected;
  final void Function(String?) onChanged;
  const _UnitDropdown({this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.lightBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('Select unit'),
          ),
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          items: ProductUnit.all.map((u) {
            return DropdownMenuItem(value: u, child: Text(u));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
