import 'package:flutter/material.dart';

class PolyMeshBackground extends StatelessWidget {
  final Widget? child;
  final Color? accentColor;
  final bool isLight;

  // ── Color tokens ────────────
  static const _bgDark1 =
      Color(0xFF1E2ED2); // top-left of dark background gradient (royal blue)
  static const _bgDark2 =
      Color(0xFF6B58F5); // bottom-right of dark background gradient (purple/blue)

  static const _bgLight1 = Color(0xFFFFFFFF); // premium white top-left
  static const _bgLight2 =
      Color(0xFFEEF2FF); // very soft indigo-tint bottom-right

  const PolyMeshBackground({
    super.key,
    this.child,
    this.accentColor,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight ? [_bgLight1, _bgLight2] : [_bgDark1, _bgDark2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: PolyMeshPainter(
                accentColor: accentColor,
                isLight: isLight,
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Abstract blob shape painter — elegant floating shapes
// ─────────────────────────────────────────────────────────────

class PolyMeshPainter extends CustomPainter {
  final Color? accentColor;
  final bool isLight;

  PolyMeshPainter({this.accentColor, this.isLight = false});

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // Use accentColor if provided, otherwise fallback to the default website brand royal blue/purple colors
    final primaryOrbColor = accentColor ?? const Color(0xFF2537D5);
    final secondaryOrbColor = accentColor ?? const Color(0xFFD362EC);
    final midOrbColor = accentColor ?? const Color(0xFF6B58F5);
    final beamColor = accentColor ?? const Color(0xFF2537D5);
    final waveColor1 = accentColor ?? const Color(0xFF6B58F5);
    final waveColor2 = accentColor ?? const Color(0xFFD362EC);
    final ringColor = accentColor ?? const Color(0xFF2537D5);
    final sparkleColor = accentColor ?? const Color(0xFFD362EC);

    if (isLight) {
      // ── Premium Minimalist Light Ambient Aurora Background ──
      // This creates a highly professional, clean visual depth with very large, soft-blurred radial glows.

      // 1. Soft Mint/Cyan Aurora - Top-Right
      _drawOrb(
        canvas,
        center: Offset(W * 1.0, H * -0.05),
        radius: W * 0.90,
        colors: [
          secondaryOrbColor.withValues(alpha: 0.08),
          secondaryOrbColor.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      );

      // 2. Soft Brand Teal Aurora - Bottom-Left
      _drawOrb(
        canvas,
        center: Offset(W * -0.15, H * 0.95),
        radius: W * 1.10,
        colors: [
          primaryOrbColor.withValues(alpha: 0.07),
          primaryOrbColor.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      );

      // 3. Central Ambient Wash - Soft Glow
      _drawOrb(
        canvas,
        center: Offset(W * 0.5, H * 0.45),
        radius: W * 0.70,
        colors: [
          midOrbColor.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      );

      // Elegant, extremely thin and subtle divider line at the bottom for modern detail
      canvas.drawLine(
        Offset(W * 0.1, H * 0.93),
        Offset(W * 0.9, H * 0.93),
        Paint()
          ..color = primaryOrbColor.withValues(alpha: 0.06)
          ..strokeWidth = 1.0,
      );

      return; // Stop drawing the heavy dark-mode elements (waves, rings, beams, sparkles)!
    }

    // Soften pastels on white background to keep it premium and clean
    final double opacityMultiplier = isLight ? 0.35 : 1.0;

    // ── 1. Primary hero orb — top-left, large, rich teal ─────
    _drawOrb(
      canvas,
      center: Offset(W * -0.05, H * 0.05),
      radius: W * 0.80,
      colors: [
        primaryOrbColor.withValues(alpha: 0.55 * opacityMultiplier),
        primaryOrbColor.withValues(alpha: 0.22 * opacityMultiplier),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    // ── 2. Secondary orb — upper-right, cool cyan ─────────────
    _drawOrb(
      canvas,
      center: Offset(W * 1.05, H * -0.02),
      radius: W * 0.55,
      colors: [
        secondaryOrbColor.withValues(alpha: 0.38 * opacityMultiplier),
        secondaryOrbColor.withValues(alpha: 0.14 * opacityMultiplier),
        Colors.transparent,
      ],
      stops: const [0.0, 0.50, 1.0],
    );

    // ── 3. Mid orb — center-left, warm teal-indigo blend ──────
    _drawOrb(
      canvas,
      center: Offset(W * 0.20, H * 0.42),
      radius: W * 0.50,
      colors: [
        midOrbColor.withValues(alpha: 0.18 * opacityMultiplier),
        midOrbColor.withValues(alpha: 0.08 * opacityMultiplier),
        Colors.transparent,
      ],
      stops: const [0.0, 0.55, 1.0],
    );

    // ── 4. Diagonal aurora / light beam ───────────────────────
    final beamPath = Path()
      ..moveTo(W * -0.10, H * 0.30)
      ..lineTo(W * 0.45, H * 0.00)
      ..lineTo(W * 0.65, H * 0.00)
      ..lineTo(W * 0.10, H * 0.30)
      ..close();
    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            beamColor.withValues(alpha: 0.22 * opacityMultiplier),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, W, H * 0.30)),
    );

    // ── 5. Upper wave band ─────────────────────────────────────
    _drawWave(
      canvas,
      W,
      H,
      y1: 0.16,
      cp1x: 0.28,
      cp1y: 0.09,
      cp2x: 0.65,
      cp2y: 0.23,
      y2: 0.20,
      color: waveColor1.withValues(alpha: 0.13 * opacityMultiplier),
    );

    // ── 6. Second wave band (offset) ──────────────────────────
    _drawWave(
      canvas,
      W,
      H,
      y1: 0.24,
      cp1x: 0.30,
      cp1y: 0.14,
      cp2x: 0.68,
      cp2y: 0.30,
      y2: 0.28,
      color: waveColor2.withValues(alpha: 0.09 * opacityMultiplier),
    );

    // ── 7. Bottom swoosh ──────────────────────────────────
    final swooshColor = isLight ? Colors.white : Colors.black;
    final swoosh = Path()
      ..moveTo(0, H * 0.70)
      ..cubicTo(W * 0.25, H * 0.55, W * 0.75, H * 0.78, W, H * 0.62)
      ..lineTo(W, H)
      ..lineTo(0, H)
      ..close();
    canvas.drawPath(
      swoosh,
      Paint()
        ..shader = LinearGradient(
          colors: [
            swooshColor.withValues(alpha: isLight ? 0.45 : 0.22),
            swooshColor.withValues(alpha: isLight ? 0.10 : 0.06),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(0, H * 0.60, W, H * 0.40)),
    );

    // ── 8. Concentric glowing rings — left anchor ─────────────
    _drawRing(canvas, Offset(W * -0.02, H * 0.14), W * 0.46,
        ringColor.withValues(alpha: 0.18 * opacityMultiplier), 1.4);
    _drawRing(canvas, Offset(W * -0.02, H * 0.14), W * 0.62,
        ringColor.withValues(alpha: 0.10 * opacityMultiplier), 0.9);
    _drawRing(canvas, Offset(W * -0.02, H * 0.14), W * 0.80,
        ringColor.withValues(alpha: 0.05 * opacityMultiplier), 0.6);

    // ── 9. Scattered sparkle dots ─────────────────────────────
    final sparkles = [
      // top-right cluster
      (W * 0.78, H * 0.05, 2.8),
      (W * 0.85, H * 0.02, 1.8),
      (W * 0.91, H * 0.07, 3.2),
      (W * 0.82, H * 0.11, 1.5),
      (W * 0.95, H * 0.03, 2.2),
      // mid-right scatter
      (W * 0.88, H * 0.20, 2.0),
      (W * 0.94, H * 0.25, 1.4),
      (W * 0.80, H * 0.28, 2.5),
      // bottom-left scatter
      (W * 0.12, H * 0.30, 1.6),
      (W * 0.06, H * 0.34, 2.2),
      (W * 0.18, H * 0.32, 1.2),
    ];
    for (final s in sparkles) {
      // Outer glow halo
      canvas.drawCircle(
        Offset(s.$1, s.$2),
        s.$3 * 2.8,
        Paint()
          ..color = sparkleColor.withValues(alpha: 0.10 * opacityMultiplier),
      );
      // Bright core
      canvas.drawCircle(
        Offset(s.$1, s.$2),
        s.$3,
        Paint()
          ..color = (accentColor != null
                  ? Color.alphaBlend(
                      accentColor!.withValues(alpha: 0.4), Colors.white)
                  : const Color(0xFFE8AEFF))
              .withValues(alpha: isLight ? 0.85 : 0.75),
      );
    }

    // ── 10. Subtle horizontal shimmer line ────────────────────
    canvas.drawLine(
      Offset(0, H * 0.365),
      Offset(W, H * 0.365),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            ringColor.withValues(alpha: 0.25 * opacityMultiplier),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, H * 0.365, W, 1))
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
  }

  // ── Helper: radial gradient orb ───────────────────────────────
  void _drawOrb(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required List<Color> colors,
    required List<double> stops,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(colors: colors, stops: stops)
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  // ── Helper: bezier wave band ───────────────────────────────────
  void _drawWave(
    Canvas canvas,
    double W,
    double H, {
    required double y1,
    required double cp1x,
    required double cp1y,
    required double cp2x,
    required double cp2y,
    required double y2,
    required Color color,
  }) {
    final path = Path()
      ..moveTo(0, H * y1)
      ..cubicTo(W * cp1x, H * cp1y, W * cp2x, H * cp2y, W, H * y2)
      ..lineTo(W, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
  }

  // ── Helper: single ring stroke ────────────────────────────────
  void _drawRing(Canvas canvas, Offset c, double r, Color color, double width) {
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width);
  }

  @override
  bool shouldRepaint(covariant PolyMeshPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.isLight != isLight;
  }
}
