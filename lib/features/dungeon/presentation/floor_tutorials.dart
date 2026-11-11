import 'dungeon_tutorial_lesson.dart';
import 'floor_one_tutorial.dart';
import 'floor_two_tutorial.dart';
import 'opening_tutorial.dart';

const dungeonTutorials = <int, DungeonTutorialLesson>{
  0: DungeonTutorialLesson(
    delay: OpeningTutorial.delay,
    dialogue: OpeningTutorial.dialogue,
    guide: OpeningTutorial.guide,
  ),
  1: DungeonTutorialLesson(
    delay: FloorOneTutorial.delay,
    dialogue: FloorOneTutorial.dialogue,
    guide: FloorOneTutorial.guide,
  ),
  2: DungeonTutorialLesson(
    delay: FloorTwoTutorial.delay,
    dialogue: FloorTwoTutorial.dialogue,
    guide: FloorTwoTutorial.guide,
  ),
};
