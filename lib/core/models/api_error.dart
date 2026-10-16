import 'json.dart';

/// The `error` object of the API's failure envelope (`{code, message}`).
class ApiError {
  const ApiError({required this.code, required this.message});

  factory ApiError.fromJson(JsonMap json) => ApiError(
    code: json.stringValue('code'),
    message: json.stringValue('message'),
  );

  final String code;
  final String message;

  JsonMap toJson() => {'code': code, 'message': message};
}

/// The top-level failure envelope: `{"error": {"code", "message"}}`.
class ApiErrorEnvelope {
  const ApiErrorEnvelope({required this.error});

  factory ApiErrorEnvelope.fromJson(JsonMap json) =>
      ApiErrorEnvelope(error: ApiError.fromJson(json.objectValue('error')));

  final ApiError error;

  JsonMap toJson() => {'error': error.toJson()};
}
