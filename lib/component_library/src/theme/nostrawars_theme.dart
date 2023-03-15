import 'package:flutter/material.dart';

import 'nostrawars_theme_data.dart';

class NostraWarsTheme extends InheritedWidget {
  const NostraWarsTheme({
    super.key,
    required Widget child,
    required this.lightTheme,
    required this.darkTheme,
  }) : super(
          child: child,
        );

  final NostraWarsThemeData lightTheme;
  final NostraWarsThemeData darkTheme;

  @override
  bool updateShouldNotify(NostraWarsTheme oldWidget) =>
      oldWidget.lightTheme != lightTheme || oldWidget.darkTheme != darkTheme;

  static NostraWarsThemeData of(BuildContext context) {
    final NostraWarsTheme? inheritedTheme =
        context.dependOnInheritedWidgetOfExactType<NostraWarsTheme>();
    assert(inheritedTheme != null, 'No NostraWarsTheme found in context');

    final currentBrightness = Theme.of(context).brightness;

    return currentBrightness == Brightness.dark
        ? inheritedTheme!.darkTheme
        : inheritedTheme!.lightTheme;
  }
}
