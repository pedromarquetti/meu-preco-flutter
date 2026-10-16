import 'json.dart';
import 'user.dart';

/// Login/registration credentials.
class Credentials {
  const Credentials({required this.email, required this.password});

  factory Credentials.fromJson(JsonMap json) => Credentials(
    email: json.stringValue('email'),
    password: json.stringValue('password'),
  );

  final String email;
  final String password;

  JsonMap toJson() => {'email': email, 'password': password};
}

/// Access/refresh token pair plus the authenticated user.
///
/// Refresh tokens rotate: every successful `/auth/refresh` returns a new pair
/// that must replace both stored tokens.
class AuthPair {
  const AuthPair({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthPair.fromJson(JsonMap json) => AuthPair(
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

/// Body of `/auth/refresh`.
class RefreshRequest {
  const RefreshRequest({required this.refreshToken});

  final String refreshToken;

  JsonMap toJson() => {'refresh_token': refreshToken};
}
