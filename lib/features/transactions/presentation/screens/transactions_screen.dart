import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_saoji/core/constants/app_constants.dart';
import 'package:smart_saoji/core/l10n/app_strings.dart';
import 'package:smart_saoji/core/router/app_router.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/features/transactions/data/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(() {
  return TransactionsNotifier();
});

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() => _fetch();

  Future<List<Transaction>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
    if (businessId == null) return [];
    final res = await Supabase.instance.client
        .from('transactions')
        .select('*, transaction_items(*)')
        .eq('business_id', businessId)
        .order('transaction_date', ascending: false)
        .limit(100);
    return (res as List)
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Transaction> _filter(List<Transaction> txs, String? type) {
    var list = type == null ? txs : txs.where((t) => t.type == type).toList();
    if (_search.isNotEmpty) {
      list = list
          .where((t) =>
              (t.partyName?.toLowerCase().contains(_search.toLowerCase()) ??
                  false) ||
              t.type.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsProvider);

    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.transactions),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: [
            Tab(text: l.all),
            Tab(text: l.sale),
            Tab(text: l.purchase),
            Tab(text: l.expenses),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.addTransaction),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l.searchTransactions,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.clear, size: 18))
                    : null,
              ),
            ),
          ),
          Expanded(
            child: txAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (txs) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(transactionsProvider.notifier).refresh(),
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _TxList(transactions: _filter(txs, null)),
                    _TxList(transactions: _filter(txs, AppConstants.txSale)),
                    _TxList(
                        transactions: _filter(txs, AppConstants.txPurchase)),
                    _TxList(transactions: _filter(txs, AppConstants.txExpense)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addTransaction),
        icon: const Icon(Icons.add),
        label: Text(l.addTransaction),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _TxList extends StatelessWidget {
  final List<Transaction> transactions;
  const _TxList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 56, color: AppTheme.lightTextHint),
            const SizedBox(height: 16),
            Text(context.l10n.noTransactionsFound,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<Transaction>>{};
    for (final tx in transactions) {
      final dateKey = DateFormat('dd MMM yyyy').format(tx.transactionDate);
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }

    final dates = grouped.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: dates.length,
      itemBuilder: (context, di) {
        final date = dates[di];
        final txList = grouped[date]!;
        final dayTotal = txList.fold<double>(
            0,
            (s, t) =>
                s + (t.type == AppConstants.txExpense ? -t.amount : t.amount));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(date,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.lightTextSecondary,
                          )),
                  Text(
                    '${dayTotal >= 0 ? '+' : ''}${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(dayTotal)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: dayTotal >= 0
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            ...txList.asMap().entries.map((entry) {
              return _TxCard(tx: entry.value)
                  .animate(delay: Duration(milliseconds: entry.key * 30))
                  .fadeIn()
                  .slideX(begin: 0.05, end: 0);
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _TxCard extends StatelessWidget {
  final Transaction tx;
  const _TxCard({required this.tx});

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

    final isDebit =
        tx.type == AppConstants.txExpense || tx.type == AppConstants.txPurchase;
    final formatted = NumberFormat('#,##,##0.00').format(tx.amount);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
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
            color: typeColor.withValues(alpha: 0.12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/home/transactions/${tx.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.partyName ?? tx.type.toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(tx.paymentMethod.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: typeColor,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 6),
                          Text(DateFormat('hh:mm a').format(tx.transactionDate),
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isDebit ? '-' : '+'}${AppConstants.currencySymbol} $formatted',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isDebit
                                ? AppTheme.errorColor
                                : AppTheme.successColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (tx.dueAmount > 0)
                      Text(
                          'Due: ${AppConstants.currencySymbol} ${NumberFormat('#,##,##0').format(tx.dueAmount)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.warningColor,
                                  )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
