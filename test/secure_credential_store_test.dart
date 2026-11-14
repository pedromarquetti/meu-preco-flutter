import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/core/storage/credential_store.dart';
import 'package:meu_preco_frontend/core/storage/secure_credential_store.dart';

const String _channelName = 'plugins.it_nomads.com/flutter_secure_storage';
const String _storageKey = 'meu_preco.auth.session';

const User _user = User(
  id: 1,
  name: 'Ada',
  email: 'ada@example.com',
  role: UserRole.user,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> data;
  late SecureCredentialStore store;

  setUp(() {
    data = <String, String>{};
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel(_channelName), (
      call,
    ) async {
      final arguments = call.arguments as Map<Object?, Object?>;
      final key = arguments['key'] as String?;
      switch (call.method) {
        case 'read':
          return data[key!];
        case 'write':
          data[key!] = arguments['value'] as String;
          return null;
        case 'delete':
          data.remove(key);
          return null;
        case 'containsKey':
          return data.containsKey(key);
        case 'readAll':
          return data;
        case 'deleteAll':
          data.clear();
          return null;
        default:
          return null;
      }
    });
    store = SecureCredentialStore(const FlutterSecureStorage());
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(_channelName), null);
  });

  test('round-trips a stored session and clears it on logout', () async {
    await store.write(
      const StoredSession(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        user: _user,
      ),
    );

    final restored = await store.read();
    expect(restored?.accessToken, 'access-1');
    expect(restored?.refreshToken, 'refresh-1');
    expect(restored?.user.email, 'ada@example.com');

    await store.clear();
    expect(data, isEmpty);
    expect(await store.read(), isNull);
  });

  test('writes the token pair and user as one document', () async {
    await store.write(
      const StoredSession(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        user: _user,
      ),
    );

    // A single key/document keeps rotation atomic: there is never a moment
    // where the new access token is stored beside the old refresh token.
    expect(data.keys, [_storageKey]);
    final document = jsonDecode(data[_storageKey]!) as Map<String, dynamic>;
    expect(document['access_token'], 'access-1');
    expect(document['refresh_token'], 'refresh-1');
    expect((document['user'] as Map<String, dynamic>)['id'], _user.id);
  });

  test('discards malformed JSON instead of restoring a session', () async {
    data[_storageKey] = '{not valid json';

    expect(await store.read(), isNull);
    expect(data, isEmpty);
  });

  test('discards a document with missing session fields', () async {
    data[_storageKey] = jsonEncode({'access_token': 'access-1'});

    expect(await store.read(), isNull);
    expect(data, isEmpty);
  });

  test('maps a missing secure context to an actionable code', () {
    final error = SecureCredentialStore.mapStorageError(
      UnsupportedError('FlutterSecureStorageWeb only works in secure contexts'),
    );

    expect(error.code, 'secure_context_required');
    expect(error.requiresSecureContext, isTrue);
  });

  test('maps other platform failures to a generic storage code', () {
    final error = SecureCredentialStore.mapStorageError(
      PlatformException(code: 'unavailable'),
    );

    expect(error.code, 'credential_storage_failed');
    expect(error.requiresSecureContext, isFalse);
  });

  test(
    'write surfaces a typed failure instead of leaking the platform one',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel(_channelName),
            (call) async => throw PlatformException(code: 'unavailable'),
          );

      await expectLater(
        store.write(
          const StoredSession(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
            user: _user,
          ),
        ),
        throwsA(
          isA<CredentialStorageException>().having(
            (error) => error.code,
            'code',
            'credential_storage_failed',
          ),
        ),
      );
    },
  );

  test(
    'read surfaces a typed failure instead of restoring a session',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel(_channelName),
            (call) async => throw PlatformException(code: 'unavailable'),
          );

      await expectLater(
        store.read(),
        throwsA(isA<CredentialStorageException>()),
      );
    },
  );
}
