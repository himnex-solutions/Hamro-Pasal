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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF1AB8C4),
      body: Stack(
        children: [
          // ── Ultra-Professional Mesh Gradient Background ──────────
          Container(color: const Color(0xFF0EA5B0)),

          // Soft ambient glow 1 (Top Left)
          Positioned(
            top: -screenHeight * 0.1,
            left: -screenWidth * 0.2,
            child: Container(
              width: screenWidth * 1.2,
              height: screenWidth * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF14C1CC).withValues(alpha: 0.9),
                    const Color(0xFF14C1CC).withValues(alpha: 0.0),
                  ],
                ),
              ),
            )
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(
                    begin: 1.0,
                    end: 1.1,
                    duration: 7.seconds,
                    curve: Curves.easeInOut),
          ),

          // Soft ambient glow 2 (Bottom Right)
          Positioned(
            bottom: screenHeight * 0.2,
            right: -screenWidth * 0.3,
            child: Container(
              width: screenWidth * 1.4,
              height: screenWidth * 1.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF098A94).withValues(alpha: 0.8),
                    const Color(0xFF098A94).withValues(alpha: 0.0),
                  ],
                ),
              ),
            )
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .moveX(
                    begin: 0,
                    end: -40,
                    duration: 8.seconds,
                    curve: Curves.easeInOut)
                .scaleXY(
                    begin: 1.0,
                    end: 1.15,
                    duration: 8.seconds,
                    curve: Curves.easeInOut),
          ),

          // ── Main content ──────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top: Clean Minimalist Space ──────────────────
                const Expanded(
                  flex: 55,
                  child: SizedBox(),
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
                          )
                              .animate(delay: 200.ms)
                              .fadeIn()
                              .slideY(begin: 0.2, end: 0),

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
                          )
                              .animate(delay: 300.ms)
                              .fadeIn()
                              .slideY(begin: 0.2, end: 0),

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
                          )
                              .animate(delay: 500.ms)
                              .fadeIn()
                              .slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ).animate(delay: 100.ms).slideY(
                      begin: 0.12,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOut),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// _IllustrationWidget removed (was unused)

// Unused illustration widgets removed
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
