import '../errors/app_exception.dart';
import 'decimal.dart';
import 'json.dart';
import 'pagination.dart';
import 'user.dart';

/// A needs-review price log row (`/admin/products/needs-review`).
class ReviewItem {
  const ReviewItem({
    this.priceLogId,
    this.nfceId,
    this.accessKey,
    this.line,
    this.description,
    this.storeCode,
    this.cnpjBase,
    this.storeName,
    this.unit,
    this.qty,
    this.pricePerUnit,
    this.unitPrice,
    this.totalPrice,
    this.suggestedStem,
    this.createdAt,
  });

  factory ReviewItem.fromJson(JsonMap json) => ReviewItem(
    priceLogId: json.intOrNull('price_log_id'),
    nfceId: json.intOrNull('nfce_id'),
    accessKey: json.stringOrNull('access_key'),
    line: json.intOrNull('line'),
    description: json.stringOrNull('description'),
    storeCode: json.stringOrNull('store_code'),
    cnpjBase: json.stringOrNull('cnpj_base'),
    storeName: json.stringOrNull('store_name'),
    unit: json.stringOrNull('unit'),
    qty: json.decimalOrNull('qty'),
    pricePerUnit: json.decimalOrNull('price_per_unit'),
    unitPrice: json.decimalOrNull('unit_price'),
    totalPrice: json.decimalOrNull('total_price'),
    suggestedStem: json.stringOrNull('suggested_stem'),
    createdAt: json.dateTimeOrNull('created_at'),
  );

  final int? priceLogId;
  final int? nfceId;
  final String? accessKey;
  final int? line;
  final String? description;
  final String? storeCode;
  final String? cnpjBase;
  final String? storeName;
  final String? unit;
  final Decimal? qty;
  final Decimal? pricePerUnit;
  final Decimal? unitPrice;
  final Decimal? totalPrice;
  final String? suggestedStem;
  final DateTime? createdAt;

  JsonMap toJson() => {
    'price_log_id': priceLogId,
    'nfce_id': nfceId,
    'access_key': accessKey,
    'line': line,
    'description': description,
    'store_code': storeCode,
    'cnpj_base': cnpjBase,
    'store_name': storeName,
    'unit': unit,
    'qty': qty?.toJson(),
    'price_per_unit': pricePerUnit?.toJson(),
    'unit_price': unitPrice?.toJson(),
    'total_price': totalPrice?.toJson(),
    'suggested_stem': suggestedStem,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

/// Paginated needs-review queue.
class ReviewQueuePage {
  const ReviewQueuePage({required this.items, this.page});

  factory ReviewQueuePage.fromJson(JsonMap json) => ReviewQueuePage(
    items: json
        .objectListOrEmpty('items')
        .map(ReviewItem.fromJson)
        .toList(growable: false),
    page: json.objectOrNull('page') == null
        ? null
        : Page.fromJson(json.objectValue('page')),
  );

  final List<ReviewItem> items;
  final Page? page;

  JsonMap toJson() => {
    'items': [for (final item in items) item.toJson()],
    'page': page?.toJson(),
  };
}

/// Whether an assignment links to an existing product or creates one.
enum AssignmentAction {
  existing,
  create;

  static AssignmentAction fromJson(String value) => switch (value) {
    'existing' => AssignmentAction.existing,
    'create' => AssignmentAction.create,
    _ => throw SerializationException(
      message: 'Unknown assignment action: "$value"',
    ),
  };

  String toJson() => name;
}

/// A single batch-assignment entry.
class Assignment {
  const Assignment({
    required this.id,
    required this.action,
    this.productId,
    this.name,
    this.brand,
    this.unit,
  });

  factory Assignment.fromJson(JsonMap json) => Assignment(
    id: json.intValue('id'),
    action: AssignmentAction.fromJson(json.stringValue('action')),
    productId: json.intOrNull('product_id'),
    name: json.stringOrNull('name'),
    brand: json.stringOrNull('brand'),
    unit: json.stringOrNull('unit'),
  );

  final int id;
  final AssignmentAction action;
  final int? productId;
  final String? name;
  final String? brand;
  final String? unit;

  JsonMap toJson() => withoutNulls({
    'id': id,
    'action': action.toJson(),
    'product_id': productId,
    'name': name,
    'brand': brand,
    'unit': unit,
  });
}

/// Body of `POST /admin/products/batch-assign`.
class BatchAssignRequest {
  const BatchAssignRequest({required this.assignments});

  final List<Assignment> assignments;

  JsonMap toJson() => {
    'assignments': [for (final assignment in assignments) assignment.toJson()],
  };
}

/// Result of a batch assignment.
class BatchAssignResult {
  const BatchAssignResult({this.assigned, this.created});

  factory BatchAssignResult.fromJson(JsonMap json) => BatchAssignResult(
    assigned: json.intOrNull('assigned'),
    created: json.intOrNull('created'),
  );

  final int? assigned;
  final int? created;

  JsonMap toJson() => {'assigned': assigned, 'created': created};
}

/// Body of `PATCH /admin/users/{id}/role`.
class RoleUpdateRequest {
  const RoleUpdateRequest({required this.role});

  final UserRole role;

  JsonMap toJson() => {'role': role.toJson()};
}
