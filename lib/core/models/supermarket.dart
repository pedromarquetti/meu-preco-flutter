import 'decimal.dart';
import 'json.dart';
import 'pagination.dart';
import 'product.dart';

/// Minimal supermarket reference embedded in price points.
class SupermarketRef {
  const SupermarketRef({this.id, this.cnpj, this.legalName});

  factory SupermarketRef.fromJson(JsonMap json) => SupermarketRef(
    id: json.intOrNull('id'),
    cnpj: json.stringOrNull('cnpj'),
    legalName: json.stringOrNull('legal_name'),
  );

  final int? id;
  final String? cnpj;
  final String? legalName;

  JsonMap toJson() => {'id': id, 'cnpj': cnpj, 'legal_name': legalName};
}

/// A receipt emitter (store) in the catalog.
class SupermarketView {
  const SupermarketView({
    this.id,
    this.cnpj,
    this.legalName,
    this.address,
    this.createdAt,
  });

  factory SupermarketView.fromJson(JsonMap json) => SupermarketView(
    id: json.intOrNull('id'),
    cnpj: json.stringOrNull('cnpj'),
    legalName: json.stringOrNull('legal_name'),
    address: json.stringOrNull('address'),
    createdAt: json.dateTimeOrNull('created_at'),
  );

  final int? id;
  final String? cnpj;
  final String? legalName;
  final String? address;
  final DateTime? createdAt;

  JsonMap toJson() => {
    'id': id,
    'cnpj': cnpj,
    'legal_name': legalName,
    'address': address,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

/// Paginated supermarket listing.
class SupermarketPage {
  const SupermarketPage({required this.items, this.page});

  factory SupermarketPage.fromJson(JsonMap json) => SupermarketPage(
    items: json
        .objectListOrEmpty('items')
        .map(SupermarketView.fromJson)
        .toList(growable: false),
    page: json.objectOrNull('page') == null
        ? null
        : Page.fromJson(json.objectValue('page')),
  );

  final List<SupermarketView> items;
  final Page? page;

  JsonMap toJson() => {
    'items': [for (final item in items) item.toJson()],
    'page': page?.toJson(),
  };
}

/// A product plus the latest price logged at one supermarket.
class SupermarketProductView {
  const SupermarketProductView({
    this.product,
    this.priceLogId,
    this.qty,
    this.normalizedUnit,
    this.pricePerUnit,
    this.unitPrice,
    this.totalPrice,
    this.lastIssuedAt,
    this.lastLoggedAt,
  });

  factory SupermarketProductView.fromJson(JsonMap json) =>
      SupermarketProductView(
        product: json.objectOrNull('product') == null
            ? null
            : ProductView.fromJson(json.objectValue('product')),
        priceLogId: json.intOrNull('price_log_id'),
        qty: json.decimalOrNull('qty'),
        normalizedUnit: json.stringOrNull('normalized_unit'),
        pricePerUnit: json.decimalOrNull('price_per_unit'),
        unitPrice: json.decimalOrNull('unit_price'),
        totalPrice: json.decimalOrNull('total_price'),
        lastIssuedAt: json.dateTimeOrNull('last_issued_at'),
        lastLoggedAt: json.dateTimeOrNull('last_logged_at'),
      );

  final ProductView? product;
  final int? priceLogId;
  final Decimal? qty;
  final String? normalizedUnit;
  final Decimal? pricePerUnit;
  final Decimal? unitPrice;
  final Decimal? totalPrice;
  final DateTime? lastIssuedAt;
  final DateTime? lastLoggedAt;

  JsonMap toJson() => {
    'product': product?.toJson(),
    'price_log_id': priceLogId,
    'qty': qty?.toJson(),
    'normalized_unit': normalizedUnit,
    'price_per_unit': pricePerUnit?.toJson(),
    'unit_price': unitPrice?.toJson(),
    'total_price': totalPrice?.toJson(),
    'last_issued_at': lastIssuedAt?.toUtc().toIso8601String(),
    'last_logged_at': lastLoggedAt?.toUtc().toIso8601String(),
  };
}

/// Paginated products for a single supermarket, including the store itself.
class SupermarketProductsPage {
  const SupermarketProductsPage({
    this.supermarket,
    required this.items,
    this.page,
  });

  factory SupermarketProductsPage.fromJson(JsonMap json) =>
      SupermarketProductsPage(
        supermarket: json.objectOrNull('supermarket') == null
            ? null
            : SupermarketView.fromJson(json.objectValue('supermarket')),
        items: json
            .objectListOrEmpty('items')
            .map(SupermarketProductView.fromJson)
            .toList(growable: false),
        page: json.objectOrNull('page') == null
            ? null
            : Page.fromJson(json.objectValue('page')),
      );

  final SupermarketView? supermarket;
  final List<SupermarketProductView> items;
  final Page? page;

  JsonMap toJson() => {
    'supermarket': supermarket?.toJson(),
    'items': [for (final item in items) item.toJson()],
    'page': page?.toJson(),
  };
}
