import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class BankAccount {
  final String id, name, type;
  final double balance;
  const BankAccount(
      {required this.id,
      required this.name,
      required this.type,
      required this.balance});
  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      balance: (json['balance'] as num).toDouble());
}

final accountsProvider =
    AsyncNotifierProvider<AccountsNotifier, List<BankAccount>>(() {
  return AccountsNotifier();
});

class AccountsNotifier extends AsyncNotifier<List<BankAccount>> {
  @override
  Future<List<BankAccount>> build() => _fetch();
  Future<List<BankAccount>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
    if (businessId == null) return [];
    final res = await Supabase.instance.client
        .from('bank_accounts')
        .select()
        .eq('business_id', businessId);
    return (res as List)
        .map((e) => BankAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank & Cash'),
        actions: [
          IconButton(
            onPressed: () => _showAddAccountDialog(context, ref),
            icon: const Icon(Icons.add_card_outlined),
            tooltip: 'Add Account',
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) {
          final totalBalance =
              accounts.fold<double>(0, (s, a) => s + a.balance);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total balance card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Balance',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                          '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(totalBalance)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _BalancePill('${accounts.length} Accounts',
                              Icons.account_balance_outlined),
                          const SizedBox(width: 10),
                          _BalancePill(
                              'Rs. ${NumberFormat('#,##,##0').format(totalBalance)}',
                              Icons.currency_rupee),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                const SizedBox(height: 24),
                Text('Accounts', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                if (accounts.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        const Icon(Icons.account_balance_outlined,
                            size: 56, color: AppTheme.lightTextHint),
                        const SizedBox(height: 16),
                        Text('No accounts yet',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Add your cash or bank accounts to track money.',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  )
                else
                  ...accounts.asMap().entries.map((entry) {
                    final acc = entry.value;
                    final isCash = acc.type == 'cash';
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
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
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {},
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isCash
                                    ? AppTheme.successColor
                                        .withValues(alpha: 0.1)
                                    : AppTheme.primaryColor
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isCash
                                    ? Icons.payments_outlined
                                    : Icons.account_balance_outlined,
                                color: isCash
                                    ? AppTheme.successColor
                                    : AppTheme.primaryColor,
                                size: 24,
                              ),
                            ),
                            title: Text(acc.name,
                                style: Theme.of(context).textTheme.titleMedium),
                            subtitle: Text(acc.type.toUpperCase(),
                                style: Theme.of(context).textTheme.bodySmall),
                            trailing: Text(
                              '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(acc.balance)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: acc.balance >= 0
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor,
                                      fontWeight: FontWeight.w700),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                          ),
                        ),
                      ),
                    )
                        .animate(delay: Duration(milliseconds: entry.key * 60))
                        .fadeIn()
                        .slideX(begin: 0.05, end: 0);
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController(text: '0');
    String type = 'cash';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Account'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Account Name'),
              const SizedBox(height: 8),
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      hintText: 'e.g. Main Cash, NIC Bank')),
              const SizedBox(height: 16),
              const Text('Account Type'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: type,
                isExpanded: true,
                items: ['cash', 'bank', 'mobile_banking']
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.replaceAll('_', ' ').toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => type = v ?? type),
              ),
              const SizedBox(height: 16),
              const Text('Opening Balance (Rs.)'),
              const SizedBox(height: 8),
              TextField(
                  controller: balCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '0.00')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final businessId =
                    prefs.getString(AppConstants.kSelectedBusinessId) ?? '';
                await Supabase.instance.client.from('bank_accounts').insert({
                  'id': const Uuid().v4(),
                  'business_id': businessId,
                  'name': nameCtrl.text.trim(),
                  'type': type,
                  'balance': double.tryParse(balCtrl.text) ?? 0,
                  'created_at': DateTime.now().toIso8601String(),
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ref.invalidate(accountsProvider);
                }
              },
              child: const Text('Add Account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _BalancePill(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
