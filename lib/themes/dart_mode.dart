import 'package:flutter/material.dart';/// Тёмная тема в том же ключе
final ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,

    surface:    Color(0xFF1C1C1E),   // карточки / модалки

    primary:    Color(0xFF8E8E93),   // тот же нейтральный серый
    onPrimary:  Colors.black,

    secondary:  Color(0xFF8E8E93),
    onSecondary:Colors.black,
    tertiary:   Color(0xFF8E8E93),
    onTertiary: Color(0xFF4A90E2),

    error:      Color(0xFFCF6679),
    onError:    Colors.black,

    onSurface:    Colors.white,

    primaryContainer:   Color(0xFF636366),
    secondaryContainer: Color(0xFF48484A),
  ),

  scaffoldBackgroundColor: const Color(0xFF000000),

  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Color(0xFF1C1C1E),
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
);