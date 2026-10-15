import 'package:meu_preco_frontend/core/http/server_health_service.dart';
import 'package:meu_preco_frontend/core/storage/key_value_store.dart';

/// In-memory [KeyValueStore] so tests never touch platform storage.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _data = <String, String>{};

  Map<String, String> get entries => Map.unmodifiable(_data);

  @override
  Future<String?> readString(String key) async => _data[key];

  @override
  Future<void> writeString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }
}

/// Controllable [ServerHealthChecker] for driving the server-config flow in
/// widget tests without networking.
class FakeServerHealthChecker implements ServerHealthChecker {
  FakeServerHealthChecker({
    ServerHealthResult? result,
    ServerHealthResult? readiness,
  }) : _result = result ?? const ServerHealthResult.ok(),
       _readiness = readiness ?? result ?? const ServerHealthResult.ok();

  ServerHealthResult _result;
  ServerHealthResult _readiness;
  int callCount = 0;
  final List<String> requestedOrigins = <String>[];

  set result(ServerHealthResult value) => _result = value;

  set readiness(ServerHealthResult value) => _readiness = value;

  @override
  Future<ServerHealthResult> check(String rawOrigin) async {
    callCount++;
    requestedOrigins.add(rawOrigin);
    return _result;
  }

  @override
  Future<ServerHealthResult> checkReadiness(String rawOrigin) async {
    callCount++;
    requestedOrigins.add(rawOrigin);
    return _readiness;
  }
}
