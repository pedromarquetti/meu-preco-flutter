import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import '../../../core/models/models.dart';

/// Product catalog reads: search, detail, and price history.
///
/// Supermarket listing endpoints are intentionally absent: the current UX
/// reaches store context through the supermarket embedded in each price point
/// of [ProductHistory], so no comparison screen needs the extra calls yet.
abstract interface class ProductRepository {
  /// `GET /products` — fuzzy catalog search.
  Future<ProductPage> search({
    String? q,
    String? gtin,
    String? unit,
    String? brand,
    int page = 1,
    int limit = 20,
  });

  /// `GET /products/{id}` — one product.
  Future<ProductView> detail(int id);

  /// `GET /products/{id}/history` — price curve and per-unit aggregates.
  Future<ProductHistory> history(int id, {DateTime? from, DateTime? to});
}

/// [ProductRepository] built on the shared authenticated [ApiClient].
class ApiProductRepository implements ProductRepository {
  ApiProductRepository({required ApiClient client})
    : _client = client; // ignore: prefer_initializing_formals

  final ApiClient _client;

  @override
  Future<ProductPage> search({
    String? q,
    String? gtin,
    String? unit,
    String? brand,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _client.get(
      '/products',
      query: <String, String>{
        if (q != null && q.isNotEmpty) 'q': q,
        if (gtin != null && gtin.isNotEmpty) 'gtin': gtin,
        if (unit != null && unit.isNotEmpty) 'unit': unit,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        'page': '$page',
        'limit': '$limit',
      },
    );
    return ProductPage.fromJson(_asObject(data));
  }

  @override
  Future<ProductView> detail(int id) async {
    final data = await _client.get('/products/$id');
    return ProductView.fromJson(_asObject(data));
  }

  @override
  Future<ProductHistory> history(int id, {DateTime? from, DateTime? to}) async {
    final data = await _client.get(
      '/products/$id/history',
      query: <String, String>{
        if (from != null) 'from': _dateOnly(from),
        if (to != null) 'to': _dateOnly(to),
      },
    );
    return ProductHistory.fromJson(_asObject(data));
  }

  /// The API accepts `YYYY-MM-DD` for the optional range bounds.
  String _dateOnly(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  JsonMap _asObject(Object? data) {
    if (data is JsonMap) return data;
    throw const SerializationException(
      message: 'Expected a JSON object response',
    );
  }
}
