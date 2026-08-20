import 'package:flutter/material.dart';
import 'package:qr_scanner/app/theme/app_tokens.dart';

class ScanOverlay extends StatelessWidget {
  const ScanOverlay({
    super.key,
    required this.cutOutSize,
    required this.animation,
  });

  final double cutOutSize;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).brightness == Brightness.dark
        ? AppColors.brandBright
        : AppColors.brand;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _ScanOverlayPainter(
            cutOutSize: cutOutSize,
            borderColor: accent,
            scanProgress: animation.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  _ScanOverlayPainter({
    required this.cutOutSize,
    required this.borderColor,
    required this.scanProgress,
  });

  final double cutOutSize;
  final Color borderColor;
  final double scanProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final cut = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 24),
      width: cutOutSize,
      height: cutOutSize,
    );

    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(cut, const Radius.circular(22)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.58),
    );

    final cornerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    void corner(Offset a, Offset b, Offset c) {
      canvas.drawLine(a, b, cornerPaint);
      canvas.drawLine(a, c, cornerPaint);
    }

    corner(
      cut.topLeft,
      cut.topLeft.translate(len, 0),
      cut.topLeft.translate(0, len),
    );
    corner(
      cut.topRight,
      cut.topRight.translate(-len, 0),
      cut.topRight.translate(0, len),
    );
    corner(
      cut.bottomLeft,
      cut.bottomLeft.translate(len, 0),
      cut.bottomLeft.translate(0, -len),
    );
    corner(
      cut.bottomRight,
      cut.bottomRight.translate(-len, 0),
      cut.bottomRight.translate(0, -len),
    );

    // Animated scan line
    final y = cut.top + (cut.height - 2) * scanProgress;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          borderColor.withValues(alpha: 0),
          borderColor.withValues(alpha: 0.95),
          borderColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(cut.left, y, cut.width, 2));
    canvas.drawRect(
      Rect.fromLTWH(cut.left + 12, y, cut.width - 24, 2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) =>
      oldDelegate.cutOutSize != cutOutSize ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.scanProgress != scanProgress;
}
