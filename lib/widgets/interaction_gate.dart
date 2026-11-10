import 'package:flutter/material.dart';

/// Bloquea los controles de una sección completa, tanto por tacto como por foco.
class InteractionGate extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const InteractionGate({
    super.key,
    required this.enabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ExcludeFocus(
    excluding: !enabled,
    child: AbsorbPointer(absorbing: !enabled, child: child),
  );
}
