import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/inventory/models/product.dart';
import '../models/sale.dart';

final _uuid = Uuid();
final _fmt = NumberFormat('#,##0.00', 'en_US');

class POSState {
  final List<SaleItem> items;
  final double discount;
  final double taxRate;
  final PaymentMethod paymentMethod;
  final String? customerId;
  final bool isLoading;

  const POSState({
    this.items = const [],
    this.discount = 0.0,
    this.taxRate = 0.0,
    this.paymentMethod = PaymentMethod.cash,
    this.customerId,
    this.isLoading = false,
  });

  double get subtotal => items.fold(0, (s, i) => s + i.total);
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount - discount;

  POSState copyWith({
    List<SaleItem>? items,
    double? discount,
    double? taxRate,
    PaymentMethod? paymentMethod,
    String? customerId,
    bool? isLoading,
  }) =>
      POSState(
        items: items ?? this.items,
        discount: discount ?? this.discount,
        taxRate: taxRate ?? this.taxRate,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        customerId: customerId ?? this.customerId,
        isLoading: isLoading ?? this.isLoading,
      );
}

final posProvider =
    StateNotifierProvider<POSNotifier, POSState>((ref) => POSNotifier());

class POSNotifier extends StateNotifier<POSState> {
  POSNotifier() : super(const POSState());

  void addProduct(Product product) {
    final idx = state.items.indexWhere((i) => i.productId == product.id);
    if (idx >= 0) {
      final items = [...state.items];
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
      state = state.copyWith(items: items);
    } else {
      state = state.copyWith(
          items: [...state.items, SaleItem.fromProduct(product, 1)]);
    }
  }

  void updateQuantity(String productId, int qty) {
    if (qty <= 0) {
      removeItem(productId);
      return;
    }
    state = state.copyWith(
        items: state.items
            .map((i) => i.productId == productId ? i.copyWith(quantity: qty) : i)
            .toList());
  }

  void removeItem(String productId) => state = state.copyWith(
      items: state.items.where((i) => i.productId != productId).toList());

  void setDiscount(double v) => state = state.copyWith(discount: v);
  void setTax(double v) => state = state.copyWith(taxRate: v);
  void setPaymentMethod(PaymentMethod m) =>
      state = state.copyWith(paymentMethod: m);
  void clearCart() => state = const POSState();

  Future<Map<String, dynamic>?> checkout() async {
    if (state.items.isEmpty) return null;
    state = state.copyWith(isLoading: true);
    try {
      final userId = SupabaseService.instance.currentUserId!;
      final billNo =
          'HP-${DateFormat('yyyyMMdd').format(DateTime.now())}-${_uuid.v4().substring(0, 6).toUpperCase()}';
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final saleData = {
        'user_id': userId,
        'customer_id': state.customerId,
        'bill_number': billNo,
        'subtotal': state.subtotal,
        'discount': state.discount,
        'tax': state.taxAmount,
        'total': state.total,
        'payment_status': 'paid',
        'payment_method': state.paymentMethod.name,
        'ad_date': today,
      };

      final itemsData = state.items
          .map((i) => {
                'product_id': i.productId,
                'product_name': i.productName,
                'quantity': i.quantity,
                'price': i.price,
                'total': i.total,
              })
          .toList();

      final sale = await SupabaseService.instance.insertSale(saleData, itemsData);
      for (final item in state.items) {
        await SupabaseService.instance.decrementStock(item.productId, item.quantity);
      }
      final result = {...sale, 'sale_items': itemsData};
      clearCart();
      return result;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final productsForPOSProvider = FutureProvider<List<Product>>((ref) async {
  final userId = SupabaseService.instance.currentUserId!;
  final data = await SupabaseService.instance.getProducts(userId);
  return data.map(Product.fromJson).toList();
});

class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});
  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsForPOSProvider);
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Billing'),
        leading: IconButton(
            icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.delete_sweep_rounded, size: 18),
            label: const Text('Clear'),
            onPressed: () => ref.read(posProvider.notifier).clearCart(),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
      body: isWide
          ? Row(children: [
              Expanded(
                  flex: 3,
                  child: _ProductPanel(
                      query: _query,
                      searchCtrl: _searchCtrl,
                      onQueryChanged: (v) => setState(() => _query = v),
                      productsAsync: productsAsync)),
              const VerticalDivider(width: 1),
              const Expanded(flex: 2, child: _CartPanel()),
            ])
          : Column(children: [
              Expanded(
                  child: _ProductPanel(
                      query: _query,
                      searchCtrl: _searchCtrl,
                      onQueryChanged: (v) => setState(() => _query = v),
                      productsAsync: productsAsync)),
              const _CartSummaryBar(),
            ]),
    );
  }
}

class _ProductPanel extends ConsumerWidget {
  final String query;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onQueryChanged;
  final AsyncValue<List<Product>> productsAsync;

  const _ProductPanel(
      {required this.query,
      required this.searchCtrl,
      required this.onQueryChanged,
      required this.productsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: searchCtrl,
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search product...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchCtrl.clear();
                      onQueryChanged('');
                    })
                : null,
          ),
        ),
      ),
      Expanded(
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (products) {
            final filtered = query.isEmpty
                ? products
                : products
                    .where((p) =>
                        p.name.toLowerCase().contains(query.toLowerCase()))
                    .toList();
            if (filtered.isEmpty) {
              return const Center(
                  child: Text('No products found',
                      style: TextStyle(color: AppColors.textSecondary)));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _ProductTile(product: filtered[i]),
            );
          },
        ),
      ),
    ]);
  }
}

class _ProductTile extends ConsumerWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inCart =
        ref.watch(posProvider).items.any((i) => i.productId == product.id);
    return GestureDetector(
      onTap: () => ref.read(posProvider.notifier).addProduct(product),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: inCart ? AppColors.primaryLight : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: inCart ? AppColors.primary : AppColors.border,
              width: inCart ? 2 : 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(product.name,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('NPR ${_fmt.format(product.sellingPrice)}',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                Text('${product.stockQuantity}',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartPanel extends ConsumerWidget {
  const _CartPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(posProvider);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          const Icon(Icons.shopping_cart_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Cart (${posState.items.length})',
              style: Theme.of(context).textTheme.titleMedium),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: posState.items.isEmpty
            ? const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 48, color: AppColors.textHint),
                SizedBox(height: 8),
                Text('Cart is empty',
                    style: TextStyle(color: AppColors.textSecondary)),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: posState.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _CartItemTile(item: posState.items[i]),
              ),
      ),
      if (posState.items.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border))),
          child: Column(children: [
            _Row('Subtotal', 'NPR ${_fmt.format(posState.subtotal)}'),
            if (posState.discount > 0)
              _Row('Discount', '- NPR ${_fmt.format(posState.discount)}',
                  color: AppColors.error),
            const Divider(height: 16),
            _Row('Total', 'NPR ${_fmt.format(posState.total)}', bold: true),
            const SizedBox(height: 12),
            _CheckoutButton(),
          ]),
        ),
    ]);
  }
}

class _CartItemTile extends ConsumerWidget {
  final SaleItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(posProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.productName,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text('NPR ${_fmt.format(item.price)}',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
        _QtyBtn(Icons.remove,
            () => n.updateQuantity(item.productId, item.quantity - 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('${item.quantity}',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        _QtyBtn(
            Icons.add, () => n.updateQuantity(item.productId, item.quantity + 1)),
        const SizedBox(width: 8),
        Text('NPR ${_fmt.format(item.total)}',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _Row(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                    color: color)),
            Text(value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    color: color ?? (bold ? AppColors.primary : null))),
          ],
        ),
      );
}

class _CheckoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(posProvider);
    return ElevatedButton.icon(
      onPressed: posState.isLoading
          ? null
          : () async {
              final sale = await ref.read(posProvider.notifier).checkout();
              if (!context.mounted || sale == null) return;
              context.push(AppConstants.routeReceipt, extra: sale);
            },
      icon: posState.isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.check_circle_rounded),
      label: Text(posState.isLoading
          ? 'Processing...'
          : 'Checkout – NPR ${_fmt.format(posState.total)}'),
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          minimumSize: const Size(double.infinity, 52)),
    );
  }
}

class _CartSummaryBar extends ConsumerWidget {
  const _CartSummaryBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(posProvider);
    if (posState.items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('${posState.items.length} items',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('NPR ${_fmt.format(posState.total)}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        ]),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () async {
            final sale = await ref.read(posProvider.notifier).checkout();
            if (!context.mounted || sale == null) return;
            context.push(AppConstants.routeReceipt, extra: sale);
          },
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Checkout'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, foregroundColor: AppColors.primary),
        ),
      ]),
    );
  }
}
