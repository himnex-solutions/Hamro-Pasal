import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/customer.dart';

final _fmt = NumberFormat('#,##0.00', 'en_US');

final ledgerProvider =
    FutureProvider.family<List<LedgerTransaction>, String>((ref, customerId) async {
  final data = await SupabaseService.instance.getLedger(customerId);
  return data.map(LedgerTransaction.fromJson).toList();
});

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(ledgerProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Transaction',
            onPressed: () => _showAddTransaction(context, ref),
          ),
        ],
      ),
      body: ledgerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (transactions) {
          final totalCredit = transactions
              .where((t) => t.type == LedgerType.credit)
              .fold<double>(0, (s, t) => s + t.amount);
          final totalPaid = transactions
              .where((t) => t.type == LedgerType.payment)
              .fold<double>(0, (s, t) => s + t.amount);
          final balance = totalCredit - totalPaid;

          return Column(
            children: [
              // Balance summary
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: balance > 0
                        ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                        : [const Color(0xFF10B981), const Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(balance > 0 ? 'Total Due (Udhaar)' : 'All Clear ✓',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('NPR ${_fmt.format(balance.abs())}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBadge(
                            'Total Credit', 'NPR ${_fmt.format(totalCredit)}'),
                        _StatBadge(
                            'Total Paid', 'NPR ${_fmt.format(totalPaid)}'),
                      ],
                    ),
                  ],
                ),
              ),

              // Transaction list
              Expanded(
                child: transactions.isEmpty
                    ? const Center(
                        child: Text('No transactions yet',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _TransactionTile(tx: transactions[i]),
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showAddTransaction(context, ref, type: LedgerType.credit),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Udhaar'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    minimumSize: const Size(0, 48)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showAddTransaction(context, ref, type: LedgerType.payment),
                icon: const Icon(Icons.payments_rounded),
                label: const Text('Record Payment'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(0, 48)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTransaction(BuildContext context, WidgetRef ref,
      {LedgerType? type}) async {
    LedgerType selectedType = type ?? LedgerType.credit;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Transaction',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => selectedType = LedgerType.credit),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == LedgerType.credit
                                ? AppColors.warningLight
                                : Colors.transparent,
                            border: Border.all(
                              color: selectedType == LedgerType.credit
                                  ? AppColors.warning
                                  : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                              child: Text('Udhaar (Credit)',
                                  style: TextStyle(fontWeight: FontWeight.w600))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => selectedType = LedgerType.payment),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == LedgerType.payment
                                ? AppColors.successLight
                                : Colors.transparent,
                            border: Border.all(
                              color: selectedType == LedgerType.payment
                                  ? AppColors.success
                                  : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                              child: Text('Payment',
                                  style: TextStyle(fontWeight: FontWeight.w600))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                    controller: amountCtrl,
                    label: 'Amount (NPR) *',
                    hint: '0.00',
                    prefixIcon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                AppTextField(
                    controller: noteCtrl,
                    label: 'Note (Optional)',
                    hint: 'e.g. Rice purchase',
                    prefixIcon: Icons.notes_rounded),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final amount = double.tryParse(amountCtrl.text);
                    if (amount == null || amount <= 0) {
                      return;
                    }
                    
                    setState(() => isSaving = true);
                    
                    final today = DateTime.now();
                    final data = {
                      'user_id': SupabaseService.instance.currentUserId!,
                      'customer_id': customerId,
                      'type': selectedType.name,
                      'amount': amount,
                      'note': noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                      'ad_date': '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
                    };
                    
                    await SupabaseService.instance.insertLedgerTransaction(data);
                    
                    // Invalidate providers to force UI refresh
                    ref.invalidate(ledgerProvider(customerId));
                    
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: selectedType == LedgerType.credit
                          ? AppColors.warning
                          : AppColors.success),
                  child: isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(selectedType == LedgerType.credit ? 'Add Udhaar' : 'Record Payment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  const _StatBadge(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ],
      );
}

class _TransactionTile extends StatelessWidget {
  final LedgerTransaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.type == LedgerType.credit;
    return ListTile(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border)),
      tileColor: Theme.of(context).cardColor,
      leading: CircleAvatar(
        backgroundColor:
            isCredit ? AppColors.warningLight : AppColors.successLight,
        child: Icon(
            isCredit
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: isCredit ? AppColors.warning : AppColors.success,
            size: 20),
      ),
      title: Text(
          isCredit ? 'Udhaar' : 'Payment',
          style: Theme.of(context).textTheme.labelLarge),
      subtitle: Text(tx.note ?? tx.adDate,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary)),
      trailing: Text(
          '${isCredit ? '+' : '-'} NPR ${_fmt.format(tx.amount)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isCredit ? AppColors.warning : AppColors.success,
              fontWeight: FontWeight.w700)),
    );
  }
}
