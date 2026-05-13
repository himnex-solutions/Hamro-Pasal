import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _GetStartedScreen();
  }
}

class _GetStartedScreen extends StatelessWidget {
  const _GetStartedScreen();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF1AB8C4),
      body: Stack(
        children: [
          // ── Teal gradient background ──────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF14C1CC), Color(0xFF0EA5B0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Subtle circular decorations ───────────────────
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: 30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.15,
            left: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          // ── Shopping-themed watermark icons ───────────────────
          // Storefront — top-right
          Positioned(
            top: screenHeight * 0.04, right: 22,
            child: const Icon(Icons.storefront_outlined,
                color: Colors.white24, size: 56),
          ),
          // Large cart — bottom-left of teal area
          Positioned(
            top: screenHeight * 0.28, left: -8,
            child: const Icon(Icons.shopping_cart_outlined,
                color: Colors.white24, size: 80),
          ),
          // Shopping bag — mid-right
          Positioned(
            top: screenHeight * 0.22, right: 14,
            child: const Icon(Icons.shopping_bag_outlined,
                color: Colors.white12, size: 34),
          ),
          // Price tag — top-center
          Positioned(
            top: screenHeight * 0.02, left: screenHeight * 0.16,
            child: const Icon(Icons.local_offer_outlined,
                color: Colors.white12, size: 28),
          ),
          // Star — mid
          Positioned(
            top: screenHeight * 0.18, left: 22,
            child: const Icon(Icons.star_outline_rounded,
                color: Colors.white12, size: 26),
          ),

          // ── Main content ──────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Illustration area (top teal section) ──
                Expanded(
                  flex: 55,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _IllustrationWidget()
                        .animate()
                        .fadeIn(duration: 700.ms)
                        .slideY(begin: -0.05, end: 0),
                  ),
                ),

                // ── White bottom card ─────────────────────
                Expanded(
                  flex: 45,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(36),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // App name
                          const Text(
                            'Hamro Pasal',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0EA5B0),
                              letterSpacing: 1.2,
                            ),
                          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 12),

                          // Headline
                          const Text(
                            "Let's Get You Set Up\nfor Success",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 14),

                          // Subtitle
                          const Text(
                            'Organize your workflow and manage tasks easily\nall in one simple, powerful app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF94A3B8),
                              height: 1.55,
                            ),
                          ).animate(delay: 400.ms).fadeIn(),

                          const Spacer(),

                          // Get Started Button
                          _GetStartedButton(
                            onTap: () => context.go(AppRoutes.login),
                          ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ).animate(delay: 100.ms).slideY(begin: 0.12, end: 0, duration: 500.ms, curve: Curves.easeOut),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Illustration Widget ────────────────────────────────────────
class _IllustrationWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main document card
            Positioned(
              left: 30,
              top: 20,
              child: _IllustrationCard(
                width: 160,
                height: 200,
                color: Colors.white.withValues(alpha: 0.95),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5B0).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Mini chart bars
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _MiniBar(height: 28, color: const Color(0xFF0EA5B0).withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        _MiniBar(height: 44, color: const Color(0xFF0EA5B0).withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        _MiniBar(height: 36, color: const Color(0xFF0EA5B0).withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        const _MiniBar(height: 52, color: Color(0xFF0EA5B0)),
                        const SizedBox(width: 4),
                        _MiniBar(height: 40, color: const Color(0xFF0EA5B0).withValues(alpha: 0.6)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Circle progress indicator
                    Row(
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            value: 0.72,
                            strokeWidth: 4,
                            backgroundColor: Colors.grey.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0EA5B0)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 6,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 6,
                              width: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5B0).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Second overlapping card
            Positioned(
              right: 20,
              top: 50,
              child: _IllustrationCard(
                width: 130,
                height: 145,
                color: const Color(0xFF0EA5B0).withValues(alpha: 0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 8,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 6,
                      width: 55,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 6,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 6,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Person illustration (left) — simple geometric
            const Positioned(
              bottom: 10,
              left: 20,
              child: _PersonFigure(isLeft: true),
            ),

            // Person illustration (right)
            const Positioned(
              bottom: 20,
              right: 15,
              child: _PersonFigure(isLeft: false),
            ),

            // Lightbulb icon top-left
            Positioned(
              top: 15,
              left: 10,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    size: 17, color: Color(0xFFF59E0B)),
              ),
            ),

            // Settings icon top-right
            Positioned(
              top: 0,
              right: 50,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings_outlined,
                    size: 16, color: Color(0xFF0EA5B0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final Widget child;
  const _IllustrationCard({
    required this.width,
    required this.height,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double height;
  final Color color;
  const _MiniBar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

class _PersonFigure extends StatelessWidget {
  final bool isLeft;
  const _PersonFigure({required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: isLeft ? 1 : -1,
      child: Column(
        children: [
          // Head
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Color(0xFFFBD0A0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 2),
          // Body
          Container(
            width: 22,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 2),
          // Legs
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF374151).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF374151).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Get Started Button ─────────────────────────────────────────
class _GetStartedButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GetStartedButton({required this.onTap});

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _pressed
                  ? [const Color(0xFF0B8E99), const Color(0xFF0AABB8)]
                  : [const Color(0xFF0EA5B0), const Color(0xFF14C1CC)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF0EA5B0).withValues(alpha: 0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: const Center(
            child: Text(
              'Get started',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
