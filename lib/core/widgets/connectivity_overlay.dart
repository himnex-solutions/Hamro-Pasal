import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_saoji/core/services/sync_service.dart';

/// A global overlay widget that displays a beautiful, one-time top banner
/// when the user opens the app offline.
class ConnectivityOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const ConnectivityOverlay({super.key, required this.child});

  @override
  ConsumerState<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends ConsumerState<ConnectivityOverlay> {
  static bool _hasShownOfflineBanner = false;
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ConnectivityStatus>>(connectivityProvider, (previous, next) {
      if (next is AsyncData<ConnectivityStatus>) {
        final status = next.value;
        if (status == ConnectivityStatus.offline && !_hasShownOfflineBanner) {
          setState(() {
            _hasShownOfflineBanner = true;
            _isVisible = true;
          });

          // Auto dismiss after 6 seconds
          Future.delayed(const Duration(seconds: 6), () {
            if (mounted && _isVisible) {
              setState(() => _isVisible = false);
            }
          });
        }
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        widget.child,
        if (_isVisible)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFFFFBEB), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD97706).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Icon with pulsing warning glow
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: Color(0xFFD97706),
                        size: 24,
                      ),
                    ).animate(onPlay: (controller) => controller.repeat())
                     .shimmer(duration: 1800.ms, color: const Color(0xFFFBBF24)),
                    const SizedBox(width: 14),

                    // Information texts
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Offline Mode Active',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Your changes will be saved locally & synced automatically when online.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Dismiss action button
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white38 : Colors.black38,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _isVisible = false);
                      },
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            ).animate()
             .fadeIn(duration: 400.ms)
             .slideY(begin: -0.5, end: 0, curve: Curves.easeOutBack),
          ),
      ],
    );
  }
}
