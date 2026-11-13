import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import '../../../core/models/models.dart';

/// Admin operations: user management and needs-review queue.
abstract interface class AdminRepository {
  Future<UserPage> listUsers({int page = 1, int pageSize = 50});

  /// Looks up one account by id, or returns `null` when it no longer exists.
  ///
  /// The review queue only carries `resolved_by` ids, so this resolves the
  /// proposer without paging the whole directory.
  Future<UserView?> findUser(int id);
  Future<UserView> updateUserRole({
    required int userId,
    required UserRole role,
  });
  Future<ReviewQueuePage> listNeedsReview({int page = 1, int pageSize = 50});
  Future<ReviewDecisionResult> reviewPriceLog({
    required int priceLogId,
    required PriceLogReviewAction action,
  });
  Future<BatchAssignResult> batchAssign(List<Assignment> assignments);
  Future<ProductView> updateProduct(int id, ProductPatch patch);
  Future<ProductPage> searchProducts({
    String? q,
    int page = 1,
    int pageSize = 50,
  });
  Future<MergeResult> mergeProducts(int fromId, int toId);
}

class ApiAdminRepository implements AdminRepository {
  ApiAdminRepository({required this.client});

  final ApiClient client;

  /// Accounts resolved during this repository's lifetime. Queue refreshes
  /// reuse them, so the same proposer is fetched at most once.
  final Map<int, UserView> _userCache = {};

  /// In-flight lookups keyed by id, so concurrent rows sharing a proposer
  /// issue a single request.
  final Map<int, Future<UserView?>> _userLookups = {};

  JsonMap _asObject(Object? data) {
    if (data is JsonMap) return data;
    throw const SerializationException(message: 'Expected JSON object');
  }

  @override
  Future<UserPage> listUsers({int page = 1, int pageSize = 50}) async {
    final data = await client.get(
      '/admin/users',
      query: {'page': '$page', 'limit': '$pageSize'},
    );
    final result = UserPage.fromJson(_asObject(data));
    for (final user in result.items) {
      final id = user.id;
      if (id != null) _userCache[id] = user;
    }
    return result;
  }

  @override
  Future<UserView?> findUser(int id) {
    final cached = _userCache[id];
    if (cached != null) return Future.value(cached);

    return _userLookups.putIfAbsent(id, () async {
      try {
        final data = await client.get('/admin/user/$id');
        final user = UserView.fromJson(_asObject(data));
        _userCache[id] = user;
        return user;
      } on NotFoundException {
        // A deleted account leaves the proposal intact; the caller falls back
        // to the raw id.
        return null;
      } finally {
        _userLookups.remove(id);
      }
    });
  }

  @override
  Future<ReviewDecisionResult> reviewPriceLog({
    required int priceLogId,
    required PriceLogReviewAction action,
  }) async {
    final data = await client.post(
      '/admin/products/price-logs/$priceLogId/review',
      body: ReviewDecisionRequest(action: action).toJson(),
    );
    return ReviewDecisionResult.fromJson(_asObject(data));
  }

  @override
  Future<UserView> updateUserRole({
    required int userId,
    required UserRole role,
  }) async {
    final data = await client.put(
      '/admin/users/$userId/role',
      body: RoleUpdateRequest(role: role).toJson(),
    );
    return UserView.fromJson(_asObject(data));
  }

  @override
  Future<ReviewQueuePage> listNeedsReview({
    int page = 1,
    int pageSize = 50,
  }) async {
    final data = await client.get(
      '/admin/products/needs-review',
      query: {'page': '$page', 'limit': '$pageSize'},
    );
    return ReviewQueuePage.fromJson(_asObject(data));
  }

  @override
  Future<BatchAssignResult> batchAssign(List<Assignment> assignments) async {
    final data = await client.post(
      '/admin/products/batch-assign',
      body: BatchAssignRequest(assignments: assignments).toJson(),
    );
    return BatchAssignResult.fromJson(_asObject(data));
  }

  @override
  Future<ProductView> updateProduct(int id, ProductPatch patch) async {
    final data = await client.patch(
      '/admin/products/$id',
      body: patch.toJson(),
    );
    return ProductView.fromJson(_asObject(data));
  }

  @override
  Future<ProductPage> searchProducts({
    String? q,
    int page = 1,
    int pageSize = 50,
  }) async {
    final data = await client.get(
      '/products',
      query: <String, String>{
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'page': '$page',
        'limit': '$pageSize',
      },
    );
    return ProductPage.fromJson(_asObject(data));
  }

  @override
  Future<MergeResult> mergeProducts(int fromId, int toId) async {
    final data = await client.post(
      '/admin/products/merge',
      body: MergeProductsRequest(fromId: fromId, toId: toId).toJson(),
    );
    return MergeResult.fromJson(_asObject(data));
  }
}
