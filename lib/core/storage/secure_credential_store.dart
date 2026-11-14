import 'dart:convert';

import 'package:flutter/foundation.dart';
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
///
/// On Web the browser only exposes `WebCrypto` in a secure context (`https://`
/// or `localhost`), so serving the app from a plain-HTTP LAN address makes every
/// operation fail with [CredentialStorageException] instead of silently storing
/// tokens in clear text.
class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore(this._storage);

  static const String _key = 'meu_preco.auth.session';

  final FlutterSecureStorage _storage;

  /// Builds the production store for the current platform.
  static SecureCredentialStore create() =>
      SecureCredentialStore(const FlutterSecureStorage());

  /// Maps a raw storage failure to a typed, actionable exception.
  @visibleForTesting
  static CredentialStorageException mapStorageError(Object error) {
    return CredentialStorageException(
      code: error is UnsupportedError
          ? 'secure_context_required'
          : 'credential_storage_failed',
      message: '$error',
    );
  }

  @override
  Future<StoredSession?> read() async {
    final raw = await _readRaw();
    if (raw == null || raw.isEmpty) return null;

    final Object? decoded;

    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      await _discard();
      return null;
    }
    if (decoded is! JsonMap) {
      await _discard();
      return null;
    }

    try {
      return StoredSession.fromJson(decoded);
    } on SerializationException {
      await _discard();
      return null;
    }
  }

  @override
  Future<void> write(StoredSession session) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(session.toJson()));
    } catch (error) {
      throw mapStorageError(error);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (error) {
      throw mapStorageError(error);
    }
  }

  Future<String?> _readRaw() async {
    try {
      return await _storage.read(key: _key);
    } catch (error) {
      throw mapStorageError(error);
    }
  }

  /// Removes an unreadable document without masking the reason it was dropped.
  Future<void> _discard() async {
    try {
      await clear();
    } on CredentialStorageException {
      // Nothing else to do: the value could not be decrypted or parsed, so
      // leaving it in place is equivalent to having deleted it.
    }
  }
}
