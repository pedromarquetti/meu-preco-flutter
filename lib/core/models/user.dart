import '../errors/app_exception.dart';
import 'json.dart';
import 'pagination.dart';

/// The authenticated account attached to [UserResponse]/[AuthPair].
enum UserRole {
  user,
  admin;

  static UserRole fromJson(String value) => switch (value) {
    'user' => UserRole.user,
    'admin' => UserRole.admin,
    _ => throw SerializationException(message: 'Unknown role: "$value"'),
  };

  String toJson() => name;
}

/// User summary returned by `/auth/me`, `/users/me`, and auth responses.
class User {
  const User({required this.id, required this.email, required this.role});

  factory User.fromJson(JsonMap json) => User(
    id: json.intValue('id'),
    email: json.stringValue('email'),
    role: UserRole.fromJson(json.stringValue('role')),
  );

  final int id;
  final String email;
  final UserRole role;

  JsonMap toJson() => {'id': id, 'email': email, 'role': role.toJson()};
}

/// `{"user": {...}}` wrapper returned by the auth/me endpoints.
class UserResponse {
  const UserResponse({required this.user});

  factory UserResponse.fromJson(JsonMap json) =>
      UserResponse(user: User.fromJson(json.objectValue('user')));

  final User user;

  JsonMap toJson() => {'user': user.toJson()};
}

/// A user row in the admin listing (`/admin/users`), which also carries the
/// creation timestamp.
class UserView {
  const UserView({this.id, this.email, this.role, this.createdAt});

  factory UserView.fromJson(JsonMap json) => UserView(
    id: json.intOrNull('id'),
    email: json.stringOrNull('email'),
    role: json.stringOrNull('role') == null
        ? null
        : UserRole.fromJson(json.stringValue('role')),
    createdAt: json.dateTimeOrNull('created_at'),
  );

  final int? id;
  final String? email;
  final UserRole? role;
  final DateTime? createdAt;

  JsonMap toJson() => {
    'id': id,
    'email': email,
    'role': role?.toJson(),
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

/// Paginated user listing.
class UserPage {
  const UserPage({required this.items, this.page});

  factory UserPage.fromJson(JsonMap json) => UserPage(
    items: json
        .objectListOrEmpty('items')
        .map(UserView.fromJson)
        .toList(growable: false),
    page: json.objectOrNull('page') == null
        ? null
        : Page.fromJson(json.objectValue('page')),
  );

  final List<UserView> items;
  final Page? page;

  JsonMap toJson() => {
    'items': [for (final item in items) item.toJson()],
    'page': page?.toJson(),
  };
}
