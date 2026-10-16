import '../errors/app_exception.dart';
import 'decimal.dart';
import 'json.dart';

/// Classification of a scanned receipt line.
enum PreviewItemStatus {
  gtinKnown,
  gtinNew,
  commodityFingerprint,
  uidUncertain,
  parseError;

  static PreviewItemStatus fromJson(String value) => switch (value) {
    'gtin_known' => PreviewItemStatus.gtinKnown,
    'gtin_new' => PreviewItemStatus.gtinNew,
    'commodity_fingerprint' => PreviewItemStatus.commodityFingerprint,
    'uid_uncertain' => PreviewItemStatus.uidUncertain,
    'parse_error' => PreviewItemStatus.parseError,
    _ => throw SerializationException(
      message: 'Unknown preview item status: "$value"',
    ),
  };

  String toJson() => switch (this) {
    PreviewItemStatus.gtinKnown => 'gtin_known',
    PreviewItemStatus.gtinNew => 'gtin_new',
    PreviewItemStatus.commodityFingerprint => 'commodity_fingerprint',
    PreviewItemStatus.uidUncertain => 'uid_uncertain',
    PreviewItemStatus.parseError => 'parse_error',
  };
}

/// Request body for `/nfce/new`. Supply exactly one of the two identifiers.
class DraftRequest {
  const DraftRequest({this.accessKey, this.qrPayload});

  final String? accessKey;
  final String? qrPayload;

  JsonMap toJson() =>
      withoutNulls({'access_key': accessKey, 'qr_payload': qrPayload});
}

/// A single line of a receipt preview.
class PreviewItem {
  const PreviewItem({
    required this.line,
    required this.description,
    required this.status,
    this.message,
    this.productKey,
    this.productName,
    this.brand,
    this.gtin,
    this.unit,
    this.pricePerUnit,
    this.similarity,
  });

  factory PreviewItem.fromJson(JsonMap json) => PreviewItem(
    line: json.intValue('line'),
    description: json.stringValue('description'),
    status: PreviewItemStatus.fromJson(json.stringValue('status')),
    message: json.stringOrNull('message'),
    productKey: json.stringOrNull('product_key'),
    productName: json.stringOrNull('product_name'),
    brand: json.stringOrNull('brand'),
    gtin: json.stringOrNull('gtin'),
    unit: json.stringOrNull('unit'),
    pricePerUnit: json.decimalOrNull('price_per_unit'),
    similarity: json.doubleOrNull('similarity'),
  );

  final int line;
  final String description;
  final PreviewItemStatus status;
  final String? message;
  final String? productKey;
  final String? productName;
  final String? brand;
  final String? gtin;
  final String? unit;
  final Money? pricePerUnit;
  final double? similarity;

  JsonMap toJson() => withoutNulls({
    'line': line,
    'description': description,
    'status': status.toJson(),
    'message': message,
    'product_key': productKey,
    'product_name': productName,
    'brand': brand,
    'gtin': gtin,
    'unit': unit,
    'price_per_unit': pricePerUnit?.toJson(),
    'similarity': similarity,
  });
}

/// Counts and estimated total for a preview.
class PlanTotals {
  const PlanTotals({
    this.items,
    this.autoSave,
    this.uidUncertain,
    this.needsReview,
    this.parseErrors,
    this.estimatedTotal,
  });

  factory PlanTotals.fromJson(JsonMap json) => PlanTotals(
    items: json.intOrNull('items'),
    autoSave: json.intOrNull('auto_save'),
    uidUncertain: json.intOrNull('uid_uncertain'),
    needsReview: json.intOrNull('needs_review'),
    parseErrors: json.intOrNull('parse_errors'),
    estimatedTotal: json.decimalOrNull('estimated_total'),
  );

  final int? items;
  final int? autoSave;
  final int? uidUncertain;
  final int? needsReview;
  final int? parseErrors;
  final Money? estimatedTotal;

  JsonMap toJson() => {
    'items': items,
    'auto_save': autoSave,
    'uid_uncertain': uidUncertain,
    'needs_review': needsReview,
    'parse_errors': parseErrors,
    'estimated_total': estimatedTotal?.toJson(),
  };
}

/// A drafted (not yet committed) receipt preview.
class PreviewResult {
  const PreviewResult({
    required this.previewId,
    required this.status,
    required this.accessKey,
    required this.expiresAt,
    required this.items,
    required this.totals,
  });

  factory PreviewResult.fromJson(JsonMap json) => PreviewResult(
    previewId: json.intValue('preview_id'),
    status: json.stringValue('status'),
    accessKey: json.stringValue('access_key'),
    expiresAt: json.dateTimeValue('expires_at'),
    items: json
        .objectListOrEmpty('items')
        .map(PreviewItem.fromJson)
        .toList(growable: false),
    totals: PlanTotals.fromJson(json.objectValue('totals')),
  );

  final int previewId;
  final String status;
  final String accessKey;
  final DateTime expiresAt;
  final List<PreviewItem> items;
  final PlanTotals totals;

  JsonMap toJson() => {
    'preview_id': previewId,
    'status': status,
    'access_key': accessKey,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'items': [for (final item in items) item.toJson()],
    'totals': totals.toJson(),
  };
}

/// Resolution applied to an uncertain (`uid_uncertain`) line.
enum ResolutionAction {
  needsReview,
  skip,
  assign;

  static ResolutionAction fromJson(String value) => switch (value) {
    'needs_review' => ResolutionAction.needsReview,
    'skip' => ResolutionAction.skip,
    'assign' => ResolutionAction.assign,
    _ => throw SerializationException(
      message: 'Unknown resolution action: "$value"',
    ),
  };

  String toJson() => switch (this) {
    ResolutionAction.needsReview => 'needs_review',
    ResolutionAction.skip => 'skip',
    ResolutionAction.assign => 'assign',
  };
}

/// Per-line resolution sent with a commit.
class Resolution {
  const Resolution({required this.line, required this.action, this.productId});

  factory Resolution.fromJson(JsonMap json) => Resolution(
    line: json.intValue('line'),
    action: ResolutionAction.fromJson(json.stringValue('action')),
    productId: json.intOrNull('product_id'),
  );

  final int line;
  final ResolutionAction action;
  final int? productId;

  JsonMap toJson() => withoutNulls({
    'line': line,
    'action': action.toJson(),
    'product_id': productId,
  });
}

/// Request body for `/nfce/submit`.
class CommitRequest {
  const CommitRequest({
    required this.previewId,
    required this.confirm,
    this.resolutions = const [],
  });

  final int previewId;
  final bool confirm;
  final List<Resolution> resolutions;

  JsonMap toJson() => {
    'preview_id': previewId,
    'confirm': confirm,
    'resolutions': [for (final resolution in resolutions) resolution.toJson()],
  };
}

/// Result of committing a preview.
class CommitResult {
  const CommitResult({
    this.previewId,
    this.confirmed,
    this.written,
    this.autoSaved,
    this.assigned,
    this.needsReview,
    this.skipped,
    this.nfceId,
    this.accessKey,
  });

  factory CommitResult.fromJson(JsonMap json) => CommitResult(
    previewId: json.intOrNull('preview_id'),
    confirmed: json.boolOrNull('confirmed'),
    written: json.intOrNull('written'),
    autoSaved: json.intOrNull('auto_saved'),
    assigned: json.intOrNull('assigned'),
    needsReview: json.intOrNull('needs_review'),
    skipped: json.intOrNull('skipped'),
    nfceId: json.intOrNull('nfce_id'),
    accessKey: json.stringOrNull('access_key'),
  );

  final int? previewId;
  final bool? confirmed;
  final int? written;
  final int? autoSaved;
  final int? assigned;
  final int? needsReview;
  final int? skipped;
  final int? nfceId;
  final String? accessKey;

  JsonMap toJson() => {
    'preview_id': previewId,
    'confirmed': confirmed,
    'written': written,
    'auto_saved': autoSaved,
    'assigned': assigned,
    'needs_review': needsReview,
    'skipped': skipped,
    'nfce_id': nfceId,
    'access_key': accessKey,
  };
}

/// Body of `/nfce/delete`.
class DeleteReceiptRequest {
  const DeleteReceiptRequest({required this.accessKey});

  final String accessKey;

  JsonMap toJson() => {'access_key': accessKey};
}

/// Result of deleting a receipt.
class DeleteReceiptResult {
  const DeleteReceiptResult({
    this.accessKey,
    this.nfceId,
    this.logsDeleted,
    this.previewsDeleted,
  });

  factory DeleteReceiptResult.fromJson(JsonMap json) => DeleteReceiptResult(
    accessKey: json.stringOrNull('access_key'),
    nfceId: json.intOrNull('nfce_id'),
    logsDeleted: json.intOrNull('logs_deleted'),
    previewsDeleted: json.intOrNull('previews_deleted'),
  );

  final String? accessKey;
  final int? nfceId;
  final int? logsDeleted;
  final int? previewsDeleted;

  JsonMap toJson() => {
    'access_key': accessKey,
    'nfce_id': nfceId,
    'logs_deleted': logsDeleted,
    'previews_deleted': previewsDeleted,
  };
}
