import 'json.dart';
import 'user.dart';

/// Body of `/auth/login`.
///
/// [login] is an email address or an account name; the backend resolves either
/// one to the same account and still accepts the legacy `email` field.
class LoginCredentials {
  const LoginCredentials({required this.login, required this.password});

  factory LoginCredentials.fromJson(JsonMap json) => LoginCredentials(
    login: json.stringValue('login'),
    password: json.stringValue('password'),
  );

  final String login;
  final String password;

  JsonMap toJson() => {'login': login, 'password': password};
}

/// Body of `/auth/register`.
class RegisterCredentials {
  const RegisterCredentials({
    required this.name,
    required this.email,
    required this.password,
  });

  factory RegisterCredentials.fromJson(JsonMap json) => RegisterCredentials(
    name: json.stringValue('name'),
    email: json.stringValue('email'),
    password: json.stringValue('password'),
  );

  final String name;
  final String email;
  final String password;

  JsonMap toJson() => {'name': name, 'email': email, 'password': password};
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
