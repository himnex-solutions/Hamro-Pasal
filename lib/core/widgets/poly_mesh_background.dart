import 'package:flutter/material.dart';

class PolyMeshBackground extends StatelessWidget {
  final Widget? child;
  final Color? accentColor;
  
  // ── Color tokens ────────────
  static const _bgDark1 = Color(0xFF07242B);   // top-left of background gradient
  static const _bgDark2 = Color(0xFF0F4850);   // bottom-right of background gradient

  const PolyMeshBackground({super.key, this.child, this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_bgDark1, _bgDark2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: PolyMeshPainter(accentColor: accentColor)),
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

  PolyMeshPainter({this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // Use accentColor if provided, otherwise fallback to the default website brand teal/cyan colors
    final primaryOrbColor = accentColor ?? const Color(0xFF1FE0F0);
    final secondaryOrbColor = accentColor ?? const Color(0xFF38EAF7);
    final midOrbColor = accentColor ?? const Color(0xFF0CCEDF);
    final beamColor = accentColor ?? const Color(0xFF1FE0F0);
    final waveColor1 = accentColor ?? const Color(0xFF0ECFDD);
    final waveColor2 = accentColor ?? const Color(0xFF0BBAC8);
    final ringColor = accentColor ?? const Color(0xFF1DD8E8);
    final sparkleColor = accentColor ?? const Color(0xFF1DD8E8);

    // ── 1. Primary hero orb — top-left, large, rich teal ─────
    _drawOrb(canvas,
      center: Offset(W * -0.05, H * 0.05),
      radius: W * 0.80,
      colors: [
        primaryOrbColor.withValues(alpha: 0.55),
        primaryOrbColor.withValues(alpha: 0.22),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    // ── 2. Secondary orb — upper-right, cool cyan ─────────────
    _drawOrb(canvas,
      center: Offset(W * 1.05, H * -0.02),
      radius: W * 0.55,
      colors: [
        secondaryOrbColor.withValues(alpha: 0.38),
        secondaryOrbColor.withValues(alpha: 0.14),
        Colors.transparent,
      ],
      stops: const [0.0, 0.50, 1.0],
    );

    // ── 3. Mid orb — center-left, warm teal-indigo blend ──────
    _drawOrb(canvas,
      center: Offset(W * 0.20, H * 0.42),
      radius: W * 0.50,
      colors: [
        midOrbColor.withValues(alpha: 0.18),
        midOrbColor.withValues(alpha: 0.08),
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
            beamColor.withValues(alpha: 0.22),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, W, H * 0.30)),
    );

    // ── 5. Upper wave band ─────────────────────────────────────
    _drawWave(canvas, W, H,
      y1: 0.16, cp1x: 0.28, cp1y: 0.09,
      cp2x: 0.65, cp2y: 0.23, y2: 0.20,
      color: waveColor1.withValues(alpha: 0.13),
    );

    // ── 6. Second wave band (offset) ──────────────────────────
    _drawWave(canvas, W, H,
      y1: 0.24, cp1x: 0.30, cp1y: 0.14,
      cp2x: 0.68, cp2y: 0.30, y2: 0.28,
      color: waveColor2.withValues(alpha: 0.09),
    );

    // ── 7. Bottom dark swoosh ──────────────────────────────────
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
            Colors.black.withValues(alpha: 0.22),
            Colors.black.withValues(alpha: 0.06),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(0, H * 0.60, W, H * 0.40)),
    );

    // ── 8. Concentric glowing rings — left anchor ─────────────
    _drawRing(canvas, Offset(W * -0.02, H * 0.14), W * 0.46,
        ringColor.withValues(alpha: 0.18), 1.4);
    _drawRing(canvas, Offset(W * -0.02, H * 0.14), W * 0.62,
        ringColor.withValues(alpha: 0.10), 0.9);
    _drawRing(canvas, Offset(W * -0.02, H * 0.14), W * 0.80,
        ringColor.withValues(alpha: 0.05), 0.6);

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
        Paint()..color = sparkleColor.withValues(alpha: 0.10),
      );
      // Bright core
      canvas.drawCircle(
        Offset(s.$1, s.$2),
        s.$3,
        Paint()..color = (accentColor != null ? Color.alphaBlend(accentColor!.withValues(alpha: 0.4), Colors.white) : const Color(0xFF6FF6FF)).withValues(alpha: 0.75),
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
            ringColor.withValues(alpha: 0.25),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, H * 0.365, W, 1))
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
  }

  // ── Helper: radial gradient orb ───────────────────────────────
  void _drawOrb(Canvas canvas, {
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
  void _drawWave(Canvas canvas, double W, double H, {
    required double y1, required double cp1x, required double cp1y,
    required double cp2x, required double cp2y, required double y2,
    required Color color,
  }) {
    final path = Path()
      ..moveTo(0, H * y1)
      ..cubicTo(W * cp1x, H * cp1y, W * cp2x, H * cp2y, W, H * y2)
      ..lineTo(W, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  // ── Helper: single ring stroke ────────────────────────────────
  void _drawRing(Canvas canvas, Offset c, double r, Color color, double width) {
    canvas.drawCircle(c, r, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width);
  }

  @override
  bool shouldRepaint(covariant PolyMeshPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}
