import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
