import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_saoji/core/constants/app_constants.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/features/inventory/data/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final productDetailProvider =
    FutureProvider.family<Product, String>((ref, id) async {
  final res = await Supabase.instance.client
      .from('products')
      .select()
      .eq('id', id)
      .single();
  return Product.fromJson(res);
});

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (product) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: product.imageUrl != null
                    ? Image.network(product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _Placeholder())
                    : _Placeholder(),
              ),
              actions: [
                IconButton(
                    onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(product.name,
                                style:
                                    Theme.of(context).textTheme.headlineSmall)),
                        if (product.isLowStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.warningColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppTheme.warningColor
                                      .withValues(alpha: 0.3)),
                            ),
                            child: const Text('Low Stock',
                                style: TextStyle(
                                    color: AppTheme.warningColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                      ],
                    ),
                    if (product.sku != null)
                      Text('SKU: ${product.sku}',
                          style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                            child: _InfoCard(
                                'Selling Price',
                                '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(product.sellingPrice)}',
                                AppTheme.successColor,
                                Icons.sell_outlined)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _InfoCard(
                                'Cost Price',
                                '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(product.costPrice)}',
                                AppTheme.infoColor,
                                Icons.money_off_outlined)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _InfoCard(
                                'Stock',
                                '${product.stockQuantity} ${product.unit ?? ''}',
                                product.isLowStock
                                    ? AppTheme.warningColor
                                    : AppTheme.primaryColor,
                                Icons.layers_outlined)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _InfoCard(
                                'Profit Margin',
                                '${product.profitMargin.toStringAsFixed(1)}%',
                                AppTheme.accentColor,
                                Icons.trending_up_rounded)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Details',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _DetailRow('Unit', product.unit ?? '-'),
                            _DetailRow(
                                'Min Stock Alert', '${product.minStockAlert}'),
                            _DetailRow('Inventory Value',
                                '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(product.inventoryValue)}'),
                            _DetailRow('Status',
                                product.isActive ? 'Active' : 'Inactive'),
                            _DetailRow(
                                'Added',
                                DateFormat(AppConstants.dateFormat)
                                    .format(product.createdAt)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                            child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.tune),
                          label: const Text('Adjust Stock'),
                        )),
                        const SizedBox(width: 12),
                        Expanded(
                            child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.history),
                          label: const Text('Movement'),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.inventory_2_outlined,
            size: 80, color: AppTheme.primaryColor),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title, value;
  final Color color;
  final IconData icon;
  const _InfoCard(this.title, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w700)),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
