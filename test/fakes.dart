import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' hide Page;
import 'package:meu_preco_frontend/core/http/auth_token_source.dart';
import 'package:meu_preco_frontend/core/http/server_health_service.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/core/storage/credential_store.dart';
import 'package:meu_preco_frontend/core/storage/key_value_store.dart';
import 'package:meu_preco_frontend/features/auth/data/auth_repository.dart';
import 'package:meu_preco_frontend/features/admin/data/admin_repository.dart';
import 'package:meu_preco_frontend/features/nfce/code_scanner.dart';
import 'package:meu_preco_frontend/features/nfce/data/nfce_repository.dart';
import 'package:meu_preco_frontend/features/nfce/scanner_status.dart';
import 'package:meu_preco_frontend/features/products/data/product_repository.dart';

/// In-memory [KeyValueStore] so tests never touch platform storage.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _data = <String, String>{};

  Map<String, String> get entries => Map.unmodifiable(_data);

  @override
  Future<String?> readString(String key) async => _data[key];

  @override
  Future<void> writeString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }
}

/// In-memory [CredentialStore] for exercising the session lifecycle.
class InMemoryCredentialStore implements CredentialStore {
  InMemoryCredentialStore([this._session]);

  StoredSession? _session;
  int readCalls = 0;
  int writeCalls = 0;
  int clearCalls = 0;

  StoredSession? get session => _session;

  @override
  Future<StoredSession?> read() async {
    readCalls++;
    return _session;
  }

  @override
  Future<void> write(StoredSession session) async {
    writeCalls++;
    _session = session;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    _session = null;
  }
}

/// Controllable [ServerHealthChecker] for driving the server-config flow in
/// widget tests without networking.
class FakeServerHealthChecker implements ServerHealthChecker {
  FakeServerHealthChecker({
    ServerHealthResult? result,
    ServerHealthResult? readiness,
  }) : _result = result ?? const ServerHealthResult.ok(),
       _readiness = readiness ?? result ?? const ServerHealthResult.ok();

  ServerHealthResult _result;
  ServerHealthResult _readiness;
  int callCount = 0;
  final List<String> requestedOrigins = <String>[];

  set result(ServerHealthResult value) => _result = value;

  set readiness(ServerHealthResult value) => _readiness = value;

  @override
  Future<ServerHealthResult> check(String rawOrigin) async {
    callCount++;
    requestedOrigins.add(rawOrigin);
    return _result;
  }

  @override
  Future<ServerHealthResult> checkReadiness(String rawOrigin) async {
    callCount++;
    requestedOrigins.add(rawOrigin);
    return _readiness;
  }
}

/// Configurable [AuthRepository] that never touches the network.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    User? user,
    this.loginError,
    this.registerError,
    this.refreshError,
    this.currentUserError,
    this.refreshDelay = Duration.zero,
    this.currentUserDelay = Duration.zero,
    this.loginResult,
  }) : user =
           user ??
           const User(
             id: 1,
             name: 'Ada',
             email: 'user@example.com',
             role: UserRole.user,
           );

  User user;
  Object? loginError;
  Object? registerError;
  Object? refreshError;
  Object? currentUserError;
  Duration refreshDelay = Duration.zero;
  Duration currentUserDelay = Duration.zero;
  AuthPair? loginResult;

  int loginCalls = 0;
  int registerCalls = 0;
  int refreshCalls = 0;
  int currentUserCalls = 0;

  /// When set, [refresh] waits for this before completing, so tests can observe
  /// concurrent refreshes sharing one operation.
  Completer<void>? refreshGate;

  int _tokenCounter = 0;

  AuthPair _nextPair() {
    _tokenCounter++;
    return AuthPair(
      accessToken: 'access-$_tokenCounter',
      refreshToken: 'refresh-$_tokenCounter',
      user: user,
    );
  }

  @override
  Future<AuthPair> login(LoginCredentials credentials) async {
    loginCalls++;
    if (loginError != null) throw loginError!;
    if (loginResult != null) return loginResult!;
    return _nextPair();
  }

  @override
  Future<User> register(RegisterCredentials credentials) async {
    registerCalls++;
    if (registerError != null) throw registerError!;
    user = User(
      id: user.id,
      name: credentials.name,
      email: credentials.email,
      role: UserRole.user,
    );
    return user;
  }

  @override
  Future<AuthPair> refresh(RefreshRequest request) async {
    refreshCalls++;
    if (refreshDelay > Duration.zero) await Future.delayed(refreshDelay);
    final gate = refreshGate;
    if (gate != null) await gate.future;
    if (refreshError != null) throw refreshError!;
    return _nextPair();
  }

  @override
  Future<User> currentUser(String accessToken) async {
    currentUserCalls++;
    if (currentUserDelay > Duration.zero) {
      await Future.delayed(currentUserDelay);
    }
    if (currentUserError != null) {
      throw currentUserError!;
    }
    return user;
  }
}

/// Controllable [AuthTokenSource] for [AuthenticatedClient] tests.
class FakeAuthTokenSource implements AuthTokenSource {
  FakeAuthTokenSource({
    String? accessToken,
    this.refreshResult = true,
    this.rotatedAccessToken,
  }) : _accessToken = accessToken; // ignore: prefer_initializing_formals

  String? _accessToken;

  /// Whether [refreshAccessToken] reports success.
  bool refreshResult;

  /// When set, a successful refresh installs this as the new access token.
  String? rotatedAccessToken;

  int refreshCalls = 0;

  /// When set, [refreshAccessToken] waits for this before completing.
  Completer<void>? gate;

  set accessToken(String? value) => _accessToken = value;

  @override
  String? get accessToken => _accessToken;

  @override
  Future<bool> refreshAccessToken() async {
    refreshCalls++;
    final pending = gate;
    if (pending != null) await pending.future;
    if (refreshResult && rotatedAccessToken != null) {
      _accessToken = rotatedAccessToken;
    }
    return refreshResult;
  }
}

/// A 44-digit, alphanumeric-free access key used across receipt fixtures.
const String kSampleAccessKey = '35200123456789012345678901234567890123456789';

/// A 1x1 transparent PNG, valid enough for `Image.memory` to decode.
final Uint8List kSamplePngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

/// Builds a representative pending preview with one recognized line and one
/// uncertain line.
PreviewResult samplePreview({
  int previewId = 42,
  String accessKey = kSampleAccessKey,
  DateTime? expiresAt,
  List<PreviewItem>? items,
}) {
  final resolvedItems =
      items ??
      const <PreviewItem>[
        PreviewItem(
          line: 1,
          description: 'LIMAO TAHITI KG',
          status: PreviewItemStatus.commodityFingerprint,
          message: "matched commodity 'Limao Tahiti'",
          productName: 'Limao Tahiti',
          unit: 'KG',
          pricePerUnit: Decimal('24.90'),
          similarity: 0.93,
        ),
        PreviewItem(
          line: 2,
          description: 'Item sem código',
          status: PreviewItemStatus.uidUncertain,
          message: "product 'Item sem código' has unknown id: unknown product",
        ),
      ];
  return PreviewResult(
    previewId: previewId,
    status: 'pending',
    accessKey: accessKey,
    expiresAt: expiresAt ?? DateTime.now().add(const Duration(minutes: 10)),
    items: resolvedItems,
    totals: const PlanTotals(
      items: 2,
      autoSave: 1,
      uidUncertain: 1,
      needsReview: 1,
      parseErrors: 0,
      estimatedTotal: Decimal('24.90'),
    ),
  );
}

/// Scriptable [NfceRepository] that never touches the network.
class FakeNfceRepository implements NfceRepository {
  DraftOutcome? draftOutcome;
  CaptchaSolveOutcome? solveOutcome;
  CaptchaState? captchaStateResult;
  Uint8List? imageBytes;
  CommitResult? submitResult;
  DeleteReceiptResult? deleteResult;

  Object? draftError;
  Object? solveError;
  Object? captchaStateError;
  Object? imageError;
  Object? submitError;
  Object? deleteError;

  int draftCalls = 0;
  int solveCalls = 0;
  int captchaStateCalls = 0;
  int imageCalls = 0;
  int submitCalls = 0;
  int deleteCalls = 0;

  final List<DraftRequest> draftRequests = <DraftRequest>[];
  final List<CaptchaSolutionRequest> solveRequests = <CaptchaSolutionRequest>[];
  final List<CommitRequest> submitRequests = <CommitRequest>[];
  final List<DeleteReceiptRequest> deleteRequests = <DeleteReceiptRequest>[];

  @override
  Future<DraftOutcome> draft(DraftRequest request) async {
    draftCalls++;
    draftRequests.add(request);
    if (draftError != null) throw draftError!;
    return draftOutcome ?? DraftPreview(samplePreview());
  }

  @override
  Future<CaptchaSolveOutcome> solveCaptcha(
    CaptchaSolutionRequest request,
  ) async {
    solveCalls++;
    solveRequests.add(request);
    if (solveError != null) throw solveError!;
    return solveOutcome ?? CaptchaSolved(samplePreview());
  }

  @override
  Future<CaptchaState> captchaState(String challengeId) async {
    captchaStateCalls++;
    if (captchaStateError != null) throw captchaStateError!;
    return captchaStateResult ??
        const CaptchaState(
          challengeId: 'c1',
          status: CaptchaStatus.pending,
          attemptsLeft: 5,
          maxAttempts: 5,
        );
  }

  @override
  Future<Uint8List> captchaImage(String challengeId) async {
    imageCalls++;
    if (imageError != null) throw imageError!;
    return imageBytes ?? kSamplePngBytes;
  }

  @override
  Future<CommitResult> submit(CommitRequest request) async {
    submitCalls++;
    submitRequests.add(request);
    if (submitError != null) throw submitError!;
    return submitResult ??
        const CommitResult(
          previewId: 42,
          confirmed: true,
          written: 1,
          autoSaved: 1,
          assigned: 0,
          needsReview: 1,
          skipped: 0,
          accessKey: kSampleAccessKey,
        );
  }

  @override
  Future<DeleteReceiptResult> deleteReceipt(
    DeleteReceiptRequest request,
  ) async {
    deleteCalls++;
    deleteRequests.add(request);
    if (deleteError != null) throw deleteError!;
    return deleteResult ??
        const DeleteReceiptResult(
          accessKey: kSampleAccessKey,
          nfceId: 1,
          logsDeleted: 1,
          previewsDeleted: 1,
        );
  }
}

/// Scriptable [AdminRepository] that never touches the network.
class FakeAdminRepository implements AdminRepository {
  UserPage? usersResult;
  ReviewQueuePage? needsReviewResult;
  BatchAssignResult? batchAssignResult;
  ProductPage? searchResult;

  Object? listUsersError;
  Object? updateUserRoleError;
  Object? needsReviewError;
  Object? batchAssignError;
  Object? updateProductError;

  int listUsersCalls = 0;
  int updateUserRoleCalls = 0;
  int needsReviewCalls = 0;
  int batchAssignCalls = 0;
  int searchProductsCalls = 0;

  @override
  Future<UserPage> listUsers({int page = 1, int pageSize = 50}) async {
    listUsersCalls++;
    if (listUsersError != null) throw listUsersError!;
    return usersResult ??
        UserPage(
          items: const [
            UserView(
              id: 1,
              name: 'Ada',
              email: 'ada@example.com',
              role: UserRole.user,
            ),
          ],
          page: const Page(total: 1, totalPages: 1),
        );
  }

  @override
  Future<UserView> updateUserRole({
    required int userId,
    required UserRole role,
  }) async {
    updateUserRoleCalls++;
    if (updateUserRoleError != null) throw updateUserRoleError!;
    return UserView(
      id: userId,
      name: 'Ada',
      email: 'ada@example.com',
      role: role,
    );
  }

  @override
  Future<ReviewQueuePage> listNeedsReview({
    int page = 1,
    int pageSize = 50,
  }) async {
    needsReviewCalls++;
    if (needsReviewError != null) throw needsReviewError!;
    return needsReviewResult ??
        ReviewQueuePage(items: const [], page: const Page());
  }

  @override
  Future<BatchAssignResult> batchAssign(List<Assignment> assignments) async {
    batchAssignCalls++;
    if (batchAssignError != null) throw batchAssignError!;
    return batchAssignResult ??
        const BatchAssignResult(assigned: 0, created: 0);
  }

  @override
  Future<ProductView> updateProduct(int id, ProductPatch patch) async {
    if (updateProductError != null) throw updateProductError!;
    return sampleProduct(id: id);
  }

  @override
  Future<ProductPage> searchProducts({
    String? q,
    int page = 1,
    int pageSize = 50,
  }) async {
    searchProductsCalls++;
    return searchResult ?? ProductPage(items: const [], page: const Page());
  }

  @override
  Future<MergeResult> mergeProducts(int fromId, int toId) async {
    return MergeResult(
      fromId: fromId,
      toId: toId,
      logsMoved: 0,
      dupRemoved: false,
    );
  }

  @override
  Future<ProductView> getProduct(int id) async {
    return sampleProduct(id: id);
  }
}

/// Controllable [CodeScanner] for driving the camera path in tests.
class FakeCodeScanner implements CodeScanner {
  FakeCodeScanner({this.isAvailable = false, this.payload});

  @override
  bool get isSupported => isAvailable;

  final bool isAvailable;

  String? payload;
  Object? error;
  int scanCalls = 0;
  int prepareCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<ScannerStatus> prepare() async {
    prepareCalls++;
    if (error != null) throw error!;
    return isAvailable
        ? const ScannerStatus.ready()
        : const ScannerStatus(ScannerAvailability.unavailable);
  }

  @override
  Future<String?> scan() async {
    scanCalls++;
    if (error != null) throw error!;
    return payload;
  }

  @override
  Widget buildPreview({required ValueChanged<String> onDetected}) =>
      const SizedBox.shrink();

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return true;
  }
}

/// Scriptable [ProductRepository] for catalog and history tests.
class FakeProductRepository implements ProductRepository {
  ProductPage? searchResult;
  ProductView? detailResult;
  ProductHistory? historyResult;

  Object? searchError;
  Object? detailError;
  Object? historyError;

  FutureOr<ProductPage> Function(int page, String? q)? searchHandler;
  FutureOr<ProductHistory> Function(DateTime? from, DateTime? to)?
  historyHandler;

  int searchCalls = 0;
  int detailCalls = 0;
  int historyCalls = 0;

  final List<
    ({
      String? q,
      String? gtin,
      String? unit,
      String? brand,
      int page,
      int limit,
    })
  >
  searchRequests =
      <
        ({
          String? q,
          String? gtin,
          String? unit,
          String? brand,
          int page,
          int limit,
        })
      >[];
  final List<({int id, DateTime? from, DateTime? to})> historyRequests =
      <({int id, DateTime? from, DateTime? to})>[];
  final List<int> detailRequests = <int>[];

  @override
  Future<ProductPage> search({
    String? q,
    String? gtin,
    String? unit,
    String? brand,
    int page = 1,
    int limit = 20,
  }) async {
    searchCalls++;
    searchRequests.add((
      q: q,
      gtin: gtin,
      unit: unit,
      brand: brand,
      page: page,
      limit: limit,
    ));
    if (searchError != null) throw searchError!;
    final handler = searchHandler;
    if (handler != null) return await handler(page, q);
    return searchResult ?? ProductPage(items: const [], page: const Page());
  }

  @override
  Future<ProductView> detail(int id) async {
    detailCalls++;
    detailRequests.add(id);
    if (detailError != null) throw detailError!;
    return detailResult ?? sampleProduct(id: id);
  }

  @override
  Future<ProductHistory> history(int id, {DateTime? from, DateTime? to}) async {
    historyCalls++;
    historyRequests.add((id: id, from: from, to: to));
    if (historyError != null) throw historyError!;
    final handler = historyHandler;
    if (handler != null) return await handler(from, to);
    return historyResult ?? sampleHistory();
  }
}

ProductView sampleProduct({
  int? id = 1,
  String? name = 'Arroz Tipo 1 5kg',
  String? brand = 'Marca Boa',
  String? unit = 'kg',
  String? gtin = '7891234567890',
}) => ProductView(
  id: id,
  productKey: 'rice-5kg',
  gtin: gtin,
  name: name,
  brand: brand,
  unit: unit,
  canonicalStem: 'arroz',
  createdAt: DateTime.utc(2025, 1, 1),
);

PricePointView samplePricePoint({
  String? price = '5.49',
  String? total = '27.45',
  String? qty = '5',
  String? unit = 'kg',
  String? supermarketName = 'Mercado Central',
  DateTime? loggedAt,
  DateTime? issuedAt,
  String? accessKey,
}) => PricePointView(
  accessKey: accessKey ?? kSampleAccessKey,
  supermarket: SupermarketRef(id: 1, cnpj: '123', legalName: supermarketName),
  line: 1,
  qty: qty == null ? null : Decimal(qty),
  unit: unit,
  normalizedUnit: unit,
  pricePerUnit: price == null ? null : Decimal(price),
  comparableUnit: unit,
  comparablePricePerUnit: price == null ? null : Decimal(price),
  unitPrice: price == null ? null : Decimal(price),
  totalPrice: total == null ? null : Decimal(total),
  issuedAt: issuedAt ?? DateTime.utc(2025, 2, 1),
  loggedAt: loggedAt ?? DateTime.utc(2025, 2, 2),
);

ProductHistory sampleHistory({
  ProductView? product,
  List<PricePointView>? points,
  List<UnitStats>? aggregate,
}) {
  final resolvedPoints =
      points ??
      <PricePointView>[
        samplePricePoint(
          price: '4.99',
          loggedAt: DateTime.utc(2025, 1, 10),
          issuedAt: DateTime.utc(2025, 1, 9),
        ),
        samplePricePoint(
          price: '5.49',
          loggedAt: DateTime.utc(2025, 2, 10),
          issuedAt: DateTime.utc(2025, 2, 9),
        ),
      ];
  return ProductHistory(
    product: product ?? sampleProduct(),
    from: DateTime.utc(2025, 1, 1),
    to: DateTime.utc(2025, 12, 31),
    points: resolvedPoints,
    aggregate:
        aggregate ??
        const <UnitStats>[
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
}
