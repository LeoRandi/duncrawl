import '../../settings/domain/text_speed.dart';
import '../../settings/domain/movement_speed.dart';

abstract final class DungeonStrings {
  static const appTitle = 'Dungeon Crawler 0';
  static const adventurer = 'Adventurer';
  static const adventurerDescription =
      'A lone adventurer exploring the dungeon.';
  static const stairs = 'Stairs leading upstairs';
  static const stairsName = 'Upstairs';
  static const stairsDescription = 'Stairs leading to a higher floor.';
  static const grass = 'Grass';
  static const grassDescription =
      'A patch of grass growing on the dungeon floor.';
  static const water = 'Water';
  static const waterDescription =
      'Water: liquid. Normally unwalkable, unless you fly';
  static const shallowWater = 'Shallow Water';
  static const shallowWaterDescription =
      'Shallow: This pool of liquid is walkable';
  static const bat = 'Bat';
  static const batDescription = 'A bat found in the dungeon.';
  static const movementHelp =
      'Walkable amount of tiles per turn outside of combat. When in combat, its always reduced by two, as shown in the parenthesys';
  static const dismissStatInfo = 'Dismiss stat information';
  static const tutorialSelectBat =
      'Select a Bat to see its description and stats.';
  static const tutorialBatStats =
      'Here you can see its description, level, HP and Movement. Tap (?) beside Movement to learn what it means.';
  static const wall = 'Wall';
  static const wallDescription = 'A solid wall that blocks movement.';
  static const skipTutorials = 'Skip tutorials';
  static const ultraFast = 'Ultra Fast';
  static const grid = 'Dungeon, 15 by 15 tiles';
  static const emptyMenu = 'Empty option menu';
  static const start = 'Start';
  static const settings = 'Settings';
  static const close = 'Close';
  static const mainMenu = 'Main menu';
  static const movementSensitivity = 'Movement sensitivity';
  static const autoClimbStairs = 'Auto-climb stairs';
  static const autoPickUpItems = 'Auto-pick-up items';
  static const climbStairsQuestion = 'Climb the stairs?';
  static const pickUpItemQuestion = 'Pick up this item?';
  static const activateObjectQuestion = 'Activate this object?';
  static const yes = 'Yes';
  static const no = 'No';
  static const slowText = 'Slow';
  static const mediumText = 'Medium';
  static const fastText = 'Fast';
  static const instantText = 'Instant';
  static const slower = 'Slower';
  static const faster = 'Faster';
  static const done = 'Done';
  static const confirm = 'Confirm';
  static const moving = 'Moving…';
  static const optionMenu = 'Selection options';
  static const menu = 'Menu';
  static const continueGame = 'Continue';
  static const bestiary = 'Bestiary';
  static const emptyBestiary = 'No creatures discovered yet.';
  static const back = 'Back';
  static const unselect = 'Unselect';
  static const selectAdventurer = 'Select adventurer';
  static const selectPrompt = 'Select something to continue';
  static const movement = 'Movement';
  static const tutorialSelect = 'Select your character to allow movement';
  static const tutorialDrag = 'Now try dragging around to move the character';
  static const tutorialStairs = 'Use the stairs to exit this floor';
  static const mysteriousVoice = 'Misteryous voice';
  static const tutorialInspectTile =
      'Tap a tile with letters or an object to select it and view its details.';
  static const tutorialTileDetails =
      'The bottom panel shows the selected tile\'s name, description and portrait. '
      'Tap an empty tile to clear the selection.';

  static String over(String name) => 'Over: $name';
  static String below(String name) => 'Below: $name';
  static String statInfo(String name) => 'About $name';
  static String movementStat({required int normal, required int combat}) =>
      '$normal($combat)';

  static String textSpeedName(TextSpeed speed) => switch (speed) {
    TextSpeed.slow => slowText,
    TextSpeed.medium => mediumText,
    TextSpeed.fast => fastText,
    TextSpeed.instant => instantText,
  };

  static String textSpeedSetting(TextSpeed speed) =>
      'Text speed: ${textSpeedName(speed)}';

  static String movementSpeedName(MovementSpeed speed) => switch (speed) {
    MovementSpeed.slow => slowText,
    MovementSpeed.medium => mediumText,
    MovementSpeed.fast => fastText,
    MovementSpeed.ultraFast => ultraFast,
  };

  static String movementSpeedSetting(MovementSpeed speed) =>
      'Movement speed: ${movementSpeedName(speed)}';

  static String movementAllowance({
    required int remaining,
    required int total,
  }) => '$remaining/$total';

  static String destination({required int column, required int row}) =>
      'Destination: column $column, row $row';

  static String pathStep({
    required int step,
    required int column,
    required int row,
  }) => 'Step $step, column $column, row $row';

  static String level(int level) => 'Lv. $level';

  static String health({required int current, required int maximum}) =>
      'HP $current/$maximum';

  static String playerPosition({required int column, required int row}) =>
      'Adventurer, column $column, row $row';
}
