import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/poly_mesh_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Precision POS & Billing',
      'desc':
          'Unleash complete control over your store. Record sales, purchases, and keep tab of every transaction effortlessly.',
      'quote':
          '"Do not save what is left after spending; spend what is left after saving."',
      'author': 'Warren Buffett',
      'icon': Icons.storefront_rounded,
      'color': AppTheme.primaryLight, // Teal primary accent
    },
    {
      'title': 'Automated Credit Reminders',
      'desc':
          'Never lose track of outstanding balances. Get instant realtime system reminders to pay suppliers and collect client dues.',
      'quote':
          '"The key to wealth is not how much you make, but how much you keep."',
      'author': 'Financial Wisdom',
      'icon': Icons.notifications_active_rounded,
      'color': AppTheme.accentColor, // Glowing warm cyan accent
    },
    {
      'title': 'Profit Insights & Stock',
      'desc':
          'Realtime low stock alerts paired with comprehensive margin analyses. Watch your profits grow with concrete reports.',
      'quote':
          '"Beware of little expenses; a small leak will sink a great ship."',
      'author': 'Benjamin Franklin',
      'icon': Icons.query_stats_rounded,
      'color': const Color(0xFF1DD8E8), // Glowing cyan
    },
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.kOnboardingDone, true);
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // ── Dynamic Glowing Background (Transitions with Swipe) ──
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              end: _slides[_currentIndex]['color'] as Color,
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, color, child) {
              return Positioned.fill(
                child: PolyMeshBackground(
                  accentColor: color,
                ),
              );
            },
          ),

          // ── Main Page Content ──────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top Header (Skip button + App logo)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppTheme.cardShadow(
                                AppTheme.primaryColor,
                                opacity: 0.3,
                              ),
                            ),
                            child: const Icon(
                              Icons.store_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Hamro Pasal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      if (_currentIndex < _slides.length - 1)
                        TextButton(
                          onPressed: _finishOnboarding,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.45),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Sliding views
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (idx) => setState(() => _currentIndex = idx),
                    itemCount: _slides.length,
                    itemBuilder: (context, idx) {
                      final slide = _slides[idx];
                      final Color accentColor = slide['color'] as Color;

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxHeight < 580;
                          final orbitSize = isCompact ? 130.0 : 185.0;
                          final innerOrbitSize = isCompact ? 100.0 : 145.0;
                          final auraSize = isCompact ? 80.0 : 115.0;
                          final ringSize = isCompact ? 70.0 : 100.0;
                          final coreSize = isCompact ? 56.0 : 80.0;
                          final coreIconSize = isCompact ? 26.0 : 36.0;
                          final spacing = isCompact ? 16.0 : 36.0;

                          return Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: isCompact ? 8 : 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: isCompact ? 8 : 16),
                                // ── Premium Double-Orbit Illustration ─────
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // 1. Outer Orbit (Clockwise rotation)
                                    CustomPaint(
                                      size: Size(orbitSize, orbitSize),
                                      painter: OrbitPainter(
                                        color: accentColor,
                                        dashCount: isCompact ? 24 : 32,
                                        dotCount: 3,
                                        dotSize: isCompact ? 2.5 : 3.5,
                                      ),
                                    )
                                        .animate(
                                            onPlay: (controller) =>
                                                controller.repeat())
                                        .rotate(duration: 15.seconds),

                                    // 2. Inner Orbit (Counter-clockwise rotation)
                                    CustomPaint(
                                      size: Size(innerOrbitSize, innerOrbitSize),
                                      painter: OrbitPainter(
                                        color: accentColor,
                                        dashCount: isCompact ? 18 : 22,
                                        dotCount: 2,
                                        dotSize: isCompact ? 2.0 : 2.5,
                                      ),
                                    )
                                        .animate(
                                            onPlay: (controller) =>
                                                controller.repeat())
                                        .rotate(
                                            duration: 10.seconds,
                                            begin: 1.0,
                                            end: 0.0), // reverse

                                    // 3. Pulsing aura
                                    Container(
                                      width: auraSize,
                                      height: auraSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accentColor.withValues(alpha: 0.08),
                                      ),
                                    )
                                        .animate(
                                            onPlay: (controller) =>
                                                controller.repeat(reverse: true))
                                        .scale(
                                            begin: const Offset(0.85, 0.85),
                                            end: const Offset(1.15, 1.15),
                                            duration: 2.seconds,
                                            curve: Curves.easeInOut),

                                    // 4. Glowing inner ring
                                    Container(
                                      width: ringSize,
                                      height: ringSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              accentColor.withValues(alpha: 0.25),
                                          width: 2.0,
                                        ),
                                      ),
                                    ),

                                    // 5. Core badge icon
                                    Container(
                                      width: coreSize,
                                      height: coreSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            accentColor,
                                            accentColor.withValues(alpha: 0.7)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: AppTheme.glowShadow(
                                          accentColor,
                                          opacity: 0.35,
                                        ),
                                      ),
                                      child: Icon(
                                        slide['icon'] as IconData,
                                        size: coreIconSize,
                                        color: Colors.white,
                                      ),
                                    )
                                        .animate()
                                        .scale(
                                            duration: 500.ms,
                                            curve: Curves.elasticOut,
                                            begin: const Offset(0.4, 0.4))
                                        .rotate(
                                            duration: 800.ms,
                                            begin: -0.15,
                                            end: 0,
                                            curve: Curves.easeOut),
                                  ],
                                ),
                                SizedBox(height: spacing),

                                // ── Glassmorphic Text Card ──────────────────
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 12, sigmaY: 12),
                                    child: Container(
                                      padding: EdgeInsets.all(isCompact ? 16 : 24),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.03),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            slide['title'] as String,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isCompact ? 20 : 24,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5,
                                            ),
                                          ).animate().fadeIn().slideY(
                                              begin: 0.2, end: 0, duration: 400.ms),
                                          SizedBox(height: isCompact ? 8 : 12),
                                          Text(
                                            slide['desc'] as String,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.55),
                                              fontSize: isCompact ? 13.0 : 14.5,
                                              height: 1.5,
                                            ),
                                          ).animate().fadeIn(delay: 150.ms).slideY(
                                              begin: 0.15, end: 0, duration: 450.ms),
                                          if (!isCompact) ...[
                                            const SizedBox(height: 20),
                                            Divider(
                                              color: Colors.white.withValues(alpha: 0.08),
                                              thickness: 1,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              slide['quote'] as String,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                                fontStyle: FontStyle.italic,
                                                height: 1.5,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '— ${slide['author']}',
                                              style: TextStyle(
                                                color: accentColor.withValues(alpha: 0.8),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 200.ms)
                                    .scale(duration: 400.ms),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Dot Indicators + Navigation Control Panel
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    28,
                    16,
                    28,
                    MediaQuery.of(context).size.height < 600 ? 16 : 32,
                  ),
                  child: Column(
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (idx) {
                          final isActive = _currentIndex == idx;
                          final accent =
                              _slides[_currentIndex]['color'] as Color;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isActive ? 24 : 6,
                            decoration: BoxDecoration(
                              color: isActive ? accent : Colors.white24,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: accent.withValues(alpha: 0.5),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height < 600 ? 12 : 32,
                      ),

                      // Actions Button
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: _currentIndex == _slides.length - 1
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _finishOnboarding,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white.withValues(alpha: 0.4),
                              ),
                              child: const Text(
                                'SKIP',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: AppTheme.glowShadow(
                                  _slides[_currentIndex]['color'] as Color,
                                  opacity: 0.3,
                                ),
                              ),
                              child: FloatingActionButton(
                                onPressed: () {
                                  _pageCtrl.nextPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                backgroundColor:
                                    _slides[_currentIndex]['color'] as Color,
                                shape: const CircleBorder(),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        secondChild: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(27),
                            boxShadow: AppTheme.glowShadow(
                              AppTheme.primaryColor,
                              opacity: 0.35,
                            ),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _finishOnboarding,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(
                              Icons.rocket_launch_rounded,
                              size: 20,
                            ),
                            label: const Text(
                              'Get Started Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Orbit Painter — Dotted orbits with orbiting nodes
// ─────────────────────────────────────────────────────────────

class OrbitPainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final int dotCount;
  final double dotSize;

  const OrbitPainter({
    required this.color,
    this.dashCount = 24,
    this.dotCount = 3,
    this.dotSize = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw dashed ring
    final paint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const double totalAngle = 2 * pi;
    final double dashAngle = totalAngle / dashCount;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          i * dashAngle,
          dashAngle,
          false,
          paint,
        );
      }
    }

    // 2. Draw dots on the ring
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < dotCount; i++) {
      final double angle = i * (totalAngle / dotCount);
      final double x = center.dx + radius * cos(angle);
      final double y = center.dy + radius * sin(angle);

      // Glow under the dot
      canvas.drawCircle(
        Offset(x, y),
        dotSize * 2.2,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      // Core dot
      canvas.drawCircle(Offset(x, y), dotSize, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant OrbitPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashCount != dashCount ||
        oldDelegate.dotCount != dotCount ||
        oldDelegate.dotSize != dotSize;
  }
}
