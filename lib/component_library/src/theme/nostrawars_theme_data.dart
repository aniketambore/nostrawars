import 'package:flutter/material.dart';
import 'colors.dart';

abstract class NostraWarsThemeData {
  ThemeData get materialThemeData;
}

class LightThemeData extends NostraWarsThemeData {
  @override
  ThemeData get materialThemeData => ThemeData(
      brightness: Brightness.light,
      primarySwatch: persianBlue.toMaterialColor());
}

class DarkThemeData extends NostraWarsThemeData {
  // @override
  // ThemeData get materialThemeData => ThemeData(
  //       brightness: Brightness.dark,
  //       primarySwatch: persianBlue.toMaterialColor(),
  //     );

  @override
  ThemeData get materialThemeData => ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFBB86FC),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        disabledColor: const Color(0xFF3E3E3E),
        primaryTextTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: Color(0xFFFFFFFF),
          ),
          bodyLarge: TextStyle(
            color: Color(0xFFFFFFFF),
          ),
          labelLarge: TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
          ),
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xFFBB86FC),
          disabledColor: Color(0xFF3E3E3E),
          textTheme: ButtonTextTheme.primary,
        ),
      );
}

extension on Color {
  Map<int, Color> _toSwatch() => {
        50: withOpacity(0.1),
        100: withOpacity(0.2),
        200: withOpacity(0.3),
        300: withOpacity(0.4),
        400: withOpacity(0.5),
        500: withOpacity(0.6),
        600: withOpacity(0.7),
        700: withOpacity(0.8),
        800: withOpacity(0.9),
        900: this,
      };

  MaterialColor toMaterialColor() => MaterialColor(
        value,
        _toSwatch(),
      );
}
