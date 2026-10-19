import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/http/auth_token_source.dart';
import '../../core/models/models.dart';
import '../../core/storage/credential_store.dart';
import 'data/auth_repository.dart';

/// The lifecycle states of the authentication session.
enum AuthStatus {
  /// Not yet restored from storage.
  unknown,

  /// No valid session; the user must sign in.
  unauthenticated,

  /// A session is held and (optimistically) usable.
  authenticated,

  /// A session existed but could no longer be refreshed; sign-in is required.
  expired,
}

/// Owns the authentication session: token pair, current user, credential
/// storage, and the single-flight refresh used by the HTTP layer.
///
/// It is a [ChangeNotifier] so navigation guards and screens can react to
/// sign-in/out, and an [AuthTokenSource] so [AuthenticatedClient] can recover
/// from expired tokens without depending on feature code.
class AuthSession extends ChangeNotifier implements AuthTokenSource {
  AuthSession({
    required AuthRepository repository,
    required CredentialStore credentialStore,
  }) : _repository = repository, // ignore: prefer_initializing_formals
       // ignore: prefer_initializing_formals
       _credentialStore = credentialStore;

  final AuthRepository _repository;
  final CredentialStore _credentialStore;

  AuthStatus _status = AuthStatus.unknown;
  String? _accessToken;
  String? _refreshToken;
  User? _user;
  Future<bool>? _refreshInFlight;

  /// Current lifecycle state.
  AuthStatus get status => _status;

  /// The signed-in user, when known.
  User? get user => _user;

  /// Whether a usable session is held.
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Whether the current user has the admin role.
  bool get isAdmin => _user?.role == UserRole.admin;

  /// The current refresh token, exposed for tests and diagnostics.
  String? get refreshToken => _refreshToken;

  @override
  String? get accessToken => _accessToken;

  /// Restores a persisted session without hitting the network.
  ///
  /// A stored session is trusted optimistically so the UI can render
  /// immediately; call [validate] afterwards to confirm it with the server.
  Future<void> restore() async {
    final stored = await _credentialStore.read();
    if (stored == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _accessToken = stored.accessToken;
    _refreshToken = stored.refreshToken;
    _user = stored.user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Confirms the restored session against `GET /auth/me`, refreshing once on
  /// a `401` and expiring the session if that fails.
  Future<void> validate() async {
    if (_accessToken == null) return;
    try {
      await _loadCurrentUser();
    } on UnauthorizedException {
      if (await refreshAccessToken()) {
        try {
          await _loadCurrentUser();
        } on AppException {
          await _expire();
        }
      }
    } on AppException {
      // Network or transient failure: keep the optimistic session.
    }
  }

  /// Signs in and persists the returned token pair.
  Future<User> login({required String email, required String password}) async {
    _validateCredentials(email, password);
    final pair = await _repository.login(
      Credentials(email: email.trim(), password: password),
    );
    await _apply(pair);
    return pair.user;
  }

  /// Registers an account and signs in with the same credentials.
  ///
  /// The account is created even if the follow-up sign-in fails, in which case
  /// the created user is returned and the caller can send the user to login.
  Future<User> register({
    required String email,
    required String password,
  }) async {
    _validateCredentials(email, password);
    final credentials = Credentials(email: email.trim(), password: password);
    final created = await _repository.register(credentials);
    try {
      final pair = await _repository.login(credentials);
      await _apply(pair);
      return pair.user;
    } on AppException {
      return created;
    }
  }

  /// Clears all local credentials and cached authenticated state.
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    await _credentialStore.clear();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  @override
  Future<bool> refreshAccessToken() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final future = _performRefresh();
    _refreshInFlight = future;
    future.whenComplete(() {
      if (identical(_refreshInFlight, future)) _refreshInFlight = null;
    });
    return future;
  }

  Future<bool> _performRefresh() async {
    final token = _refreshToken;
    if (token == null || token.isEmpty) {
      await _expire();
      return false;
    }
    try {
      final pair = await _repository.refresh(
        RefreshRequest(refreshToken: token),
      );
      await _apply(pair);
      return true;
    } on AppException {
      await _expire();
      return false;
    }
  }

  Future<void> _loadCurrentUser() async {
    final token = _accessToken;
    if (token == null) return;
    _user = await _repository.currentUser(token);
    _status = AuthStatus.authenticated;
    await _persist();
    notifyListeners();
  }

  Future<void> _apply(AuthPair pair) async {
    _accessToken = pair.accessToken;
    _refreshToken = pair.refreshToken;
    _user = pair.user;
    _status = AuthStatus.authenticated;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final access = _accessToken;
    final refresh = _refreshToken;
    final user = _user;
    if (access == null || refresh == null || user == null) return;
    await _credentialStore.write(
      StoredSession(accessToken: access, refreshToken: refresh, user: user),
    );
  }

  Future<void> _expire() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    await _credentialStore.clear();
    _status = AuthStatus.expired;
    notifyListeners();
  }

  void _validateCredentials(String email, String password) {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      throw const ValidationException(
        code: 'invalid_email',
        message: 'Invalid e-mail address',
      );
    }
    if (password.length < 8) {
      throw const ValidationException(
        code: 'invalid_password',
        message: 'Password must be at least 8 characters',
      );
    }
  }
}
