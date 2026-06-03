import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
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
      'image': 'assets/images/onboarding_billing.png',
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
      'image': 'assets/images/onboarding_reminders.png',
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
      'image': 'assets/images/onboarding_insights.png',
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
      backgroundColor: Colors.white,
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
                  isLight: true,
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppTheme.cardShadow(
                                AppTheme.primaryColor,
                                opacity: 0.2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                  ),
                                  child: const Icon(
                                    Icons.store_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Hamro Pasal',
                            style: TextStyle(
                              color: Color(0xFF0D7E8A),
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
                            foregroundColor: const Color(0xFF94A3B8),
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
                          final orbitSize = isCompact ? 210.0 : 290.0;
                          final innerOrbitSize = isCompact ? 170.0 : 240.0;
                          final auraSize = isCompact ? 140.0 : 200.0;
                          final ringSize = isCompact ? 120.0 : 170.0;
                          final spacing = isCompact ? 16.0 : 36.0;

                          return Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: isCompact ? 8 : 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: isCompact ? 8 : 16),
                                // ── Concrete Illustration Group with Orbit Animations ──
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

                                    // 4. Glass ring
                                    Container(
                                      width: ringSize,
                                      height: ringSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: accentColor.withValues(alpha: 0.25),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),

                                    // 5. Concrete PNG Illustration with float animation
                                    Container(
                                      height: isCompact ? 160.0 : 220.0,
                                      constraints: BoxConstraints(
                                        maxWidth: isCompact ? 240.0 : 320.0,
                                      ),
                                      child: Image.asset(
                                        slide['image'] as String,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: isCompact ? 120.0 : 160.0,
                                          height: isCompact ? 120.0 : 160.0,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: AppTheme.primaryGradient,
                                            boxShadow: AppTheme.glowShadow(
                                              accentColor,
                                              opacity: 0.3,
                                            ),
                                          ),
                                          child: Icon(
                                            slide['icon'] as IconData,
                                            size: isCompact ? 50.0 : 70.0,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                        .animate(
                                            onPlay: (controller) => controller
                                                .repeat(reverse: true))
                                        .moveY(
                                            begin: -8,
                                            end: 8,
                                            duration: 2000.ms,
                                            curve: Curves.easeInOut),
                                  ],
                                )
                                    .animate()
                                    .fadeIn(duration: 500.ms)
                                    .scale(
                                        begin: const Offset(0.75, 0.75),
                                        duration: 500.ms,
                                        curve: Curves.easeOutBack),
                                SizedBox(height: spacing),

                                // ── Glassmorphic Text Card ──────────────────
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 12, sigmaY: 12),
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(isCompact ? 20 : 28),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.70),
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color: const Color(0xFF0D7E8A)
                                              .withValues(alpha: 0.10),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0D7E8A)
                                                .withValues(alpha: 0.04),
                                            blurRadius: 40,
                                            offset: const Offset(0, 16),
                                            spreadRadius: -4,
                                          ),
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.015),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
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
                                              color: const Color(0xFF07242B),
                                              fontSize: isCompact ? 22 : 26,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.6,
                                              height: 1.25,
                                            ),
                                          ).animate().fadeIn().slideY(
                                              begin: 0.2,
                                              end: 0,
                                              duration: 400.ms),
                                          SizedBox(height: isCompact ? 10 : 14),
                                          Text(
                                            slide['desc'] as String,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: const Color(0xFF475569),
                                              fontSize: isCompact ? 13.5 : 15.0,
                                              fontWeight: FontWeight.w400,
                                              height: 1.6,
                                            ),
                                          )
                                              .animate()
                                              .fadeIn(delay: 150.ms)
                                              .slideY(
                                                  begin: 0.15,
                                                  end: 0,
                                                  duration: 450.ms),
                                          if (!isCompact) ...[
                                            const SizedBox(height: 22),
                                            const Divider(
                                              color: Color(0xFFE2E8F0),
                                              thickness: 1.2,
                                            ),
                                            const SizedBox(height: 18),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  left: BorderSide(
                                                    color:
                                                        accentColor.withValues(
                                                            alpha: 0.35),
                                                    width: 3.5,
                                                  ),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    slide['quote'] as String,
                                                    style: const TextStyle(
                                                      color: Color(0xFF334155),
                                                      fontSize: 13.5,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      height: 1.55,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '— ${slide['author']}',
                                                    style: TextStyle(
                                                      color: accentColor
                                                          .withValues(
                                                              alpha: 0.9),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                ],
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
                    12,
                    28,
                    MediaQuery.of(context).size.height < 600 ? 12 : 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_currentIndex == _slides.length - 1) ...[
                        // ── Last page: centered dots + full-width CTA ──
                        SmoothPageIndicator(
                          controller: _pageCtrl,
                          count: _slides.length,
                          effect: ExpandingDotsEffect(
                            activeDotColor:
                                _slides[_currentIndex]['color'] as Color,
                            dotColor: const Color(0xFFE2E8F0),
                            dotHeight: 7,
                            dotWidth: 7,
                            expansionFactor: 4.0,
                            spacing: 6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
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
                      ] else ...[
                        // ── Pages 1 & 2: Back (left) | Dots (center) | Next (right) ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left: Back button (invisible on page 0 but keeps space)
                            SizedBox(
                              width: 60,
                              height: 44,
                              child: _currentIndex > 0
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(
                                        onPressed: () => _pageCtrl.previousPage(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFF94A3B8),
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(44, 44),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'Back',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // Center: SmoothPageIndicator
                            SmoothPageIndicator(
                              controller: _pageCtrl,
                              count: _slides.length,
                              effect: ExpandingDotsEffect(
                                activeDotColor: _slides[_currentIndex]['color'] as Color,
                                dotColor: const Color(0xFFE2E8F0),
                                dotHeight: 7,
                                dotWidth: 7,
                                expansionFactor: 4.0,
                                spacing: 6,
                              ),
                            ),

                            // Right: Next arrow button (no shadow)
                            SizedBox(
                              width: 60,
                              height: 44,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  onPressed: () => _pageCtrl.nextPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: _slides[_currentIndex]['color'] as Color,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                    minimumSize: const Size(44, 44),
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

