import '../models/json.dart';
import '../models/user.dart';

/// The persisted authentication session: the rotating token pair plus the
/// signed-in user, so a cold start can restore the UI before any request.
class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory StoredSession.fromJson(JsonMap json) => StoredSession(
    accessToken: json.stringValue('access_token'),
    refreshToken: json.stringValue('refresh_token'),
    user: User.fromJson(json.objectValue('user')),
  );

  final String accessToken;
  final String refreshToken;
  final User user;

  JsonMap toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'user': user.toJson(),
  };
}

/// Persists the authentication session across app restarts.
///
/// Secrets never travel through configuration files, query strings, or logs;
/// they are written through this interface so the concrete backend can be an
/// OS keychain/keystore on mobile and a browser store on Web.
abstract interface class CredentialStore {
  /// Returns the stored session, or `null` when there is none (or it is no
  /// longer readable).
  Future<StoredSession?> read();

  /// Atomically replaces the stored session.
  Future<void> write(StoredSession session);

  /// Removes the stored session.
  Future<void> clear();
}
