import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:meu_preco_frontend/core/http/auth_token_source.dart';
import 'package:meu_preco_frontend/core/http/server_health_service.dart';
import 'package:meu_preco_frontend/core/models/models.dart';
import 'package:meu_preco_frontend/core/storage/credential_store.dart';
import 'package:meu_preco_frontend/core/storage/key_value_store.dart';
import 'package:meu_preco_frontend/features/auth/data/auth_repository.dart';
import 'package:meu_preco_frontend/features/nfce/code_scanner.dart';
import 'package:meu_preco_frontend/features/nfce/data/nfce_repository.dart';

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
    final gate = refreshGate;
    if (gate != null) await gate.future;
    if (refreshError != null) throw refreshError!;
    return _nextPair();
  }

  @override
  Future<User> currentUser(String accessToken) async {
    currentUserCalls++;
    if (currentUserError != null) throw currentUserError!;
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

/// Controllable [CodeScanner] for driving the camera path in tests.
class FakeCodeScanner implements CodeScanner {
  FakeCodeScanner({this.isAvailable = false, this.payload});

  @override
  final bool isAvailable;

  String? payload;
  Object? error;
  int scanCalls = 0;

  @override
  Future<String?> scan() async {
    scanCalls++;
    if (error != null) throw error!;
    return payload;
  }
}
