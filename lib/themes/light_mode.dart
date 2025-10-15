import 'package:flutter/material.dart';

/// LIGHT — графит-минимал
final ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,

    // Базовые слои
    surface:    Color(0xFFF0F0F0),   // карточки / списки


    // «Акцент» = холодный средне-серый
    primary:    Color(0xFF8E8E93),   // System Gray
    onPrimary:  Colors.white,        // иконки/текст на серой кнопке

    // Вторичного и третичного цветов нет ― сохраняем монохром
    secondary:  Color(0xFF8E8E93),
    onSecondary:Colors.white,
    tertiary:   Color(0xFF8E8E93),
    onTertiary: Color(0xFF4A90E2),

    // Ошибки (оставим чуть теплее, но всё ещё скромно-серые)
    error:      Color(0xFFB00020),
    onError:    Colors.white,

    // Контрастный текст

    onSurface:    Color(0xFF1C1C1E),

    // Контейнеры (Material 3)
    primaryContainer:   Color(0xFFD1D1D6),
    secondaryContainer: Color(0xFFE5E5EA),
  ),

  scaffoldBackgroundColor: const Color(0xFFF9F9F9),

  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Color(0xFFF0F0F0),
    foregroundColor: Color(0xFF1C1C1E),
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1C1C1E),
    ),
  ),
);