import 'package:flutter/material.dart';

import 'app/dungeon_theme.dart';
import 'features/shards/presentation/shard_scope.dart';
import 'features/dungeon/presentation/dungeon_strings.dart';
import 'features/main_menu/presentation/main_menu_page.dart';
import 'widgets/iris_transition.dart';

void main() {
  runApp(const DungeonCrawlerApp());
}

class DungeonCrawlerApp extends StatefulWidget {
  const DungeonCrawlerApp({super.key});

  @override
  State<DungeonCrawlerApp> createState() => _DungeonCrawlerAppState();
}

class _DungeonCrawlerAppState extends State<DungeonCrawlerApp> {
  final _shards = ShardController();

  @override
  void dispose() {
    _shards.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShardScope(
    controller: _shards,
    child: MaterialApp(
      title: DungeonStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: DungeonTheme.dark,
      builder: (context, child) =>
          IrisTransition(child: child ?? const SizedBox.shrink()),
      home: const MainMenuPage(),
    ),
  );
}
