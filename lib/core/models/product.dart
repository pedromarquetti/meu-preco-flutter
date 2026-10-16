import 'json.dart';
import 'pagination.dart';

/// A product in the shared catalog.
class ProductView {
  const ProductView({
    this.id,
    this.productKey,
    this.gtin,
    this.name,
    this.brand,
    this.unit,
    this.canonicalStem,
    this.createdAt,
  });

  factory ProductView.fromJson(JsonMap json) => ProductView(
    id: json.intOrNull('id'),
    productKey: json.stringOrNull('product_key'),
    gtin: json.stringOrNull('gtin'),
    name: json.stringOrNull('name'),
    brand: json.stringOrNull('brand'),
    unit: json.stringOrNull('unit'),
    canonicalStem: json.stringOrNull('canonical_stem'),
    createdAt: json.dateTimeOrNull('created_at'),
  );

  final int? id;
  final String? productKey;
  final String? gtin;
  final String? name;
  final String? brand;
  final String? unit;
  final String? canonicalStem;
  final DateTime? createdAt;

  JsonMap toJson() => {
    'id': id,
    'product_key': productKey,
    'gtin': gtin,
    'name': name,
    'brand': brand,
    'unit': unit,
    'canonical_stem': canonicalStem,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

/// Paginated product search result.
class ProductPage {
  const ProductPage({required this.items, this.page});

  factory ProductPage.fromJson(JsonMap json) => ProductPage(
    items: json
        .objectListOrEmpty('items')
        .map(ProductView.fromJson)
        .toList(growable: false),
    page: json.objectOrNull('page') == null
        ? null
        : Page.fromJson(json.objectValue('page')),
  );

  final List<ProductView> items;
  final Page? page;

  JsonMap toJson() => {
    'items': [for (final item in items) item.toJson()],
    'page': page?.toJson(),
  };
}

/// Editable product fields for `/admin/products/{id}`.
class ProductPatch {
  const ProductPatch({this.name, this.brand, this.unit});

  final String? name;
  final String? brand;
  final String? unit;

  JsonMap toJson() =>
      withoutNulls({'name': name, 'brand': brand, 'unit': unit});
}
