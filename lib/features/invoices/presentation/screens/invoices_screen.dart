import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Invoice {
  final String id, businessId, invoiceNumber, status;
  final String? partyId, partyName;
  final double subtotal, taxAmount, discountAmount, totalAmount, paidAmount;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final List<Map<String, dynamic>> items;

  const Invoice({
    required this.id, required this.businessId, required this.invoiceNumber,
    required this.status, this.partyId, this.partyName,
    required this.subtotal, this.taxAmount = 0, this.discountAmount = 0,
    required this.totalAmount, this.paidAmount = 0,
    required this.invoiceDate, this.dueDate, this.items = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: json['id'] as String, businessId: json['business_id'] as String,
    invoiceNumber: json['invoice_number'] as String,
    status: json['status'] as String,
    partyId: json['party_id'] as String?, partyName: json['party_name'] as String?,
    subtotal: (json['subtotal'] as num).toDouble(),
    taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
    discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
    totalAmount: (json['total_amount'] as num).toDouble(),
    paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
    invoiceDate: DateTime.parse(json['invoice_date'] as String),
    dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
    items: (json['invoice_items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
  );

  bool get isPaid => status == 'paid';
  bool get isUnpaid => status == 'unpaid';
  double get dueAmount => totalAmount - paidAmount;
}

final invoicesProvider = AsyncNotifierProvider<InvoicesNotifier, List<Invoice>>(() {
  return InvoicesNotifier();
});

class InvoicesNotifier extends AsyncNotifier<List<Invoice>> {
  @override
  Future<List<Invoice>> build() => _fetch();

  Future<List<Invoice>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
    if (businessId == null) return [];
    final res = await Supabase.instance.client
        .from('invoices').select('*, invoice_items(*)')
        .eq('business_id', businessId)
        .order('invoice_date', ascending: false).limit(50);
    return (res as List).map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});
  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'All'), Tab(text: 'Unpaid'), Tab(text: 'Paid')],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.createInvoice),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (invoices) {
          final all = invoices;
          final unpaid = invoices.where((i) => i.isUnpaid).toList();
          final paid = invoices.where((i) => i.isPaid).toList();
          return TabBarView(
            controller: _tabCtrl,
            children: [
              _InvoiceList(invoices: all),
              _InvoiceList(invoices: unpaid),
              _InvoiceList(invoices: paid),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createInvoice),
        icon: const Icon(Icons.add),
        label: const Text('Create Invoice'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _InvoiceList extends StatelessWidget {
  final List<Invoice> invoices;
  const _InvoiceList({required this.invoices});

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined, size: 56, color: AppTheme.lightTextHint),
            const SizedBox(height: 16),
            Text('No invoices', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final inv = invoices[i];
        return _InvoiceCard(invoice: inv)
            .animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05, end: 0);
      },
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    switch (invoice.status) {
      case 'paid': statusColor = AppTheme.successColor; statusLabel = 'Paid'; break;
      case 'partial': statusColor = AppTheme.warningColor; statusLabel = 'Partial'; break;
      default: statusColor = AppTheme.errorColor; statusLabel = 'Unpaid';
    }

    return Card(
      child: InkWell(
        onTap: () => context.push('/home/invoices/${invoice.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${invoice.invoiceNumber}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (invoice.partyName != null)
                Text(invoice.partyName!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat(AppConstants.dateFormat).format(invoice.invoiceDate),
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(invoice.totalAmount)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (invoice.dueAmount > 0) ...[
                const SizedBox(height: 4),
                Text('Due: ${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(invoice.dueAmount)}',
                    style: const TextStyle(color: AppTheme.warningColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder screens for invoice creation and detail
class CreateInvoiceScreen extends StatelessWidget {
  const CreateInvoiceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: const Center(child: Text('Invoice creation form coming soon')),
    );
  }
}

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: Center(child: Text('Invoice detail for: $invoiceId')),
    );
  }
}
