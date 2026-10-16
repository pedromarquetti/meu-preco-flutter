/// Minimal key/value storage abstraction used by configuration and session
/// state.
///
/// Keeping this behind an interface lets the app run with an in-memory fake in
/// tests while production uses `shared_preferences` (and a dedicated secure
/// store for credentials).
abstract interface class KeyValueStore {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<void> remove(String key);

  Future<void> clear();
}
