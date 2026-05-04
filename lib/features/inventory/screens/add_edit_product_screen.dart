import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../models/product.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? product;
  const AddEditProductScreen({super.key, required this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState
    extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _sellCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _lowCtrl;
  late final TextEditingController _categoryCtrl;
  bool _loading = false;
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?['name'] ?? '');
    _costCtrl = TextEditingController(text: p != null ? '${p['cost_price']}' : '');
    _sellCtrl = TextEditingController(text: p != null ? '${p['selling_price']}' : '');
    _stockCtrl = TextEditingController(text: p != null ? '${p['stock_quantity']}' : '');
    _lowCtrl = TextEditingController(text: p != null ? '${p['low_stock_limit'] ?? 5}' : '5');
    _categoryCtrl = TextEditingController(text: p?['category'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _costCtrl.dispose(); _sellCtrl.dispose();
    _stockCtrl.dispose(); _lowCtrl.dispose(); _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'user_id': SupabaseService.instance.currentUserId!,
        'name': _nameCtrl.text.trim(),
        'category': _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
        'cost_price': double.parse(_costCtrl.text),
        'selling_price': double.parse(_sellCtrl.text),
        'stock_quantity': int.parse(_stockCtrl.text),
        'low_stock_limit': int.parse(_lowCtrl.text),
      };
      if (_isEditing) {
        await SupabaseService.instance.updateProduct(widget.product!['id'] as String, data);
      } else {
        await SupabaseService.instance.insertProduct(data);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(children: [
                AppTextField(controller: _nameCtrl, label: 'Product Name *',
                    hint: 'e.g. Wai Wai Noodles', prefixIcon: Icons.shopping_bag_outlined,
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 14),
                AppTextField(controller: _categoryCtrl, label: 'Category',
                    hint: 'e.g. Food', prefixIcon: Icons.category_outlined),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: AppTextField(controller: _costCtrl, label: 'Cost Price (NPR) *',
                      hint: '0.00', prefixIcon: Icons.money_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => double.tryParse(v!) == null ? 'Invalid' : null)),
                  const SizedBox(width: 14),
                  Expanded(child: AppTextField(controller: _sellCtrl, label: 'Selling Price (NPR) *',
                      hint: '0.00', prefixIcon: Icons.sell_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => double.tryParse(v!) == null ? 'Invalid' : null)),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: AppTextField(controller: _stockCtrl, label: 'Stock Qty *',
                      hint: '0', prefixIcon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => int.tryParse(v!) == null ? 'Invalid' : null)),
                  const SizedBox(width: 14),
                  Expanded(child: AppTextField(controller: _lowCtrl, label: 'Low Stock Alert',
                      hint: '5', prefixIcon: Icons.warning_amber_outlined,
                      keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 28),
                AppButton(
                  label: _isEditing ? 'Update Product' : 'Add Product',
                  onPressed: _save,
                  icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
