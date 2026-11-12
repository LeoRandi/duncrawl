import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import '../../settings/domain/movement_speed.dart';

import '../domain/dungeon.dart';
import '../domain/dungeon_floor.dart';
import '../domain/encounter_state.dart';
import '../domain/enemy_tactics.dart';
import '../domain/game_command.dart';
import '../domain/game_event.dart';
import '../domain/game_rules.dart';
import '../domain/game_state.dart';
import '../domain/game_transition.dart';
import '../domain/floor_change_request.dart';
import '../domain/grid_position.dart';
import '../domain/ground_object_interaction_context.dart';
import '../domain/ground_object_interaction_request.dart';
import '../domain/movement_plan.dart';
import '../domain/tile_inspection.dart';
import '../floors/floor_zero_test_bats.dart';

enum MovementPhase { idle, dragging, awaitingConfirmation, moving }

enum ControlMode { inspect, move, strike }

class DungeonController extends ChangeNotifier {
  static final stepDuration = MovementSpeed.defaultSpeed.stepInterval;
  static final _movementMenuLock = Object();
  static const _rules = GameRules();
  static const _enemyTactics = EnemyTactics();

  final Set<Object> _bottomMenuLocks = {};
  final Duration Function() _playerMovementInterval;
  GameState _state;
  bool _floorZeroBats;
  Dungeon get _dungeon => _state.dungeon;
  late MovementPlan _plan = _newPlan();
  final bool Function(InteractiveDungeonGroundObject object)
  _requiresConfirmation;
  final _interactionQueue = Queue<GroundObjectInteractionRequest>();
  GroundObjectInteractionRequest? _pendingInteraction;
  MovementPhase _phase = MovementPhase.idle;
  Timer? _movementTimer;
  Timer? _enemyTimer;
  Timer? _presentationTimer;
  bool _isPresenting = false;
  bool _isDisposed = false;
  ControlMode _controlMode = ControlMode.inspect;
  DungeonDirection? _aimDirection;
  MovementPlan? _planBeforePadDrag;
  String? _attackTargetId;
  GameEvent? _lastCombatEvent;
  AttackResolved? _lastAttack;
  int _attackSequence = 0;
  int _nextStep = 0;
  TileInspection? _selection;
  List<TileInspection> _selectionStack = const [];
  bool _isPaused = false;
  bool _isInteracting = false;
  FloorChangeRequest? _pendingFloorChange;

  DungeonController(
    Dungeon dungeon, {
    Duration Function()? playerMovementInterval,
    bool Function(InteractiveDungeonGroundObject object)? requiresConfirmation,
    bool floorZeroBats = false,
  }) : _state = GameState(
         dungeon: FloorZeroTestBats.apply(dungeon, enabled: floorZeroBats),
       ),
       _floorZeroBats = floorZeroBats,
       _playerMovementInterval =
           playerMovementInterval ?? _defaultMovementInterval,
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
    movementBudget: _movementBudget,
    additionalStop: (position) => _dungeon.floor
        .interactiveObjectsAt(position)
        .any(_requiresConfirmation),
  );

  int? get _movementBudget {
    if (!isInCombat) {
      return null;
    }
    return isPlayerTurn ? encounter?.remainingMovement : 0;
  }

  Dungeon get dungeon => _dungeon;
  GameState get gameState => _state;
  EncounterState? get encounter => _state.encounter;
  bool get isInCombat => _state.mode == GameMode.combat;
  bool get isDefeated => _state.mode == GameMode.defeated;
  bool get isPlayerTurn => _state.isPlayerTurn;
  bool get isEnemyTurn => isInCombat && !isPlayerTurn;
  ControlMode get controlMode => _controlMode;
  bool get isControlPadOpen => _controlMode != ControlMode.inspect;
  bool get isTargetingAttack => _controlMode == ControlMode.strike;
  DungeonDirection? get aimDirection => _aimDirection;
  GridPosition? get aimedPosition => _aimDirection?.stepFrom(_dungeon.player);
  String get controlledActorId => _dungeon.adventurer.id;
  bool get canOpenMove => isBottomMenuEnabled && !isMoving;
  bool get canCancelAction =>
      isBottomMenuEnabled &&
      !isMoving &&
      (_plan.path.isNotEmpty || _aimDirection != null);
  String? get attackTargetId => _attackTargetId;
  GameEvent? get lastCombatEvent => _lastCombatEvent;
  AttackResolved? get lastAttack => _lastAttack;
  int get attackSequence => _attackSequence;
  bool get canAttack =>
      isInCombat &&
      isPlayerTurn &&
      encounter?.actionAvailable == true &&
      isBottomMenuEnabled &&
      !isMoving;
  bool get canStrike {
    final targetId = _attackTargetId;
    return canAttack &&
        targetId != null &&
        _rules.canAttack(
          _state,
          actorId: _dungeon.adventurer.id,
          targetId: targetId,
        );
  }

  bool get canEndTurn => isPlayerTurn && isBottomMenuEnabled && !isMoving;
  Set<GridPosition> get attackRange => isTargetingAttack
      ? {
          for (final direction in DungeonDirection.values)
            if (_dungeon.floor.contains(direction.stepFrom(_dungeon.player)))
              direction.stepFrom(_dungeon.player),
        }
      : const {};
  MovementPlan get plan => _plan;
  MovementPhase get phase => _phase;
  bool get isMoving => _phase == MovementPhase.moving;
  bool get canConfirm =>
      (isSelected || _controlMode == ControlMode.move) &&
      !isTargetingAttack &&
      isBottomMenuEnabled &&
      _plan.path.isNotEmpty &&
      (_phase == MovementPhase.dragging ||
          _phase == MovementPhase.awaitingConfirmation);
  bool get isSelected => _selection?.isAdventurer ?? false;
  GridPosition? get selectedPosition => _selection?.position;
  TileInspection? get selectedInspection => _selection;
  List<TileInspection> get selectionStack => _selectionStack;
  List<TileInspection> get alternateSelections {
    final selection = _selection;
    if (selection == null) {
      return const [];
    }
    return List.unmodifiable(
      _selectionStack.where((entry) => !entry.hasSameTarget(selection)),
    );
  }

  TileInspection? get alternateSelection => alternateSelections.firstOrNull;
  bool get isInspectingBelow =>
      _selection != null && !_selectionStack.first.hasSameTarget(_selection!);

  bool isAboveSelection(TileInspection target) {
    final selection = _selection;
    return selection != null &&
        _selectionStack.indexOf(target) < _selectionStack.indexOf(selection);
  }

  TileInspection? get inspectedTile => isSelected ? null : _selection;

  bool get isPaused => _isPaused;
  bool get isBottomMenuEnabled =>
      !_isPaused &&
      !_isPresenting &&
      !isEnemyTurn &&
      !isDefeated &&
      _pendingFloorChange == null &&
      _pendingInteraction == null &&
      _bottomMenuLocks.isEmpty;
  FloorChangeRequest? get pendingFloorChange => _pendingFloorChange;
  GroundObjectInteractionRequest? get pendingInteraction => _pendingInteraction;
  bool get _canSelect => isBottomMenuEnabled && !isMoving && !_isInteracting;

  bool completeFloorChange(DungeonFloor floor) {
    final request = _pendingFloorChange;
    if (_state.mode != GameMode.exploration ||
        isMoving ||
        _pendingInteraction != null ||
        request == null ||
        request.floorNumber != floor.number ||
        request.sourceFloorNumber != _dungeon.floor.number ||
        request.sourcePosition != _dungeon.player) {
      return false;
    }

    _state = GameState(
      dungeon: FloorZeroTestBats.apply(
        _dungeon.enterFloor(floor),
        enabled: _floorZeroBats,
      ),
    );
    _lastCombatEvent = null;
    _lastAttack = null;
    _controlMode = ControlMode.inspect;
    _clearAim();
    _pendingFloorChange = null;
    _interactionQueue.clear();
    _phase = MovementPhase.idle;
    _nextStep = 0;
    _setSelectionPair(const []);
    _interactAtPlayer();
    _plan = _newPlan();
    notifyListeners();
    return true;
  }

  /// Permite activar el mismo comportamiento desde menús, toques u otras acciones.
  /// Los objetos retirados, de otra planta o durante una acción bloqueada se ignoran.
  bool interactWith(InteractiveDungeonGroundObject object) {
    if (_state.mode != GameMode.exploration ||
        !isBottomMenuEnabled ||
        isMoving ||
        _isInteracting) {
      return false;
    }
    if (!_invokeInteraction(object, GroundObjectTrigger.activated)) {
      return false;
    }

    _phase = MovementPhase.idle;
    _refreshCombat();
    _plan = _newPlan();
    notifyListeners();
    return true;
  }

  bool _interactAtPlayer() {
    final wasInCombat = isInCombat;
    var stopsMovement = false;
    final objects = _dungeon.floor
        .interactiveObjectsAt(_dungeon.player)
        .toList();
    for (final object in objects) {
      if (object.interactionKind == GroundObjectInteractionKind.automatic) {
        if (_invokeInteraction(object, GroundObjectTrigger.enteredTile)) {
          stopsMovement = stopsMovement || object.stopsMovement;
        }
        continue;
      }
      if (_interactionQueue.any(
        (request) =>
            identical(request.object, object) &&
            request.floorNumber == _dungeon.floor.number &&
            request.playerPosition == _dungeon.player,
      )) {
        continue;
      }
      _interactionQueue.add(
        GroundObjectInteractionRequest(
          object: object,
          trigger: GroundObjectTrigger.enteredTile,
          floorNumber: _dungeon.floor.number,
          playerPosition: _dungeon.player,
        ),
      );
    }
    _refreshCombat();
    if (isInCombat || isDefeated) {
      return stopsMovement || !wasInCombat || isDefeated;
    }
    return _resolveInteractionQueue() || stopsMovement;
  }

  bool _resolveInteractionQueue() {
    if (_state.mode != GameMode.exploration) {
      return false;
    }
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
      _refreshCombat();
      if (_state.mode != GameMode.exploration) {
        return true;
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
    _refreshCombat();
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
    _state = _state.withDungeon(dungeon);
    final selection = _refreshSelection(_selection);
    _selection = selection;
    _selectionStack = selection == null
        ? const []
        : _dungeon.selectionStackAt(selection.position);
  }

  TileInspection? _refreshSelection(TileInspection? previous) {
    if (previous == null) {
      return null;
    }

    final actorId = previous.actorId;
    final position = actorId == null
        ? previous.position
        : _dungeon.positionOf(actorId);
    if (position == null) {
      return null;
    }

    return _dungeon
        .selectionStackAt(position)
        .where(previous.hasSameTarget)
        .firstOrNull;
  }

  void _requestFloorChange(int floorNumber) {
    if (_state.mode != GameMode.exploration) {
      return;
    }
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
    if (!_canSelect) {
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
    _setSelectionPair(
      position == null ? const [] : _dungeon.selectionStackAt(position),
    );
    if (isControlPadOpen) {
      notifyListeners();
      return;
    }
    _resetSelectionPlan();
  }

  void _setSelectionPair(List<TileInspection> stack) {
    _selectionStack = stack;
    _selection = stack.firstOrNull;
  }

  /// Selecciona cualquier contenido de la pila sin activar sus interacciones.
  void selectStackEntry(TileInspection target) {
    if (!_canSelect || !_selectionStack.contains(target)) {
      return;
    }
    _selection = target;
    if (isControlPadOpen) {
      notifyListeners();
      return;
    }
    _resetSelectionPlan();
  }

  void toggleStackSelection() {
    final alternate = alternateSelection;
    if (alternate != null) {
      selectStackEntry(alternate);
    }
  }

  void _resetSelectionPlan() {
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
    if (isControlPadOpen) {
      cancelPadDrag();
    } else {
      cancelDrag();
    }
    _isPaused = true;
    _movementTimer?.cancel();
    _movementTimer = null;
    _enemyTimer?.cancel();
    _enemyTimer = null;
    _presentationTimer?.cancel();
    _presentationTimer = null;
    notifyListeners();
  }

  void resume() {
    if (!_isPaused) {
      return;
    }
    _isPaused = false;
    if (isMoving) {
      _movementTimer = Timer.periodic(
        _playerMovementInterval(),
        (_) => _advance(),
      );
    }
    if (_isPresenting) {
      _schedulePresentationEnd();
    } else {
      _startEnemyTurns();
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
    if (!isSelected || !isBottomMenuEnabled || isMoving || isTargetingAttack) {
      return;
    }

    _plan = _newPlan();
    _planBeforePadDrag = null;
    _phase = MovementPhase.dragging;
    notifyListeners();
  }

  void preview(DungeonDirection direction, {int steps = 1}) {
    if ((!isSelected && _controlMode != ControlMode.move) ||
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
    _planBeforePadDrag = null;
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

    _planBeforePadDrag = null;
    _plan = _newPlan();
    _phase = MovementPhase.idle;
    notifyListeners();
  }

  void confirm() {
    if (!canConfirm) {
      return;
    }

    _planBeforePadDrag = null;
    _phase = MovementPhase.moving;
    _nextStep = 0;
    _movementTimer = Timer.periodic(
      _playerMovementInterval(),
      (_) => _advance(),
    );
    disableBottomMenu(_movementMenuLock);
  }

  void _advance() {
    final transition = _rules.resolve(
      _state,
      MoveActor(
        actorId: _dungeon.adventurer.id,
        destination: _plan.path[_nextStep],
      ),
    );
    if (!transition.accepted) {
      _finishMovement();
      return;
    }

    _recordTransition(transition);
    if (!isInCombat) {
      _lastCombatEvent = null;
    }
    _setSelectionPair(_dungeon.selectionStackAt(_dungeon.player));
    _nextStep++;
    final interactionStopsMovement = _interactAtPlayer();
    if (_nextStep == _plan.path.length || interactionStopsMovement) {
      _finishMovement();
      return;
    }
    notifyListeners();
  }

  void _finishMovement() {
    _movementTimer?.cancel();
    _movementTimer = null;
    _phase = MovementPhase.idle;
    _nextStep = 0;
    _plan = _newPlan();
    enableBottomMenu(_movementMenuLock);
  }

  void beginAttack() {
    if (!canAttack || isTargetingAttack) {
      return;
    }
    _planBeforePadDrag = null;
    _phase = MovementPhase.idle;
    _plan = _newPlan();
    _controlMode = ControlMode.strike;
    _clearAim();
    notifyListeners();
  }

  void beginMove() {
    if (!canOpenMove || _controlMode == ControlMode.move) {
      return;
    }
    _planBeforePadDrag = null;
    _controlMode = ControlMode.move;
    _clearAim();
    _phase = MovementPhase.idle;
    _plan = _newPlan();
    notifyListeners();
  }

  void closeControls() {
    if (!canOpenMove) {
      return;
    }
    if (_selection == null) {
      _setSelectionPair(_dungeon.selectionStackAt(_dungeon.player));
    }
    _controlMode = ControlMode.inspect;
    _clearAim();
    _phase = MovementPhase.idle;
    _plan = _newPlan();
    _planBeforePadDrag = null;
    notifyListeners();
  }

  /// Un segundo gesto continúa la ruta; no restaura el saldo del turno.
  void beginPadDrag() {
    if (_controlMode != ControlMode.move || !canOpenMove) {
      return;
    }
    _planBeforePadDrag = _plan;
    _phase = MovementPhase.dragging;
    notifyListeners();
  }

  void cancelPadDrag() {
    final previous = _planBeforePadDrag;
    if (_phase != MovementPhase.dragging || previous == null) {
      return;
    }
    _plan = previous;
    _planBeforePadDrag = null;
    _phase = _plan.path.isEmpty
        ? MovementPhase.idle
        : MovementPhase.awaitingConfirmation;
    notifyListeners();
  }

  void aim(DungeonDirection? direction) {
    if (!isTargetingAttack || !canAttack) {
      return;
    }
    _aimDirection = direction;
    _attackTargetId = null;
    final position = direction?.stepFrom(_dungeon.player);
    final target = position == null ? null : _dungeon.actorAt(position);
    if (target != null &&
        _rules.canAttack(
          _state,
          actorId: controlledActorId,
          targetId: target.id,
        )) {
      _attackTargetId = target.id;
    }
    notifyListeners();
  }

  void confirmAction() {
    if (isTargetingAttack) {
      strike();
    } else {
      confirm();
    }
  }

  void cancelAction() {
    if (!isBottomMenuEnabled || isMoving) {
      return;
    }
    if (isTargetingAttack) {
      _clearAim();
      notifyListeners();
    } else {
      cancelPreview();
    }
  }

  void _clearAim() {
    _aimDirection = null;
    _attackTargetId = null;
  }

  void setFloorZeroBats(bool enabled) {
    if (_floorZeroBats == enabled) {
      return;
    }
    _floorZeroBats = enabled;
    final wasInCombat = isInCombat;
    _state = _state.withDungeon(
      FloorZeroTestBats.apply(_dungeon, enabled: enabled),
    );
    _refreshCombat();
    if (!wasInCombat && isInCombat && isMoving) {
      _finishMovement();
    }
    if (!isMoving) {
      _plan = _newPlan();
    }
    if (!isEnemyTurn) {
      _enemyTimer?.cancel();
      _enemyTimer = null;
    }
    notifyListeners();
  }

  void cancelAttack() {
    if (!_canSelect) {
      return;
    }
    _controlMode = ControlMode.move;
    _clearAim();
    notifyListeners();
  }

  void strike() {
    final targetId = _attackTargetId;
    if (!canStrike || targetId == null) {
      return;
    }
    final transition = _rules.resolve(
      _state,
      AttackActor(actorId: _dungeon.adventurer.id, targetId: targetId),
    );
    if (!transition.accepted) {
      return;
    }
    _clearAim();
    _recordTransition(transition);
    _plan = _newPlan();
    _isPresenting = true;
    _schedulePresentationEnd();
    notifyListeners();
  }

  void endTurn() {
    if (!canEndTurn) {
      return;
    }
    _planBeforePadDrag = null;
    _controlMode = ControlMode.move;
    _clearAim();
    _phase = MovementPhase.idle;
    _recordTransition(
      _rules.resolve(_state, EndActorTurn(_dungeon.adventurer.id)),
    );
    _plan = _newPlan();
    _startEnemyTurns();
    notifyListeners();
  }

  void _schedulePresentationEnd() {
    _presentationTimer?.cancel();
    _presentationTimer = Timer(_playerMovementInterval(), () {
      if (_isDisposed || _isPaused) {
        return;
      }
      _presentationTimer = null;
      _isPresenting = false;
      _resolveInteractionQueue();
      _startEnemyTurns();
      notifyListeners();
    });
  }

  void _startEnemyTurns() {
    if (!isEnemyTurn || _isPaused || _isPresenting || _enemyTimer != null) {
      return;
    }
    final enemy = _dungeon.floor.enemyById(encounter?.activeActorId ?? '');
    if (enemy == null) {
      return;
    }
    _enemyTimer = Timer(enemy.type.stepInterval, _advanceEnemy);
  }

  void _advanceEnemy() {
    _enemyTimer = null;
    if (_isDisposed || _isPaused) {
      return;
    }
    _refreshCombat();
    final command = _enemyTactics.nextCommand(_state);
    if (command != null) {
      _recordTransition(_rules.resolve(_state, command));
      _refreshCombat();
    }
    if (!isEnemyTurn) {
      _resolveInteractionQueue();
    }
    _plan = _newPlan();
    _startEnemyTurns();
    notifyListeners();
  }

  void _refreshCombat() => _recordTransition(_rules.refresh(_state));

  void _recordTransition(GameTransition transition) {
    final wasInCombat = isInCombat;
    _state = transition.state;
    for (final event in transition.events) {
      if (event is AttackResolved) {
        _lastAttack = event;
        _attackSequence++;
      }
      if (event is AttackResolved ||
          event is EncounterStarted ||
          event is EncounterWon ||
          event is ActorDefeated && event.actorId == _dungeon.adventurer.id) {
        _lastCombatEvent = event;
      }
    }
    if ((!wasInCombat && isInCombat) || isDefeated) {
      _pendingFloorChange = null;
      _pendingInteraction = null;
      _controlMode = isDefeated ? ControlMode.inspect : ControlMode.move;
      _clearAim();
      _setSelectionPair(_dungeon.selectionStackAt(_dungeon.player));
    } else {
      if (wasInCombat && !isInCombat) {
        _controlMode = ControlMode.move;
        _clearAim();
      }
      final selection = _refreshSelection(_selection);
      _selection = selection;
      _selectionStack = selection == null
          ? const []
          : _dungeon.selectionStackAt(selection.position);
    }
    if (isDefeated) {
      _interactionQueue.clear();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _movementTimer?.cancel();
    _enemyTimer?.cancel();
    _presentationTimer?.cancel();
    super.dispose();
  }
}
