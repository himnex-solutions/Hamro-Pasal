import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/product.dart';

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, AsyncValue<List<Product>>>((ref) {
  return InventoryNotifier()..load();
});

class InventoryNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  InventoryNotifier() : super(const AsyncValue.loading());

  Future<void> load() async {
    try {
      final userId = SupabaseService.instance.currentUserId!;
      final data = await SupabaseService.instance.getProducts(userId);
      state = AsyncValue.data(data.map(Product.fromJson).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String id) async {
    await SupabaseService.instance.deleteProduct(id);
    await load();
  }
}

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _query = '';
  String _filter = 'All';
  final _filters = ['All', 'Low Stock', 'Out of Stock'];

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              await context.push('/inventory/add');
              ref.read(inventoryProvider.notifier).load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(f),
                                selected: _filter == f,
                                onSelected: (_) => setState(() => _filter = f),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: inventoryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (products) {
                final q = _query.trim().toLowerCase();
                var filtered = products.where((p) {
                  final matchQ = q.isEmpty || p.name.toLowerCase().contains(q);
                  final matchF = _filter == 'All' ||
                      (_filter == 'Low Stock' && p.isLowStock) ||
                      (_filter == 'Out of Stock' && p.stockQuantity == 0);
                  return matchQ && matchF;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text('No products found',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/inventory/add'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(inventoryProvider.notifier).load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ProductCard(
                      product: filtered[i],
                      onEdit: () async {
                        await context.push('/inventory/edit',
                            extra: filtered[i].toJson());
                        ref.read(inventoryProvider.notifier).load();
                      },
                      onDelete: () =>
                          _confirmDelete(context, ref, filtered[i].id!),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/inventory/add');
          ref.read(inventoryProvider.notifier).load();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(inventoryProvider.notifier).delete(id);
    }
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard(
      {required this.product,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final stockColor = product.stockQuantity == 0
        ? AppColors.error
        : product.isLowStock
            ? AppColors.warning
            : AppColors.success;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: product.isLowStock ? AppColors.warningLight : AppColors.border,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Stock indicator
          Container(
            width: 8,
            height: 60,
            decoration: BoxDecoration(
              color: stockColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Tag(
                        'Sell: NPR ${product.sellingPrice.toStringAsFixed(0)}',
                        AppColors.primary),
                    const SizedBox(width: 6),
                    _Tag('Cost: NPR ${product.costPrice.toStringAsFixed(0)}',
                        AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.inventory_rounded, size: 14, color: stockColor),
                    const SizedBox(width: 4),
                    Text('Stock: ${product.stockQuantity}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: stockColor)),
                    if (product.category != null) ...[
                      const SizedBox(width: 8),
                      const Text('•',
                          style: TextStyle(color: AppColors.textHint)),
                      const SizedBox(width: 8),
                      Text(product.category!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') {
                onEdit();
              }
              if (v == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ])),
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_rounded,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                  ])),
            ],
            child: const Icon(Icons.more_vert_rounded,
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
