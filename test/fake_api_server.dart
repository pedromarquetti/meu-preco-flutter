import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meu_preco_frontend/core/models/models.dart';

import 'fakes.dart';

/// A request the fake server received, kept for assertions.
class RecordedRequest {
  const RecordedRequest({
    required this.method,
    required this.path,
    required this.authorization,
  });

  final String method;
  final String path;
  final String? authorization;

  bool get isUnauthenticated => authorization == null;
}

/// An in-process implementation of the Meu Preço API contract.
///
/// It speaks the real wire format — bearer tokens with rotating refresh
/// tokens, the `{error: {code, message}}` envelope, `/api/v1` paths, and the
/// operational `/healthz`/`/readyz` endpoints — so tests can drive the app's
/// actual HTTP pipeline, repositories, and session lifecycle end to end over
/// loopback HTTP instead of fakes.
class FakeApiServer {
  FakeApiServer._(this._server);

  static Future<FakeApiServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = FakeApiServer._(server);
    server.listen(fake._handle);
    return fake;
  }

  final HttpServer _server;

  /// Loopback origin of this server, e.g. `http://127.0.0.1:54321`.
  Uri get origin => Uri(
    scheme: 'http',
    host: InternetAddress.loopbackIPv4.address,
    port: _server.port,
  );

  static const String captchaAccessKey = kSampleAccessKey;

  /// Access key whose draft always demands a captcha.
  static const String captchaRequiredKey =
      '35200123456789012345678901234567890123456780';

  /// Access key whose draft reports an already-committed receipt (409).
  static const String duplicateAccessKey =
      '35200123456789012345678901234567890123456781';

  /// The only captcha solution the server accepts.
  static const String captchaSolution = 'AB12';

  final List<RecordedRequest> requests = <RecordedRequest>[];

  int refreshCallCount = 0;

  final List<_FakeUser> _users = <_FakeUser>[
    _FakeUser(
      id: 1,
      name: 'Ada',
      email: 'ada@example.com',
      password: 'secret123',
    ),
    _FakeUser(
      id: 2,
      name: 'Admin',
      email: 'admin@example.com',
      password: 'secret123',
      role: UserRole.admin,
    ),
  ];

  final Map<String, int> _accessTokens = <String, int>{};
  final Map<String, int> _refreshTokens = <String, int>{};
  final Map<String, int> _usedRefreshOwners = <String, int>{};
  int _tokenCounter = 0;
  int _previewCounter = 0;
  final Set<int> _committedPreviewIds = <int>{};
  bool _captchaSolved = false;

  final List<ProductView> _catalog = <ProductView>[
    const ProductView(
      id: 1,
      productKey: 'rice-5kg',
      gtin: '7891234567890',
      name: 'Arroz Tipo 1 5kg',
      brand: 'Marca Boa',
      unit: 'kg',
      canonicalStem: 'arroz',
    ),
    const ProductView(
      id: 2,
      productKey: 'beans-1kg',
      gtin: '7891234567891',
      name: 'Feijão Carioca 1kg',
      brand: 'Marca Boa',
      unit: 'kg',
      canonicalStem: 'feijao',
    ),
    const ProductView(
      id: 3,
      productKey: 'lime-unit',
      gtin: null,
      name: 'Limão Tahiti',
      brand: null,
      unit: 'kg',
      canonicalStem: 'limao',
    ),
  ];

  /// Invalidates every issued access token, simulating expiry while leaving
  /// refresh tokens valid — the situation the 401 refresh/retry path handles.
  void expireAccessTokens() => _accessTokens.clear();

  Future<void> close() async {
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    final authorization = request.headers.value('Authorization');
    requests.add(
      RecordedRequest(
        method: request.method,
        path: request.uri.path,
        authorization: authorization,
      ),
    );

    try {
      await _dispatch(request);
    } on Object {
      // Never let an unhandled fake-server bug hang the client; surface it as
      // a server error through the standard envelope.
      await _error(
        request,
        500,
        'internal_error',
        'Unhandled fake-server error',
      );
    }
  }

  Future<void> _dispatch(HttpRequest request) async {
    final authorization = request.headers.value('Authorization');
    final path = request.uri.path;
    if (path == '/healthz' || path == '/readyz') {
      return _json(request, 200, {'status': 'ok'});
    }

    if (!path.startsWith('/api/v1')) {
      return _error(request, 404, 'not_found', 'Route not found');
    }
    final route = path.substring('/api/v1'.length);

    if (request.method == 'POST' && route == '/auth/login') {
      return _handleLogin(request);
    }
    if (request.method == 'POST' && route == '/auth/register') {
      return _handleRegister(request);
    }
    if (request.method == 'POST' && route == '/auth/refresh') {
      return _handleRefresh(request);
    }

    final userId = _authenticatedUserId(authorization);
    if (userId == null) {
      return _error(request, 401, 'unauthorized', 'Missing or invalid token');
    }
    final user = _userById(userId);

    if (request.method == 'GET' && route == '/auth/me') {
      return _json(request, 200, {'user': user!.toJson()});
    }

    if (request.method == 'GET' && route == '/products') {
      return _handleProductSearch(request);
    }
    final detailMatch = RegExp(r'^/products/(\d+)$').firstMatch(route);
    if (request.method == 'GET' && detailMatch != null) {
      return _handleProductDetail(request, int.parse(detailMatch.group(1)!));
    }
    final historyMatch = RegExp(r'^/products/(\d+)/history$').firstMatch(route);
    if (request.method == 'GET' && historyMatch != null) {
      return _handleProductHistory(request, int.parse(historyMatch.group(1)!));
    }

    if (request.method == 'POST' && route == '/nfce/new') {
      return _handleNfceDraft(request);
    }
    if (request.method == 'GET' && route == '/nfce/captcha') {
      return _handleCaptchaState(request);
    }
    final imageMatch = RegExp(r'^/nfce/captcha/image/(.+)$').firstMatch(route);
    if (request.method == 'GET' && imageMatch != null) {
      return _handleCaptchaImage(request, imageMatch.group(1)!);
    }
    if (request.method == 'POST' && route == '/nfce/captcha') {
      return _handleCaptchaSolve(request);
    }
    if (request.method == 'POST' && route == '/nfce/submit') {
      return _handleNfceSubmit(request);
    }
    if (request.method == 'POST' && route == '/nfce/delete') {
      return _handleNfceDelete(request);
    }

    if (route.startsWith('/admin')) {
      if (user?.role != UserRole.admin) {
        return _error(
          request,
          403,
          'forbidden',
          'Admin privileges are required',
        );
      }
      return _handleAdmin(request, route);
    }

    return _error(request, 404, 'not_found', 'Route not found');
  }

  // ---------------------------------------------------------------- auth ---

  Future<void> _handleLogin(HttpRequest request) async {
    final body = await _readJson(request);
    final login = body['login'] is String ? body['login'] as String : '';
    final password = body['password'] is String
        ? body['password'] as String
        : '';
    final user = _users.where(
      (candidate) => candidate.email == login || candidate.name == login,
    );
    if (user.isEmpty || user.first.password != password) {
      return _error(
        request,
        401,
        'invalid_credentials',
        'Invalid e-mail or password',
      );
    }
    _json(request, 200, _issuePair(user.first));
  }

  Future<void> _handleRegister(HttpRequest request) async {
    final body = await _readJson(request);
    final name = body['name'] as String? ?? '';
    final email = body['email'] as String? ?? '';
    final password = body['password'] as String? ?? '';
    final created = _FakeUser(
      id: _users.length + 1,
      name: name,
      email: email,
      password: password,
    );
    _users.add(created);
    _json(request, 200, {'user': created.toJson()});
  }

  Future<void> _handleRefresh(HttpRequest request) async {
    refreshCallCount++;
    final body = await _readJson(request);
    final token = body['refresh_token'] is String
        ? body['refresh_token'] as String
        : '';
    final userId = _refreshTokens.remove(token);
    if (userId == null) {
      final reuseOwner = _usedRefreshOwners[token];
      if (reuseOwner != null) {
        // Refresh-token reuse: revoke the whole token family for that user.
        _revokeUser(reuseOwner);
        return _error(
          request,
          401,
          'refresh_reuse_detected',
          'Refresh token reuse detected',
        );
      }
      return _error(
        request,
        401,
        'invalid_refresh_token',
        'Unknown refresh token',
      );
    }
    _usedRefreshOwners[token] = userId;
    _accessTokens.removeWhere((_, owner) => owner == userId);
    final user = _userById(userId)!;
    _json(request, 200, _issuePair(user));
  }

  Map<String, Object?> _issuePair(_FakeUser user) {
    _tokenCounter++;
    final access = 'access-token-$_tokenCounter';
    final refresh = 'refresh-token-$_tokenCounter';
    _accessTokens[access] = user.id;
    _refreshTokens[refresh] = user.id;
    return {
      'access_token': access,
      'refresh_token': refresh,
      'user': user.toJson(),
    };
  }

  void _revokeUser(int userId) {
    _accessTokens.removeWhere((_, owner) => owner == userId);
    _refreshTokens.removeWhere((_, owner) => owner == userId);
  }

  int? _authenticatedUserId(String? authorization) {
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      return null;
    }
    return _accessTokens[authorization.substring('Bearer '.length)];
  }

  _FakeUser? _userById(int id) {
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  // ------------------------------------------------------------- products ---

  Future<void> _handleProductSearch(HttpRequest request) async {
    final query = request.uri.queryParameters['q']?.trim().toLowerCase();
    final matches = _catalog
        .where((product) {
          if (query == null || query.isEmpty) return true;
          final name = product.name!.toLowerCase();
          final stem = product.canonicalStem?.toLowerCase() ?? '';
          return name.contains(query) || stem.contains(query);
        })
        .toList(growable: false);
    _json(request, 200, _pageOf(matches));
  }

  Future<void> _handleProductDetail(HttpRequest request, int id) async {
    for (final product in _catalog) {
      if (product.id == id) {
        return _json(request, 200, product.toJson());
      }
    }
    return _error(request, 404, 'product_not_found', 'Product not found');
  }

  Future<void> _handleProductHistory(HttpRequest request, int id) async {
    ProductView? product;
    for (final candidate in _catalog) {
      if (candidate.id == id) product = candidate;
    }
    if (product == null) {
      return _error(request, 404, 'product_not_found', 'Product not found');
    }
    final history = ProductHistory(
      product: product,
      from: DateTime.utc(2025, 1, 1),
      to: DateTime.utc(2025, 12, 31),
      points: <PricePointView>[
        PricePointView(
          accessKey: kSampleAccessKey,
          supermarket: const SupermarketRef(
            id: 1,
            cnpj: '12345678000199',
            legalName: 'Mercado Central',
          ),
          line: 1,
          qty: const Decimal('5'),
          unit: 'kg',
          normalizedUnit: 'kg',
          pricePerUnit: const Decimal('4.99'),
          comparableUnit: 'kg',
          comparablePricePerUnit: const Decimal('4.99'),
          unitPrice: const Decimal('4.99'),
          totalPrice: const Decimal('24.95'),
          issuedAt: DateTime.utc(2025, 1, 9),
          loggedAt: DateTime.utc(2025, 1, 10),
        ),
        PricePointView(
          accessKey: duplicateAccessKey,
          supermarket: const SupermarketRef(
            id: 1,
            cnpj: '12345678000199',
            legalName: 'Mercado Central',
          ),
          line: 1,
          qty: const Decimal('5'),
          unit: 'kg',
          normalizedUnit: 'kg',
          pricePerUnit: const Decimal('5.49'),
          comparableUnit: 'kg',
          comparablePricePerUnit: const Decimal('5.49'),
          unitPrice: const Decimal('5.49'),
          totalPrice: const Decimal('27.45'),
          issuedAt: DateTime.utc(2025, 2, 9),
          loggedAt: DateTime.utc(2025, 2, 10),
        ),
      ],
      aggregate: const <UnitStats>[
        UnitStats(
          unit: 'kg',
          count: 2,
          min: Decimal('4.99'),
          avg: Decimal('5.24'),
          max: Decimal('5.49'),
          last: Decimal('5.49'),
        ),
      ],
    );
    _json(request, 200, history.toJson());
  }

  Map<String, Object?> _pageOf(List<Object> items) => {
    'items': [for (final item in items) (item as dynamic).toJson()],
    'page': {'page': 1, 'limit': 20, 'total': items.length, 'total_pages': 1},
  };

  // ---------------------------------------------------------------- nfce ---

  Future<void> _handleNfceDraft(HttpRequest request) async {
    final body = await _readJson(request);
    final accessKey = body['access_key'] as String?;
    final qrPayload = body['qr_payload'] as String?;

    if (accessKey == null && qrPayload == null) {
      return _error(
        request,
        422,
        'invalid_access_key',
        'An access key or QR payload is required',
      );
    }
    if (accessKey != null && accessKey.length != 44) {
      return _error(
        request,
        422,
        'invalid_access_key',
        'The access key must have 44 digits',
      );
    }
    if (accessKey == duplicateAccessKey) {
      return _error(
        request,
        409,
        'preview_already_committed',
        'This receipt was already committed',
      );
    }
    if (accessKey == captchaRequiredKey && !_captchaSolved) {
      return _error(
        request,
        412,
        'captcha_required',
        'Solve the captcha to continue',
        details: <String, Object?>{
          'challenge_id': 'challenge-1',
          'image_url': '/api/v1/nfce/captcha/image/challenge-1',
        },
      );
    }
    _json(request, 200, _previewJson(accessKey ?? qrPayload!));
  }

  Future<void> _handleCaptchaState(HttpRequest request) async {
    final challengeId = request.uri.queryParameters['challenge_id'];
    if (challengeId != 'challenge-1') {
      return _error(request, 404, 'challenge_not_found', 'Unknown challenge');
    }
    _json(request, 200, {
      'challenge_id': challengeId,
      'status': _captchaSolved ? 'solved' : 'pending',
      'attempts_left': 5,
      'max_attempts': 5,
      'image_url': '/api/v1/nfce/captcha/image/challenge-1',
    });
  }

  Future<void> _handleCaptchaImage(HttpRequest request, String challengeId) {
    if (challengeId != 'challenge-1') {
      return _error(request, 404, 'challenge_not_found', 'Unknown challenge');
    }
    request.response.statusCode = 200;
    request.response.headers.contentType = ContentType(
      'image',
      'png',
      charset: 'binary',
    );
    request.response.add(kSamplePngBytes);
    return request.response.close();
  }

  Future<void> _handleCaptchaSolve(HttpRequest request) async {
    final body = await _readJson(request);
    final challengeId = body['challenge_id'] as String?;
    final solution = body['solution'] as String?;
    if (challengeId != 'challenge-1') {
      return _error(request, 404, 'challenge_not_found', 'Unknown challenge');
    }
    if (solution != captchaSolution) {
      return _error(
        request,
        412,
        'captcha_wrong_solution',
        'The captcha solution is wrong',
        details: <String, Object?>{
          'challenge_id': challengeId,
          'attempts_left': 4,
          'image_url': '/api/v1/nfce/captcha/image/challenge-1',
        },
      );
    }
    _captchaSolved = true;
    _json(request, 200, _previewJson(captchaRequiredKey));
  }

  Future<void> _handleNfceSubmit(HttpRequest request) async {
    final body = await _readJson(request);
    final previewId = body['preview_id'] as int?;
    final confirm = body['confirm'] == true;
    if (previewId == null) {
      return _error(request, 422, 'invalid_preview', 'preview_id required');
    }
    if (confirm && _committedPreviewIds.contains(previewId)) {
      return _error(
        request,
        409,
        'preview_already_committed',
        'This preview was already committed',
      );
    }
    if (confirm) _committedPreviewIds.add(previewId);
    _json(request, 200, {
      'preview_id': previewId,
      'confirmed': confirm,
      'written': 1,
      'auto_saved': 1,
      'assigned': 0,
      'needs_review': 1,
      'skipped': 0,
      'nfce_id': 7,
      'access_key': captchaAccessKey,
    });
  }

  Future<void> _handleNfceDelete(HttpRequest request) async {
    final body = await _readJson(request);
    _json(request, 200, {
      'access_key': body['access_key'],
      'nfce_id': 7,
      'logs_deleted': 1,
      'previews_deleted': 1,
    });
  }

  Map<String, Object?> _previewJson(String accessKey) {
    _previewCounter++;
    return samplePreview(
      previewId: 42 + _previewCounter - 1,
      accessKey: accessKey.length == 44 ? accessKey : kSampleAccessKey,
    ).toJson();
  }

  // --------------------------------------------------------------- admin ---

  Future<void> _handleAdmin(HttpRequest request, String route) async {
    if (request.method == 'GET' && route == '/admin/users') {
      return _json(request, 200, {
        'items': [
          for (final user in _users)
            <String, Object?>{
              ...user.toJson(),
              'created_at': '2025-01-01T00:00:00Z',
            },
        ],
        'page': {
          'page': 1,
          'limit': 50,
          'total': _users.length,
          'total_pages': 1,
        },
      });
    }
    final roleMatch = RegExp(r'^/admin/users/(\d+)/role$').firstMatch(route);
    if (request.method == 'PUT' && roleMatch != null) {
      final body = await _readJson(request);
      final userId = int.parse(roleMatch.group(1)!);
      final role = UserRole.fromJson(body['role'] as String? ?? 'user');
      final user = _userById(userId);
      if (user == null) {
        return _error(request, 404, 'user_not_found', 'User not found');
      }
      user.role = role;
      return _json(request, 200, {
        ...user.toJson(),
        'created_at': '2025-01-01T00:00:00Z',
      });
    }
    if (request.method == 'GET' && route == '/admin/products/needs-review') {
      return _json(request, 200, {
        'items': <Object?>[],
        'page': {'page': 1, 'limit': 50, 'total': 0, 'total_pages': 0},
      });
    }
    if (request.method == 'POST' && route == '/admin/products/batch-assign') {
      final body = await _readJson(request);
      final assignments = body['assignments'];
      final count = assignments is List ? assignments.length : 0;
      return _json(request, 200, {'assigned': count, 'created': 0});
    }
    return _error(request, 404, 'not_found', 'Route not found');
  }

  // ------------------------------------------------------------- plumbing ---

  Future<Map<String, Object?>> _readJson(HttpRequest request) async {
    final raw = await utf8.decoder.bind(request).join();
    if (raw.isEmpty) return <String, Object?>{};
    final decoded = jsonDecode(raw);
    return decoded is Map<String, Object?> ? decoded : <String, Object?>{};
  }

  Future<void> _json(HttpRequest request, int status, Object? body) async {
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }

  Future<void> _error(
    HttpRequest request,
    int status,
    String code,
    String message, {
    Map<String, Object?>? details,
  }) {
    return _json(request, status, {
      'error': <String, Object?>{'code': code, 'message': message, ...?details},
    });
  }
}

class _FakeUser {
  _FakeUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = UserRole.user,
  });

  final int id;
  final String name;
  final String email;
  final String password;
  UserRole role;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.toJson(),
  };
}
