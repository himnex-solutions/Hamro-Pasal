import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/services/daily_limit_service.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_button.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/core/widgets/app_text_field.dart';
import 'package:hamro_pasal/core/widgets/plan_limit_dialog.dart';
import 'package:hamro_pasal/features/parties/data/models/party_model.dart';
import 'package:hamro_pasal/features/inventory/data/models/product_model.dart';
import 'package:hamro_pasal/features/subscription/data/services/subscription_manager.dart';
import 'package:hamro_pasal/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  String _txType = AppConstants.txSale;
  String _paymentMethod = AppConstants.paymentCash;
  Party? _selectedParty;
  final List<_CartItem> _cart = [];
  final _amountCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _txDate = DateTime.now();
  bool _isLoading = false;
  bool _useItemizedMode = true;

  List<Party> _parties = [];
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _paidCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId) ?? '';
    final supabase = Supabase.instance.client;

    final partiesRes = await supabase
        .from('parties')
        .select()
        .eq('business_id', businessId)
        .order('name');
    final productsRes = await supabase
        .from('products')
        .select()
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('name');

    if (mounted) {
      setState(() {
        _parties = (partiesRes as List)
            .map((e) => Party.fromJson(e as Map<String, dynamic>))
            .toList();
        _products = (productsRes as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
  }

  double get _totalAmount {
    if (_useItemizedMode) {
      return _cart.fold(0, (s, i) => s + i.total);
    }
    return double.tryParse(_amountCtrl.text) ?? 0;
  }

  double get _paidAmount => double.tryParse(_paidCtrl.text) ?? _totalAmount;
  double get _dueAmount =>
      (_totalAmount - _paidAmount).clamp(0, double.infinity);

  Future<void> _save() async {
    if (_useItemizedMode && _cart.isEmpty) {
      AppSnackbar.show(context, 'Add at least one item', isError: true);
      return;
    }
    if (!_useItemizedMode && _amountCtrl.text.isEmpty) {
      AppSnackbar.show(context, 'Enter transaction amount', isError: true);
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
          .checkLimit(planCode, 'transactions');
      if (!limitResult.allowed) {
        if (mounted) {
          await PlanLimitDialog.showDailyLimitReached(
            context,
            planCode: planCode,
            action: 'transactions',
            limit: limitResult.limit!,
            used: limitResult.used,
          );
        }
        return;
      }
      // ─────────────────────────────────────────────────────

      final txId = const Uuid().v4();
      final now = DateTime.now().toIso8601String();

      await Supabase.instance.client.from('transactions').insert({
        'id': txId,
        'business_id': businessId,
        'type': _txType,
        'payment_method': _paymentMethod,
        'amount': _totalAmount,
        'paid_amount': _paidAmount,
        'due_amount': _dueAmount,
        'party_id': _selectedParty?.id,
        'party_name': _selectedParty?.name,
        'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        'transaction_date': _txDate.toIso8601String(),
        'created_at': now,
        'created_by': Supabase.instance.client.auth.currentUser?.id,
      });

      if (_useItemizedMode && _cart.isNotEmpty) {
        final items = _cart
            .map((item) => {
                  'id': const Uuid().v4(),
                  'transaction_id': txId,
                  'product_id': item.product.id,
                  'product_name': item.product.name,
                  'quantity': item.quantity,
                  'unit_price': _txType == AppConstants.txSale
                      ? item.product.sellingPrice
                      : item.product.costPrice,
                  'discount': item.discount,
                  'total_price': item.total,
                })
            .toList();
        await Supabase.instance.client.from('transaction_items').insert(items);

        // Update stock
        for (final cartItem in _cart) {
          final delta = _txType == AppConstants.txSale
              ? -cartItem.quantity
              : cartItem.quantity;
          await Supabase.instance.client.rpc('update_product_stock', params: {
            'p_product_id': cartItem.product.id,
            'p_delta': delta,
          });
        }
      }

      // Increment daily counter on success
      await DailyLimitService.instance.increment(planCode, 'transactions');

      if (mounted) {
        ref.invalidate(transactionsProvider);
        AppSnackbar.show(context, 'Transaction saved!', isSuccess: true);
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
      appBar: AppBar(title: const Text('New Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction type
            const _SectionLabel('Transaction Type'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TxTypeChip(
                      AppConstants.txSale,
                      'Sale',
                      Icons.trending_up_rounded,
                      AppTheme.successColor,
                      _txType,
                      (v) => setState(() => _txType = v)),
                  const SizedBox(width: 8),
                  _TxTypeChip(
                      AppConstants.txPurchase,
                      'Purchase',
                      Icons.shopping_bag_outlined,
                      AppTheme.infoColor,
                      _txType,
                      (v) => setState(() => _txType = v)),
                  const SizedBox(width: 8),
                  _TxTypeChip(
                      AppConstants.txExpense,
                      'Expense',
                      Icons.wallet_outlined,
                      AppTheme.errorColor,
                      _txType,
                      (v) => setState(() => _txType = v)),
                  const SizedBox(width: 8),
                  _TxTypeChip(
                      AppConstants.txIncome,
                      'Income',
                      Icons.savings_outlined,
                      AppTheme.accentColor,
                      _txType,
                      (v) => setState(() => _txType = v)),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 20),
            const _SectionLabel('Party'),
            _PartyDropdown(
              parties: _parties,
              selected: _selectedParty,
              onChanged: (p) => setState(() => _selectedParty = p),
            ).animate(delay: 50.ms).fadeIn(),

            const SizedBox(height: 20),
            Row(
              children: [
                const _SectionLabel('Items'),
                const Spacer(),
                Switch(
                  value: _useItemizedMode,
                  onChanged: (v) => setState(() => _useItemizedMode = v),
                ),
                Text('Itemized', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),

            if (_useItemizedMode) ...[
              _ProductSelector(
                products: _products,
                cart: _cart,
                txType: _txType,
                onCartChanged: () => setState(() {}),
              ).animate(delay: 100.ms).fadeIn(),
            ] else ...[
              const SizedBox(height: 8),
              AppTextField(
                controller: _amountCtrl,
                label: 'Amount (Rs.)',
                hint: '0.00',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money_rounded,
                onChanged: (_) => setState(() {}),
              ).animate(delay: 100.ms).fadeIn(),
            ],

            const SizedBox(height: 20),
            const _SectionLabel('Payment Method'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PayChip('Cash', AppConstants.paymentCash, _paymentMethod,
                      (v) => setState(() => _paymentMethod = v)),
                  const SizedBox(width: 8),
                  _PayChip('Bank', AppConstants.paymentBank, _paymentMethod,
                      (v) => setState(() => _paymentMethod = v)),
                  const SizedBox(width: 8),
                  _PayChip(
                      'Credit',
                      AppConstants.paymentCredit,
                      _paymentMethod,
                      (v) => setState(() {
                            _paymentMethod = v;
                            _paidCtrl.text = '0';
                          })),
                  const SizedBox(width: 8),
                  _PayChip(
                      'Partial',
                      AppConstants.paymentPartial,
                      _paymentMethod,
                      (v) => setState(() => _paymentMethod = v)),
                ],
              ),
            ).animate(delay: 150.ms).fadeIn(),

            if (_paymentMethod == AppConstants.paymentPartial) ...[
              const SizedBox(height: 16),
              AppTextField(
                controller: _paidCtrl,
                label: 'Amount Paid (Rs.)',
                hint: '0.00',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_outlined,
                onChanged: (_) => setState(() {}),
              ),
            ],

            const SizedBox(height: 20),
            const _SectionLabel('Date'),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _txDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _txDate = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.lightBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppTheme.lightTextSecondary),
                    const SizedBox(width: 10),
                    Text(DateFormat('dd MMM yyyy').format(_txDate),
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 16),
            AppTextField(
              controller: _noteCtrl,
              label: 'Note (Optional)',
              hint: 'Add a note...',
              maxLines: 2,
            ).animate(delay: 250.ms).fadeIn(),

            const SizedBox(height: 24),
            // Total summary
            if (_totalAmount > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    _SummaryRow('Total Amount',
                        '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(_totalAmount)}',
                        bold: true),
                    if (_paymentMethod != AppConstants.paymentCredit)
                      _SummaryRow('Paid Amount',
                          '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(_paidAmount)}'),
                    if (_dueAmount > 0)
                      _SummaryRow('Due Amount',
                          '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(_dueAmount)}',
                          color: AppTheme.warningColor),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn(),

            const SizedBox(height: 24),
            AppButton(
              label: 'Save Transaction',
              onPressed: _save,
              isLoading: _isLoading,
              icon: Icons.save_outlined,
            ).animate(delay: 350.ms).fadeIn(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _TxTypeChip extends StatelessWidget {
  final String value, label, selected;
  final IconData icon;
  final Color color;
  final void Function(String) onTap;
  const _TxTypeChip(
      this.value, this.label, this.icon, this.color, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _PayChip extends StatelessWidget {
  final String label, value, selected;
  final void Function(String) onTap;
  const _PayChip(this.label, this.value, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.lightBorder),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.lightTextSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            )),
      ),
    );
  }
}

class _PartyDropdown extends StatelessWidget {
  final List<Party> parties;
  final Party? selected;
  final void Function(Party?) onChanged;
  const _PartyDropdown(
      {required this.parties, this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.lightBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Party>(
          value: selected,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('Select party (optional)'),
          ),
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          items: [
            const DropdownMenuItem<Party>(value: null, child: Text('No party')),
            ...parties
                .map((p) => DropdownMenuItem(value: p, child: Text(p.name))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CartItem {
  final Product product;
  double quantity = 1;
  double discount = 0;
  _CartItem({required this.product});
  double get total => (product.sellingPrice - discount) * quantity;
}

class _ProductSelector extends StatefulWidget {
  final List<Product> products;
  final List<_CartItem> cart;
  final String txType;
  final VoidCallback onCartChanged;
  const _ProductSelector(
      {required this.products,
      required this.cart,
      required this.txType,
      required this.onCartChanged});

  @override
  State<_ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<_ProductSelector> {
  Product? _selectedProduct;

  void _addToCart() {
    if (_selectedProduct == null) return;
    final exists = widget.cart.any((i) => i.product.id == _selectedProduct!.id);
    if (!exists) {
      widget.cart.add(_CartItem(product: _selectedProduct!));
      widget.onCartChanged();
    }
    setState(() => _selectedProduct = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.lightBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Product>(
                    value: _selectedProduct,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Select product'),
                    ),
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    borderRadius: BorderRadius.circular(12),
                    items: widget.products
                        .map((p) =>
                            DropdownMenuItem(value: p, child: Text(p.name)))
                        .toList(),
                    onChanged: (p) => setState(() => _selectedProduct = p),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(52, 52),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
        if (widget.cart.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...widget.cart.asMap().entries.map((entry) {
            final item = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.name,
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                              '${AppConstants.currencySymbol} ${item.product.sellingPrice} each',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (item.quantity > 1) {
                              item.quantity--;
                              widget.onCartChanged();
                            }
                          },
                          icon:
                              const Icon(Icons.remove_circle_outline, size: 22),
                          padding: EdgeInsets.zero,
                        ),
                        SizedBox(
                          width: 32,
                          child: Text('${item.quantity.toInt()}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        IconButton(
                          onPressed: () {
                            item.quantity++;
                            widget.onCartChanged();
                          },
                          icon: const Icon(Icons.add_circle_outline,
                              size: 22, color: AppTheme.primaryColor),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          onPressed: () {
                            widget.cart.removeAt(entry.key);
                            widget.onCartChanged();
                          },
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: AppTheme.errorColor),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    Text(
                      '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(item.total)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? color;
  const _SummaryRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    color: color ?? AppTheme.primaryColor,
                  )),
        ],
      ),
    );
  }
}
