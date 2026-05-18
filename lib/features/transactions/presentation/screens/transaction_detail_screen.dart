import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/features/transactions/data/models/transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final transactionDetailProvider =
    FutureProvider.family<Transaction, String>((ref, id) async {
  final res = await Supabase.instance.client
      .from('transactions')
      .select('*, transaction_items(*)')
      .eq('id', id)
      .single();
  return Transaction.fromJson(res);
});

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionDetailProvider(transactionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tx) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              _HeaderCard(tx: tx),
              const SizedBox(height: 16),
              // Items list
              if (tx.items.isNotEmpty) ...[
                Text('Items', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tx.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = tx.items[i];
                      return ListTile(
                        title: Text(item.productName),
                        subtitle: Text(
                            '${item.quantity} x ${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(item.unitPrice)}'),
                        trailing: Text(
                            '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(item.totalPrice)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Totals
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _Row('Total',
                          '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(tx.amount)}',
                          bold: true),
                      _Row('Paid',
                          '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(tx.paidAmount)}'),
                      if (tx.dueAmount > 0)
                        _Row('Due',
                            '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(tx.dueAmount)}',
                            color: AppTheme.warningColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (tx.note != null) ...[
                Text('Note', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBorder.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(tx.note!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Transaction tx;
  const _HeaderCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    IconData typeIcon;
    switch (tx.type) {
      case AppConstants.txSale:
        typeColor = AppTheme.successColor;
        typeIcon = Icons.trending_up_rounded;
        break;
      case AppConstants.txPurchase:
        typeColor = AppTheme.infoColor;
        typeIcon = Icons.shopping_bag_outlined;
        break;
      case AppConstants.txExpense:
        typeColor = AppTheme.errorColor;
        typeIcon = Icons.trending_down_rounded;
        break;
      default:
        typeColor = AppTheme.accentColor;
        typeIcon = Icons.swap_horiz_rounded;
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          typeColor.withValues(alpha: 0.1),
          typeColor.withValues(alpha: 0.05)
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Icon(typeIcon, color: typeColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.type.toUpperCase(),
                    style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1)),
                Text(
                    '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(tx.amount)}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                if (tx.partyName != null)
                  Text(tx.partyName!,
                      style: Theme.of(context).textTheme.bodySmall),
                Text(
                    DateFormat(AppConstants.dateTimeFormat)
                        .format(tx.transactionDate),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? color;
  const _Row(this.label, this.value, {this.bold = false, this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: color ?? AppTheme.primaryColor)),
        ],
      ),
    );
  }
}
