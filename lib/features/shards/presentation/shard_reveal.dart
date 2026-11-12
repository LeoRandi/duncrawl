import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/shard_progress.dart';
import 'shard_colors.dart';

Future<void> showShardReveal(BuildContext context, ColorShard shard) async {
  final route = RawDialogRoute<void>(
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => PopScope(
      canPop: false,
      child: ShardReveal(
        shard: shard,
        onComplete: () => Navigator.of(context).pop(),
      ),
    ),
  );
  await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
}

class ShardReveal extends StatefulWidget {
  static const duration = Duration(seconds: 1);
  final ColorShard shard;
  final VoidCallback onComplete;

  const ShardReveal({super.key, required this.shard, required this.onComplete});

  @override
  State<ShardReveal> createState() => _ShardRevealState();
}

class _ShardRevealState extends State<ShardReveal>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: ShardReveal.duration,
  );
  Timer? _completionTimer;

  @override
  void initState() {
    super.initState();
    _animation.forward();
    // La duración no depende de cuándo llegue el siguiente fotograma.
    _completionTimer = Timer(ShardReveal.duration, () => widget.onComplete());
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (widget.shard) {
      ColorShard.red => ShardColors.bat.unlocked,
      ColorShard.gold => ShardColors.adventurer.unlocked,
      ColorShard.green => ShardColors.grass.unlocked,
      ColorShard.blue => ShardColors.water.unlocked,
      ColorShard.lightBlue => ShardColors.shallowWater.unlocked,
      ColorShard.orange => ShardColors.alert.unlocked,
    };
    return Material(
      type: MaterialType.transparency,
      child: IgnorePointer(
        child: Center(
          child: Semantics(
            label: '${widget.shard.name} shard',
            liveRegion: true,
            child: SizedBox.square(
              key: const ValueKey('shard-reveal'),
              dimension: 240,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) => CustomPaint(
                  painter: _ShardBurstPainter(
                    progress: _animation.value,
                    color: color,
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale:
                          1 + 0.15 * math.sin(_animation.value * math.pi * 6),
                      child: Icon(Icons.star, size: 72, color: color),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShardBurstPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ShardBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rayPaint = Paint()..isAntiAlias = false;
    for (var index = 0; index < 12; index++) {
      final angle = index * math.pi / 6 + progress * 0.7;
      final length = 72 + 24 * math.sin(progress * math.pi * 4 + index);
      rayPaint.color = color.withValues(alpha: 0.15 + 0.2 * (1 - progress));
      final ray = Path()..moveTo(center.dx, center.dy);
      for (final edge in [-0.055, 0.055]) {
        ray.lineTo(
          center.dx + math.cos(angle + edge) * length,
          center.dy + math.sin(angle + edge) * length,
        );
      }
      ray.close();
      canvas.drawPath(ray, rayPaint);
    }
    final pixelPaint = Paint()..isAntiAlias = false;
    for (var index = 0; index < 24; index++) {
      final phase = (progress * 2 + index / 24) % 1;
      final angle = index * math.pi * 2 / 24;
      final radius = 32 + phase * 80;
      pixelPaint.color = color.withValues(alpha: 1 - phase);
      canvas.drawRect(
        Rect.fromCenter(
          center: center + Offset(math.cos(angle), math.sin(angle)) * radius,
          width: 4,
          height: 4,
        ),
        pixelPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ShardBurstPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
