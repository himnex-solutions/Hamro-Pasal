import 'package:flutter/material.dart';

class WavyClipper extends CustomClipper<Path> {
  final double waveOffset;

  WavyClipper({this.waveOffset = 0.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    const waveHeight = 30.0;
    
    // Start at top-left
    path.moveTo(0, waveHeight + waveOffset);

    // First control point and end point
    final controlPoint1 = Offset(size.width * 0.25, waveOffset);
    final endPoint1 = Offset(size.width * 0.5, waveHeight / 2 + waveOffset);

    // Second control point and end point
    final controlPoint2 = Offset(size.width * 0.75, waveHeight + waveOffset);
    final endPoint2 = Offset(size.width, waveOffset);

    path.quadraticBezierTo(
      controlPoint1.dx,
      controlPoint1.dy,
      endPoint1.dx,
      endPoint1.dy,
    );

    path.quadraticBezierTo(
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint2.dx,
      endPoint2.dy,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant WavyClipper oldClipper) {
    return oldClipper.waveOffset != waveOffset;
  }
}

class WavyDivider extends StatelessWidget {
  final Widget child;
  final Color mainColor;
  final Color waveColor;

  const WavyDivider({
    super.key,
    required this.child,
    this.mainColor = Colors.white,
    this.waveColor = const Color(0x26FFFFFF), // semi-transparent white
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: Background decorative wave (highest, offset: 0.0)
        Positioned.fill(
          child: ClipPath(
            clipper: WavyClipper(waveOffset: 0.0),
            child: Container(
              color: waveColor,
            ),
          ),
        ),
        // Layer 2: Second decorative wave (middle, offset: 8.0)
        Positioned.fill(
          child: ClipPath(
            clipper: WavyClipper(waveOffset: 8.0),
            child: Container(
              color: waveColor.withValues(alpha: waveColor.a * 0.7),
            ),
          ),
        ),
        // Layer 3: Main content container (lowest, offset: 16.0)
        Positioned.fill(
          child: ClipPath(
            clipper: WavyClipper(waveOffset: 16.0),
            child: Container(
              color: mainColor,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
