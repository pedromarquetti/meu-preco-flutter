import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/app_exception.dart';
import '../models/json.dart';
import 'credential_store.dart';

/// [CredentialStore] backed by `flutter_secure_storage`, which stores the whole
/// session as one JSON document under a single key.
///
/// Platform guarantees:
/// - Android: `EncryptedSharedPreferences` backed by the Android Keystore.
/// - iOS/macOS: the Keychain.
/// - Web: `flutter_secure_storage`'s browser backend (`WebCrypto` + browser
///   storage). This protects tokens from casual inspection but **not** from
///   same-origin script injection (XSS) or a compromised host page, so a Web
///   deployment should still use HTTPS, a strict Content-Security-Policy, and
///   short access-token lifetimes. Tokens are never placed in URLs.
class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore(this._storage);

  static const String _key = 'meu_preco.auth.session';

  final FlutterSecureStorage _storage;

  /// Builds the production store for the current platform.
  static SecureCredentialStore create() =>
      SecureCredentialStore(const FlutterSecureStorage());

  @override
  Future<StoredSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;

    final Object? decoded;

    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      await clear();
      return null;
    }
    if (decoded is! JsonMap) {
      await clear();
      return null;
    }

    try {
      return StoredSession.fromJson(decoded);
    } on SerializationException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(StoredSession session) {
    return _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
