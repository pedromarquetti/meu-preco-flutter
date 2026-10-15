import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

/// [KeyValueStore] backed by `shared_preferences`.
///
/// Only non-sensitive configuration is stored here for now. Credentials will
/// use a dedicated secure storage abstraction introduced later.
class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore(this._preferences);

  final SharedPreferences _preferences;

  static Future<SharedPreferencesKeyValueStore> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesKeyValueStore(preferences);
  }

  @override
  Future<String?> readString(String key) async => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }

  @override
  Future<void> clear() async {
    await _preferences.clear();
  }
}
