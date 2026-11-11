import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import '../../settings/domain/movement_speed.dart';

import '../domain/dungeon.dart';
import '../domain/dungeon_floor.dart';
import '../domain/floor_change_request.dart';
import '../domain/grid_position.dart';
import '../domain/ground_object_interaction_context.dart';
import '../domain/ground_object_interaction_request.dart';
import '../domain/movement_plan.dart';
import '../domain/tile_inspection.dart';

enum MovementPhase { idle, dragging, awaitingConfirmation, moving }

class DungeonController extends ChangeNotifier {
  static final stepDuration = MovementSpeed.defaultSpeed.stepInterval;
  static final _movementMenuLock = Object();

  final Set<Object> _bottomMenuLocks = {};
  final Duration Function() _movementInterval;
  Dungeon _dungeon;
  late MovementPlan _plan = _newPlan();
  final bool Function(InteractiveDungeonGroundObject object)
  _requiresConfirmation;
  final _interactionQueue = Queue<GroundObjectInteractionRequest>();
  GroundObjectInteractionRequest? _pendingInteraction;
  MovementPhase _phase = MovementPhase.idle;
  Timer? _movementTimer;
  int _nextStep = 0;
  GridPosition? _selectedPosition;
  bool _isPaused = false;
  bool _isInteracting = false;
  FloorChangeRequest? _pendingFloorChange;

  DungeonController(
    this._dungeon, {
    Duration Function()? movementInterval,
    bool Function(InteractiveDungeonGroundObject object)? requiresConfirmation,
  }) : _movementInterval = movementInterval ?? _defaultMovementInterval,
       _requiresConfirmation =
           requiresConfirmation ?? _defaultConfirmationPolicy {
    _interactAtPlayer();
  }

  static Duration _defaultMovementInterval() => stepDuration;

  static bool _defaultConfirmationPolicy(
    InteractiveDungeonGroundObject object,
  ) => false;

  MovementPlan _newPlan() => MovementPlan.start(
    _dungeon,
    additionalStop: (position) => _dungeon.floor
        .interactiveObjectsAt(position)
        .any(_requiresConfirmation),
  );

  Dungeon get dungeon => _dungeon;
  MovementPlan get plan => _plan;
  MovementPhase get phase => _phase;
  bool get isMoving => _phase == MovementPhase.moving;
  bool get canConfirm =>
      isSelected &&
      isBottomMenuEnabled &&
      _plan.path.isNotEmpty &&
      (_phase == MovementPhase.dragging ||
          _phase == MovementPhase.awaitingConfirmation);
  bool get isSelected => _selectedPosition == _dungeon.player;
  GridPosition? get selectedPosition => _selectedPosition;
  TileInspection? get inspectedTile {
    final position = _selectedPosition;
    if (position == null || isSelected) {
      return null;
    }
    return _dungeon.floor.inspectTile(position);
  }

  bool get isPaused => _isPaused;
  bool get isBottomMenuEnabled =>
      !_isPaused &&
      _pendingFloorChange == null &&
      _pendingInteraction == null &&
      _bottomMenuLocks.isEmpty;
  FloorChangeRequest? get pendingFloorChange => _pendingFloorChange;
  GroundObjectInteractionRequest? get pendingInteraction => _pendingInteraction;
  bool get _canSelect => isBottomMenuEnabled && !isMoving && !_isInteracting;

  bool completeFloorChange(DungeonFloor floor) {
    final request = _pendingFloorChange;
    if (isMoving ||
        _pendingInteraction != null ||
        request == null ||
        request.floorNumber != floor.number ||
        request.sourceFloorNumber != _dungeon.floor.number ||
        request.sourcePosition != _dungeon.player) {
      return false;
    }

    _dungeon = _dungeon.enterFloor(floor);
    _pendingFloorChange = null;
    _interactionQueue.clear();
    _phase = MovementPhase.idle;
    _nextStep = 0;
    _selectedPosition = null;
    _interactAtPlayer();
    _plan = _newPlan();
    notifyListeners();
    return true;
  }

  /// Permite activar el mismo comportamiento desde menús, toques u otras acciones.
  /// Los objetos retirados, de otra planta o durante una acción bloqueada se ignoran.
  bool interactWith(InteractiveDungeonGroundObject object) {
    if (!isBottomMenuEnabled || isMoving || _isInteracting) {
      return false;
    }
    if (!_invokeInteraction(object, GroundObjectTrigger.activated)) {
      return false;
    }

    _phase = MovementPhase.idle;
    _plan = _newPlan();
    notifyListeners();
    return true;
  }

  bool _interactAtPlayer() {
    final objects = _dungeon.floor
        .interactiveObjectsAt(_dungeon.player)
        .toList();
    for (final object in objects) {
      _interactionQueue.add(
        GroundObjectInteractionRequest(
          object: object,
          trigger: GroundObjectTrigger.enteredTile,
          floorNumber: _dungeon.floor.number,
          playerPosition: _dungeon.player,
        ),
      );
    }
    return _resolveInteractionQueue();
  }

  bool _resolveInteractionQueue() {
    var stopsMovement = false;
    while (_interactionQueue.isNotEmpty) {
      final request = _interactionQueue.first;
      if (!request.isValidFor(_dungeon)) {
        _interactionQueue.removeFirst();
        continue;
      }
      if (_requiresConfirmation(request.object)) {
        _pendingInteraction = request;
        return true;
      }
      _interactionQueue.removeFirst();
      if (_invokeInteraction(request.object, request.trigger)) {
        stopsMovement = stopsMovement || request.object.stopsMovement;
      }
    }
    return stopsMovement || _pendingFloorChange != null;
  }

  /// La respuesta consume la petición; no se vuelve a preguntar hasta otra entrada.
  bool respondToInteraction({
    required GroundObjectInteractionRequest request,
    required bool accept,
  }) {
    if (!identical(request, _pendingInteraction)) {
      return false;
    }
    _pendingInteraction = null;
    _interactionQueue.removeFirst();
    if (accept && request.isValidFor(_dungeon)) {
      _invokeInteraction(request.object, request.trigger);
    }
    _resolveInteractionQueue();
    _phase = MovementPhase.idle;
    _plan = _newPlan();
    notifyListeners();
    return true;
  }

  bool _invokeInteraction(
    InteractiveDungeonGroundObject object,
    GroundObjectTrigger trigger,
  ) {
    if (_isInteracting || !_dungeon.floor.groundObjects.contains(object)) {
      return false;
    }

    _isInteracting = true;
    try {
      object.onInteract(
        GroundObjectInteractionContext(
          object: object,
          trigger: trigger,
          readDungeon: () => _dungeon,
          updateDungeon: _updateFromInteraction,
          requestFloorChange: _requestFloorChange,
        ),
      );
    } finally {
      _isInteracting = false;
    }
    return true;
  }

  void _updateFromInteraction(Dungeon dungeon) {
    if (dungeon.floor.number != _dungeon.floor.number ||
        dungeon.player != _dungeon.player) {
      throw ArgumentError(
        'Interactions must request scene changes instead of moving the player directly.',
      );
    }
    _dungeon = dungeon;
    final position = _selectedPosition;
    if (position != null &&
        !isSelected &&
        _dungeon.floor.inspectTile(position) == null) {
      _selectedPosition = null;
    }
  }

  void _requestFloorChange(int floorNumber) {
    _pendingFloorChange ??= FloorChangeRequest(
      floorNumber: floorNumber,
      sourceFloorNumber: _dungeon.floor.number,
      sourcePosition: _dungeon.player,
    );
  }

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
    if (isSelected || !_canSelect) {
      return;
    }

    _selectPosition(_dungeon.player);
  }

  /// Selecciona lo visible sin activar objetos; una casilla vacía limpia la selección.
  void selectTile(GridPosition position) {
    if (!_canSelect || !_dungeon.floor.contains(position)) {
      return;
    }
    if (position == _dungeon.player) {
      selectCharacter();
      return;
    }
    if (_dungeon.floor.inspectTile(position) == null) {
      unselect();
      return;
    }
    _selectPosition(position);
  }

  void _selectPosition(GridPosition? position) {
    _selectedPosition = position;
    _nextStep = 0;
    _phase = MovementPhase.idle;
    _plan = _newPlan();
    notifyListeners();
  }

  /// Cancela la selección y el turno pendiente cuando el menú está disponible.
  void unselect() {
    if (!_canSelect) {
      return;
    }

    _movementTimer?.cancel();
    _movementTimer = null;
    _selectPosition(null);
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
      _movementTimer = Timer.periodic(_movementInterval(), (_) => _advance());
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
    if (!isSelected || !isBottomMenuEnabled || isMoving) {
      return;
    }

    _plan = _newPlan();
    _phase = MovementPhase.dragging;
    notifyListeners();
  }

  void preview(DungeonDirection direction, {int steps = 1}) {
    if (!isSelected ||
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

    _plan = _newPlan();
    _phase = MovementPhase.idle;
    notifyListeners();
  }

  void confirm() {
    if (!canConfirm) {
      return;
    }

    _phase = MovementPhase.moving;
    _nextStep = 0;
    _movementTimer = Timer.periodic(_movementInterval(), (_) => _advance());
    disableBottomMenu(_movementMenuLock);
  }

  void _advance() {
    _dungeon = _dungeon.stepTo(_plan.path[_nextStep]);
    _selectedPosition = _dungeon.player;
    _nextStep++;
    final interactionStopsMovement = _interactAtPlayer();
    if (_nextStep == _plan.path.length || interactionStopsMovement) {
      _movementTimer?.cancel();
      _movementTimer = null;
      _phase = MovementPhase.idle;
      _plan = _newPlan();
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
