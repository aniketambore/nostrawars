import 'package:flutter/material.dart';
import 'component_library/component_library.dart';
import 'features/main_page/src/main_page_screen.dart';

void main() {
  runApp(const NostraWarsApp());
}

class NostraWarsApp extends StatefulWidget {
  const NostraWarsApp({super.key});

  @override
  State<NostraWarsApp> createState() => _NostraWarsAppState();
}

class _NostraWarsAppState extends State<NostraWarsApp> {
  final _lightTheme = LightThemeData();
  final _darkTheme = DarkThemeData();

  @override
  Widget build(BuildContext context) {
    return NostraWarsTheme(
      lightTheme: _lightTheme,
      darkTheme: _darkTheme,
      child: MaterialApp(
        title: 'Nostrawars',
        theme: _darkTheme.materialThemeData,
        darkTheme: _darkTheme.materialThemeData,
        themeMode: ThemeMode.dark,
        home: const MainPageScreen(),
      ),
    );
  }
}
