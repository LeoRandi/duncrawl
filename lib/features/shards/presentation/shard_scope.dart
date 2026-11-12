import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/shard_progress.dart';

class ShardController extends ChangeNotifier
    implements ValueListenable<ShardProgress> {
  static final _allShards = const ShardProgress.empty().unlockAll();
  ShardProgress _earned;
  bool _unlockAll = false;

  ShardController([ShardProgress progress = const ShardProgress.empty()])
    : _earned = progress;

  @override
  ShardProgress get value => _unlockAll ? _allShards : _earned;

  void unlock(ColorShard shard) {
    final updated = _earned.unlock(shard);
    if (identical(updated, _earned)) {
      return;
    }
    _earned = updated;
    if (!_unlockAll) {
      notifyListeners();
    }
  }

  /// El ajuste visual no borra los fragmentos ganados durante la partida.
  void setUnlockAll(bool enabled) {
    if (_unlockAll == enabled) {
      return;
    }
    _unlockAll = enabled;
    notifyListeners();
  }
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
