import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/core/widgets/app_button.dart';
import 'package:smart_saoji/core/widgets/app_snackbar.dart';
import 'package:smart_saoji/core/widgets/app_text_field.dart';
import 'package:smart_saoji/features/invoices/data/services/invoice_settings_service.dart';
import 'package:smart_saoji/features/subscription/data/services/subscription_manager.dart';
import 'package:smart_saoji/core/l10n/app_strings.dart';

import 'package:smart_saoji/core/widgets/plan_limit_dialog.dart';

class InvoiceSettingsScreen extends ConsumerStatefulWidget {
  const InvoiceSettingsScreen({super.key});

  @override
  ConsumerState<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends ConsumerState<InvoiceSettingsScreen> {
  late TextEditingController _prefixCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _footerCtrl;
  String _selectedColorHex = '#6366F1';
  bool _showTax = true;
  bool _showDiscount = true;
  String _printTemplate = 'a4';

  final List<Map<String, String>> _colors = [
    {'name': 'Indigo', 'hex': '#6366F1'},
    {'name': 'Emerald', 'hex': '#10B981'},
    {'name': 'Amber', 'hex': '#F59E0B'},
    {'name': 'Rose', 'hex': '#F43F5E'},
    {'name': 'Slate', 'hex': '#64748B'},
  ];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(invoiceSettingsProvider);
    _prefixCtrl = TextEditingController(text: settings.prefix);
    _titleCtrl = TextEditingController(text: settings.title);
    _footerCtrl = TextEditingController(text: settings.footerNote);
    _selectedColorHex = settings.themeColorHex;
    _showTax = settings.showTax;
    _showDiscount = settings.showDiscount;
    _printTemplate = settings.printTemplate;
  }

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _titleCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final settings = ref.read(invoiceSettingsProvider);
    final updated = settings.copyWith(
      prefix: _prefixCtrl.text.trim().toUpperCase(),
      title: _titleCtrl.text.trim(),
      footerNote: _footerCtrl.text.trim(),
      themeColorHex: _selectedColorHex,
      showTax: _showTax,
      showDiscount: _showDiscount,
      printTemplate: _printTemplate,
    );

    ref.read(invoiceSettingsProvider.notifier).updateSettings(updated);
    AppSnackbar.show(context, 'Invoice settings saved successfully!', isSuccess: true);
    context.pop();
  }

  void _showUpgradeDialog(String feature) {
    String label = feature;
    if (feature == 'transaction_prefixes') {
      label = 'Custom Invoice Prefix';
    } else if (feature == 'invoice_customization') {
      label = 'Invoice Style Customization';
    } else if (feature == 'thermal_printing') {
      label = 'Thermal Printing Template';
    }
    PlanLimitDialog.showDiamondFeatureRequired(
      context,
      featureName: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(subscriptionManagerProvider);
    
    // Feature Permissions
    final hasPrefix = manager.checkFeatureAccess('transaction_prefixes');
    final hasCustomization = manager.checkFeatureAccess('invoice_customization');
    final hasThermal = manager.checkFeatureAccess('thermal_printing');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Customization'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _save,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Transaction Prefix
          _CardContainer(
            title: 'Transaction Prefix',
            icon: Icons.code_rounded,
            isLocked: !hasPrefix,
            onLockTap: () => _showUpgradeDialog('transaction_prefixes'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set the default prefix for generated invoice numbers (e.g., INV, REC, TX).',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _prefixCtrl,
                  hint: 'e.g. INV',
                  enabled: hasPrefix,
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.05, end: 0),

          const SizedBox(height: 16),

          // Section 2: Layout & Aesthetics (Customization)
          _CardContainer(
            title: 'Invoice Style & Aesthetics',
            icon: Icons.palette_outlined,
            isLocked: !hasCustomization,
            onLockTap: () => _showUpgradeDialog('invoice_customization'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose theme color for pdf invoices:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _colors.map((c) {
                    final isSel = _selectedColorHex == c['hex'];
                    final color = Color(int.parse(c['hex']!.replaceFirst('#', '0xFF')));
                    return GestureDetector(
                      onTap: hasCustomization ? () => setState(() => _selectedColorHex = c['hex']!) : null,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                        child: isSel ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Default Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _titleCtrl,
                  hint: 'e.g. TAX INVOICE',
                  enabled: hasCustomization,
                ),
                const SizedBox(height: 16),
                const Text('Footer terms or Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _footerCtrl,
                  hint: 'Thank you for your business!',
                  enabled: hasCustomization,
                  maxLines: 2,
                ),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 16),

          // Section 3: Show/Hide Fields
          _CardContainer(
            title: 'Invoice Fields visibility',
            icon: Icons.visibility_outlined,
            isLocked: !hasCustomization,
            onLockTap: () => _showUpgradeDialog('invoice_customization'),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Show Tax Column'),
                  subtitle: const Text('Display tax percent & tax calculations'),
                  value: _showTax,
                  onChanged: hasCustomization ? (v) => setState(() => _showTax = v) : null,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile.adaptive(
                  title: const Text('Show Discount Column'),
                  subtitle: const Text('Display line item and summary discount info'),
                  value: _showDiscount,
                  onChanged: hasCustomization ? (v) => setState(() => _showDiscount = v) : null,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ).animate(delay: 150.ms).fadeIn(),

          const SizedBox(height: 16),

          // Section 4: Print Paper Templates
          _CardContainer(
            title: 'Print Page Template',
            icon: Icons.print_outlined,
            isLocked: !hasThermal,
            onLockTap: () => _showUpgradeDialog('thermal_printing'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select template format optimized for your printer hardware.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _printTemplate,
                  items: const [
                    DropdownMenuItem(value: 'a4', child: Text('Standard A4 Page')),
                    DropdownMenuItem(value: 'a5', child: Text('A5 Statement Page')),
                    DropdownMenuItem(value: 'thermal_58', child: Text('Thermal Receipt (58mm)')),
                    DropdownMenuItem(value: 'thermal_80', child: Text('Thermal Receipt (80mm)')),
                  ],
                  onChanged: hasThermal ? (v) => setState(() => _printTemplate = v!) : null,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(),

          const SizedBox(height: 24),

          AppButton(
            label: 'Save Preferences',
            onPressed: _save,
          ).animate(delay: 250.ms).fadeIn(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isLocked;
  final VoidCallback? onLockTap;

  const _CardContainer({
    required this.title,
    required this.icon,
    required this.child,
    this.isLocked = false,
    this.onLockTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardTheme.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const Divider(height: 24),
              child,
            ],
          ),
        ),
        if (isLocked)
          Positioned.fill(
            child: Material(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onLockTap,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.premiumFeature,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
