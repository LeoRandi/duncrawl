class EncounterState {
  final List<String> enemyIds;
  final List<String> enemyTurnOrder;
  final String activeActorId;
  final int round;
  final int remainingMovement;
  final bool actionAvailable;

  EncounterState({
    required Iterable<String> enemyIds,
    Iterable<String> enemyTurnOrder = const [],
    required this.activeActorId,
    required this.remainingMovement,
    this.round = 1,
    this.actionAvailable = true,
  }) : enemyIds = List.unmodifiable(enemyIds),
       enemyTurnOrder = List.unmodifiable(enemyTurnOrder),
       assert(round > 0),
       assert(remainingMovement >= 0);

  EncounterState copyWith({
    Iterable<String>? enemyIds,
    Iterable<String>? enemyTurnOrder,
    String? activeActorId,
    int? round,
    int? remainingMovement,
    bool? actionAvailable,
  }) => EncounterState(
    enemyIds: enemyIds ?? this.enemyIds,
    enemyTurnOrder: enemyTurnOrder ?? this.enemyTurnOrder,
    activeActorId: activeActorId ?? this.activeActorId,
    round: round ?? this.round,
    remainingMovement: remainingMovement ?? this.remainingMovement,
    actionAvailable: actionAvailable ?? this.actionAvailable,
  );
}
