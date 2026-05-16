import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/l10n/app_strings.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/features/inventory/data/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, List<Product>>(() {
  return InventoryNotifier();
});

class InventoryNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() => _fetch();

  Future<List<Product>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
    if (businessId == null) return [];
    final res = await Supabase.instance.client
        .from('products')
        .select()
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('name');
    return (res as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _filter = 'all'; // all, low_stock

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);

    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.inventory),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.addProduct),
            icon: const Icon(Icons.add_box_outlined),
            tooltip: l.addProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: l.searchProducts,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              },
                              icon: const Icon(Icons.clear, size: 18))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilterChip(
                  label: Text(l.lowStock),
                  selected: _filter == 'low_stock',
                  onSelected: (v) =>
                      setState(() => _filter = v ? 'low_stock' : 'all'),
                  selectedColor: AppTheme.warningColor.withValues(alpha: 0.15),
                  checkmarkColor: AppTheme.warningColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Inventory stats
          inventoryAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (products) => _InventoryStats(products: products),
          ),

          Expanded(
            child: inventoryAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (products) {
                var filtered = products.where((p) {
                  final matchSearch = _search.isEmpty ||
                      p.name.toLowerCase().contains(_search.toLowerCase()) ||
                      (p.sku?.toLowerCase().contains(_search.toLowerCase()) ?? false);
                  final matchFilter = _filter == 'all' || p.isLowStock;
                  return matchSearch && matchFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 56,
                            color: AppTheme.lightTextHint),
                        const SizedBox(height: 16),
                        Text(_filter == 'low_stock'
                            ? 'No low stock items'
                            : l.noProductsFound,
                            style: Theme.of(context).textTheme.titleMedium),
                        if (_filter == 'all') ...[
                          const SizedBox(height: 8),
                          Text('Add your first product to start tracking inventory.',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(inventoryProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      return _ProductCard(product: filtered[i])
                          .animate(
                              delay: Duration(milliseconds: i * 40))
                          .fadeIn()
                          .slideX(begin: 0.05, end: 0);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addProduct),
        icon: const Icon(Icons.add),
        label: Text(l.addProduct),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _InventoryStats extends StatelessWidget {
  final List<Product> products;
  const _InventoryStats({required this.products});

  @override
  Widget build(BuildContext context) {
    final totalValue = products.fold<double>(0, (s, p) => s + p.inventoryValue);
    final lowStockCount = products.where((p) => p.isLowStock).length;
    final formatted = NumberFormat('#,##,##0').format(totalValue);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _StatChip('${products.length} ${context.l10n.products}', Icons.inventory_2_outlined, AppTheme.primaryColor),
          const SizedBox(width: 8),
          _StatChip('Rs. $formatted', Icons.monetization_on_outlined, AppTheme.successColor),
          const SizedBox(width: 8),
          if (lowStockCount > 0)
            _StatChip('$lowStockCount ${context.l10n.lowStock}', Icons.warning_amber_outlined, AppTheme.warningColor),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatChip(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/home/inventory/${product.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Product image placeholder
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.lightBorder),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(product.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_not_supported_outlined)),
                      )
                    : const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(product.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (product.isLowStock)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Low Stock',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.warningColor,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                      ],
                    ),
                    if (product.sku != null)
                      Text('SKU: ${product.sku}',
                          style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${context.l10n.stock}: ',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          '${product.stockQuantity.toStringAsFixed(product.stockQuantity % 1 == 0 ? 0 : 2)} ${product.unit ?? ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: product.isLowStock
                                    ? AppTheme.warningColor
                                    : AppTheme.successColor,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(product.sellingPrice)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Cost: ${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(product.costPrice)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
