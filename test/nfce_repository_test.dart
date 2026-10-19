import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_preco_frontend/core/config/app_config.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/http/api_client.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/nfce/data/nfce_repository.dart';

import 'fakes.dart';

void main() {
  ApiNfceRepository repositoryWith(
    Future<http.Response> Function(http.Request) handler,
  ) {
    return ApiNfceRepository(
      client: ApiClient(
        configProvider: () =>
            AppConfig.tryFromOrigin('https://api.example.com')!,
        httpClient: MockClient(handler),
      ),
    );
  }

  group('draft', () {
    test('returns the preview on 200', () async {
      final preview = samplePreview();
      final repository = repositoryWith(
        (request) async => http.Response(jsonEncode(preview.toJson()), 200),
      );

      final outcome = await repository.draft(
        const DraftRequest(accessKey: kSampleAccessKey),
      );

      expect(outcome, isA<DraftPreview>());
      expect((outcome as DraftPreview).preview.previewId, 42);
      expect(outcome.preview.items, hasLength(2));
    });

    test('sends a qr_payload body verbatim', () async {
      late String body;
      final repository = repositoryWith((request) async {
        body = request.body;
        return http.Response(jsonEncode(samplePreview().toJson()), 200);
      });

      await repository.draft(
        const DraftRequest(qrPayload: 'https://sefaz.example/qr?p=abc'),
      );

      expect(jsonDecode(body), {
        'qr_payload': 'https://sefaz.example/qr?p=abc',
      });
    });

    test('returns the challenge on 412 captcha_required', () async {
      final repository = repositoryWith(
        (request) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'captcha_required',
              'message': 'solve the captcha',
              'challenge_id': 'c1',
              'image_url': '/api/v1/nfce/captcha/image/c1',
            },
          }),
          412,
        ),
      );

      final outcome = await repository.draft(
        const DraftRequest(accessKey: kSampleAccessKey),
      );

      expect(outcome, isA<DraftCaptchaRequired>());
      final challenge = (outcome as DraftCaptchaRequired).challenge;
      expect(challenge.challengeId, 'c1');
      expect(challenge.imageUrl, '/api/v1/nfce/captcha/image/c1');
    });

    test('rethrows a 412 that is not a captcha challenge', () async {
      final repository = repositoryWith(
        (request) async => http.Response(
          jsonEncode({
            'error': {'code': 'some_other_precondition', 'message': 'nope'},
          }),
          412,
        ),
      );

      await expectLater(
        repository.draft(const DraftRequest(accessKey: kSampleAccessKey)),
        throwsA(isA<PreconditionFailedException>()),
      );
    });

    test('maps an invalid key to a typed validation failure', () async {
      final repository = repositoryWith(
        (request) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'invalid_access_key',
              'message': 'a chave deve ter 44 dígitos',
            },
          }),
          422,
        ),
      );

      await expectLater(
        repository.draft(const DraftRequest(accessKey: '123')),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'invalid_access_key',
          ),
        ),
      );
    });
  });

  group('solveCaptcha', () {
    test('returns the preview on success', () async {
      final repository = repositoryWith(
        (request) async =>
            http.Response(jsonEncode(samplePreview().toJson()), 200),
      );

      final outcome = await repository.solveCaptcha(
        const CaptchaSolutionRequest(challengeId: 'c1', solution: 'AB12'),
      );

      expect(outcome, isA<CaptchaSolved>());
    });

    test('returns the feedback on 412 captcha_wrong_solution', () async {
      final repository = repositoryWith(
        (request) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'captcha_wrong_solution',
              'message': 'wrong',
              'challenge_id': 'c1',
              'attempts_left': 3,
              'image_url': '/api/v1/nfce/captcha/image/c1',
            },
          }),
          412,
        ),
      );

      final outcome = await repository.solveCaptcha(
        const CaptchaSolutionRequest(challengeId: 'c1', solution: 'zz'),
      );

      expect(outcome, isA<CaptchaRejected>());
      expect((outcome as CaptchaRejected).feedback.attemptsLeft, 3);
    });
  });

  test('captchaState sends the challenge_id query parameter', () async {
    late Uri uri;
    final repository = repositoryWith((request) async {
      uri = request.url;
      return http.Response(
        jsonEncode(
          const CaptchaState(
            challengeId: 'c1',
            status: CaptchaStatus.pending,
            attemptsLeft: 5,
            maxAttempts: 5,
          ).toJson(),
        ),
        200,
      );
    });

    final state = await repository.captchaState('c1');

    expect(uri.queryParameters['challenge_id'], 'c1');
    expect(state.status, CaptchaStatus.pending);
  });

  test('captchaImage returns the raw response bytes', () async {
    final repository = repositoryWith(
      (request) async => http.Response.bytes(kSamplePngBytes, 200),
    );

    final bytes = await repository.captchaImage('c1');

    expect(bytes, kSamplePngBytes);
  });

  test('submit encodes preview_id, confirm and resolutions', () async {
    late String body;
    final repository = repositoryWith((request) async {
      body = request.body;
      return http.Response(
        jsonEncode(
          const CommitResult(
            previewId: 42,
            confirmed: true,
            written: 2,
          ).toJson(),
        ),
        200,
      );
    });

    final result = await repository.submit(
      const CommitRequest(
        previewId: 42,
        confirm: true,
        resolutions: [Resolution(line: 2, action: ResolutionAction.skip)],
      ),
    );

    expect(result.written, 2);
    expect(jsonDecode(body), {
      'preview_id': 42,
      'confirm': true,
      'resolutions': [
        {'line': 2, 'action': 'skip'},
      ],
    });
  });

  test('deleteReceipt posts the access key', () async {
    late String body;
    final repository = repositoryWith((request) async {
      body = request.body;
      return http.Response(
        jsonEncode(
          const DeleteReceiptResult(
            accessKey: kSampleAccessKey,
            logsDeleted: 4,
          ).toJson(),
        ),
        200,
      );
    });

    final result = await repository.deleteReceipt(
      const DeleteReceiptRequest(accessKey: kSampleAccessKey),
    );

    expect(result.logsDeleted, 4);
    expect(jsonDecode(body), {'access_key': kSampleAccessKey});
  });
}
