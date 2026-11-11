import 'dart:math';

import 'package:flutter/material.dart';

/// A one-shot confetti burst that falls over its child's area (no package).
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.height = 160});

  final double height;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward();

  late final List<_Piece> _pieces = () {
    final r = Random(7);
    const colors = [
      Color(0xFFFFC107),
      Color(0xFFE91E63),
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFF9C27B0),
    ];
    return List.generate(
      60,
      (_) => _Piece(
        x: r.nextDouble(),
        delay: r.nextDouble() * 0.4,
        speed: 0.6 + r.nextDouble() * 0.4,
        size: 5 + r.nextDouble() * 5,
        spin: r.nextDouble() * 6,
        color: colors[r.nextInt(colors.length)],
      ),
    );
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) =>
              CustomPaint(painter: _ConfettiPainter(_pieces, _c.value)),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.spin,
    required this.color,
  });

  final double x, delay, speed, size, spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local == 0) continue;
      final y = local * p.speed * size.height;
      final x = p.x * size.width + sin(local * 8 + p.spin) * 12;
      final opacity = local > 0.8 ? (1 - local) / 0.2 : 1.0;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * p.spin * 4);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.6),
        Paint()..color = p.color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
