import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/expense.dart';

final _fmt = NumberFormat('#,##0.00', 'en_US');

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  return ExpensesNotifier()..load();
});

class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  ExpensesNotifier() : super(const AsyncValue.loading());

  Future<void> load() async {
    try {
      final userId = SupabaseService.instance.currentUserId!;
      final data = await SupabaseService.instance.getExpenses(userId);
      state = AsyncValue.data(data.map(Expense.fromJson).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String id) async {
    await SupabaseService.instance.deleteExpense(id);
    await load();
  }
}

class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddExpense(context, ref),
          ),
        ],
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (expenses) {
          final total = expenses.fold<double>(0, (s, e) => s + e.amount);

          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text('No expenses recorded',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddExpense(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Expense'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Icon(Icons.receipt_long_rounded, color: AppColors.error),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Total Expenses',
                        style: TextStyle(color: AppColors.error, fontSize: 12)),
                    Text('NPR ${_fmt.format(total)}',
                        style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 20)),
                  ]),
                ]),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(expensesProvider.notifier).load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border)),
                      tileColor: Theme.of(context).cardColor,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.errorLight,
                        child: const Icon(Icons.money_off_rounded,
                            color: AppColors.error, size: 20),
                      ),
                      title: Text(expenses[i].title),
                      subtitle: Text('${expenses[i].category} • ${expenses[i].adDate}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('NPR ${_fmt.format(expenses[i].amount)}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700)),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded,
                                color: AppColors.error, size: 20),
                            onPressed: () => ref
                                .read(expensesProvider.notifier)
                                .delete(expenses[i].id!),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpense(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _showAddExpense(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedCategory = Expense.categories.first;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Expense',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                AppTextField(
                    controller: titleCtrl,
                    label: 'Title *',
                    hint: 'e.g. Monthly Rent',
                    prefixIcon: Icons.label_outline_rounded),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: Expense.categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                AppTextField(
                    controller: amountCtrl,
                    label: 'Amount (NPR) *',
                    hint: '0.00',
                    prefixIcon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text);
                    if (titleCtrl.text.isEmpty || amount == null) return;
                    final today = DateTime.now();
                    final dateStr =
                        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                    await SupabaseService.instance.insertExpense({
                      'user_id': SupabaseService.instance.currentUserId!,
                      'title': titleCtrl.text.trim(),
                      'category': selectedCategory,
                      'amount': amount,
                      'ad_date': dateStr,
                    });
                    await ref.read(expensesProvider.notifier).load();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Add Expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
