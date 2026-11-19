import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/core/config/app_config.dart';
import 'package:meu_preco_frontend/core/config/app_config_controller.dart';

import 'fakes.dart';

void main() {
  group('AppConfig.tryFromOrigin', () {
    test('normalizes trailing slashes', () {
      final config = AppConfig.tryFromOrigin('https://api.example.com/');
      expect(config, isNotNull);
      expect(config!.apiOrigin.toString(), 'https://api.example.com');
      expect(
        config.resolveRoot('/healthz').toString(),
        'https://api.example.com/healthz',
      );
      expect(
        config.resolveApi('/auth/login').toString(),
        'https://api.example.com/api/v1/auth/login',
      );
    });

    test('strips a duplicated /api/v1 prefix', () {
      final config = AppConfig.tryFromOrigin('https://api.example.com/api/v1');
      expect(config!.apiOrigin.toString(), 'https://api.example.com');
      expect(
        config.resolveApi('/products').toString(),
        'https://api.example.com/api/v1/products',
      );
    });

    test('strips a prefix pasted more than once', () {
      final config = AppConfig.tryFromOrigin(
        'https://api.example.com/api/v1/api/v1',
      );
      expect(config!.apiOrigin.toString(), 'https://api.example.com');
      expect(
        config.resolveApi('/auth/login').toString(),
        'https://api.example.com/api/v1/auth/login',
      );
    });

    test('preserves a sub-path when stripping the prefix', () {
      final config = AppConfig.tryFromOrigin(
        'https://example.com/meupreco/api/v1',
      );
      expect(config!.apiOrigin.toString(), 'https://example.com/meupreco');
      expect(
        config.resolveApi('/products').toString(),
        'https://example.com/meupreco/api/v1/products',
      );
    });

    test('preserves a deployment sub-path', () {
      final config = AppConfig.tryFromOrigin('https://example.com/meupreco');
      expect(config!.apiOrigin.toString(), 'https://example.com/meupreco');
      expect(
        config.resolveRoot('/healthz').toString(),
        'https://example.com/meupreco/healthz',
      );
    });

    test('rejects non-http and malformed origins', () {
      expect(AppConfig.tryFromOrigin('ftp://example.com'), isNull);
      expect(AppConfig.tryFromOrigin('not-a-url'), isNull);
      expect(AppConfig.tryFromOrigin(''), isNull);
      expect(AppConfig.tryFromOrigin('   '), isNull);
    });

    test('probes the fallback port first for scheme-less addresses', () {
      // No port: fallback port first (http, https), then the scheme defaults.
      expect(AppConfig.candidateOrigins('api.example.com'), [
        'http://api.example.com:8080',
        'https://api.example.com:8080',
        'http://api.example.com',
        'https://api.example.com',
      ]);
      expect(AppConfig.candidateOrigins('localhost'), [
        'http://localhost:8080',
        'https://localhost:8080',
        'http://localhost',
        'https://localhost',
      ]);
      expect(AppConfig.candidateOrigins('  localhost  '), [
        'http://localhost:8080',
        'https://localhost:8080',
        'http://localhost',
        'https://localhost',
      ]);
      // An IP address is not misread as containing a port.
      expect(AppConfig.candidateOrigins('192.168.1.5'), [
        'http://192.168.1.5:8080',
        'https://192.168.1.5:8080',
        'http://192.168.1.5',
        'https://192.168.1.5',
      ]);
      // Digits inside a hostname are not a port either.
      expect(AppConfig.candidateOrigins('web2.example.com'), [
        'http://web2.example.com:8080',
        'https://web2.example.com:8080',
        'http://web2.example.com',
        'https://web2.example.com',
      ]);
    });

    test('keeps an explicit port and tries both schemes', () {
      expect(AppConfig.candidateOrigins('localhost:2138'), [
        'https://localhost:2138',
        'http://localhost:2138',
      ]);
      expect(AppConfig.candidateOrigins('localhost:8080/api/v1'), [
        'https://localhost:8080/api/v1',
        'http://localhost:8080/api/v1',
      ]);
    });

    test('keeps an explicit scheme and adds the fallback port last', () {
      expect(AppConfig.candidateOrigins('http://localhost'), [
        'http://localhost',
        'http://localhost:8080',
      ]);
      expect(AppConfig.candidateOrigins('https://api.example.com'), [
        'https://api.example.com',
        'https://api.example.com:8080',
      ]);
      // An explicit port is tried exactly as typed.
      expect(AppConfig.candidateOrigins('http://localhost:8080'), [
        'http://localhost:8080',
      ]);
    });

    test('keeps a non-http scheme and rejects unusable input', () {
      expect(AppConfig.candidateOrigins('ftp://localhost:8080'), [
        'ftp://localhost:8080',
      ]);
      expect(AppConfig.candidateOrigins(''), isEmpty);
      expect(AppConfig.candidateOrigins('   '), isEmpty);
      expect(AppConfig.candidateOrigins('local host:8080'), isEmpty);
    });

    test('accepts ports within range', () {
      for (final raw in [
        'http://localhost:80',
        'http://localhost:8080',
        'https://api.example.com:65535',
      ]) {
        expect(AppConfig.tryFromOrigin(raw), isNotNull, reason: raw);
      }
    });

    test('rejects out-of-range ports instead of sending a doomed request', () {
      for (final raw in [
        'http://localhost:0',
        'http://localhost:-1',
        'http://localhost:65536',
        'http://localhost:372184721897213',
      ]) {
        expect(AppConfig.tryFromOrigin(raw), isNull, reason: raw);
      }
    });
  });

  group('AppConfigController', () {
    test('a fresh controller has no configured server', () {
      final store = InMemoryKeyValueStore();
      final controller = AppConfigController(store: store);

      expect(controller.config, isNull);
      expect(controller.isConfigured, isFalse);
    });

    test('saveOrigin persists, notifies, and reloads', () async {
      final store = InMemoryKeyValueStore();
      final controller = AppConfigController(store: store);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.saveOrigin('https://api.example.com/api/v1/');

      expect(
        controller.config!.apiOrigin.toString(),
        'https://api.example.com',
      );
      expect(controller.isConfigured, isTrue);
      expect(notifications, 1);
      expect(
        store.entries[AppConfigController.apiOriginKey],
        'https://api.example.com',
      );

      final restored = AppConfigController(store: store);
      await restored.load();
      expect(restored.config!.apiOrigin.toString(), 'https://api.example.com');
      expect(restored.isConfigured, isTrue);
    });

    test('saveOrigin rejects invalid origins without notifying', () async {
      final store = InMemoryKeyValueStore();
      final controller = AppConfigController(store: store);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await expectLater(
        controller.saveOrigin('not-a-url'),
        throwsA(isA<FormatException>()),
      );
      expect(notifications, 0);
      expect(controller.isConfigured, isFalse);
      expect(store.entries, isEmpty);
    });

    test('clearOrigin forgets the selected server', () async {
      final store = InMemoryKeyValueStore();
      final controller = AppConfigController(store: store);
      await controller.saveOrigin('https://api.example.com');
      await controller.clearOrigin();

      expect(controller.isConfigured, isFalse);
      expect(controller.config, isNull);
      expect(store.entries, isEmpty);
    });

    test('a cold start after clearOrigin has no configured server', () async {
      final store = InMemoryKeyValueStore();
      final controller = AppConfigController(store: store);
      await controller.saveOrigin('https://api.example.com');
      await controller.clearOrigin();

      final restored = AppConfigController(store: store);
      await restored.load();

      expect(restored.isConfigured, isFalse);
      expect(restored.config, isNull);
      expect(store.entries, isEmpty);
    });

    test('load ignores a stored invalid origin', () async {
      final store = InMemoryKeyValueStore();
      await store.writeString(AppConfigController.apiOriginKey, 'garbage');
      final controller = AppConfigController(store: store);

      await controller.load();
      expect(controller.isConfigured, isFalse);
      expect(controller.config, isNull);
    });

    test('an origin change clears the session before persisting it', () async {
      final store = InMemoryKeyValueStore();
      final events = <String>[];
      final controller = AppConfigController(
        store: store,
        initialConfig: AppConfig.tryFromOrigin('https://old.example.com'),
        onOriginChanged: () async {
          events.add('reset');
          expect(store.entries, isEmpty);
        },
      );

      await controller.saveOrigin('https://api.example.com');

      expect(events, ['reset']);
      expect(
        store.entries[AppConfigController.apiOriginKey],
        'https://api.example.com',
      );
    });

    test('the first origin does not clear anything', () async {
      final store = InMemoryKeyValueStore();
      var resets = 0;
      final controller = AppConfigController(
        store: store,
        onOriginChanged: () async => resets++,
      );

      await controller.saveOrigin('https://api.example.com');

      expect(resets, 0);
    });

    test('saving the same normalized origin keeps the session', () async {
      final store = InMemoryKeyValueStore();
      var resets = 0;
      final controller = AppConfigController(
        store: store,
        initialConfig: AppConfig.tryFromOrigin('https://api.example.com'),
        onOriginChanged: () async => resets++,
      );

      await controller.saveOrigin('https://api.example.com/api/v1/');

      expect(resets, 0);
    });

    test('clearOrigin clears the session only when a server was set', () async {
      final store = InMemoryKeyValueStore();
      var resets = 0;
      final controller = AppConfigController(
        store: store,
        onOriginChanged: () async => resets++,
      );

      await controller.saveOrigin('https://api.example.com');
      await controller.clearOrigin();
      await controller.clearOrigin();

      expect(resets, 1);
      expect(controller.isConfigured, isFalse);
    });

    test('an invalid origin never clears the session', () async {
      final store = InMemoryKeyValueStore();
      var resets = 0;
      final controller = AppConfigController(
        store: store,
        onOriginChanged: () async => resets++,
      );

      await expectLater(
        controller.saveOrigin('not-a-url'),
        throwsA(isA<FormatException>()),
      );

      expect(resets, 0);
    });

    test(
      'a failed session clear aborts the origin change before persisting',
      () async {
        final store = InMemoryKeyValueStore();
        final controller = AppConfigController(
          store: store,
          initialConfig: AppConfig.tryFromOrigin('https://old.example.com'),
        );
        controller.bindOriginChanged(
          () async => throw StateError('credential clear failed'),
        );

        await expectLater(
          controller.saveOrigin('https://new.example.com'),
          throwsA(isA<StateError>()),
        );

        expect(
          controller.config!.apiOrigin.toString(),
          'https://old.example.com',
        );
        expect(store.entries, isEmpty);
      },
    );
  });
}
