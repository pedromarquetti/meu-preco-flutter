import 'package:http/http.dart' as http;

import 'auth_token_source.dart';

/// An [http.Client] that signs requests with the current bearer token and
/// transparently recovers from an expired access token.
///
/// On a `401` it asks the [AuthTokenSource] to refresh once and replays the
/// original request a single time. Two properties keep token rotation safe:
///
/// * The token source serializes refreshes, so concurrent `401`s share one
///   rotation instead of rotating the refresh token several times.
/// * A request whose token was already rotated by another in-flight request
///   retries with the newer token rather than triggering another refresh.
///
/// Login/refresh/register requests are never replayed, and only buffered
/// `http.Request` bodies are eligible so streaming uploads stay untouched.
class AuthenticatedClient extends http.BaseClient {
  AuthenticatedClient({
    required http.Client inner,
    required AuthTokenSource tokens,
  }) : _inner = inner, // ignore: prefer_initializing_formals
       _tokens = tokens; // ignore: prefer_initializing_formals

  final http.Client _inner;
  final AuthTokenSource _tokens;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final usedToken = _tokens.accessToken;
    final response = await _inner.send(_sign(request, usedToken));

    if (response.statusCode != 401 || !_canReplay(request)) {
      return response;
    }

    // Keep the 401 body so it can be returned verbatim if recovery fails.
    final buffered = await _BufferedResponse.capture(response);

    final current = _tokens.accessToken;
    final String? retryToken;

    if (current != null && current.isNotEmpty && current != usedToken) {
      retryToken = current;
    } else if (await _tokens.refreshAccessToken()) {
      retryToken = _tokens.accessToken;
    } else {
      return buffered.toResponse();
    }

    if (retryToken == null || retryToken.isEmpty) {
      return buffered.toResponse();
    }

    try {
      return await _inner.send(_sign(request, retryToken));
    } on http.ClientException {
      return buffered.toResponse();
    }
  }

  /// Whether [request] can be safely rebuilt and resent.
  bool _canReplay(http.BaseRequest request) {
    if (request is! http.Request) return false;
    final path = request.url.path;
    return !path.endsWith('/auth/login') &&
        !path.endsWith('/auth/refresh') &&
        !path.endsWith('/auth/register');
  }

  /// Returns a resendable copy of [request] carrying [token].
  http.BaseRequest _sign(http.BaseRequest request, String? token) {
    if (request is! http.Request) return request;

    final signed = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection;
    if (request.bodyBytes.isNotEmpty) {
      signed.bodyBytes = request.bodyBytes;
    }

    if (token != null && token.isNotEmpty) {
      signed.headers['Authorization'] = 'Bearer $token';
    } else {
      signed.headers.remove('Authorization');
    }
    return signed;
  }
}

/// A fully-read response that can be replayed to the caller.
class _BufferedResponse {
  const _BufferedResponse(this._response, this._bytes);

  static Future<_BufferedResponse> capture(
    http.StreamedResponse response,
  ) async {
    final bytes = await response.stream.toBytes();
    return _BufferedResponse(response, bytes);
  }

  final http.StreamedResponse _response;
  final List<int> _bytes;

  http.StreamedResponse toResponse() => http.StreamedResponse(
    Stream<List<int>>.value(_bytes),
    _response.statusCode,
    contentLength: _bytes.length,
    request: _response.request,
    headers: _response.headers,
    reasonPhrase: _response.reasonPhrase,
    isRedirect: _response.isRedirect,
    persistentConnection: _response.persistentConnection,
  );
}
