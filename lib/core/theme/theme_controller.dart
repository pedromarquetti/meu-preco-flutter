import 'package:flutter/material.dart';

import '../storage/key_value_store.dart';

/// Persists and exposes the app's theme mode.
class ThemeController extends ChangeNotifier {
  ThemeController({required this.store});

  static const String _key = 'theme_mode';

  final KeyValueStore store;

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    final value = await store.readString(_key);
    _mode = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    await store.writeString(_key, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    notifyListeners();
  }
}
