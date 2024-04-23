import 'package:flutter/material.dart';
import '../helpers/utils/sec_storage.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  /// current theme mode [light, theme or system]
  ThemeMode get themeMode => _themeMode;

  /// gets theme mode immediately ThemeProvider is initialized
  ThemeProvider() {
    _getThemeMode();
  }

  /// gets saved theme mode. If null is found, defaults to system theme
  Future<void> _getThemeMode() async {
    String? theme = await secStorage.read(key: "theme");

    switch (theme) {
      case "light":
        _themeMode = ThemeMode.light;
      case "dark":
        _themeMode = ThemeMode.dark;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// change theme mode
  Future changeTheme(String theme) async {
    if (theme == "light") {
      await secStorage.write(key: "theme", value: "light");
      _themeMode = ThemeMode.light;
    } else if (theme == "dark") {
      await secStorage.write(key: "theme", value: "dark");
      _themeMode = ThemeMode.dark;
    } else {
      await secStorage.write(key: "theme", value: "system");
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }
}