import 'package:flutter/material.dart';

import '../domain/shard_progress.dart';

class ShardController extends ValueNotifier<ShardProgress> {
  ShardController([super.value = const ShardProgress.empty()]);

  void unlock(ColorShard shard) => value = value.unlock(shard);
}

/// Vive por encima del navegador para compartir los desbloqueos entre escenas.
class ShardScope extends InheritedNotifier<ShardController> {
  const ShardScope({
    super.key,
    required ShardController controller,
    required super.child,
  }) : super(notifier: controller);

  static ShardController? controllerOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShardScope>()?.notifier;

  static ShardProgress progressOf(BuildContext context) =>
      controllerOf(context)?.value ?? const ShardProgress.empty();
}
