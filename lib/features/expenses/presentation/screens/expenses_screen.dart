import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/l10n/app_strings.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_button.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/core/widgets/app_text_field.dart';
import 'package:hamro_pasal/core/services/daily_limit_service.dart';
import 'package:hamro_pasal/core/widgets/plan_limit_dialog.dart';
import 'package:hamro_pasal/features/subscription/data/services/subscription_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

IconData getCategoryIcon(String categoryName) {
  switch (categoryName.toLowerCase()) {
    case 'rent':
      return Icons.home_outlined;
    case 'salary':
      return Icons.people_outline;
    case 'electricity':
      return Icons.bolt_outlined;
    case 'transport':
      return Icons.local_shipping_outlined;
    case 'purchase cost':
      return Icons.shopping_cart_outlined;
    case 'internet':
      return Icons.wifi_outlined;
    case 'water':
      return Icons.water_drop_outlined;
    case 'office supplies':
      return Icons.inventory_2_outlined;
    case 'marketing':
      return Icons.campaign_outlined;
    case 'maintenance':
      return Icons.build_outlined;
    case 'other':
      return Icons.more_horiz_outlined;
    default:
      return Icons.receipt_outlined;
  }
}

// Expense model
class Expense {
  final String id;
  final String businessId;
  final String categoryName;
  final double amount;
  final String? note;
  final DateTime expenseDate;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.businessId,
    required this.categoryName,
    required this.amount,
    this.note,
    required this.expenseDate,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        categoryName: json['category_name'] as String,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String?,
        expenseDate: DateTime.parse(json['expense_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

final expensesProvider =
    AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(() {
  return ExpensesNotifier();
});

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() => _fetch();

  Future<List<Expense>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
    if (businessId == null) return [];
    final res = await Supabase.instance.client
        .from('expenses')
        .select()
        .eq('business_id', businessId)
        .order('expense_date', ascending: false)
        .limit(100);
    return (res as List)
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expAsync = ref.watch(expensesProvider);

    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.expenses),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.addExpense),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: expAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (expenses) {
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wallet_outlined,
                      size: 56, color: AppTheme.lightTextHint),
                  const SizedBox(height: 16),
                  Text(context.l10n.noExpensesFound,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(context.l10n.trackExpensesHere,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }

          // Monthly total
          final thisMonth = expenses.where((e) {
            final now = DateTime.now();
            return e.expenseDate.month == now.month &&
                e.expenseDate.year == now.year;
          }).fold<double>(0, (s, e) => s + e.amount);

          return RefreshIndicator(
            onRefresh: () => ref.read(expensesProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppTheme.darkBorder
                                    : Colors.white,
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.errorColor.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.errorColor.withValues(alpha: 0.05),
                            AppTheme.warningColor.withValues(alpha: 0.05)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined,
                              color: AppTheme.errorColor),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${context.l10n.thisMonth} ${context.l10n.expenses}',
                                  style: Theme.of(context).textTheme.bodySmall),
                              Text(
                                  '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(thisMonth)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          color: AppTheme.errorColor,
                                          fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: -0.1, end: 0),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final expense = expenses[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: _ExpenseCard(expense: expense)
                            .animate(delay: Duration(milliseconds: i * 40))
                            .fadeIn()
                            .slideX(begin: 0.05, end: 0),
                      );
                    },
                    childCount: expenses.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addExpense),
        icon: const Icon(Icons.add),
        label: Text(l.addExpense),
        backgroundColor: AppTheme.errorColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    final icon = getCategoryIcon(expense.categoryName);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : Colors.white,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardTheme.color ?? Colors.white,
            (Theme.of(context).cardTheme.color ?? Colors.white)
                .withValues(alpha: 0.6),
          ],
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.errorColor, size: 22),
        ),
        title: Text(expense.categoryName,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expense.note != null)
              Text(expense.note!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            Text(
                DateFormat(AppConstants.dateFormat).format(expense.expenseDate),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        isThreeLine: expense.note != null,
        trailing: Text(
          '-${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(expense.amount)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.errorColor, fontWeight: FontWeight.w700),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
    );
  }
}

// ── Add Expense Screen ────────────────────────────────────────────────────────

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});
  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _category = 'Rent';
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  static const _defaultCategories = [
    'Rent',
    'Salary',
    'Electricity',
    'Transport',
    'Purchase cost',
    'Internet',
    'Water',
    'Office Supplies',
    'Marketing',
    'Maintenance',
    'Other',
  ];
  List<String> _customCategories = [];

  List<String> get _allCategories =>
      [..._defaultCategories, ..._customCategories];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId) ?? '';
    final saved =
        prefs.getStringList('custom_exp_categories_$businessId') ?? [];
    setState(() {
      _customCategories = saved;
    });
  }

  Future<void> _addCustomCategory(String name) async {
    if (name.trim().isEmpty || _allCategories.contains(name.trim())) return;
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId) ?? '';
    setState(() {
      _customCategories.add(name.trim());
      _category = name.trim();
    });
    await prefs.setStringList(
        'custom_exp_categories_$businessId', _customCategories);
  }

  Future<void> _removeCustomCategory(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId) ?? '';
    setState(() {
      _customCategories.remove(name);
      if (_category == name) _category = _defaultCategories.first;
    });
    await prefs.setStringList(
        'custom_exp_categories_$businessId', _customCategories);
  }

  void _showManageCategoriesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManageCategoriesSheet(
        customCategories: _customCategories,
        onAdd: _addCustomCategory,
        onRemove: _removeCustomCategory,
      ),
    );
  }

  void _showCategorySelectorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategorySelectorSheet(
        allCategories: _allCategories,
        selectedCategory: _category,
        onSelected: (cat) {
          setState(() => _category = cat);
          Navigator.pop(ctx);
        },
        onManage: () {
          Navigator.pop(ctx);
          _showManageCategoriesSheet();
        },
      ),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_amountCtrl.text.isEmpty) {
      AppSnackbar.show(context, 'Enter expense amount', isError: true);
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
          .checkLimit(planCode, 'expenses');
      if (!limitResult.allowed) {
        if (mounted) {
          await PlanLimitDialog.showDailyLimitReached(
            context,
            planCode: planCode,
            action: 'expenses',
            limit: limitResult.limit!,
            used: limitResult.used,
          );
        }
        return;
      }
      // ─────────────────────────────────────────────────────

      final now = DateTime.now().toIso8601String();
      await Supabase.instance.client.from('expenses').insert({
        'id': const Uuid().v4(),
        'business_id': businessId,
        'category_name': _category,
        'amount': double.tryParse(_amountCtrl.text) ?? 0,
        'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        'expense_date': _date.toIso8601String(),
        'created_at': now,
      });
      // Increment daily counter on success
      await DailyLimitService.instance.increment(planCode, 'expenses');

      if (mounted) {
        ref.invalidate(expensesProvider);
        AppSnackbar.show(context, 'Expense added!', isSuccess: true);
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
      appBar: AppBar(title: Text(context.l10n.addExpense)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.expenseCategory,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showCategorySelectorSheet,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  border: Border.all(
                      color: AppTheme.lightBorder.withValues(alpha: 0.5),
                      width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(getCategoryIcon(_category),
                          color: AppTheme.errorColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(_category,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.lightTextHint),
                  ],
                ),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 20),
            Text('${context.l10n.amount} (Rs.) *',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AppTextField(
                    controller: _amountCtrl,
                    hint: '0.00',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money_rounded)
                .animate(delay: 50.ms)
                .fadeIn(),
            const SizedBox(height: 16),
            Text(context.l10n.date,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.lightBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppTheme.lightTextSecondary),
                  const SizedBox(width: 10),
                  Text(DateFormat('dd MMM yyyy').format(_date),
                      style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
            ).animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 16),
            Text('${context.l10n.notes} (${context.l10n.optional})',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AppTextField(
                    controller: _noteCtrl,
                    hint: 'Details about this expense...',
                    maxLines: 3)
                .animate(delay: 150.ms)
                .fadeIn(),
            const SizedBox(height: 32),
            AppButton(
                    label: context.l10n.save,
                    onPressed: _save,
                    isLoading: _isLoading,
                    icon: Icons.save_outlined,
                    color: AppTheme.errorColor)
                .animate(delay: 200.ms)
                .fadeIn(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ManageCategoriesSheet extends StatefulWidget {
  final List<String> customCategories;
  final Function(String) onAdd;
  final Function(String) onRemove;

  const _ManageCategoriesSheet({
    required this.customCategories,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_ManageCategoriesSheet> createState() => _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState extends State<_ManageCategoriesSheet> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.only(
          bottom: bottomInset + 16, top: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : Colors.white,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Manage Custom Categories',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _ctrl,
                  hint: 'New Category Name',
                  prefixIcon: Icons.category_outlined,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.errorColor,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  widget.onAdd(_ctrl.text);
                  _ctrl.clear();
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.customCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No custom categories yet.',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.customCategories.map((c) {
                return Chip(
                  label: Text(c),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => widget.onRemove(c),
                  backgroundColor: Theme.of(context).cardTheme.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.lightBorder),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _CategorySelectorSheet extends StatelessWidget {
  final List<String> allCategories;
  final String selectedCategory;
  final Function(String) onSelected;
  final VoidCallback onManage;

  const _CategorySelectorSheet({
    required this.allCategories,
    required this.selectedCategory,
    required this.onSelected,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Category',
                    style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('Manage'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: allCategories.length,
              itemBuilder: (ctx, i) {
                final cat = allCategories[i];
                final isSelected = cat == selectedCategory;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.errorColor
                          : AppTheme.errorColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      getCategoryIcon(cat),
                      color: isSelected ? Colors.white : AppTheme.errorColor,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    cat,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.errorColor
                          : AppTheme.lightTextPrimary,
                      fontSize: 16,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: AppTheme.errorColor)
                      : null,
                  onTap: () => onSelected(cat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
