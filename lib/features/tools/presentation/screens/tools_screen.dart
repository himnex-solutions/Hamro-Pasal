import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tools = [
      const _ToolItem(
        title: 'Daily Calculator',
        subtitle: 'Standard arithmetic for quick calculations',
        icon: Icons.calculate_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFF2537D5), Color(0xFFD362EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: AppRoutes.calculator,
      ),
      const _ToolItem(
        title: 'EMI Calculator',
        subtitle: 'Loan EMI with full amortization schedule',
        icon: Icons.account_balance_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: AppRoutes.emiCalculator,
      ),
      _ToolItem(
        title: 'Coming Soon',
        subtitle: 'GST Calculator, Currency Converter & more',
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
        title: const Text('Business Tools'),
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
                      const Text(
                        'Tools for your Business',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'EMI, calculator & more — all in one place',
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
                onTap: tool.route == null
                    ? null
                    : () => context.push(tool.route!),
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
  final bool locked;

  const _ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.route,
    this.locked = false,
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
            color: widget.tool.locked
                ? (isDark
                    ? AppTheme.darkSurface.withValues(alpha: 0.5)
                    : Colors.grey.shade50)
                : (isDark ? AppTheme.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered && !widget.tool.locked
                  ? AppTheme.primaryColor.withValues(alpha: 0.4)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              width: _hovered && !widget.tool.locked ? 1.5 : 1,
            ),
            boxShadow: _hovered && !widget.tool.locked
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
                  boxShadow: widget.tool.locked
                      ? null
                      : [
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
              if (!widget.tool.locked)
                Icon(
                  Icons.chevron_right_rounded,
                  color: _hovered
                      ? AppTheme.primaryColor
                      : AppTheme.lightTextHint,
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Soon',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.lightTextHint,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
