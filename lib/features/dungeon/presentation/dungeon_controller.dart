import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/dungeon.dart';
import '../domain/grid_position.dart';
import '../domain/movement_plan.dart';

enum MovementPhase { idle, dragging, awaitingConfirmation, moving }

class DungeonController extends ChangeNotifier {
  static const stepDuration = Duration(milliseconds: 300);
  static final _movementMenuLock = Object();

  final Set<Object> _bottomMenuLocks = {};
  Dungeon _dungeon;
  late MovementPlan _plan = MovementPlan.start(_dungeon);
  MovementPhase _phase = MovementPhase.idle;
  Timer? _movementTimer;
  int _nextStep = 0;
  bool _isSelected = false;
  bool _isPaused = false;

  DungeonController(this._dungeon);

  Dungeon get dungeon => _dungeon;
  MovementPlan get plan => _plan;
  MovementPhase get phase => _phase;
  bool get isMoving => _phase == MovementPhase.moving;
  bool get canConfirm =>
      _isSelected &&
      isBottomMenuEnabled &&
      _plan.path.isNotEmpty &&
      (_phase == MovementPhase.dragging ||
          _phase == MovementPhase.awaitingConfirmation);
  bool get isSelected => _isSelected;
  bool get isPaused => _isPaused;
  bool get isBottomMenuEnabled => !_isPaused && _bottomMenuLocks.isEmpty;

  /// Bloquea el menú hasta que el mismo propietario libere su motivo.
  /// Cada acción usa su propio token; adquirirlo de nuevo no duplica el bloqueo.
  void disableBottomMenu(Object reason) {
    if (!_bottomMenuLocks.add(reason)) {
      return;
    }

    notifyListeners();
  }

  /// Libera solo este motivo, conservando los bloqueos de otras acciones.
  void enableBottomMenu(Object reason) {
    if (!_bottomMenuLocks.remove(reason)) {
      return;
    }

    notifyListeners();
  }

  void selectCharacter() {
    if (_isSelected || _isPaused) {
      return;
    }

    _isSelected = true;
    notifyListeners();
  }

  /// Cancela la selección y el turno pendiente cuando el menú está disponible.
  void unselect() {
    if (!isBottomMenuEnabled) {
      return;
    }

    _movementTimer?.cancel();
    _movementTimer = null;
    _nextStep = 0;
    _isSelected = false;
    _phase = MovementPhase.idle;
    _plan = MovementPlan.start(_dungeon);
    notifyListeners();
  }

  void pause() {
    if (_isPaused) {
      return;
    }
    cancelDrag();
    _isPaused = true;
    _movementTimer?.cancel();
    _movementTimer = null;
    notifyListeners();
  }

  void resume() {
    if (!_isPaused) {
      return;
    }
    _isPaused = false;
    if (isMoving) {
      _movementTimer = Timer.periodic(stepDuration, (_) => _advance());
    }
    notifyListeners();
  }

  List<GridPosition> get remainingPath {
    if (!isMoving) {
      return _plan.path;
    }

    return _plan.path.sublist(_nextStep);
  }

  void beginDrag() {
    if (!_isSelected || !isBottomMenuEnabled || isMoving) {
      return;
    }

    _plan = MovementPlan.start(_dungeon);
    _phase = MovementPhase.dragging;
    notifyListeners();
  }

  void preview(DungeonDirection direction, {int steps = 1}) {
    if (!_isSelected ||
        !isBottomMenuEnabled ||
        _phase != MovementPhase.dragging) {
      return;
    }

    final updatedPlan = _plan.extend(direction, steps: steps);
    if (identical(updatedPlan, _plan)) {
      return;
    }

    _plan = updatedPlan;
    notifyListeners();
  }

  void endDrag() {
    if (_phase != MovementPhase.dragging) {
      return;
    }

    _phase = _plan.path.isEmpty
        ? MovementPhase.idle
        : MovementPhase.awaitingConfirmation;
    notifyListeners();
  }

  void cancelDrag() {
    if (_phase == MovementPhase.dragging) {
      cancelPreview();
    }
  }

  void cancelPreview() {
    if (isMoving || _phase == MovementPhase.idle) {
      return;
    }

    _plan = MovementPlan.start(_dungeon);
    _phase = MovementPhase.idle;
    notifyListeners();
  }

  void confirm() {
    if (!canConfirm) {
      return;
    }

    _phase = MovementPhase.moving;
    _nextStep = 0;
    _movementTimer = Timer.periodic(stepDuration, (_) => _advance());
    disableBottomMenu(_movementMenuLock);
  }

  void _advance() {
    _dungeon = _dungeon.stepTo(_plan.path[_nextStep]);
    _nextStep++;
    if (_nextStep == _plan.path.length) {
      _movementTimer?.cancel();
      _movementTimer = null;
      _phase = MovementPhase.idle;
      _plan = MovementPlan.start(_dungeon);
      enableBottomMenu(_movementMenuLock);
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }
}
