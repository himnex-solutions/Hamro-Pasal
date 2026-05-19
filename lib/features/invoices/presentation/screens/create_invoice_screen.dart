import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/l10n/app_strings.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_button.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';
import 'package:hamro_pasal/features/invoices/presentation/screens/invoices_screen.dart';

// ── Line Item Model ────────────────────────────────────────────
class _LineItem {
  String productId = '';
  String productName = '';
  double quantity = 1;
  double unitPrice = 0;
  double discount = 0;

  double get total => (quantity * unitPrice) - discount;
}

// ── Create Invoice Screen ──────────────────────────────────────
class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _supabase = Supabase.instance.client;

  // Party
  String? _selectedPartyId;
  String? _selectedPartyName;
  List<Map<String, dynamic>> _parties = [];

  // Products
  List<Map<String, dynamic>> _products = [];

  // Line items
  final List<_LineItem> _items = [_LineItem()];

  // Invoice fields
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  double _taxPercent = 0;
  double _discountAmount = 0;
  bool _isLoading = false;
  bool _isFetching = true;
  String _businessId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isFetching = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _businessId = prefs.getString(AppConstants.kSelectedBusinessId) ?? '';
      if (_businessId.isEmpty) return;

      // Load parties and products in parallel
      final results = await Future.wait([
        _supabase
            .from('parties')
            .select('id, name, type')
            .eq('business_id', _businessId)
            .order('name'),
        _supabase
            .from('products')
            .select('id, name, selling_price, stock_quantity')
            .eq('business_id', _businessId)
            .eq('is_active', true)
            .order('name'),
      ]);

      if (mounted) {
        setState(() {
          _parties = (results[0] as List).cast<Map<String, dynamic>>();
          _products = (results[1] as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Failed to load data: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  // ── Totals ─────────────────────────────────────────────────
  double get _subtotal => _items.fold(0, (s, i) => s + i.total);
  double get _taxAmount => _subtotal * (_taxPercent / 100);
  double get _grandTotal => _subtotal + _taxAmount - _discountAmount;

  // ── Save ───────────────────────────────────────────────────
  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.every((i) => i.productName.trim().isEmpty)) {
      AppSnackbar.show(context, 'Add at least one item to the invoice.',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final invoiceId = const Uuid().v4();
      final now = DateTime.now().toIso8601String();

      // Generate invoice number: INV-YYYYMMDD-XXXX
      final dateStr = DateFormat('yyyyMMdd').format(_invoiceDate);
      final rand = (DateTime.now().millisecondsSinceEpoch % 10000)
          .toString()
          .padLeft(4, '0');
      final invoiceNumber = 'INV-$dateStr-$rand';

      // Insert invoice
      await _supabase.from('invoices').insert({
        'id': invoiceId,
        'business_id': _businessId,
        'invoice_number': invoiceNumber,
        'party_id': _selectedPartyId,
        'party_name': _selectedPartyName,
        'status': 'unpaid',
        'subtotal': _subtotal,
        'tax_amount': _taxAmount,
        'discount_amount': _discountAmount,
        'total_amount': _grandTotal,
        'paid_amount': 0,
        'invoice_date': _invoiceDate.toIso8601String(),
        'due_date': _dueDate?.toIso8601String(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'created_at': now,
      });

      // Insert line items
      final validItems =
          _items.where((i) => i.productName.trim().isNotEmpty).toList();
      if (validItems.isNotEmpty) {
        await _supabase.from('invoice_items').insert(
              validItems
                  .map((item) => {
                        'id': const Uuid().v4(),
                        'invoice_id': invoiceId,
                        'product_id':
                            item.productId.isEmpty ? null : item.productId,
                        'product_name': item.productName,
                        'quantity': item.quantity,
                        'unit_price': item.unitPrice,
                        'discount': item.discount,
                        'total_price': item.total,
                        'created_at': now,
                      })
                  .toList(),
            );
      }

      if (mounted) {
        // Refresh the invoices list so the new invoice appears immediately
        ref.read(invoicesProvider.notifier).refresh();
        AppSnackbar.show(context, '✅ Invoice $invoiceNumber created!',
            isSuccess: true);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Failed to save: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Date picker ────────────────────────────────────────────
  Future<void> _pickDate({required bool isDue}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDue
          ? (_dueDate ?? DateTime.now().add(const Duration(days: 15)))
          : _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isDue) {
          _dueDate = picked;
        } else {
          _invoiceDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.createInvoice),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveInvoice,
            icon: const Icon(Icons.check_rounded),
            label: Text(context.l10n.save),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
          ),
        ],
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Invoice header card ──────────────────
                  _SectionCard(
                    title: 'Invoice Details',
                    icon: Icons.receipt_long_outlined,
                    child: Column(
                      children: [
                        // Party selector
                        const _FieldLabel('Bill To (Customer/Supplier)'),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_selectedPartyId),
                          initialValue: _selectedPartyId,
                          hint: const Text('Select party (optional)'),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('— No Party —')),
                            ..._parties.map((p) => DropdownMenuItem(
                                  value: p['id'] as String,
                                  child: Text(p['name'] as String),
                                )),
                          ],
                          onChanged: (v) => setState(() {
                            _selectedPartyId = v;
                            _selectedPartyName = v == null
                                ? null
                                : _parties.firstWhere(
                                    (p) => p['id'] == v)['name'] as String;
                          }),
                        ),

                        const SizedBox(height: 16),

                        // Dates row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Invoice Date'),
                                  _DateTile(
                                    label: DateFormat('dd MMM yyyy')
                                        .format(_invoiceDate),
                                    icon: Icons.calendar_today_outlined,
                                    onTap: () => _pickDate(isDue: false),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Due Date'),
                                  _DateTile(
                                    label: _dueDate == null
                                        ? 'Not set'
                                        : DateFormat('dd MMM yyyy')
                                            .format(_dueDate!),
                                    icon: Icons.event_outlined,
                                    onTap: () => _pickDate(isDue: true),
                                    isPlaceholder: _dueDate == null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 16),

                  // ── Line items ────────────────────────────
                  _SectionCard(
                    title: 'Items',
                    icon: Icons.inventory_2_outlined,
                    trailing: TextButton.icon(
                      onPressed: () => setState(() => _items.add(_LineItem())),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(context.l10n.addItem),
                    ),
                    child: Column(
                      children: [
                        // Header row
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 4,
                                  child: Text('Item',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12))),
                              Expanded(
                                  flex: 2,
                                  child: Text('Qty',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  flex: 2,
                                  child: Text('Price',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12),
                                      textAlign: TextAlign.center)),
                              SizedBox(width: 32),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        ..._items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return _LineItemRow(
                            item: item,
                            products: _products,
                            onDelete: _items.length > 1
                                ? () => setState(() => _items.removeAt(idx))
                                : null,
                            onChanged: () => setState(() {}),
                          );
                        }),
                        const Divider(),
                        // Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal',
                                style: Theme.of(context).textTheme.bodyMedium),
                            Text(
                                '${AppConstants.currencySymbol} ${fmt.format(_subtotal)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 16),

                  // ── Tax & Discount ────────────────────────
                  _SectionCard(
                    title: 'Tax & Discount',
                    icon: Icons.percent_outlined,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Tax (%)'),
                                  TextFormField(
                                    initialValue: '0',
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      suffixText: '%',
                                    ),
                                    onChanged: (v) => setState(() =>
                                        _taxPercent = double.tryParse(v) ?? 0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel(
                                      'Discount (${AppConstants.currencySymbol})'),
                                  TextFormField(
                                    initialValue: '0',
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    onChanged: (v) => setState(() =>
                                        _discountAmount =
                                            double.tryParse(v) ?? 0),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_taxPercent > 0)
                          _SummaryRow(
                              'Tax (${_taxPercent.toStringAsFixed(1)}%)',
                              '+${AppConstants.currencySymbol} ${fmt.format(_taxAmount)}',
                              AppTheme.warningColor),
                        if (_discountAmount > 0)
                          _SummaryRow(
                              'Discount',
                              '-${AppConstants.currencySymbol} ${fmt.format(_discountAmount)}',
                              AppTheme.successColor),
                      ],
                    ),
                  ).animate(delay: 150.ms).fadeIn(),

                  const SizedBox(height: 16),

                  // ── Notes ─────────────────────────────────
                  _SectionCard(
                    title: 'Notes',
                    icon: Icons.notes_outlined,
                    child: TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add any notes or terms...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 16),

                  // ── Grand Total card ──────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Grand Total',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Text('Amount Due',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                          ],
                        ),
                        Text(
                          '${AppConstants.currencySymbol} ${fmt.format(_grandTotal)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22),
                        ),
                      ],
                    ),
                  ).animate(delay: 250.ms).fadeIn(),

                  const SizedBox(height: 24),

                  AppButton(
                    label: 'Create Invoice',
                    onPressed: _saveInvoice,
                    isLoading: _isLoading,
                  ).animate(delay: 300.ms).fadeIn(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ── Line Item Row ──────────────────────────────────────────────
class _LineItemRow extends StatefulWidget {
  final _LineItem item;
  final List<Map<String, dynamic>> products;
  final VoidCallback? onDelete;
  final VoidCallback onChanged;
  const _LineItemRow(
      {required this.item,
      required this.products,
      this.onDelete,
      required this.onChanged});

  @override
  State<_LineItemRow> createState() => _LineItemRowState();
}

class _LineItemRowState extends State<_LineItemRow> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.productName);
    _qtyCtrl =
        TextEditingController(text: widget.item.quantity.toStringAsFixed(0));
    _priceCtrl =
        TextEditingController(text: widget.item.unitPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Item name / product autocomplete
          Expanded(
            flex: 4,
            child: widget.products.isEmpty
                ? TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Item name',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (v) {
                      widget.item.productName = v;
                      widget.onChanged();
                    },
                  )
                : DropdownButtonFormField<String>(
                    key: ValueKey(widget.item.productId),
                    initialValue: widget.item.productId.isEmpty
                        ? null
                        : widget.item.productId,
                    hint: const Text('Select', overflow: TextOverflow.ellipsis),
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: '', child: Text('Custom item')),
                      ...widget.products.map((p) => DropdownMenuItem(
                            value: p['id'] as String,
                            child: Text(p['name'] as String,
                                overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (v) {
                      if (v == null || v.isEmpty) {
                        widget.item.productId = '';
                        widget.item.productName = '';
                        widget.item.unitPrice = 0;
                      } else {
                        final p =
                            widget.products.firstWhere((p) => p['id'] == v);
                        widget.item.productId = v;
                        widget.item.productName = p['name'] as String;
                        widget.item.unitPrice =
                            (p['selling_price'] as num).toDouble();
                        _priceCtrl.text =
                            widget.item.unitPrice.toStringAsFixed(2);
                      }
                      widget.onChanged();
                    },
                  ),
          ),
          const SizedBox(width: 8),

          // Quantity
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) {
                widget.item.quantity = double.tryParse(v) ?? 1;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),

          // Unit price
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) {
                widget.item.unitPrice = double.tryParse(v) ?? 0;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 4),

          // Delete
          IconButton(
            icon: Icon(
              Icons.remove_circle_outline,
              color: widget.onDelete != null
                  ? AppTheme.errorColor
                  : AppTheme.lightTextHint,
              size: 20,
            ),
            onPressed: widget.onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.child,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: AppTheme.lightTextSecondary)),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPlaceholder;
  const _DateTile(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.isPlaceholder = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.lightBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: isPlaceholder
                    ? AppTheme.lightTextHint
                    : AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: isPlaceholder ? AppTheme.lightTextHint : null)),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
