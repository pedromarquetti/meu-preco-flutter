import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import '../../../core/models/models.dart';

/// Outcome of `POST /nfce/new`.
sealed class DraftOutcome {
  const DraftOutcome();
}

/// The receipt was drafted; [preview] is ready to confirm.
final class DraftPreview extends DraftOutcome {
  const DraftPreview(this.preview);

  final PreviewResult preview;
}

/// The fiscal portal demanded a captcha before the draft could be produced.
final class DraftCaptchaRequired extends DraftOutcome {
  const DraftCaptchaRequired(this.challenge);

  final CaptchaChallenge challenge;
}

/// Outcome of solving a captcha (`POST /nfce/captcha`).
sealed class CaptchaSolveOutcome {
  const CaptchaSolveOutcome();
}

/// The solution was accepted; the previously blocked [preview] is available.
final class CaptchaSolved extends CaptchaSolveOutcome {
  const CaptchaSolved(this.preview);

  final PreviewResult preview;
}

/// The solution was rejected; [feedback] carries the remaining attempt budget.
final class CaptchaRejected extends CaptchaSolveOutcome {
  const CaptchaRejected(this.feedback);

  final CaptchaWrongSolution feedback;
}

/// NFC-e ingestion operations against the Meu Preço API.
abstract interface class NfceRepository {
  /// `POST /nfce/new` — normalize an access key or QR payload into a draft.
  Future<DraftOutcome> draft(DraftRequest request);

  /// `POST /nfce/captcha` — submit a captcha solution to unblock a draft.
  Future<CaptchaSolveOutcome> solveCaptcha(CaptchaSolutionRequest request);

  /// `GET /nfce/captcha` — the current state of a challenge.
  Future<CaptchaState> captchaState(String challengeId);

  /// `GET /nfce/captcha/image/{id}` — the challenge image bytes.
  Future<Uint8List> captchaImage(String challengeId);

  /// `POST /nfce/submit` — confirm (or dry-run) a draft.
  Future<CommitResult> submit(CommitRequest request);

  /// `POST /nfce/delete` — delete a committed receipt (owner or admin).
  Future<DeleteReceiptResult> deleteReceipt(DeleteReceiptRequest request);
}

/// [NfceRepository] built on the shared authenticated [ApiClient].
class ApiNfceRepository implements NfceRepository {
  ApiNfceRepository({required ApiClient client})
    : _client = client; // ignore: prefer_initializing_formals

  final ApiClient _client;

  @override
  Future<DraftOutcome> draft(DraftRequest request) async {
    try {
      final data = await _client.post('/nfce/new', body: request.toJson());
      return DraftPreview(PreviewResult.fromJson(_asObject(data)));
    } on PreconditionFailedException catch (error) {
      if (error.code == 'captcha_required') {
        return DraftCaptchaRequired(
          CaptchaChallenge.fromError(_details(error)),
        );
      }
      rethrow;
    }
  }

  @override
  Future<CaptchaSolveOutcome> solveCaptcha(
    CaptchaSolutionRequest request,
  ) async {
    try {
      final data = await _client.post('/nfce/captcha', body: request.toJson());
      return CaptchaSolved(PreviewResult.fromJson(_asObject(data)));
    } on PreconditionFailedException catch (error) {
      if (error.code == 'captcha_wrong_solution') {
        return CaptchaRejected(CaptchaWrongSolution.fromError(_details(error)));
      }
      rethrow;
    }
  }

  @override
  Future<CaptchaState> captchaState(String challengeId) async {
    final data = await _client.get(
      '/nfce/captcha',
      query: {'challenge_id': challengeId},
    );
    return CaptchaState.fromJson(_asObject(data));
  }

  @override
  Future<Uint8List> captchaImage(String challengeId) =>
      _client.getBytes('/nfce/captcha/image/$challengeId');

  @override
  Future<CommitResult> submit(CommitRequest request) async {
    final data = await _client.post('/nfce/submit', body: request.toJson());
    return CommitResult.fromJson(_asObject(data));
  }

  @override
  Future<DeleteReceiptResult> deleteReceipt(
    DeleteReceiptRequest request,
  ) async {
    final data = await _client.post('/nfce/delete', body: request.toJson());
    return DeleteReceiptResult.fromJson(_asObject(data));
  }

  JsonMap _asObject(Object? data) {
    if (data is JsonMap) return data;
    throw const SerializationException(
      message: 'Expected a JSON object response',
    );
  }

  /// The flattened `error` object a `412` carries, used to rebuild the captcha
  /// challenge/feedback the typed exception would otherwise drop.
  JsonMap _details(PreconditionFailedException error) {
    final details = error.details;
    if (details == null) {
      throw const SerializationException(message: 'Missing error details');
    }
    return details.cast<String, dynamic>();
  }
}
