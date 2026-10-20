import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/features/nfce/data/nfce_repository.dart';
import 'package:meu_preco_frontend/features/nfce/nfce_input.dart';
import 'package:meu_preco_frontend/features/nfce/nfce_submission_controller.dart';

import 'fakes.dart';

void main() {
  NfceInput accessKeyInput() => NfceInput.tryParse(kSampleAccessKey)!;

  CaptchaChallenge sampleChallenge() => const CaptchaChallenge(
    message: 'solve it',
    challengeId: 'c1',
    imageUrl: '/api/v1/nfce/captcha/image/c1',
  );

  test('start drafts an access key and installs the preview', () async {
    final repository = FakeNfceRepository();
    final controller = NfceSubmissionController(repository: repository);

    await controller.start(accessKeyInput());

    expect(controller.stage, NfceStage.preview);
    expect(repository.draftRequests.single.accessKey, kSampleAccessKey);
    expect(repository.draftRequests.single.qrPayload, isNull);
    expect(controller.resolutions, hasLength(1));
    expect(controller.resolutionFor(2).action, ResolutionAction.needsReview);
  });

  test(
    'start sends a QR payload when the input is not a 44-digit key',
    () async {
      final repository = FakeNfceRepository();
      final controller = NfceSubmissionController(repository: repository);

      await controller.start(
        NfceInput.tryParse('https://sefaz.example/qr?p=abc')!,
      );

      expect(repository.draftRequests.single.qrPayload, isNotNull);
      expect(repository.draftRequests.single.accessKey, isNull);
    },
  );

  test('an invalid access key stays on the input stage', () async {
    final repository = FakeNfceRepository()
      ..draftError = const ValidationException(code: 'invalid_access_key');
    final controller = NfceSubmissionController(repository: repository);

    await controller.start(accessKeyInput());

    expect(controller.stage, NfceStage.input);
    expect(controller.error, isA<ValidationException>());
  });

  group('captcha', () {
    test('captcha_required loads the challenge and its image', () async {
      final repository = FakeNfceRepository()
        ..draftOutcome = DraftCaptchaRequired(sampleChallenge());
      final controller = NfceSubmissionController(repository: repository);

      await controller.start(accessKeyInput());

      expect(controller.stage, NfceStage.captcha);
      expect(controller.challenge!.challengeId, 'c1');
      expect(repository.imageCalls, 1);
      expect(controller.captchaImage, isNotNull);
    });

    test('a wrong solution keeps the draft and updates the budget', () async {
      final repository = FakeNfceRepository()
        ..draftOutcome = DraftCaptchaRequired(sampleChallenge())
        ..solveOutcome = const CaptchaRejected(
          CaptchaWrongSolution(
            message: 'wrong',
            challengeId: 'c1',
            attemptsLeft: 3,
            imageUrl: '/api/v1/nfce/captcha/image/c1',
          ),
        );
      final controller = NfceSubmissionController(repository: repository);

      await controller.start(accessKeyInput());
      await controller.solveCaptcha('zz');

      expect(controller.stage, NfceStage.captcha);
      expect(controller.captchaFeedback!.attemptsLeft, 3);
      expect(controller.preview, isNull);
      expect(repository.imageCalls, 2);
    });

    test('a correct solution installs the pending preview', () async {
      final repository = FakeNfceRepository()
        ..draftOutcome = DraftCaptchaRequired(sampleChallenge())
        ..solveOutcome = CaptchaSolved(samplePreview());
      final controller = NfceSubmissionController(repository: repository);

      await controller.start(accessKeyInput());
      await controller.solveCaptcha('AB12');

      expect(controller.stage, NfceStage.preview);
      expect(controller.preview, isNotNull);
      expect(repository.solveRequests.single.challengeId, 'c1');
      expect(repository.solveRequests.single.solution, 'AB12');
    });

    test('an expired challenge moves to the error stage', () async {
      final repository = FakeNfceRepository()
        ..draftOutcome = DraftCaptchaRequired(sampleChallenge())
        ..solveError = const ValidationException(code: 'challenge_expired');
      final controller = NfceSubmissionController(repository: repository);

      await controller.start(accessKeyInput());
      await controller.solveCaptcha('zz');

      expect(controller.stage, NfceStage.error);
    });
  });

  group('submit', () {
    test('a dry run keeps the preview and records the counts', () async {
      final repository = FakeNfceRepository();
      final controller = NfceSubmissionController(repository: repository);
      await controller.start(accessKeyInput());

      await controller.submit(confirm: false);

      expect(controller.stage, NfceStage.preview);
      expect(controller.dryRun, isNotNull);
      expect(controller.result, isNull);
      expect(repository.submitRequests.single.confirm, isFalse);
    });

    test('a commit latches the result and blocks a second submit', () async {
      final repository = FakeNfceRepository();
      final controller = NfceSubmissionController(repository: repository);
      await controller.start(accessKeyInput());

      await controller.submit(confirm: true);
      expect(controller.stage, NfceStage.result);
      expect(controller.result, isNotNull);

      await controller.submit(confirm: true);
      expect(repository.submitCalls, 1);
    });

    test('sends the selected skip resolution for an uncertain line', () async {
      final repository = FakeNfceRepository();
      final controller = NfceSubmissionController(repository: repository);
      await controller.start(accessKeyInput());

      controller.setResolution(2, ResolutionAction.skip);
      await controller.submit(confirm: true);

      final resolutions = repository.submitRequests.single.resolutions;
      expect(resolutions, hasLength(1));
      expect(resolutions.single.line, 2);
      expect(resolutions.single.action, ResolutionAction.skip);
    });

    test('refuses to submit an expired preview', () async {
      final repository = FakeNfceRepository()
        ..draftOutcome = DraftPreview(
          samplePreview(
            expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
        );
      final controller = NfceSubmissionController(repository: repository);
      await controller.start(accessKeyInput());

      await controller.submit(confirm: true);

      expect(repository.submitCalls, 0);
      expect(controller.stage, NfceStage.error);
      expect(controller.error!.code, 'preview_expired');
    });
  });

  test('retryDraft re-drafts the last input after a failure', () async {
    final repository = FakeNfceRepository()
      ..draftError = const ServerException(
        message: 'boom',
        code: 'upstream_error',
        statusCode: 502,
      );
    final controller = NfceSubmissionController(repository: repository);
    await controller.start(accessKeyInput());
    expect(controller.stage, NfceStage.error);

    repository.draftError = null;
    await controller.retryDraft();

    expect(controller.stage, NfceStage.preview);
    expect(repository.draftCalls, 2);
  });

  test('deleteReceipt deletes the committed receipt and resets', () async {
    final repository = FakeNfceRepository();
    final controller = NfceSubmissionController(repository: repository);
    await controller.start(accessKeyInput());
    await controller.submit(confirm: true);

    await controller.deleteReceipt();

    expect(repository.deleteCalls, 1);
    expect(repository.deleteRequests.single.accessKey, kSampleAccessKey);
    expect(controller.deletion, isNotNull);
    expect(controller.stage, NfceStage.input);
  });

  group('product assignment', () {
    test(
      'assigning a product sends an assign resolution with its id',
      () async {
        final repository = FakeNfceRepository();
        final controller = NfceSubmissionController(repository: repository);
        await controller.start(accessKeyInput());
        final product = sampleProduct(id: 42, name: 'Arroz 5kg');

        controller.assignProduct(2, product);
        await controller.submit(confirm: true);

        expect(controller.assignmentFor(2), same(product));
        expect(controller.resolutionFor(2).action, ResolutionAction.assign);
        final resolutions = repository.submitRequests.single.resolutions;
        expect(resolutions, hasLength(1));
        expect(resolutions.single.line, 2);
        expect(resolutions.single.action, ResolutionAction.assign);
        expect(resolutions.single.productId, 42);
      },
    );

    test('switching back to review clears the assigned product', () async {
      final controller = NfceSubmissionController(
        repository: FakeNfceRepository(),
      );
      await controller.start(accessKeyInput());
      controller.assignProduct(2, sampleProduct(id: 42));

      controller.setResolution(2, ResolutionAction.needsReview);

      expect(controller.assignmentFor(2), isNull);
      expect(controller.resolutionFor(2).action, ResolutionAction.needsReview);
      expect(controller.resolutionFor(2).productId, isNull);
    });

    test('ignores products without an id', () async {
      final controller = NfceSubmissionController(
        repository: FakeNfceRepository(),
      );
      await controller.start(accessKeyInput());

      controller.assignProduct(2, sampleProduct(id: null));

      expect(controller.assignmentFor(2), isNull);
      expect(controller.resolutionFor(2).action, ResolutionAction.needsReview);
    });
  });
}
