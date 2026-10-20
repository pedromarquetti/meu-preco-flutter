import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/models/models.dart';
import 'data/nfce_repository.dart';
import 'nfce_input.dart';

/// High-level stage of the receipt submission flow.
enum NfceStage { input, drafting, captcha, preview, committing, result, error }

/// Drives the NFC-e draft → captcha → preview → commit flow.
///
/// It is a [ChangeNotifier] so the screen can render per stage without holding
/// flow logic in widgets, and it owns the two hazards the UI must not
/// reintroduce: a captcha retry never drops the pending draft (the draft only
/// arrives with the accepted solution), and a confirmation can never be
/// submitted twice (a busy guard plus a committed-result latch).
class NfceSubmissionController extends ChangeNotifier {
  NfceSubmissionController({required NfceRepository repository})
    : _repository = repository; // ignore: prefer_initializing_formals

  final NfceRepository _repository;

  NfceStage _stage = NfceStage.input;
  NfceInput? _input;
  PreviewResult? _preview;
  CaptchaChallenge? _challenge;
  CaptchaWrongSolution? _captchaFeedback;
  Uint8List? _captchaImage;
  bool _captchaImageLoading = false;
  CommitResult? _dryRun;
  CommitResult? _result;
  DeleteReceiptResult? _deletion;
  AppException? _error;
  bool _busy = false;
  final Map<int, Resolution> _resolutions = <int, Resolution>{};
  final Map<int, ProductView> _assignments = <int, ProductView>{};

  NfceStage get stage => _stage;
  NfceInput? get input => _input;
  PreviewResult? get preview => _preview;
  CaptchaChallenge? get challenge => _challenge;
  CaptchaWrongSolution? get captchaFeedback => _captchaFeedback;
  Uint8List? get captchaImage => _captchaImage;
  bool get captchaImageLoading => _captchaImageLoading;
  CommitResult? get dryRun => _dryRun;
  CommitResult? get result => _result;
  DeleteReceiptResult? get deletion => _deletion;
  AppException? get error => _error;
  bool get busy => _busy;

  /// Whether the pending draft has passed its server-side expiry.
  bool get previewExpired {
    final preview = _preview;
    return preview != null && DateTime.now().isAfter(preview.expiresAt);
  }

  /// The resolution chosen for an uncertain [line], defaulting to review.
  Resolution resolutionFor(int line) =>
      _resolutions[line] ??
      Resolution(line: line, action: ResolutionAction.needsReview);

  /// The product assigned to an uncertain [line], when one was selected.
  ProductView? assignmentFor(int line) => _assignments[line];

  /// The per-line resolutions sent with a submit, one per uncertain line.
  List<Resolution> get resolutions =>
      _resolutions.values.toList(growable: false);

  /// Drafts [input], moving to the preview stage or the captcha stage.
  Future<void> start(NfceInput input) async {
    if (_busy) return;
    _input = input;
    _error = null;
    _captchaFeedback = null;
    _captchaImage = null;
    _dryRun = null;
    _stage = NfceStage.drafting;
    _setBusy(true);
    try {
      final outcome = await _repository.draft(input.toDraftRequest());
      switch (outcome) {
        case DraftPreview(:final preview):
          _installPreview(preview);
        case DraftCaptchaRequired(:final challenge):
          _challenge = challenge;
          _stage = NfceStage.captcha;
          await refreshCaptchaImage();
      }
    } on AppException catch (error) {
      _fail(error, recoverableInput: true);
    } finally {
      _setBusy(false);
    }
  }

  /// Re-drafts the last input, used to recover from an expired/locked captcha.
  Future<void> retryDraft() async {
    final input = _input;
    if (input == null || _busy) return;
    _resetState();
    await start(input);
  }

  /// Loads (or reloads) the current captcha challenge image.
  Future<void> refreshCaptchaImage() async {
    final challenge = _challenge;
    if (challenge == null) return;
    _captchaImageLoading = true;
    notifyListeners();
    try {
      _captchaImage = await _repository.captchaImage(challenge.challengeId);
    } on AppException catch (error) {
      _error = error;
    } finally {
      _captchaImageLoading = false;
      notifyListeners();
    }
  }

  /// Submits [solution] for the current captcha challenge.
  Future<void> solveCaptcha(String solution) async {
    final challenge = _challenge;
    final trimmed = solution.trim();
    if (challenge == null || _busy || trimmed.isEmpty) return;
    _error = null;
    _setBusy(true);
    try {
      final outcome = await _repository.solveCaptcha(
        CaptchaSolutionRequest(
          challengeId: challenge.challengeId,
          solution: trimmed,
        ),
      );
      switch (outcome) {
        case CaptchaSolved(:final preview):
          _installPreview(preview);
        case CaptchaRejected(:final feedback):
          _captchaFeedback = feedback;
          _challenge = CaptchaChallenge(
            message: feedback.message,
            challengeId: feedback.challengeId,
            imageUrl: feedback.imageUrl,
          );
          _captchaImage = null;
          await refreshCaptchaImage();
      }
    } on AppException catch (error) {
      _error = error;
      if (_isIrrecoverableCaptcha(error)) {
        _stage = NfceStage.error;
      }
    } finally {
      _setBusy(false);
    }
  }

  /// Confirms the draft when [confirm] is true, or reports what a commit would
  /// do when it is false. A confirmed commit latches [result] so a second tap
  /// cannot resubmit.
  Future<void> submit({required bool confirm}) async {
    final preview = _preview;
    if (preview == null || _busy) return;
    if (confirm && _result != null) return;
    if (previewExpired) {
      _error = const ValidationException(code: 'preview_expired');
      _stage = NfceStage.error;
      notifyListeners();
      return;
    }

    _error = null;
    _busy = true;
    _stage = confirm ? NfceStage.committing : NfceStage.preview;
    notifyListeners();
    try {
      final result = await _repository.submit(
        CommitRequest(
          previewId: preview.previewId,
          confirm: confirm,
          resolutions: resolutions,
        ),
      );
      if (confirm) {
        _result = result;
        _stage = NfceStage.result;
      } else {
        _dryRun = result;
        _stage = NfceStage.preview;
      }
    } on AppException catch (error) {
      _fail(error, recoverableInput: false);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Records the resolution for one uncertain [line].
  void setResolution(int line, ResolutionAction action, {int? productId}) {
    _resolutions[line] = Resolution(
      line: line,
      action: action,
      productId: productId,
    );
    if (action != ResolutionAction.assign) {
      _assignments.remove(line);
    }
    notifyListeners();
  }

  /// Links an existing catalog product to an uncertain [line].
  ///
  /// Products without an id cannot be assigned: the server requires a positive
  /// `product_id` for an `assign` resolution.
  void assignProduct(int line, ProductView product) {
    final id = product.id;
    if (id == null || id <= 0) return;
    _assignments[line] = product;
    _resolutions[line] = Resolution(
      line: line,
      action: ResolutionAction.assign,
      productId: id,
    );
    notifyListeners();
  }

  /// Deletes the committed receipt (or the pending draft) and returns to input.
  Future<void> deleteReceipt() async {
    final accessKey = _result?.accessKey ?? _preview?.accessKey;
    if (accessKey == null || _busy) return;
    _busy = true;
    notifyListeners();
    try {
      final deletion = await _repository.deleteReceipt(
        DeleteReceiptRequest(accessKey: accessKey),
      );
      _resetState();
      _deletion = deletion;
    } on AppException catch (error) {
      _error = error;
      _stage = NfceStage.error;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Returns to the input stage on a fresh flow.
  void reset() {
    if (_busy) return;
    _resetState();
    notifyListeners();
  }

  void _installPreview(PreviewResult preview) {
    _preview = preview;
    _dryRun = null;
    _error = null;
    _captchaFeedback = null;
    _challenge = null;
    _resolutions.clear();
    _assignments.clear();
    for (final item in preview.items) {
      if (item.status == PreviewItemStatus.uidUncertain) {
        _resolutions[item.line] = Resolution(
          line: item.line,
          action: ResolutionAction.needsReview,
        );
      }
    }
    _stage = NfceStage.preview;
  }

  void _fail(AppException error, {required bool recoverableInput}) {
    _error = error;
    final invalidInput =
        error.code == 'invalid_access_key' ||
        error.code == 'invalid_qr_payload';
    _stage = recoverableInput && invalidInput
        ? NfceStage.input
        : NfceStage.error;
  }

  bool _isIrrecoverableCaptcha(AppException error) => switch (error.code) {
    'challenge_expired' ||
    'challenge_locked' ||
    'challenge_used' ||
    'challenge_not_found' => true,
    _ => false,
  };

  void _resetState() {
    _stage = NfceStage.input;
    _input = null;
    _preview = null;
    _challenge = null;
    _captchaFeedback = null;
    _captchaImage = null;
    _dryRun = null;
    _result = null;
    _deletion = null;
    _error = null;
    _resolutions.clear();
    _assignments.clear();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
