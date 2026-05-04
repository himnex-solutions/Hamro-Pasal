import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/supplier.dart';

final _fmt = NumberFormat('#,##0.00', 'en_US');

final suppliersProvider =
    StateNotifierProvider<SuppliersNotifier, AsyncValue<List<Supplier>>>((ref) {
  return SuppliersNotifier()..load();
});

class SuppliersNotifier extends StateNotifier<AsyncValue<List<Supplier>>> {
  SuppliersNotifier() : super(const AsyncValue.loading());

  Future<void> load() async {
    try {
      final userId = SupabaseService.instance.currentUserId!;
      final data = await SupabaseService.instance.getSuppliers(userId);
      state = AsyncValue.data(data.map(Supplier.fromJson).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class SupplierScreen extends ConsumerWidget {
  const SupplierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddSupplier(context, ref),
          ),
        ],
      ),
      body: suppliersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text('No suppliers added',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSupplier(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Supplier'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: suppliers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final s = suppliers[i];
              return ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border)),
                tileColor: Theme.of(context).cardColor,
                leading: CircleAvatar(
                  backgroundColor: AppColors.suppliersColor.withOpacity(0.12),
                  child: Text(s.name[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.suppliersColor,
                          fontWeight: FontWeight.w700)),
                ),
                title: Text(s.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(s.phone ?? 'No phone',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                trailing: s.totalDue > 0
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Due',
                              style: TextStyle(
                                  color: AppColors.error, fontSize: 10)),
                          Text('NPR ${_fmt.format(s.totalDue)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700)),
                        ],
                      )
                    : const Icon(Icons.check_circle_rounded,
                        color: AppColors.success),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSupplier(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _showAddSupplier(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Supplier',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              AppTextField(
                  controller: nameCtrl,
                  label: 'Supplier Name *',
                  hint: 'e.g. Anil Traders',
                  prefixIcon: Icons.business_rounded),
              const SizedBox(height: 12),
              AppTextField(
                  controller: phoneCtrl,
                  label: 'Phone',
                  hint: '98XXXXXXXX',
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              AppTextField(
                  controller: addrCtrl,
                  label: 'Address',
                  hint: 'Optional',
                  prefixIcon: Icons.location_on_outlined),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  await SupabaseService.instance.insertSupplier({
                    'user_id': SupabaseService.instance.currentUserId!,
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    'address': addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                    'total_due': 0.0,
                  });
                  await ref.read(suppliersProvider.notifier).load();
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
                child: const Text('Add Supplier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
