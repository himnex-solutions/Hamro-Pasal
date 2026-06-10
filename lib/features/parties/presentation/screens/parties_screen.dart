import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_saoji/core/constants/app_constants.dart';
import 'package:smart_saoji/core/l10n/app_strings.dart';
import 'package:smart_saoji/core/router/app_router.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';

import 'package:smart_saoji/features/parties/data/models/party_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final partiesProvider = AsyncNotifierProvider<PartiesNotifier, List<Party>>(() {
  return PartiesNotifier();
});

class PartiesNotifier extends AsyncNotifier<List<Party>> {
  @override
  Future<List<Party>> build() => _fetch();

  Future<List<Party>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
    if (businessId == null) return [];
    final res = await Supabase.instance.client
        .from('parties')
        .select()
        .eq('business_id', businessId)
        .order('name');
    return (res as List)
        .map((e) => Party.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

class PartiesScreen extends ConsumerStatefulWidget {
  const PartiesScreen({super.key});

  @override
  ConsumerState<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends ConsumerState<PartiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Party> _filter(List<Party> parties, String type) {
    var filtered = type == 'all'
        ? parties
        : parties
            .where((p) => p.type == type || p.type == AppConstants.partyBoth)
            .toList();
    if (_search.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(_search.toLowerCase()) ||
              (p.phone?.contains(_search) ?? false))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final partiesAsync = ref.watch(partiesProvider);

    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.parties),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l.all),
            Tab(text: l.customers),
            Tab(text: l.suppliers),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.addParty),
            icon: const Icon(Icons.person_add_outlined),
            tooltip: l.addParty,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l.searchParties,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.clear, size: 18),
                      )
                    : null,
              ),
            ),
          ),

          Expanded(
            child: partiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (parties) => TabBarView(
                controller: _tabController,
                children: [
                  _PartyList(parties: _filter(parties, 'all')),
                  _PartyList(
                      parties: _filter(parties, AppConstants.partyCustomer)),
                  _PartyList(
                      parties: _filter(parties, AppConstants.partySupplier)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addParty),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(l.addParty),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _PartyList extends StatelessWidget {
  final List<Party> parties;
  const _PartyList({required this.parties});

  @override
  Widget build(BuildContext context) {
    if (parties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline,
                size: 56, color: AppTheme.lightTextHint),
            const SizedBox(height: 16),
            Text(context.l10n.noPartiesFound,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Add customers and suppliers to track their ledger.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: parties.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final party = parties[i];
        return _PartyCard(party: party)
            .animate(delay: Duration(milliseconds: i * 40))
            .fadeIn()
            .slideX(begin: 0.05, end: 0);
      },
    );
  }
}

class _PartyCard extends StatelessWidget {
  final Party party;
  const _PartyCard({required this.party});

  @override
  Widget build(BuildContext context) {
    final isReceivable = party.currentBalance > 0;
    final isPayable = party.currentBalance < 0;
    final formatted =
        NumberFormat('#,##,##0.00').format(party.currentBalance.abs());
    final initials = party.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

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
            color: (isReceivable
                    ? AppTheme.successColor
                    : isPayable
                        ? AppTheme.errorColor
                        : AppTheme.primaryColor)
                .withValues(alpha: 0.08),
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
          onTap: () => context.push('/home/parties/${party.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: party.type == AppConstants.partyCustomer
                          ? [AppTheme.primaryColor, AppTheme.primaryLight]
                          : [AppTheme.accentDark, AppTheme.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(party.name,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: party.type == AppConstants.partyCustomer
                                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                  : AppTheme.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              party.type == AppConstants.partyBoth
                                  ? 'Both'
                                  : party.type.capitalize(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        party.type == AppConstants.partyCustomer
                                            ? AppTheme.primaryColor
                                            : AppTheme.accentDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (party.phone != null)
                        Text(party.phone!,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (party.currentBalance != 0)
                      Text(
                        '${AppConstants.currencySymbol} $formatted',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isReceivable
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    if (isReceivable)
                      Text(context.l10n.toReceive,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.successColor,
                                  ))
                    else if (isPayable)
                      Text(context.l10n.toPay,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.errorColor,
                                  ))
                    else
                      Text(context.l10n.completed,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.lightTextSecondary,
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
