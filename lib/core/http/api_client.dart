import 'dart:async' as async;
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../config/config_provider.dart';
import '../errors/app_exception.dart';

/// A decoded response that does not throw on non-2xx statuses.
///
/// Operational endpoints (`/healthz`, `/readyz`) carry meaning in their body
/// even on failure — a `Status` payload with `status` and, for a failed
/// readiness check, a `reason` — so callers need the status code and body
/// together instead of an exception.
class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.headers,
    this.data,
  });

  final int statusCode;

  final Map<String, String> headers;

  /// Decoded JSON body, the raw string when the body is not JSON, or `null`
  /// when the body is empty.
  final Object? data;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  @override
  String toString() => 'ApiResponse($statusCode, data: $data)';
}

/// A small JSON HTTP pipeline for the Meu Preço API.
///
/// It owns the mechanical parts of every request — base URL joining, the
/// `/api/v1` prefix, request timeouts, JSON encoding/decoding,
/// status-code handling, and mapping the `{error: {code, message}}` envelope to
/// typed [AppException]s — so feature repositories only deal with data.
class ApiClient {
  ApiClient({required ConfigProvider configProvider, http.Client? httpClient})
    : _configProvider = configProvider, // ignore: prefer_initializing_formals
      _client = httpClient ?? http.Client();

  final ConfigProvider _configProvider;
  final http.Client _client;

  /// GET request; [useApiPrefix] selects `/api/v1` vs the origin root
  /// (used for `/healthz` and `/readyz`).
  Future<dynamic> get(
    String path, {
    bool useApiPrefix = true,
    Map<String, String>? headers,
    Map<String, String>? query,
    AppConfig? config,
  }) {
    return _send(
      'GET',
      path,
      useApiPrefix: useApiPrefix,
      headers: headers,
      query: query,
      config: config,
    );
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    bool useApiPrefix = true,
    Map<String, String>? headers,
    Map<String, String>? query,
    AppConfig? config,
  }) {
    return _send(
      'POST',
      path,
      useApiPrefix: useApiPrefix,
      headers: headers,
      query: query,
      body: body,
      config: config,
    );
  }

  Future<dynamic> patch(
    String path, {
    Object? body,
    bool useApiPrefix = true,
    Map<String, String>? headers,
    Map<String, String>? query,
    AppConfig? config,
  }) {
    return _send(
      'PATCH',
      path,
      useApiPrefix: useApiPrefix,
      headers: headers,
      query: query,
      body: body,
      config: config,
    );
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    bool useApiPrefix = true,
    Map<String, String>? headers,
    Map<String, String>? query,
    AppConfig? config,
  }) {
    return _send(
      'PUT',
      path,
      useApiPrefix: useApiPrefix,
      headers: headers,
      query: query,
      body: body,
      config: config,
    );
  }

  Future<dynamic> delete(
    String path, {
    bool useApiPrefix = true,
    Map<String, String>? headers,
    Map<String, String>? query,
    AppConfig? config,
  }) {
    return _send(
      'DELETE',
      path,
      useApiPrefix: useApiPrefix,
      headers: headers,
      query: query,
      config: config,
    );
  }

  /// GET a binary body (e.g. the captcha challenge image) as raw bytes.
  ///
  /// Non-2xx responses go through the same typed-error mapping as [get], so a
  /// missing or expired image surfaces as an actionable [AppException].
  Future<Uint8List> getBytes(
    String path, {
    bool useApiPrefix = true,
    Map<String, String>? headers,
    Map<String, String>? query,
    AppConfig? config,
  }) async {
    final response = await _request(
      'GET',
      path,
      useApiPrefix: useApiPrefix,
      headers: headers,
      query: query,
      config: config,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw _mapError(response);
  }

  /// Sends a request and returns the [ApiResponse] **without** throwing on a
  /// non-2xx status. Transport, timeout and decoding failures still surface as
  /// typed [AppException]s.
  ///
  /// Pass [config] to resolve the request against an origin other than the
  /// active one (e.g. probing a candidate server before it is saved).
  Future<ApiResponse> sendRaw(
    String method,
    String path, {
    bool useApiPrefix = true,
    Map<String, String>? headers,
    Map<String, String>? query,
    Object? body,
    AppConfig? config,
  }) async {
    final response = await _request(
      method,
      path,
      useApiPrefix: useApiPrefix,
      headers: headers,
      query: query,
      body: body,
      config: config,
    );
    return ApiResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      data: _tryDecode(response.body),
    );
  }

  Future<dynamic> _send(
    String method,
    String path, {
    required bool useApiPrefix,
    Map<String, String>? headers,
    Map<String, String>? query,
    Object? body,
    AppConfig? config,
  }) async {
    final response = await _request(
      method,
      path,
      useApiPrefix: useApiPrefix,
      headers: headers,
      query: query,
      body: body,
      config: config,
    );
    return _decode(response);
  }

  Future<http.Response> _request(
    String method,
    String path, {
    required bool useApiPrefix,
    Map<String, String>? headers,
    Map<String, String>? query,
    Object? body,
    AppConfig? config,
  }) async {
    final effectiveConfig = config ?? _configProvider();
    var uri = useApiPrefix
        ? effectiveConfig.resolveApi(path)
        : effectiveConfig.resolveRoot(path);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...query});
    }

    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      ...?headers,
    };

    try {
      final request = http.Request(method, uri);
      if (body != null) {
        request.body = jsonEncode(body);
        requestHeaders['Content-Type'] = 'application/json';
      }
      request.headers.addAll(requestHeaders);

      final streamed = await _client
          .send(request)
          .timeout(effectiveConfig.requestTimeout);
      return await http.Response.fromStream(streamed);
    } on async.TimeoutException {
      throw const TimeoutException();
    } on http.ClientException catch (error) {
      throw NetworkException(message: error.message);
    } on FormatException {
      throw const NetworkException(message: 'Invalid response body');
    } on ArgumentError catch (error) {
      // dart:io reports an out-of-range port as an `Error`, which would
      // otherwise escape every `catch (Exception)` and freeze the caller.
      throw NetworkException(
        message: error.message?.toString() ?? 'Invalid request',
      );
    } on Exception catch (error) {
      throw NetworkException(message: error.toString());
    }
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } on FormatException {
        throw const NetworkException(message: 'Invalid response body');
      }
    }

    throw _mapError(response);
  }

  AppException _mapError(http.Response response) {
    final String? code;
    final String? message;
    Map<String, Object?>? details;
    final decoded = _tryDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        code = error['code'] is String ? error['code'] as String : null;
        message = error['message'] is String
            ? error['message'] as String
            : null;
        details = error.cast<String, Object?>();
      } else {
        code = null;
        message = decoded['message'] is String
            ? decoded['message'] as String
            : null;
      }
    } else {
      code = null;
      message = decoded is String && decoded.isNotEmpty ? decoded : null;
    }

    final status = response.statusCode;
    return switch (status) {
      401 => UnauthorizedException(message: message, code: code),
      403 => ForbiddenException(message: message, code: code),
      404 => NotFoundException(message: message, code: code),
      409 => ConflictException(message: message, code: code),
      412 => PreconditionFailedException(
        message: message,
        code: code,
        details: details,
      ),
      422 => ValidationException(message: message, code: code),
      429 => RateLimitedException(
        message: message,
        code: code,
        retryAfter: _retryAfter(response),
      ),
      >= 500 => ServerException(
        message: message,
        code: code,
        statusCode: status,
      ),
      _ => ApiException(
        message: message,
        code: code,
        statusCode: status,
        retryAfter: _retryAfter(response),
        details: details,
      ),
    };
  }

  static dynamic _tryDecode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  static Duration? _retryAfter(http.Response response) {
    final raw = response.headers['retry-after'];
    if (raw == null) return null;
    final seconds = int.tryParse(raw.trim());
    if (seconds == null) return null;
    if (seconds < 0) return null;
    return Duration(seconds: seconds);
  }

  void dispose() {
    _client.close();
  }
}
