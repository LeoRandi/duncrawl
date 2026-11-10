import '../../settings/domain/text_speed.dart';

abstract final class DungeonStrings {
  static const appTitle = 'Dungeon Crawler 0';
  static const adventurer = 'Adventurer';
  static const stairs = 'Stairs leading upstairs';
  static const grass = 'Grass';
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
  static const optionMenu = 'Movement options';
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

  static String textSpeedName(TextSpeed speed) => switch (speed) {
    TextSpeed.slow => slowText,
    TextSpeed.medium => mediumText,
    TextSpeed.fast => fastText,
    TextSpeed.instant => instantText,
  };

  static String textSpeedSetting(TextSpeed speed) =>
      'Text speed: ${textSpeedName(speed)}';

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

  static String floor(int number) => 'Tower – Floor $number';

  static String level(int level) => 'Lv. $level';

  static String health({required int current, required int maximum}) =>
      'HP $current/$maximum';

  static String playerPosition({required int column, required int row}) =>
      'Adventurer, column $column, row $row';
}
