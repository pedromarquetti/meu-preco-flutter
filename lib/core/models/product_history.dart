import 'decimal.dart';
import 'json.dart';
import 'product.dart';
import 'supermarket.dart';

/// One logged price for a product at a supermarket.
class PricePointView {
  const PricePointView({
    this.accessKey,
    this.supermarket,
    this.line,
    this.qty,
    this.unit,
    this.normalizedUnit,
    this.pricePerUnit,
    this.comparableUnit,
    this.comparablePricePerUnit,
    this.unitPrice,
    this.totalPrice,
    this.issuedAt,
    this.loggedAt,
  });

  factory PricePointView.fromJson(JsonMap json) => PricePointView(
    accessKey: json.stringOrNull('access_key'),
    supermarket: json.objectOrNull('supermarket') == null
        ? null
        : SupermarketRef.fromJson(json.objectValue('supermarket')),
    line: json.intOrNull('line'),
    qty: json.decimalOrNull('qty'),
    unit: json.stringOrNull('unit'),
    normalizedUnit: json.stringOrNull('normalized_unit'),
    pricePerUnit: json.decimalOrNull('price_per_unit'),
    comparableUnit: json.stringOrNull('comparable_unit'),
    comparablePricePerUnit: json.decimalOrNull('comparable_price_per_unit'),
    unitPrice: json.decimalOrNull('unit_price'),
    totalPrice: json.decimalOrNull('total_price'),
    issuedAt: json.dateTimeOrNull('issued_at'),
    loggedAt: json.dateTimeOrNull('logged_at'),
  );

  final String? accessKey;
  final SupermarketRef? supermarket;
  final int? line;
  final Decimal? qty;
  final String? unit;
  final String? normalizedUnit;
  final Decimal? pricePerUnit;
  final String? comparableUnit;
  final Decimal? comparablePricePerUnit;
  final Decimal? unitPrice;
  final Decimal? totalPrice;
  final DateTime? issuedAt;
  final DateTime? loggedAt;

  JsonMap toJson() => {
    'access_key': accessKey,
    'supermarket': supermarket?.toJson(),
    'line': line,
    'qty': qty?.toJson(),
    'unit': unit,
    'normalized_unit': normalizedUnit,
    'price_per_unit': pricePerUnit?.toJson(),
    'comparable_unit': comparableUnit,
    'comparable_price_per_unit': comparablePricePerUnit?.toJson(),
    'unit_price': unitPrice?.toJson(),
    'total_price': totalPrice?.toJson(),
    'issued_at': issuedAt?.toUtc().toIso8601String(),
    'logged_at': loggedAt?.toUtc().toIso8601String(),
  };
}

/// Per-unit aggregate (min/avg/max/last) for a product's price history.
class UnitStats {
  const UnitStats({
    this.unit,
    this.count,
    this.min,
    this.avg,
    this.max,
    this.last,
  });

  factory UnitStats.fromJson(JsonMap json) => UnitStats(
    unit: json.stringOrNull('unit'),
    count: json.intOrNull('count'),
    min: json.decimalOrNull('min'),
    avg: json.decimalOrNull('avg'),
    max: json.decimalOrNull('max'),
    last: json.decimalOrNull('last'),
  );

  final String? unit;
  final int? count;
  final Decimal? min;
  final Decimal? avg;
  final Decimal? max;
  final Decimal? last;

  JsonMap toJson() => {
    'unit': unit,
    'count': count,
    'min': min?.toJson(),
    'avg': avg?.toJson(),
    'max': max?.toJson(),
    'last': last?.toJson(),
  };
}

/// A product's price curve plus per-unit aggregates.
class ProductHistory {
  const ProductHistory({
    this.product,
    this.from,
    this.to,
    this.points = const [],
    this.aggregate = const [],
  });

  factory ProductHistory.fromJson(JsonMap json) => ProductHistory(
    product: json.objectOrNull('product') == null
        ? null
        : ProductView.fromJson(json.objectValue('product')),
    from: json.dateTimeOrNull('from'),
    to: json.dateTimeOrNull('to'),
    points: json
        .objectListOrEmpty('points')
        .map(PricePointView.fromJson)
        .toList(growable: false),
    aggregate: json
        .objectListOrEmpty('aggregate')
        .map(UnitStats.fromJson)
        .toList(growable: false),
  );

  final ProductView? product;
  final DateTime? from;
  final DateTime? to;
  final List<PricePointView> points;
  final List<UnitStats> aggregate;

  JsonMap toJson() => {
    'product': product?.toJson(),
    'from': from?.toUtc().toIso8601String(),
    'to': to?.toUtc().toIso8601String(),
    'points': [for (final point in points) point.toJson()],
    'aggregate': [for (final stats in aggregate) stats.toJson()],
  };
}
