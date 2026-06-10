import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_saoji/core/constants/app_constants.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/core/l10n/app_strings.dart';
import 'package:smart_saoji/core/widgets/app_text_field.dart';
import 'package:smart_saoji/core/widgets/app_button.dart';
import 'package:smart_saoji/core/widgets/app_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class BankAccount {
  final String id, name, type;
  final double balance;
  final String? bankName;
  final String? accountNumber;
  final String? branchName;
  final String? esewaId;
  final String? esewaName;

  const BankAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.bankName,
    this.accountNumber,
    this.branchName,
    this.esewaId,
    this.esewaName,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        balance: (json['balance'] as num).toDouble(),
        bankName: json['bank_name'] as String?,
        accountNumber: json['account_number'] as String?,
        branchName: json['branch_name'] as String?,
        esewaId: json['esewa_id'] as String?,
        esewaName: json['esewa_name'] as String?,
      );
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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.isNepali ? 'बैंक तथा नगद' : 'Bank & Cash'),
        actions: [
          IconButton(
            onPressed: () => _showAddAccountDialog(context, ref),
            icon: const Icon(Icons.add_card_outlined),
            tooltip: l10n.addAccount,
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
                      Text(l10n.isNepali ? 'कुल मौज्दात' : 'Total Balance',
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
                          _BalancePill(
                            l10n.isNepali
                                ? '${accounts.length} खाताहरू'
                                : '${accounts.length} Accounts',
                            Icons.account_balance_outlined,
                          ),
                          const SizedBox(width: 10),
                          _BalancePill(
                            'Rs. ${NumberFormat('#,##,##0').format(totalBalance)}',
                            Icons.currency_rupee,
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                const SizedBox(height: 24),
                Text(
                  l10n.isNepali ? 'खाताहरू' : 'Accounts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),

                if (accounts.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        const Icon(Icons.account_balance_outlined,
                            size: 56, color: AppTheme.lightTextHint),
                        const SizedBox(height: 16),
                        Text(
                          l10n.isNepali ? 'कुनै खाता छैन' : 'No accounts yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.isNepali
                              ? 'पैसा ट्र्याक गर्न आफ्नो नगद वा बैंक खाताहरू थप्नुहोस्।'
                              : 'Add your cash or bank accounts to track money.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...accounts.asMap().entries.map((entry) {
                    final acc = entry.value;
                    final isCash = acc.type == 'cash';
                    final isBank = acc.type == 'bank';

                    Widget subtitleWidget;
                    if (isBank) {
                      subtitleWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc.bankName ?? 'BANK',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                          if (acc.accountNumber != null && acc.accountNumber!.isNotEmpty)
                            Text(
                              '${l10n.accountNumberLabel}: ${acc.accountNumber} ${acc.branchName != null && acc.branchName!.isNotEmpty ? "(${acc.branchName})" : ""}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      );
                    } else if (acc.type == 'mobile_banking') {
                      subtitleWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc.esewaName ?? 'eSewa/Khalti',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                          ),
                          if (acc.esewaId != null && acc.esewaId!.isNotEmpty)
                            Text(
                              'ID: ${acc.esewaId}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      );
                    } else {
                      subtitleWidget = Text(
                        l10n.isNepali ? 'नगद खाता' : 'CASH ACCOUNT',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }

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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isCash
                                        ? AppTheme.successColor.withValues(alpha: 0.1)
                                        : isBank
                                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                            : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isCash
                                        ? Icons.payments_outlined
                                        : isBank
                                            ? Icons.account_balance_outlined
                                            : Icons.wallet_outlined,
                                    color: isCash
                                        ? AppTheme.successColor
                                        : isBank
                                            ? AppTheme.primaryColor
                                            : Colors.orange,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acc.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      subtitleWidget,
                                    ],
                                  ),
                                ),
                                Text(
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
                              ],
                            ),
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
    final bankNameCtrl = TextEditingController();
    final acNoCtrl = TextEditingController();
    final branchCtrl = TextEditingController();
    final esewaIdCtrl = TextEditingController();
    final esewaNameCtrl = TextEditingController();

    String type = 'cash';
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isBank = type == 'bank';
          final isWallet = type == 'mobile_banking';

          return AlertDialog(
            title: Text(l10n.addAccount),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.accountName, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: nameCtrl,
                      hint: l10n.isNepali ? 'उदा: मुख्य नगद, NIC बैंक' : 'e.g. Main Cash, NIC Bank',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.accountType, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: type,
                          isExpanded: true,
                          items: ['cash', 'bank', 'mobile_banking']
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(
                                      t == 'cash'
                                          ? (l10n.isNepali ? 'नगद (Cash)' : 'CASH')
                                          : t == 'bank'
                                              ? (l10n.isNepali ? 'बैंक खाता (Bank)' : 'BANK')
                                              : (l10n.isNepali ? 'डिजिटल वालेट (eSewa/Khalti)' : 'MOBILE BANKING / WALLET'),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => type = v ?? type),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Conditionally render Bank details
                    if (isBank) ...[
                      Text(l10n.bankName, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      AppTextField(
                        controller: bankNameCtrl,
                        hint: 'e.g. NIC Asia Bank',
                        prefixIcon: Icons.account_balance_outlined,
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.accountNumberLabel, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      AppTextField(
                        controller: acNoCtrl,
                        hint: 'e.g. 123456789012',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.numbers_outlined,
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.branchName, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      AppTextField(
                        controller: branchCtrl,
                        hint: 'e.g. Koteshwor',
                        prefixIcon: Icons.location_city_outlined,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Conditionally render eSewa / Wallet details
                    if (isWallet) ...[
                      Text(l10n.esewaName, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      AppTextField(
                        controller: esewaNameCtrl,
                        hint: 'e.g. eSewa, Khalti',
                        prefixIcon: Icons.wallet_outlined,
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.esewaId, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      AppTextField(
                        controller: esewaIdCtrl,
                        hint: 'e.g. 98XXXXXXXX',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_android_outlined,
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text('${l10n.openingBalance} (Rs.)', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: balCtrl,
                      keyboardType: TextInputType.number,
                      hint: '0.00',
                      prefixIcon: Icons.account_balance_wallet_outlined,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.isNepali ? 'रद्द गर्नुहोस्' : 'Cancel')),
              AppButton(
                label: l10n.addAccount,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    AppSnackbar.show(context, l10n.isNepali ? 'खाताको नाम आवश्यक छ' : 'Account name is required', isError: true);
                    return;
                  }
                  final prefs = await SharedPreferences.getInstance();
                  final businessId =
                      prefs.getString(AppConstants.kSelectedBusinessId) ?? '';
                  await Supabase.instance.client.from('bank_accounts').insert({
                    'id': const Uuid().v4(),
                    'business_id': businessId,
                    'name': nameCtrl.text.trim(),
                    'type': type,
                    'balance': double.tryParse(balCtrl.text) ?? 0,
                    'bank_name': isBank ? bankNameCtrl.text.trim() : null,
                    'account_number': isBank ? acNoCtrl.text.trim() : null,
                    'branch_name': isBank ? branchCtrl.text.trim() : null,
                    'esewa_id': isWallet ? esewaIdCtrl.text.trim() : null,
                    'esewa_name': isWallet ? esewaNameCtrl.text.trim() : null,
                    'created_at': DateTime.now().toIso8601String(),
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ref.invalidate(accountsProvider);
                  }
                },
              ),
            ],
          );
        },
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
