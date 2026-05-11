import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_button.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/core/widgets/app_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(() {
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
    return (res as List).map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
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
                  const Icon(Icons.wallet_outlined, size: 56, color: AppTheme.lightTextHint),
                  const SizedBox(height: 16),
                  Text('No expenses recorded', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Track your business expenses here.', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.addExpense),
                    icon: const Icon(Icons.add), label: const Text('Add Expense'),
                  ),
                ],
              ),
            );
          }

          // Monthly total
          final thisMonth = expenses.where((e) {
            final now = DateTime.now();
            return e.expenseDate.month == now.month && e.expenseDate.year == now.year;
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
                        gradient: LinearGradient(
                          colors: [AppTheme.errorColor.withValues(alpha: 0.1), AppTheme.warningColor.withValues(alpha: 0.05)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, color: AppTheme.errorColor),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('This Month\'s Expenses', style: Theme.of(context).textTheme.bodySmall),
                              Text('${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(thisMonth)}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: AppTheme.errorColor, fontWeight: FontWeight.w700)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: _ExpenseCard(expense: expense)
                            .animate(delay: Duration(milliseconds: i * 40))
                            .fadeIn().slideX(begin: 0.05, end: 0),
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
        label: const Text('Add Expense'),
        backgroundColor: AppTheme.errorColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  const _ExpenseCard({required this.expense});

  static const _categoryIcons = {
    'Rent': Icons.home_outlined,
    'Salary': Icons.people_outline,
    'Electricity': Icons.bolt_outlined,
    'Transport': Icons.local_shipping_outlined,
    'Purchase cost': Icons.shopping_cart_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[expense.categoryName] ?? Icons.receipt_outlined;
    return Card(
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.errorColor, size: 22),
        ),
        title: Text(expense.categoryName, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expense.note != null)
              Text(expense.note!, style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(DateFormat(AppConstants.dateFormat).format(expense.expenseDate),
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

  static const _categories = [
    'Rent', 'Salary', 'Electricity', 'Transport', 'Purchase cost',
    'Internet', 'Water', 'Office Supplies', 'Marketing', 'Maintenance', 'Other',
  ];

  @override
  void dispose() { _amountCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_amountCtrl.text.isEmpty) {
      AppSnackbar.show(context, 'Enter expense amount', isError: true); return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final businessId = prefs.getString(AppConstants.kSelectedBusinessId) ?? '';
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
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = cat == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.errorColor : AppTheme.errorColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? AppTheme.errorColor : AppTheme.lightBorder),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.lightTextSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 13,
                        )),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(),
            const SizedBox(height: 20),
            Text('Amount (Rs.) *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AppTextField(controller: _amountCtrl, hint: '0.00',
                keyboardType: TextInputType.number, prefixIcon: Icons.attach_money_rounded)
                .animate(delay: 50.ms).fadeIn(),
            const SizedBox(height: 16),
            Text('Date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: _date,
                  firstDate: DateTime(2020), lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.lightBorder), borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.lightTextSecondary),
                  const SizedBox(width: 10),
                  Text(DateFormat('dd MMM yyyy').format(_date), style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
            ).animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 16),
            Text('Note (Optional)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AppTextField(controller: _noteCtrl, hint: 'Details about this expense...', maxLines: 3)
                .animate(delay: 150.ms).fadeIn(),
            const SizedBox(height: 32),
            AppButton(label: 'Save Expense', onPressed: _save, isLoading: _isLoading,
                icon: Icons.save_outlined, color: AppTheme.errorColor)
                .animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
