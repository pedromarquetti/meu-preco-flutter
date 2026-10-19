import 'dart:async';

import 'package:meu_preco_frontend/core/http/auth_token_source.dart';
import 'package:meu_preco_frontend/core/http/server_health_service.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/core/storage/credential_store.dart';
import 'package:meu_preco_frontend/core/storage/key_value_store.dart';
import 'package:meu_preco_frontend/features/auth/data/auth_repository.dart';

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

/// In-memory [CredentialStore] for exercising the session lifecycle.
class InMemoryCredentialStore implements CredentialStore {
  InMemoryCredentialStore([this._session]);

  StoredSession? _session;
  int readCalls = 0;
  int writeCalls = 0;
  int clearCalls = 0;

  StoredSession? get session => _session;

  @override
  Future<StoredSession?> read() async {
    readCalls++;
    return _session;
  }

  @override
  Future<void> write(StoredSession session) async {
    writeCalls++;
    _session = session;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    _session = null;
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

/// Configurable [AuthRepository] that never touches the network.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    User? user,
    this.loginError,
    this.registerError,
    this.refreshError,
    this.currentUserError,
  }) : user =
           user ??
           const User(id: 1, email: 'user@example.com', role: UserRole.user);

  User user;
  Object? loginError;
  Object? registerError;
  Object? refreshError;
  Object? currentUserError;

  int loginCalls = 0;
  int registerCalls = 0;
  int refreshCalls = 0;
  int currentUserCalls = 0;

  /// When set, [refresh] waits for this before completing, so tests can observe
  /// concurrent refreshes sharing one operation.
  Completer<void>? refreshGate;

  int _tokenCounter = 0;

  AuthPair _nextPair() {
    _tokenCounter++;
    return AuthPair(
      accessToken: 'access-$_tokenCounter',
      refreshToken: 'refresh-$_tokenCounter',
      user: user,
    );
  }

  @override
  Future<AuthPair> login(Credentials credentials) async {
    loginCalls++;
    if (loginError != null) throw loginError!;
    return _nextPair();
  }

  @override
  Future<User> register(Credentials credentials) async {
    registerCalls++;
    if (registerError != null) throw registerError!;
    return user;
  }

  @override
  Future<AuthPair> refresh(RefreshRequest request) async {
    refreshCalls++;
    final gate = refreshGate;
    if (gate != null) await gate.future;
    if (refreshError != null) throw refreshError!;
    return _nextPair();
  }

  @override
  Future<User> currentUser(String accessToken) async {
    currentUserCalls++;
    if (currentUserError != null) throw currentUserError!;
    return user;
  }
}

/// Controllable [AuthTokenSource] for [AuthenticatedClient] tests.
class FakeAuthTokenSource implements AuthTokenSource {
  FakeAuthTokenSource({
    String? accessToken,
    this.refreshResult = true,
    this.rotatedAccessToken,
  }) : _accessToken = accessToken; // ignore: prefer_initializing_formals

  String? _accessToken;

  /// Whether [refreshAccessToken] reports success.
  bool refreshResult;

  /// When set, a successful refresh installs this as the new access token.
  String? rotatedAccessToken;

  int refreshCalls = 0;

  /// When set, [refreshAccessToken] waits for this before completing.
  Completer<void>? gate;

  set accessToken(String? value) => _accessToken = value;

  @override
  String? get accessToken => _accessToken;

  @override
  Future<bool> refreshAccessToken() async {
    refreshCalls++;
    final pending = gate;
    if (pending != null) await pending.future;
    if (refreshResult && rotatedAccessToken != null) {
      _accessToken = rotatedAccessToken;
    }
    return refreshResult;
  }
}
