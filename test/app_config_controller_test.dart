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
    test('saveOrigin persists, notifies, and reloads', () async {
      final store = InMemoryKeyValueStore();
      final controller = AppConfigController(store: store);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.saveOrigin('https://api.example.com/api/v1/');

      expect(controller.config.apiOrigin.toString(), 'https://api.example.com');
      expect(controller.isConfiguredByUser, isTrue);
      expect(notifications, 1);
      expect(
        store.entries[AppConfigController.apiOriginKey],
        'https://api.example.com',
      );

      final restored = AppConfigController(store: store);
      await restored.load();
      expect(restored.config.apiOrigin.toString(), 'https://api.example.com');
      expect(restored.isConfiguredByUser, isTrue);
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
      expect(controller.isConfiguredByUser, isFalse);
      expect(store.entries, isEmpty);
    });

    test('resetToDefault clears the override', () async {
      final store = InMemoryKeyValueStore();
      final controller = AppConfigController(store: store);
      await controller.saveOrigin('https://api.example.com');
      await controller.resetToDefault();

      expect(controller.isConfiguredByUser, isFalse);
      expect(store.entries, isEmpty);
      expect(
        controller.config.apiOrigin.toString(),
        AppConfig.defaults().apiOrigin.toString(),
      );
    });

    test('load ignores a stored invalid origin', () async {
      final store = InMemoryKeyValueStore();
      await store.writeString(AppConfigController.apiOriginKey, 'garbage');
      final controller = AppConfigController(store: store);

      await controller.load();
      expect(controller.isConfiguredByUser, isFalse);
    });
  });
}
