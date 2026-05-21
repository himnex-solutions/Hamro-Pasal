import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/router/app_router.dart';

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
      'color': const Color(0xFF3B82F6), // Blue
    },
    {
      'title': 'Automated Credit Reminders',
      'desc':
          'Never lose track of outstanding balances. Get instant realtime system reminders to pay suppliers and collect client dues.',
      'quote':
          '"The key to wealth is not how much you make, but how much you keep."',
      'author': 'Financial Wisdom',
      'icon': Icons.notifications_active_rounded,
      'color': const Color(0xFFF59E0B), // Amber
    },
    {
      'title': 'Profit Insights & Stock',
      'desc':
          'Realtime low stock alerts paired with comprehensive margin analyses. Watch your profits grow with concrete reports.',
      'quote':
          '"Beware of little expenses; a small leak will sink a great ship."',
      'author': 'Benjamin Franklin',
      'icon': Icons.query_stats_rounded,
      'color': const Color(0xFF8B5CF6), // Purple
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ── Mesh Background Orbs ────────────────────────────
          Positioned(
            top: -screenHeight * 0.1,
            left: -screenWidth * 0.2,
            child: Container(
              width: screenWidth * 1.3,
              height: screenWidth * 1.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E3A8A).withValues(alpha: 0.4),
                    const Color(0xFF1E3A8A).withValues(alpha: 0.0),
                  ],
                ),
              ),
            )
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(
                    begin: 1.0,
                    end: 1.15,
                    duration: 6.seconds,
                    curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: screenHeight * 0.1,
            right: -screenWidth * 0.3,
            child: Container(
              width: screenWidth * 1.5,
              height: screenWidth * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4C1D95).withValues(alpha: 0.35),
                    const Color(0xFF4C1D95).withValues(alpha: 0.0),
                  ],
                ),
              ),
            )
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(
                    begin: 1.0,
                    end: 1.2,
                    duration: 8.seconds,
                    curve: Curves.easeInOut),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.store_rounded,
                                color: Color(0xFF60A5FA), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Hamro Pasal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      if (_currentIndex < _slides.length - 1)
                        TextButton(
                          onPressed: _finishOnboarding,
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.white38),
                          child: const Text(
                            'Skip',
                            style: TextStyle(fontWeight: FontWeight.w600),
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

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ── Decorative Illustration ────────────────
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulsing aura
                                Container(
                                  width: 170,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accentColor.withValues(alpha: 0.08),
                                  ),
                                )
                                    .animate(
                                        onPlay: (controller) =>
                                            controller.repeat(reverse: true))
                                    .scale(
                                        begin: const Offset(0.9, 0.9),
                                        end: const Offset(1.15, 1.15),
                                        duration: 2.seconds,
                                        curve: Curves.easeInOut),

                                // Glowing ring
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          accentColor.withValues(alpha: 0.25),
                                      width: 1.5,
                                    ),
                                  ),
                                ),

                                // Core badge icon
                                Container(
                                  width: 96,
                                  height: 96,
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
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            accentColor.withValues(alpha: 0.35),
                                        blurRadius: 32,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    slide['icon'] as IconData,
                                    size: 42,
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
                            const SizedBox(height: 48),

                            // ── Headline & Desc ────────────────────────
                            Text(
                              slide['title'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            )
                                .animate()
                                .fadeIn()
                                .slideY(begin: 0.2, end: 0, duration: 400.ms),
                            const SizedBox(height: 12),
                            Text(
                              slide['desc'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 13.8,
                                height: 1.5,
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 150.ms)
                                .slideY(begin: 0.15, end: 0, duration: 450.ms),

                            const SizedBox(height: 36),

                            // ── Premium Quotation Card ──────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    slide['quote'] as String,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '— ${slide['author']}',
                                    style: TextStyle(
                                      color: accentColor.withValues(alpha: 0.8),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 250.ms)
                                .scale(duration: 400.ms),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Dot Indicators + Navigation Control Panel
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
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
                            width: isActive ? 20 : 6,
                            decoration: BoxDecoration(
                              color: isActive ? accent : Colors.white24,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),

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
                                  foregroundColor: Colors.white38),
                              child: const Text('SKIP',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                            FloatingActionButton(
                              onPressed: () {
                                _pageCtrl.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                              backgroundColor:
                                  _slides[_currentIndex]['color'] as Color,
                              shape: const CircleBorder(),
                              child: const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        secondChild: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _finishOnboarding,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _slides[_slides.length - 1]['color'] as Color,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.rocket_launch_rounded,
                                size: 20),
                            label: const Text(
                              'Get Started Now',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5),
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
