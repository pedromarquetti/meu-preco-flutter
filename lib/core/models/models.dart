/// Shared API contract models.
///
/// Feature repositories decode API payloads into these types so UI code never
/// touches untyped JSON maps. Field names mirror the backend at the
/// serialization boundary (`refresh_token`, `access_key`, `preview_id`,
/// `uid_uncertain`, `needs_review`, ...); Dart fields use idiomatic names.
library;

export 'admin.dart';
export 'api_error.dart';
export 'auth.dart';
export 'captcha.dart';
export 'decimal.dart';
export 'json.dart';
export 'merge.dart';
export 'metrics.dart';
export 'pagination.dart';
export 'product.dart';
export 'product_history.dart';
export 'receipt.dart';
export 'supermarket.dart';
export 'user.dart';
