import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_saoji/core/constants/app_constants.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/core/widgets/app_snackbar.dart';
import 'package:smart_saoji/features/parties/data/models/party_model.dart';
import 'package:smart_saoji/features/parties/presentation/screens/add_party_screen.dart';
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
                    onPressed: () =>
                        _sendWhatsApp(party.phone!, party.currentBalance),
                    icon: const Icon(Icons.chat_outlined, color: Colors.white),
                    tooltip: 'Send WhatsApp reminder',
                  ),
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddPartyScreen(existingParty: party),
                      ),
                    );
                    ref.invalidate(partyDetailProvider(partyId));
                  },
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Edit Party',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BalanceCard(party: party)
                        .animate()
                        .fadeIn()
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),

                    if (party.address != null || party.email != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (party.address != null)
                                _InfoRow(Icons.location_on_outlined, 'Address',
                                    party.address!),
                              if (party.email != null)
                                _InfoRow(Icons.email_outlined, 'Email',
                                    party.email!),
                            ],
                          ),
                        ),
                      ).animate(delay: 50.ms).fadeIn(),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (_) =>
                                  _AddEntrySheet(partyId: partyId, ref: ref),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Entry'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: ledgerAsync.hasValue
                                ? () => _exportPdf(
                                    context, party, ledgerAsync.value!)
                                : null,
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Export PDF'),
                          ),
                        ),
                      ],
                    ).animate(delay: 100.ms).fadeIn(),

                    const SizedBox(height: 24),
                    Text('Ledger History',
                            style: Theme.of(context).textTheme.titleLarge)
                        .animate(delay: 150.ms)
                        .fadeIn(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            ledgerAsync.when(
              loading: () => const SliverToBoxAdapter(
                  child: Center(
                      child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator()))),
              error: (e, _) =>
                  SliverToBoxAdapter(child: Center(child: Text('$e'))),
              data: (entries) => entries.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.receipt_long_outlined,
                                  size: 48, color: AppTheme.lightTextHint),
                              const SizedBox(height: 12),
                              Text('No ledger entries yet',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('Tap "Add Entry" above to record a transaction.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center),
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
                          final date =
                              DateTime.parse(entry['entry_date'] as String);
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDebit
                                    ? AppTheme.successColor
                                        .withValues(alpha: 0.1)
                                    : AppTheme.errorColor
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isDebit
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: isDebit
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                                size: 20,
                              ),
                            ),
                            title: Text(entry['description'] as String? ??
                                (isDebit ? 'Debit' : 'Credit')),
                            subtitle:
                                Text(DateFormat('dd MMM yyyy').format(date)),
                            trailing: Text(
                              '${isDebit ? '+' : '-'}${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(amount)}',
                              style: TextStyle(
                                color: isDebit
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
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

  Future<void> _exportPdf(BuildContext context, Party party,
      List<Map<String, dynamic>> entries) async {
    try {
      final pdf = pw.Document();
      final fmt = NumberFormat('#,##,##0.00');
      final now = DateFormat('dd MMM yyyy').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => [
            pw.Text(party.name,
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
                '${party.type.toUpperCase()}${party.phone != null ? ' | ${party.phone}' : ''}${party.email != null ? ' | ${party.email}' : ''}'),
            pw.SizedBox(height: 4),
            pw.Text('Statement generated: $now'),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('Date', bold: true),
                    _pdfCell('Description', bold: true),
                    _pdfCell('Type', bold: true),
                    _pdfCell('Amount', bold: true),
                  ],
                ),
                ...entries.map((e) {
                  final date =
                      DateTime.parse(e['entry_date'] as String);
                  final amount = (e['amount'] as num).toDouble();
                  final isDebit = e['entry_type'] == 'debit';
                  return pw.TableRow(children: [
                    _pdfCell(DateFormat('dd MMM yyyy').format(date)),
                    _pdfCell(e['description'] as String? ??
                        (isDebit ? 'Debit' : 'Credit')),
                    _pdfCell(isDebit ? 'Dr' : 'Cr'),
                    _pdfCell('Rs. ${fmt.format(amount)}'),
                  ]);
                }),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Current Balance: Rs. ${fmt.format(party.currentBalance.abs())} '
                '(${party.currentBalance >= 0 ? 'To Receive' : 'To Pay'})',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e'),
                backgroundColor: Colors.red));
      }
    }
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : null, fontSize: 10)),
      );

  void _sendWhatsApp(String phone, double balance) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final npPhone = cleanPhone.startsWith('0')
        ? '977${cleanPhone.substring(1)}'
        : '977$cleanPhone';
    final msg = balance > 0
        ? 'Namaskar! Your outstanding balance is Rs. ${balance.toStringAsFixed(2)}. Please clear when convenient. Thank you! - Smart Saoji'
        : 'Namaskar! Please contact us regarding your account balance. Thank you! - Smart Saoji';
    final url =
        Uri.parse('https://wa.me/$npPhone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}

// ── Add Entry Bottom Sheet ─────────────────────────────────────────
class _AddEntrySheet extends StatefulWidget {
  final String partyId;
  final WidgetRef ref;
  const _AddEntrySheet({required this.partyId, required this.ref});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _entryType = 'debit';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      AppSnackbar.show(context, 'Please enter a valid amount', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final supabase = Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();
      final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
      if (businessId == null) {
        throw 'No active business selected';
      }

      // Fetch party current_balance
      final partyRow = await supabase
          .from('parties')
          .select('current_balance')
          .eq('id', widget.partyId)
          .single();
      final currentBal = (partyRow['current_balance'] as num).toDouble();
      final delta = _entryType == 'debit' ? amount : -amount;
      final balanceAfter = currentBal + delta;

      // Insert ledger entry
      await supabase.from('ledger_entries').insert({
        'id': const Uuid().v4(),
        'business_id': businessId,
        'party_id': widget.partyId,
        'amount': amount,
        'entry_type': _entryType,
        'balance_after': balanceAfter,
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'entry_date': _selectedDate.toIso8601String(),
      });

      // Update party current_balance
      await supabase.from('parties').update({
        'current_balance': balanceAfter,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.partyId);

      // Refresh providers
      widget.ref.invalidate(partyLedgerProvider(widget.partyId));
      widget.ref.invalidate(partyDetailProvider(widget.partyId));

      if (mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Entry added!',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(12),
            ),
          );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(12),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add Ledger Entry',
                  style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 12),

          // Entry type
          Row(
            children: [
              Expanded(
                child: _EntryTypeBtn(
                  label: 'They Owe You (Dr)',
                  isSelected: _entryType == 'debit',
                  color: AppTheme.successColor,
                  onTap: () => setState(() => _entryType = 'debit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EntryTypeBtn(
                  label: 'You Owe Them (Cr)',
                  isSelected: _entryType == 'credit',
                  color: AppTheme.errorColor,
                  onTap: () => setState(() => _entryType = 'credit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount (Rs.) *',
              prefixIcon:
                  Icon(Icons.account_balance_wallet_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              prefixIcon: Icon(Icons.notes_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Date picker
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(DateFormat('dd MMM yyyy')
                      .format(_selectedDate)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white))
                  : const Text('Save Entry',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTypeBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _EntryTypeBtn(
      {required this.label,
      required this.isSelected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12)),
        ),
      ),
    );
  }
}

// ── Existing helper widgets ─────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final Party party;
  const _BalanceCard({required this.party});

  @override
  Widget build(BuildContext context) {
    final isReceivable = party.currentBalance > 0;
    final isPayable = party.currentBalance < 0;
    final formatted =
        NumberFormat('#,##,##0.00').format(party.currentBalance.abs());
    Color color = isReceivable
        ? AppTheme.successColor
        : isPayable
            ? AppTheme.errorColor
            : AppTheme.lightTextSecondary;
    String label = isReceivable
        ? 'To Receive'
        : isPayable
            ? 'To Pay'
            : 'Settled';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05)
          ],
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
              Text('Current Balance',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text('${AppConstants.currencySymbol} $formatted',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                          color: color, fontWeight: FontWeight.w800)),
            ],
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
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
          Expanded(
              child: Text(value,
                  style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
