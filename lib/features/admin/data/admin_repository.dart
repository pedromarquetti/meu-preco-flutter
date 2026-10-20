import '../../../core/http/api_client.dart';
import '../../../core/models/models.dart';

/// Admin operations: user management and needs-review queue.
abstract interface class AdminRepository {
  Future<UserPage> listUsers({int page = 1, int pageSize = 50});
  Future<UserView> updateUserRole({
    required int userId,
    required UserRole role,
  });
  Future<ReviewQueuePage> listNeedsReview({int page = 1, int pageSize = 50});
  Future<BatchAssignResult> batchAssign(List<Assignment> assignments);
  Future<ProductView> updateProduct(int id, ProductPatch patch);
  Future<ProductPage> searchProducts({
    String? q,
    int page = 1,
    int pageSize = 50,
  });
}

class ApiAdminRepository implements AdminRepository {
  ApiAdminRepository({required this.client});

  final ApiClient client;

  JsonMap _asObject(Object? data) {
    if (data is JsonMap) return data;
    throw const FormatException('Expected JSON object');
  }

  @override
  Future<UserPage> listUsers({int page = 1, int pageSize = 50}) async {
    final data = await client.get(
      '/admin/users',
      query: {'page': '$page', 'page_size': '$pageSize'},
    );
    return UserPage.fromJson(_asObject(data));
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
      query: {'page': '$page', 'page_size': '$pageSize'},
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
        'page_size': '$pageSize',
      },
    );
    return ProductPage.fromJson(_asObject(data));
  }
}
