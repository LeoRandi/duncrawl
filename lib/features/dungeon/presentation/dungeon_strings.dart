abstract final class DungeonStrings {
  static const appTitle = 'Dungeon Crawler 0';
  static const adventurer = 'Adventurer';
  static const stairs = 'Stairs leading upstairs';
  static const grid = 'Dungeon, 15 by 15 tiles';
  static const emptyMenu = 'Empty option menu';
  static const start = 'Start';
  static const settings = 'Settings';
  static const close = 'Close';
  static const mainMenu = 'Main menu';
  static const movementSensitivity = 'Movement sensitivity';
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
