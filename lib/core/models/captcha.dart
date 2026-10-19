import '../errors/app_exception.dart';
import 'json.dart';

/// The `412` body returned by `/nfce/new` when a captcha is required.
///
/// Its `error.code` is always `captcha_required`.
class CaptchaChallenge {
  const CaptchaChallenge({
    required this.message,
    required this.challengeId,
    required this.imageUrl,
  });

  factory CaptchaChallenge.fromJson(JsonMap json) =>
      CaptchaChallenge.fromError(json.objectValue('error'));

  /// Decodes the challenge straight from the flattened `error` object the
  /// typed [AppException.details] exposes.
  factory CaptchaChallenge.fromError(JsonMap error) => CaptchaChallenge(
    message: error.stringValue('message'),
    challengeId: error.stringValue('challenge_id'),
    imageUrl: error.stringValue('image_url'),
  );

  final String message;
  final String challengeId;
  final String imageUrl;

  JsonMap toJson() => {
    'error': {
      'code': 'captcha_required',
      'message': message,
      'challenge_id': challengeId,
      'image_url': imageUrl,
    },
  };
}

/// The `412` body returned when a captcha solution is wrong.
///
/// Its `error.code` is always `captcha_wrong_solution`.
class CaptchaWrongSolution {
  const CaptchaWrongSolution({
    required this.message,
    required this.challengeId,
    required this.attemptsLeft,
    required this.imageUrl,
  });

  factory CaptchaWrongSolution.fromJson(JsonMap json) =>
      CaptchaWrongSolution.fromError(json.objectValue('error'));

  /// Decodes the retry feedback straight from the flattened `error` object the
  /// typed [AppException.details] exposes.
  factory CaptchaWrongSolution.fromError(JsonMap error) => CaptchaWrongSolution(
    message: error.stringValue('message'),
    challengeId: error.stringValue('challenge_id'),
    attemptsLeft: error.intValue('attempts_left'),
    imageUrl: error.stringValue('image_url'),
  );

  final String message;
  final String challengeId;
  final int attemptsLeft;
  final String imageUrl;

  JsonMap toJson() => {
    'error': {
      'code': 'captcha_wrong_solution',
      'message': message,
      'challenge_id': challengeId,
      'attempts_left': attemptsLeft,
      'image_url': imageUrl,
    },
  };
}

/// Lifecycle state of a captcha challenge.
enum CaptchaStatus {
  pending,
  solved,
  locked;

  static CaptchaStatus fromJson(String value) => switch (value) {
    'pending' => CaptchaStatus.pending,
    'solved' => CaptchaStatus.solved,
    'locked' => CaptchaStatus.locked,
    _ => throw SerializationException(
      message: 'Unknown captcha status: "$value"',
    ),
  };

  String toJson() => name;
}

/// Current state of a captcha challenge (`GET /nfce/captcha`).
class CaptchaState {
  const CaptchaState({
    this.challengeId,
    this.status,
    this.attemptsLeft,
    this.maxAttempts,
    this.imageUrl,
    this.expiresAt,
  });

  factory CaptchaState.fromJson(JsonMap json) => CaptchaState(
    challengeId: json.stringOrNull('challenge_id'),
    status: json.stringOrNull('status') == null
        ? null
        : CaptchaStatus.fromJson(json.stringValue('status')),
    attemptsLeft: json.intOrNull('attempts_left'),
    maxAttempts: json.intOrNull('max_attempts'),
    imageUrl: json.stringOrNull('image_url'),
    expiresAt: json.dateTimeOrNull('expires_at'),
  );

  final String? challengeId;
  final CaptchaStatus? status;
  final int? attemptsLeft;
  final int? maxAttempts;
  final String? imageUrl;
  final DateTime? expiresAt;

  JsonMap toJson() => {
    'challenge_id': challengeId,
    'status': status?.toJson(),
    'attempts_left': attemptsLeft,
    'max_attempts': maxAttempts,
    'image_url': imageUrl,
    'expires_at': expiresAt?.toUtc().toIso8601String(),
  };
}

/// Body of `POST /nfce/captcha`.
class CaptchaSolutionRequest {
  const CaptchaSolutionRequest({
    required this.challengeId,
    required this.solution,
  });

  final String challengeId;
  final String solution;

  JsonMap toJson() => {'challenge_id': challengeId, 'solution': solution};
}
