import 'package:flutter/material.dart';

import 'app/dungeon_theme.dart';
import 'features/dungeon/presentation/dungeon_strings.dart';
import 'features/main_menu/presentation/main_menu_page.dart';
import 'widgets/iris_transition.dart';

void main() {
  runApp(const DungeonCrawlerApp());
}

class DungeonCrawlerApp extends StatelessWidget {
  const DungeonCrawlerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: DungeonStrings.appTitle,
    debugShowCheckedModeBanner: false,
    theme: DungeonTheme.dark,
    builder: (context, child) =>
        IrisTransition(child: child ?? const SizedBox.shrink()),
    home: const MainMenuPage(),
  );
}
