import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/core/errors/app_exception.dart';
import 'package:meu_preco_frontend/core/models/models.dart';

void main() {
  group('Decimal', () {
    test('keeps the exact textual value', () {
      expect(const Decimal('12.50').amount, '12.50');
      expect(const Decimal('0.1').toJson(), '0.1');
    });

    test('compares without floating-point error', () {
      expect(const Decimal('0.1').compareTo(const Decimal('0.10')), 0);
      expect(
        const Decimal('10.00').compareTo(const Decimal('9.99')),
        greaterThan(0),
      );
      expect(const Decimal('-2').compareTo(const Decimal('1.5')), lessThan(0));
      expect(
        const Decimal('100').compareTo(const Decimal('99.999')),
        greaterThan(0),
      );
    });

    test('normalizes for equality and hashing', () {
      expect(const Decimal('010.50'), const Decimal('10.5'));
      expect(const Decimal('10.5').hashCode, const Decimal('10.50').hashCode);
      expect(const Decimal('0'), const Decimal('0.000'));
      expect(const Decimal('-0'), const Decimal('0'));
    });

    test('rejects non-decimal input', () {
      expect(
        () => Decimal.fromJson('R\$ 12,50'),
        throwsA(isA<SerializationException>()),
      );
    });
  });

  group('auth models', () {
    test('AuthPair round-trips the token pair and user', () {
      final json = <String, dynamic>{
        'access_token': 'access-1',
        'refresh_token': 'refresh-1',
        'user': {
          'id': 7,
          'name': 'Ada',
          'email': 'ada@example.com',
          'role': 'admin',
        },
      };

      final pair = AuthPair.fromJson(json);

      expect(pair.accessToken, 'access-1');
      expect(pair.refreshToken, 'refresh-1');
      expect(pair.user.id, 7);
      expect(pair.user.name, 'Ada');
      expect(pair.user.role, UserRole.admin);
      expect(pair.toJson(), json);
    });

    test('User falls back to the email when a cached name is absent', () {
      final user = User.fromJson({
        'id': 1,
        'email': 'ada@example.com',
        'role': 'user',
      });
      expect(user.name, 'ada@example.com');
    });

    test('LoginCredentials encodes the login identifier and password', () {
      const credentials = LoginCredentials(
        login: 'ada@example.com',
        password: 'secret',
      );
      expect(credentials.toJson(), {
        'login': 'ada@example.com',
        'password': 'secret',
      });
    });

    test('RegisterCredentials encodes name, email, and password', () {
      const credentials = RegisterCredentials(
        name: 'Ada',
        email: 'ada@example.com',
        password: 'secret',
      );
      expect(credentials.toJson(), {
        'name': 'Ada',
        'email': 'ada@example.com',
        'password': 'secret',
      });
    });

    test('unknown role is a serialization failure', () {
      expect(
        () => User.fromJson({
          'id': 1,
          'name': 'Ada',
          'email': 'a@b.c',
          'role': 'root',
        }),
        throwsA(isA<SerializationException>()),
      );
    });
  });

  group('pagination', () {
    test('Page reads snake_case total_pages', () {
      final page = Page.fromJson({
        'page': 2,
        'limit': 20,
        'total': 53,
        'total_pages': 3,
      });
      expect(page.page, 2);
      expect(page.totalPages, 3);
    });

    test('UserPage decodes its rows and page', () {
      final page = UserPage.fromJson({
        'items': [
          {
            'id': 1,
            'email': 'a@b.c',
            'role': 'user',
            'created_at': '2026-01-02T03:04:05Z',
          },
        ],
        'page': {'page': 1, 'limit': 10, 'total': 1, 'total_pages': 1},
      });

      expect(page.items.single.email, 'a@b.c');
      expect(page.items.single.role, UserRole.user);
      expect(page.items.single.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
      expect(page.page?.total, 1);
    });
  });

  group('product and history models', () {
    test('ProductPage decodes products and keeps money exact', () {
      final page = ProductPage.fromJson({
        'items': [
          {
            'id': 1,
            'product_key': 'arroz-5kg',
            'gtin': '7891000100103',
            'name': 'Arroz',
            'brand': 'Tio',
            'unit': 'kg',
            'canonical_stem': 'arroz',
            'created_at': '2026-01-02T03:04:05Z',
          },
        ],
        'page': {'page': 1, 'limit': 10, 'total': 1, 'total_pages': 1},
      });

      final product = page.items.single;
      expect(product.productKey, 'arroz-5kg');
      expect(product.canonicalStem, 'arroz');
      expect(product.toJson()['product_key'], 'arroz-5kg');
    });

    test('ProductHistory preserves high-precision prices as strings', () {
      final history = ProductHistory.fromJson({
        'product': {'id': 1, 'name': 'Arroz'},
        'from': '2026-01-01T00:00:00Z',
        'to': '2026-02-01T00:00:00Z',
        'points': [
          {
            'access_key': 'key-1',
            'supermarket': {'id': 3, 'legal_name': 'Mercado'},
            'line': 1,
            'qty': '2',
            'price_per_unit': '12.3456',
            'comparable_price_per_unit': '12.3456',
            'total_price': '24.6912',
            'issued_at': '2026-01-10T12:00:00Z',
          },
        ],
        'aggregate': [
          {
            'unit': 'kg',
            'count': 1,
            'min': '12.3456',
            'avg': '12.3456',
            'max': '12.3456',
            'last': '12.3456',
          },
        ],
      });

      expect(history.points.single.pricePerUnit?.amount, '12.3456');
      expect(history.points.single.supermarket?.legalName, 'Mercado');
      expect(history.aggregate.single.avg?.amount, '12.3456');
    });
  });

  group('supermarket models', () {
    test('SupermarketProductsPage decodes nested products', () {
      final page = SupermarketProductsPage.fromJson({
        'supermarket': {'id': 3, 'cnpj': '123', 'legal_name': 'Mercado'},
        'items': [
          {
            'product': {'id': 1, 'name': 'Arroz'},
            'price_log_id': 9,
            'qty': '1',
            'total_price': '24.6912',
            'last_logged_at': '2026-01-10T12:00:00Z',
          },
        ],
        'page': {'page': 1, 'limit': 10, 'total': 1, 'total_pages': 1},
      });

      expect(page.supermarket?.legalName, 'Mercado');
      expect(page.items.single.totalPrice?.amount, '24.6912');
    });
  });

  group('receipt models', () {
    test('PreviewResult decodes items, totals, and expiry', () {
      final preview = PreviewResult.fromJson({
        'preview_id': 42,
        'status': 'pending',
        'access_key': '3520...',
        'expires_at': '2026-01-02T03:04:05Z',
        'items': [
          {
            'line': 1,
            'description': 'ARROZ 5KG',
            'status': 'uid_uncertain',
            'similarity': 0.87,
            'price_per_unit': '24.90',
          },
          {
            'line': 2,
            'description': 'FEIJAO',
            'status': 'gtin_known',
            'gtin': '789',
          },
        ],
        'totals': {
          'items': 2,
          'auto_save': 1,
          'uid_uncertain': 1,
          'needs_review': 0,
          'parse_errors': 0,
          'estimated_total': '34.80',
        },
      });

      expect(preview.previewId, 42);
      expect(preview.items.first.status, PreviewItemStatus.uidUncertain);
      expect(preview.items.first.similarity, 0.87);
      expect(preview.items.first.pricePerUnit?.amount, '24.90');
      expect(preview.items.last.status, PreviewItemStatus.gtinKnown);
      expect(preview.totals.estimatedTotal?.amount, '34.80');
    });

    test('unknown preview status is a serialization failure', () {
      expect(
        () => PreviewItem.fromJson({
          'line': 1,
          'description': 'x',
          'status': 'mystery',
        }),
        throwsA(isA<SerializationException>()),
      );
    });

    test('DraftRequest omits absent identifiers', () {
      expect(const DraftRequest(accessKey: 'abc').toJson(), {
        'access_key': 'abc',
      });
      expect(const DraftRequest(qrPayload: 'http://x').toJson(), {
        'qr_payload': 'http://x',
      });
    });

    test('CommitRequest serializes resolutions and preserves actions', () {
      const request = CommitRequest(
        previewId: 42,
        confirm: true,
        resolutions: [
          Resolution(line: 1, action: ResolutionAction.skip),
          Resolution(line: 2, action: ResolutionAction.assign, productId: 7),
        ],
      );

      expect(request.toJson(), {
        'preview_id': 42,
        'confirm': true,
        'resolutions': [
          {'line': 1, 'action': 'skip'},
          {'line': 2, 'action': 'assign', 'product_id': 7},
        ],
      });
    });

    test('CommitResult reads counts and identifiers', () {
      final result = CommitResult.fromJson({
        'preview_id': 42,
        'confirmed': true,
        'written': 3,
        'auto_saved': 2,
        'assigned': 1,
        'needs_review': 0,
        'skipped': 0,
        'nfce_id': 5,
        'access_key': '3520...',
      });

      expect(result.written, 3);
      expect(result.accessKey, '3520...');
    });
  });

  group('captcha models', () {
    test('CaptchaChallenge reads the 412 error envelope', () {
      final challenge = CaptchaChallenge.fromJson({
        'error': {
          'code': 'captcha_required',
          'message': 'solve it',
          'challenge_id': 'c-1',
          'image_url': '/nfce/captcha/image/c-1',
        },
      });

      expect(challenge.challengeId, 'c-1');
      expect(challenge.toJson()['error'], {
        'code': 'captcha_required',
        'message': 'solve it',
        'challenge_id': 'c-1',
        'image_url': '/nfce/captcha/image/c-1',
      });
    });

    test('CaptchaWrongSolution reads attempts_left', () {
      final wrong = CaptchaWrongSolution.fromJson({
        'error': {
          'code': 'captcha_wrong_solution',
          'message': 'nope',
          'challenge_id': 'c-1',
          'attempts_left': 2,
          'image_url': '/img',
        },
      });

      expect(wrong.attemptsLeft, 2);
    });

    test('CaptchaState maps lifecycle status', () {
      final state = CaptchaState.fromJson({
        'challenge_id': 'c-1',
        'status': 'locked',
        'attempts_left': 0,
        'max_attempts': 3,
      });

      expect(state.status, CaptchaStatus.locked);
      expect(state.maxAttempts, 3);
    });
  });

  group('admin models', () {
    test('ReviewQueuePage decodes rows', () {
      final page = ReviewQueuePage.fromJson({
        'items': [
          {
            'price_log_id': 9,
            'nfce_id': 5,
            'access_key': 'key',
            'line': 1,
            'description': 'ARROZ',
            'store_name': 'Mercado',
            'qty': '2',
            'total_price': '24.6912',
            'suggested_stem': 'arroz',
            'created_at': '2026-01-02T03:04:05Z',
          },
        ],
        'page': {'page': 1, 'limit': 10, 'total': 1, 'total_pages': 1},
      });

      expect(page.items.single.description, 'ARROZ');
      expect(page.items.single.totalPrice?.amount, '24.6912');
    });

    test('BatchAssignRequest omits null fields for create actions', () {
      const request = BatchAssignRequest(
        assignments: [
          Assignment(id: 1, action: AssignmentAction.existing, productId: 7),
          Assignment(id: 2, action: AssignmentAction.create, name: 'Novo'),
        ],
      );

      expect(request.toJson(), {
        'assignments': [
          {'id': 1, 'action': 'existing', 'product_id': 7},
          {'id': 2, 'action': 'create', 'name': 'Novo'},
        ],
      });
    });

    test('RoleUpdateRequest encodes the role name', () {
      expect(const RoleUpdateRequest(role: UserRole.admin).toJson(), {
        'role': 'admin',
      });
    });

    test('merge request bodies use backend field names', () {
      expect(const MergeProductsRequest(fromId: 1, toId: 2).toJson(), {
        'from_id': 1,
        'to_id': 2,
      });
      expect(
        const MergeSupermarketsRequest(fromCnpj: 'a', toCnpj: 'b').toJson(),
        {'from_cnpj': 'a', 'to_cnpj': 'b'},
      );
    });
  });

  group('errors and metrics', () {
    test('ApiErrorEnvelope decodes the failure envelope', () {
      final envelope = ApiErrorEnvelope.fromJson({
        'error': {'code': 'not_found', 'message': 'missing'},
      });

      expect(envelope.error.code, 'not_found');
      expect(envelope.error.message, 'missing');
    });

    test('Metrics decodes reports and off-cache counters', () {
      final metrics = Metrics.fromJson({
        'requests': {
          'total_requests': 10,
          'total_duration_ms': 250,
          'auth_failures': 1,
          'by_status': {'2xx': 9, '4xx': 1},
          'routes': [
            {
              'method': 'GET',
              'pattern': '/products',
              'count': 10,
              'errors': 1,
              'total_ms': 250,
              'histogram': [1, 2, 3],
            },
          ],
          'latency_buckets_ms': [5, 10, 25],
        },
        'off_cache': {'hits': 4, 'misses': 1},
      });

      expect(metrics.requests.byStatus['2xx'], 9);
      expect(metrics.requests.routes.single.pattern, '/products');
      expect(metrics.requests.latencyBucketsMs, [5, 10, 25]);
      expect(metrics.offCache?.hits, 4);
    });
  });
}
