import 'game_event.dart';
import 'game_state.dart';

class GameTransition {
  final GameState state;
  final List<GameEvent> events;
  final bool accepted;

  GameTransition(this.state, Iterable<GameEvent> events)
    : events = List.unmodifiable(events),
      accepted = true;

  const GameTransition.rejected(this.state)
    : events = const [],
      accepted = false;
}
