import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/customer.dart';

final _fmt = NumberFormat('#,##0.00', 'en_US');

final customersProvider =
    StateNotifierProvider<CustomersNotifier, AsyncValue<List<Customer>>>((ref) {
  return CustomersNotifier()..load();
});

class CustomersNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  CustomersNotifier() : super(const AsyncValue.loading());

  Future<void> load() async {
    try {
      final userId = SupabaseService.instance.currentUserId!;
      final data = await SupabaseService.instance.getCustomers(userId);
      state = AsyncValue.data(data.map(Customer.fromJson).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});
  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showAddCustomer(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (customers) {
                final q = _query.trim().toLowerCase();
                final filtered = customers.where((c) {
                  if (q.isEmpty) {
                    return true;
                  }
                  final matchName = c.name.toLowerCase().contains(q);
                  final matchPhone = (c.phone ?? '').toLowerCase().contains(q);
                  return matchName || matchPhone;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text('No customers found',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddCustomer(context, ref),
                          icon: const Icon(Icons.person_add_rounded),
                          label: const Text('Add Customer'),
                        ),
                      ],
                    ),
                  );
                }

                // Total due summary
                final totalDue = filtered.fold<double>(
                    0, (sum, c) => sum + c.totalDue);

                return Column(
                  children: [
                    if (totalDue > 0)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.account_balance_wallet_rounded,
                              color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text(
                              'Total Udhaar: NPR ${_fmt.format(totalDue)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: AppColors.warning)),
                        ]),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref.read(customersProvider.notifier).load(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _CustomerCard(
                            customer: filtered[i],
                            onTap: () => context.push('/customers/detail',
                                extra: filtered[i].id),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomer(context, ref),
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }

  Future<void> _showAddCustomer(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Customer',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 20),
              AppTextField(controller: nameCtrl, label: 'Name *',
                  hint: 'Customer name', prefixIcon: Icons.person_outline_rounded),
              const SizedBox(height: 12),
              AppTextField(controller: phoneCtrl, label: 'Phone',
                  hint: '98XXXXXXXX', prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              AppTextField(controller: addrCtrl, label: 'Address',
                  hint: 'Optional', prefixIcon: Icons.location_on_outlined),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    return;
                  }
                  final data = {
                    'user_id': SupabaseService.instance.currentUserId!,
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    'address': addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                    'total_due': 0.0,
                  };
                  await SupabaseService.instance.insertCustomer(data);
                  await ref.read(customersProvider.notifier).load();
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
                child: const Text('Add Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border)),
      tileColor: Theme.of(context).cardColor,
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: Text(
          customer.name[0].toUpperCase(),
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(customer.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(customer.phone ?? 'No phone',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
      trailing: customer.totalDue > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('NPR ${_fmt.format(customer.totalDue)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.warning, fontWeight: FontWeight.w700)),
            )
          : const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
    );
  }
}
