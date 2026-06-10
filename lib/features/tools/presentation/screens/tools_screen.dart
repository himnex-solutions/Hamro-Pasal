import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_saoji/core/router/app_router.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/core/l10n/app_strings.dart';
import 'package:smart_saoji/features/subscription/data/services/subscription_manager.dart';
import 'package:smart_saoji/core/widgets/plan_limit_dialog.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plan = ref.watch(subscriptionManagerProvider).planCode;
    final canUseThermal = plan == 'gold' || plan == 'diamond';
    final isBasic = plan == 'basic';
    final isNe = context.l10n.isNepali;

    final tools = [
      _ToolItem(
        title: context.l10n.dailyCalculator,
        subtitle: context.l10n.dailyCalculatorDesc,
        icon: Icons.calculate_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF2537D5), Color(0xFFD362EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: AppRoutes.calculator,
      ),
      _ToolItem(
        title: context.l10n.emiCalculator,
        subtitle: context.l10n.emiCalculatorDesc,
        icon: Icons.account_balance_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: AppRoutes.emiCalculator,
      ),
      _ToolItem(
        title: context.l10n.thermalLabelPrinter,
        subtitle: canUseThermal
            ? (plan == 'diamond'
                ? (isNe ? '💎 असीमित प्रिन्ट · वेब र डेस्कटप' : '💎 Unlimited prints · Web & Desktop')
                : (isNe ? '🥇 गोल्ड · १० प्रिन्ट/दिन · वेब र डेस्कटप' : '🥇 Gold · 10 prints/day · Web & Desktop'))
            : (isNe ? '🔒 गोल्ड र डाइमण्ड · सामान लेबल र बारकोड प्रिन्ट' : '🔒 Gold & Diamond · Print product labels & barcodes'),
        icon: Icons.label_important_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: AppRoutes.thermalLabel,
        planBadge: plan == 'diamond' ? '💎' : plan == 'gold' ? '🥇' : '🔒',
        showLock: isBasic,
      ),

      _ToolItem(
        title: context.l10n.comingSoon,
        subtitle: context.l10n.comingSoonDesc,
        icon: Icons.more_horiz_rounded,
        gradient: LinearGradient(
          colors: [Colors.grey.shade400, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: null,
        locked: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.businessTools),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.glowShadow(AppTheme.primaryColor, opacity: 0.28),
            ),
            child: Row(
              children: [
                const Icon(Icons.build_rounded, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.toolsForBusiness,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.toolsDesc,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.05, end: 0),

          // Tool Cards
          ...tools.asMap().entries.map((e) {
            final tool = e.value;
            final delay = Duration(milliseconds: 80 + e.key * 80);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ToolCard(
                tool: tool,
                isDark: isDark,
                onTap: tool.locked
                    ? null
                    : (tool.showLock
                        ? () => PlanLimitDialog.showDiamondFeatureRequired(
                              context,
                              featureName: 'Thermal Printer Settings',
                            )
                        : () => context.push(tool.route!)),
              ),
            ).animate().fadeIn(delay: delay).slideY(begin: 0.06, end: 0);
          }),
        ],
      ),
    );
  }
}

class _ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final String? route;
  final String? planBadge;
  final bool locked;
  final bool showLock;

  const _ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.route,
    this.planBadge,
    this.locked = false,
    this.showLock = false,
  });
}

class _ToolCard extends StatefulWidget {
  final _ToolItem tool;
  final bool isDark;
  final VoidCallback? onTap;
  const _ToolCard(
      {required this.tool, required this.isDark, required this.onTap});

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? AppTheme.primaryColor.withValues(alpha: 0.4)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? AppTheme.cardShadow(AppTheme.primaryColor, opacity: 0.1)
                : AppTheme.cardShadow(Colors.black, opacity: 0.04),
          ),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: widget.tool.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.tool.gradient as LinearGradient)
                          .colors[0]
                          .withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.tool.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.tool.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: widget.tool.locked
                                ? AppTheme.lightTextHint
                                : null,
                          ),
                        ),
                        if (widget.tool.planBadge != null && widget.tool.planBadge == '🔒') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star_rounded, size: 10, color: AppTheme.warningColor),
                                SizedBox(width: 2),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.warningColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.tool.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.tool.planBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.tool.planBadge == '💎'
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.12)
                        : widget.tool.planBadge == '🥇'
                            ? const Color(0xFFD97706).withValues(alpha: 0.12)
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.tool.planBadge!,
                    style: const TextStyle(fontSize: 16),
                  ),
                )
              else if (!widget.tool.locked)
                Icon(
                  Icons.chevron_right_rounded,
                  color: _hovered
                      ? AppTheme.primaryColor
                      : AppTheme.lightTextHint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
