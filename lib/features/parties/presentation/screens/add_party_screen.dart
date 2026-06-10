import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_saoji/core/constants/app_constants.dart';
import 'package:smart_saoji/core/services/daily_limit_service.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/core/widgets/app_button.dart';
import 'package:smart_saoji/core/widgets/app_snackbar.dart';
import 'package:smart_saoji/core/widgets/app_text_field.dart';
import 'package:smart_saoji/core/widgets/plan_limit_dialog.dart';
import 'package:smart_saoji/features/parties/data/models/party_model.dart';
import 'package:smart_saoji/features/parties/presentation/screens/parties_screen.dart';
import 'package:smart_saoji/features/parties/presentation/screens/party_detail_screen.dart';
import 'package:smart_saoji/core/l10n/app_strings.dart';
import 'package:smart_saoji/features/subscription/data/services/subscription_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';


class AddPartyScreen extends ConsumerStatefulWidget {
  /// If non-null the screen runs in edit mode and pre-fills all fields.
  final Party? existingParty;
  const AddPartyScreen({super.key, this.existingParty});

  @override
  ConsumerState<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends ConsumerState<AddPartyScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _openingBalCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  String _type = AppConstants.partyCustomer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingParty;
    if (p != null) {
      _nameCtrl.text = p.name;
      _phoneCtrl.text = p.phone ?? '';
      _emailCtrl.text = p.email ?? '';
      _addressCtrl.text = p.address ?? '';
      _openingBalCtrl.text = p.openingBalance.toStringAsFixed(0);
      _notesCtrl.text = p.notes ?? '';
      _type = p.type;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _openingBalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Name is required', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final isEdit = widget.existingParty != null;

      if (isEdit) {
        // ── UPDATE existing party via RPC ──────────────────
        await Supabase.instance.client.rpc('update_party', params: {
          'p_party_id': widget.existingParty!.id,
          'p_name': _nameCtrl.text.trim(),
          'p_phone': _phoneCtrl.text.trim().isEmpty
              ? null
              : _phoneCtrl.text.trim(),
          'p_email': _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
          'p_address': _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
          'p_type': _type,
          'p_notes': _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        });

        if (mounted) {
          ref.invalidate(partiesProvider);
          ref.invalidate(partyDetailProvider(widget.existingParty!.id));
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Party updated!',
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
      } else {
        // ── INSERT new party ───────────────────────────────
        final prefs = await SharedPreferences.getInstance();
        final businessId =
            prefs.getString(AppConstants.kSelectedBusinessId) ?? '';

        final planCode = ref.read(subscriptionManagerProvider).planCode;
        final limitResult = await DailyLimitService.instance
            .checkLimit(planCode, 'parties');
        if (!limitResult.allowed) {
          if (mounted) {
            await PlanLimitDialog.showDailyLimitReached(
              context,
              planCode: planCode,
              action: 'parties',
              limit: limitResult.limit!,
              used: limitResult.used,
            );
          }
          return;
        }

        final opening = double.tryParse(_openingBalCtrl.text) ?? 0;
        final now = DateTime.now().toIso8601String();
        await Supabase.instance.client.from('parties').insert({
          'id': const Uuid().v4(),
          'business_id': businessId,
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim().isEmpty
              ? null
              : _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
          'address': _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
          'type': _type,
          'opening_balance': opening,
          'current_balance': opening,
          'notes': _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
          'created_at': now,
          'updated_at': now,
        });

        await DailyLimitService.instance.increment(planCode, 'parties');

        if (mounted) {
          ref.invalidate(partiesProvider);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Party added successfully!',
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
    final isEdit = widget.existingParty != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? context.l10n.editParty : context.l10n.addParty)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            Text(context.l10n.partyType, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeChip(
                    label: context.l10n.customer,
                    value: AppConstants.partyCustomer,
                    selected: _type,
                    onTap: (v) => setState(() => _type = v)),
                const SizedBox(width: 10),
                _TypeChip(
                    label: context.l10n.supplier,
                    value: AppConstants.partySupplier,
                    selected: _type,
                    onTap: (v) => setState(() => _type = v)),
                const SizedBox(width: 10),
                _TypeChip(
                    label: context.l10n.both,
                    value: AppConstants.partyBoth,
                    selected: _type,
                    onTap: (v) => setState(() => _type = v)),
              ],
            ).animate().fadeIn(),
            const SizedBox(height: 20),
            _label(context, '${context.l10n.name} *'),
            AppTextField(
                controller: _nameCtrl,
                hint: context.l10n.fullNameOrBusinessName,
                prefixIcon: Icons.person_outline),
            const SizedBox(height: 16),
            _label(context, context.l10n.phoneNumber),
            AppTextField(
                controller: _phoneCtrl,
                hint: '98XXXXXXXX',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined),
            const SizedBox(height: 16),
            _label(context, context.l10n.email),
            AppTextField(
                controller: _emailCtrl,
                hint: 'email@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined),
            const SizedBox(height: 16),
            _label(context, context.l10n.address),
            AppTextField(
                controller: _addressCtrl,
                hint: 'Street, City',
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2),
            const SizedBox(height: 16),
            _label(context, '${context.l10n.openingBalance} (Rs.)'),
            AppTextField(
                controller: _openingBalCtrl,
                hint: '0',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.account_balance_wallet_outlined),
            const SizedBox(height: 8),
            Text(
              context.l10n.positiveNegNotes,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _label(context, '${context.l10n.notes} (${context.l10n.optional})'),
            AppTextField(
                controller: _notesCtrl,
                hint: context.l10n.anyAdditionalNotes,
                maxLines: 3),
            const SizedBox(height: 32),
            AppButton(
                label: isEdit ? context.l10n.saveChanges : context.l10n.addParty,
                onPressed: _save,
                isLoading: _isLoading,
                icon: isEdit ? Icons.save_rounded : Icons.person_add_rounded),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label, value, selected;
  final void Function(String) onTap;
  const _TypeChip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.lightBorder,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.lightTextSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            )),
      ),
    );
  }
}
