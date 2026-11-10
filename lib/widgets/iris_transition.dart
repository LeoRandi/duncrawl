import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'interaction_gate.dart';

/// Progreso de cierre: 0 → 67% → 50% → 100% en 750, 350 y 400 ms.
class IrisTransitionCurve extends Curve {
  const IrisTransitionCurve();

  @override
  double transformInternal(double t) {
    const reboundStart = 0.75 / 1.5;
    const reboundEnd = 1.1 / 1.5;
    if (t <= reboundStart) {
      return 0.67 * _easePhase(t / reboundStart);
    }
    if (t <= reboundEnd) {
      final phaseProgress = (t - reboundStart) / (reboundEnd - reboundStart);
      return 0.67 - 0.17 * _easePhase(phaseProgress);
    }

    final phaseProgress = (t - reboundEnd) / (1 - reboundEnd);
    return 0.5 + 0.5 * _easePhase(phaseProgress);
  }

  static double _easePhase(double progress) =>
      (1 - math.cos(math.pi * progress)) / 2;
}

/// Cierra la escena actual y revela la siguiente sin depender de sus rutas.
class IrisTransition extends StatefulWidget {
  static const phaseDuration = Duration(milliseconds: 1500);
  static const curve = IrisTransitionCurve();

  final Widget child;

  const IrisTransition({super.key, required this.child});

  static _IrisTransitionState _stateOf(BuildContext context) {
    final state = context.findAncestorStateOfType<_IrisTransitionState>();
    if (state == null) {
      throw FlutterError(
        'An IrisTransition must wrap the application navigator.',
      );
    }

    return state;
  }

  static bool isRunning(BuildContext context) => _stateOf(context)._isRunning;

  /// Devuelve el centro global de un elemento montado y con layout.
  static Offset centerOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      throw StateError('The transition anchor must be mounted and laid out.');
    }

    return box.localToGlobal(box.size.center(Offset.zero));
  }

  /// Ejecuta onCovered con la pantalla negra y espera el layout antes de abrir.
  /// openingCenter se resuelve entonces; si falta, se usa el centro de la pantalla.
  /// Las peticiones recibidas durante otra transición se ignoran.
  static Future<void> run(
    BuildContext context, {
    required Offset closingCenter,
    required VoidCallback onCovered,
    Offset Function()? openingCenter,
  }) => _stateOf(context)._run(
    closingCenter: closingCenter,
    onCovered: onCovered,
    openingCenter: openingCenter,
  );

  @override
  State<IrisTransition> createState() => _IrisTransitionState();
}

class _IrisTransitionState extends State<IrisTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  bool _isRunning = false;
  Offset _center = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: IrisTransition.phaseDuration,
      animationBehavior: AnimationBehavior.preserve,
    );
  }

  Offset _localCenter(Offset globalCenter) {
    final box = context.findRenderObject() as RenderBox;
    return box.globalToLocal(globalCenter);
  }

  Future<void> _run({
    required Offset closingCenter,
    required VoidCallback onCovered,
    Offset Function()? openingCenter,
  }) async {
    if (_isRunning) {
      return;
    }
    setState(() {
      _isRunning = true;
      _center = _localCenter(closingCenter);
    });
    try {
      await _animation.forward(from: 0).orCancel;
      if (!mounted) {
        return;
      }
      onCovered();
      // La nueva escena debe tener coordenadas válidas antes de descubrirla.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox;
      setState(() {
        _center = openingCenter == null
            ? box.size.center(Offset.zero)
            : _localCenter(openingCenter());
      });
      await _animation.reverse(from: 1).orCancel;
    } on TickerCanceled {
      // El cierre de la app libera también la animación que estuviera en curso.
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      InteractionGate(enabled: !_isRunning, child: widget.child),
      if (_isRunning)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) => IrisMask(
              center: _center,
              aperture: 1 - IrisTransition.curve.transform(_animation.value),
            ),
          ),
        ),
    ],
  );
}

/// Máscara negra con una abertura circular: 1 descubre todo y 0 tapa todo.
class IrisMask extends StatelessWidget {
  final Offset center;
  final double aperture;

  const IrisMask({super.key, required this.center, required this.aperture});

  static double coveringRadius(Size size, Offset center) {
    var radius = 0.0;
    for (final corner in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      size.bottomRight(Offset.zero),
    ]) {
      radius = math.max(radius, (corner - center).distance);
    }

    return radius + 1;
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _IrisPainter(center: center, aperture: aperture),
  );
}

class _IrisPainter extends CustomPainter {
  final Offset center;
  final double aperture;

  const _IrisPainter({required this.center, required this.aperture});

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    final radius = IrisMask.coveringRadius(size, center) * aperture;
    if (radius <= 0) {
      canvas.drawPath(screen, Paint()..color = Colors.black);
      return;
    }

    final opening = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(
      Path.combine(PathOperation.difference, screen, opening),
      Paint()..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(_IrisPainter oldDelegate) =>
      center != oldDelegate.center || aperture != oldDelegate.aperture;
}
