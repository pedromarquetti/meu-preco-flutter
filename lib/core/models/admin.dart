import '../errors/app_exception.dart';
import 'decimal.dart';
import 'json.dart';
import 'pagination.dart';
import 'product.dart';
import 'user.dart';

/// Current state of the proposal attached to a needs-review row.
///
/// A rejected proposal stays in the queue and can be reassigned; only the
/// latest review event decides the status, so an `assign`/`approve` resets it
/// to [pending].
enum ProposalStatus {
  pending,
  rejected;

  static ProposalStatus fromJson(String value) => switch (value) {
    'pending' => ProposalStatus.pending,
    'rejected' => ProposalStatus.rejected,
    _ => throw SerializationException(
      message: 'Unknown proposal status: "$value"',
    ),
  };

  String toJson() => name;
}

/// Action recorded on the latest price-log review event.
enum ReviewAction {
  assign,
  reject,
  approve;

  static ReviewAction fromJson(String value) => switch (value) {
    'assign' => ReviewAction.assign,
    'reject' => ReviewAction.reject,
    'approve' => ReviewAction.approve,
    _ => throw SerializationException(
      message: 'Unknown review action: "$value"',
    ),
  };

  String toJson() => name;
}

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
    this.proposedProduct,
    this.resolvedBy,
    this.resolutionNote,
    this.needsReview,
    this.proposalStatus = ProposalStatus.pending,
    this.lastReviewAction,
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
    proposedProduct: json.objectOrNull('proposed_product') == null
        ? null
        : ReviewProductView.fromJson(json.objectValue('proposed_product')),
    resolvedBy: json.intOrNull('resolved_by'),
    resolutionNote: json.stringOrNull('resolution_note'),
    needsReview: json.boolOrNull('needs_review'),
    // Older payloads omit the derived status; a missing value means the row
    // has no rejection event, so pending is the safe default.
    proposalStatus: json.stringOrNull('proposal_status') == null
        ? ProposalStatus.pending
        : ProposalStatus.fromJson(json.stringValue('proposal_status')),
    lastReviewAction: json.stringOrNull('last_review_action') == null
        ? null
        : ReviewAction.fromJson(json.stringValue('last_review_action')),
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
  final ReviewProductView? proposedProduct;
  final int? resolvedBy;
  final String? resolutionNote;
  final bool? needsReview;
  final ProposalStatus proposalStatus;
  final ReviewAction? lastReviewAction;
  final DateTime? createdAt;

  /// Whether the current proposal was rejected by the latest review event.
  bool get isRejected => proposalStatus == ProposalStatus.rejected;

  /// Whether the row carries a proposed product the admin can review.
  bool get isProposal => proposedProduct != null;

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
    'proposed_product': proposedProduct?.toJson(),
    'resolved_by': resolvedBy,
    'resolution_note': resolutionNote,
    'needs_review': needsReview,
    'proposal_status': proposalStatus.toJson(),
    'last_review_action': lastReviewAction?.toJson(),
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}

/// Product proposed by a user for a manually assigned receipt line.
class ReviewProductView {
  const ReviewProductView({
    this.id,
    this.productKey,
    this.gtin,
    this.name,
    this.brand,
    this.unit,
  });

  factory ReviewProductView.fromJson(JsonMap json) => ReviewProductView(
    id: json.intOrNull('id'),
    productKey: json.stringOrNull('product_key'),
    gtin: json.stringOrNull('gtin'),
    name: json.stringOrNull('name'),
    brand: json.stringOrNull('brand'),
    unit: json.stringOrNull('unit'),
  );

  final int? id;
  final String? productKey;
  final String? gtin;
  final String? name;
  final String? brand;
  final String? unit;

  /// Projects the proposal onto the shared catalog shape so the edit UI can
  /// consume it without another product request.
  ProductView toProductView() => ProductView(
    id: id,
    productKey: productKey,
    gtin: gtin,
    name: name,
    brand: brand,
    unit: unit,
  );

  JsonMap toJson() => {
    'id': id,
    'product_key': productKey,
    'gtin': gtin,
    'name': name,
    'brand': brand,
    'unit': unit,
  };
}

enum PriceLogReviewAction {
  approve,
  reject;

  String toJson() => name;
}

class ReviewDecisionRequest {
  const ReviewDecisionRequest({required this.action});

  final PriceLogReviewAction action;

  JsonMap toJson() => {'action': action.toJson()};
}

class ReviewDecisionResult {
  const ReviewDecisionResult({
    this.id,
    this.productKey,
    this.gtin,
    this.name,
    this.unit,
  });

  factory ReviewDecisionResult.fromJson(JsonMap json) => ReviewDecisionResult(
    id: json.intOrNull('id'),
    productKey: json.stringOrNull('product_key'),
    gtin: json.stringOrNull('gtin'),
    name: json.stringOrNull('name'),
    unit: json.stringOrNull('unit'),
  );

  final int? id;
  final String? productKey;
  final String? gtin;
  final String? name;
  final String? unit;

  JsonMap toJson() => {
    'id': id,
    'product_key': productKey,
    'gtin': gtin,
    'name': name,
    'unit': unit,
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
