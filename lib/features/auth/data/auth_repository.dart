import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import '../../../core/models/models.dart';

/// Authentication operations against the Meu Preço API.
abstract interface class AuthRepository {
  /// `POST /auth/login` — exchange credentials for a token pair.
  Future<AuthPair> login(Credentials credentials);

  /// `POST /auth/register` — create an account (role `user`).
  Future<User> register(Credentials credentials);

  /// `POST /auth/refresh` — rotate a refresh token into a new pair.
  Future<AuthPair> refresh(RefreshRequest request);

  /// `GET /auth/me` — the authenticated user from the token.
  Future<User> currentUser(String accessToken);
}

/// [AuthRepository] built on the shared [ApiClient].
///
/// These calls deliberately use an unauthenticated client: login and register
/// have no token yet, and refresh must never itself trigger a token refresh.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({required ApiClient client})
    : _client = client; // ignore: prefer_initializing_formals

  final ApiClient _client;

  @override
  Future<AuthPair> login(Credentials credentials) async {
    final data = await _client.post('/auth/login', body: credentials.toJson());
    return AuthPair.fromJson(_asObject(data));
  }

  @override
  Future<User> register(Credentials credentials) async {
    final data = await _client.post(
      '/auth/register',
      body: credentials.toJson(),
    );
    return UserResponse.fromJson(_asObject(data)).user;
  }

  @override
  Future<AuthPair> refresh(RefreshRequest request) async {
    final data = await _client.post('/auth/refresh', body: request.toJson());
    return AuthPair.fromJson(_asObject(data));
  }

  @override
  Future<User> currentUser(String accessToken) async {
    final data = await _client.get(
      '/auth/me',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return UserResponse.fromJson(_asObject(data)).user;
  }

  JsonMap _asObject(Object? data) {
    if (data is JsonMap) return data;
    throw const SerializationException(
      message: 'Expected a JSON object response',
    );
  }
}
