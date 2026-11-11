import 'package:flutter/material.dart';

abstract final class DungeonColors {
  static const voidTile = Color(0xFF000000);
  static const background = voidTile;
  static const panel = voidTile;
  static const surface = voidTile;
  static const floorTile = Color(0xFF303030);
  static const wallTile = Color(0xFF606060);
  static const grass = Color(0xFFB0B0B0);
  static const water = Color(0xFF606060);
  static const primary = Color(0xFFFFFFFF);
  static const surfaceRaised = primary;
  static const textPrimary = primary;
  static const textSecondary = primary;
  static const textDisabled = Color(0xFF808080);
  static const enemy = textDisabled;
  static const shallowWaterPrefix = grass;
  static const shallowWaterBorder = shallowWaterPrefix;
}

abstract final class DungeonTheme {
  static const spacing = 8.0;
  static const pagePadding = 16.0;
  static const cornerRadius = 0.0;
  static const selectedBorderWidth = 2.0;

  static final dark = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'monospace',
    scaffoldBackgroundColor: DungeonColors.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(
      primary: DungeonColors.primary,
      onPrimary: DungeonColors.background,
      primaryContainer: DungeonColors.background,
      onPrimaryContainer: DungeonColors.primary,
      secondary: DungeonColors.primary,
      onSecondary: DungeonColors.background,
      secondaryContainer: DungeonColors.background,
      onSecondaryContainer: DungeonColors.primary,
      tertiary: DungeonColors.primary,
      onTertiary: DungeonColors.background,
      tertiaryContainer: DungeonColors.background,
      onTertiaryContainer: DungeonColors.primary,
      surface: DungeonColors.panel,
      onSurface: DungeonColors.textPrimary,
      onSurfaceVariant: DungeonColors.primary,
      surfaceTint: Colors.transparent,
      surfaceDim: DungeonColors.background,
      surfaceBright: DungeonColors.background,
      surfaceContainerLowest: DungeonColors.background,
      surfaceContainerLow: DungeonColors.background,
      surfaceContainer: DungeonColors.background,
      surfaceContainerHigh: DungeonColors.background,
      surfaceContainerHighest: DungeonColors.background,
      outline: DungeonColors.primary,
      outlineVariant: DungeonColors.primary,
      inverseSurface: DungeonColors.primary,
      onInverseSurface: DungeonColors.background,
      inversePrimary: DungeonColors.background,
      error: DungeonColors.primary,
      onError: DungeonColors.background,
      errorContainer: DungeonColors.background,
      onErrorContainer: DungeonColors.primary,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontFamily: 'monospace',
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: DungeonColors.textPrimary,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: DungeonColors.textPrimary),
      bodySmall: TextStyle(fontSize: 12, color: DungeonColors.textSecondary),
    ),
    dividerColor: DungeonColors.primary,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DungeonColors.primary,
        backgroundColor: DungeonColors.background,
        side: const BorderSide(color: DungeonColors.primary),
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(),
        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 16),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: DungeonColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: DungeonColors.primary, width: 2),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: DungeonColors.primary,
      inactiveTrackColor: DungeonColors.primary,
      thumbColor: DungeonColors.primary,
      overlayColor: Colors.transparent,
    ),
  );
}
