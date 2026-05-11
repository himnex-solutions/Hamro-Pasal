import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/features/parties/data/models/party_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final partyDetailProvider =
    FutureProvider.family<Party, String>((ref, id) async {
  final res = await Supabase.instance.client
      .from('parties')
      .select()
      .eq('id', id)
      .single();
  return Party.fromJson(res);
});

final partyLedgerProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) async {
  final res = await Supabase.instance.client
      .from('ledger_entries')
      .select()
      .eq('party_id', id)
      .order('entry_date', ascending: false)
      .limit(50);
  return (res as List).cast<Map<String, dynamic>>();
});

class PartyDetailScreen extends ConsumerWidget {
  final String partyId;
  const PartyDetailScreen({super.key, required this.partyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partyAsync = ref.watch(partyDetailProvider(partyId));
    final ledgerAsync = ref.watch(partyLedgerProvider(partyId));

    return Scaffold(
      body: partyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (party) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: party.type == AppConstants.partyCustomer
                          ? [AppTheme.primaryColor, AppTheme.primaryDark]
                          : [AppTheme.accentDark, const Color(0xFF007A5E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(party.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700)),
                          if (party.phone != null)
                            Text(party.phone!,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                if (party.phone != null)
                  IconButton(
                    onPressed: () => _sendWhatsApp(party.phone!, party.currentBalance),
                    icon: const Icon(Icons.chat_outlined, color: Colors.white),
                    tooltip: 'Send WhatsApp reminder',
                  ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Edit',
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance card
                    _BalanceCard(party: party).animate().fadeIn().slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),

                    // Info cards
                    if (party.address != null || party.email != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (party.address != null)
                                _InfoRow(Icons.location_on_outlined, 'Address', party.address!),
                              if (party.email != null)
                                _InfoRow(Icons.email_outlined, 'Email', party.email!),
                            ],
                          ),
                        ),
                      ).animate(delay: 50.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add),
                            label: const Text('Add Entry'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Export PDF'),
                          ),
                        ),
                      ],
                    ).animate(delay: 100.ms).fadeIn(),

                    const SizedBox(height: 24),

                    Text('Ledger History',
                        style: Theme.of(context).textTheme.titleLarge)
                        .animate(delay: 150.ms).fadeIn(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            ledgerAsync.when(
              loading: () => const SliverToBoxAdapter(
                  child: Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator()))),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('$e'))),
              data: (entries) => entries.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.lightTextHint),
                              const SizedBox(height: 12),
                              Text('No ledger entries yet',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final entry = entries[i];
                          final amount = (entry['amount'] as num).toDouble();
                          final isDebit = entry['entry_type'] == 'debit';
                          final date = DateTime.parse(entry['entry_date'] as String);
                          return ListTile(
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: isDebit
                                    ? AppTheme.errorColor.withValues(alpha: 0.1)
                                    : AppTheme.successColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                                color: isDebit ? AppTheme.errorColor : AppTheme.successColor,
                                size: 20,
                              ),
                            ),
                            title: Text(entry['description'] as String? ?? (isDebit ? 'Debit' : 'Credit')),
                            subtitle: Text(DateFormat('dd MMM yyyy').format(date)),
                            trailing: Text(
                              '${isDebit ? '+' : '-'}${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(amount)}',
                              style: TextStyle(
                                color: isDebit ? AppTheme.successColor : AppTheme.errorColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                        childCount: entries.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendWhatsApp(String phone, double balance) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final npPhone = cleanPhone.startsWith('0') ? '977${cleanPhone.substring(1)}' : '977$cleanPhone';
    final msg = balance > 0
        ? 'Namaskar! Your outstanding balance is Rs. ${balance.toStringAsFixed(2)}. Please clear when convenient. Thank you! - Hamro Pasal'
        : 'Namaskar! Please contact us regarding your account balance. Thank you! - Hamro Pasal';
    final url = Uri.parse('https://wa.me/$npPhone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}

class _BalanceCard extends StatelessWidget {
  final Party party;
  const _BalanceCard({required this.party});

  @override
  Widget build(BuildContext context) {
    final isReceivable = party.currentBalance > 0;
    final isPayable = party.currentBalance < 0;
    final formatted = NumberFormat('#,##,##0.00').format(party.currentBalance.abs());
    Color color = isReceivable ? AppTheme.successColor : isPayable ? AppTheme.errorColor : AppTheme.lightTextSecondary;
    String label = isReceivable ? 'To Receive' : isPayable ? 'To Pay' : 'Settled';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Balance', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text('${AppConstants.currencySymbol} $formatted',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color, fontWeight: FontWeight.w800)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.lightTextSecondary),
          const SizedBox(width: 10),
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
