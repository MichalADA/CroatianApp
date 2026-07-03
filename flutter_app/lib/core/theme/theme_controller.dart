import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller motywu — persistuje wybór w SharedPreferences, wystawia
/// aktualny [ThemeMode] przez [themeModeProvider].
///
/// Backend też ma pole `theme`, ale to jest tylko cache — źródło prawdy dla
/// UI jest tu, a synchronizacja z serwerem odbywa się w profile feature.
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._prefs) : super(_read(_prefs));

  static const String _key = 'app_theme_mode';

  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) {
    return switch (prefs.getString(_key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override in main() with .overrideWithValue'),
);

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController(ref.watch(sharedPreferencesProvider));
});
