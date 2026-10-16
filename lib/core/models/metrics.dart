import 'json.dart';

/// Runtime metrics (`GET /metrics`).
class Metrics {
  const Metrics({required this.requests, this.offCache});

  factory Metrics.fromJson(JsonMap json) => Metrics(
    requests: MetricsReport.fromJson(json.objectValue('requests')),
    offCache: json.objectOrNull('off_cache') == null
        ? null
        : OffCacheStats.fromJson(json.objectValue('off_cache')),
  );

  final MetricsReport requests;
  final OffCacheStats? offCache;

  JsonMap toJson() => {
    'requests': requests.toJson(),
    'off_cache': offCache?.toJson(),
  };
}

/// Aggregate request counters.
class MetricsReport {
  const MetricsReport({
    this.totalRequests,
    this.totalDurationMs,
    this.authFailures,
    this.byStatus = const {},
    this.routes = const [],
    this.latencyBucketsMs = const [],
  });

  factory MetricsReport.fromJson(JsonMap json) => MetricsReport(
    totalRequests: json.intOrNull('total_requests'),
    totalDurationMs: json.intOrNull('total_duration_ms'),
    authFailures: json.intOrNull('auth_failures'),
    byStatus: json.intMapOrEmpty('by_status'),
    routes: json
        .objectListOrEmpty('routes')
        .map(RouteMetrics.fromJson)
        .toList(growable: false),
    latencyBucketsMs: json.intListOrEmpty('latency_buckets_ms'),
  );

  final int? totalRequests;
  final int? totalDurationMs;
  final int? authFailures;
  final Map<String, int> byStatus;
  final List<RouteMetrics> routes;
  final List<int> latencyBucketsMs;

  JsonMap toJson() => {
    'total_requests': totalRequests,
    'total_duration_ms': totalDurationMs,
    'auth_failures': authFailures,
    'by_status': byStatus,
    'routes': [for (final route in routes) route.toJson()],
    'latency_buckets_ms': latencyBucketsMs,
  };
}

/// Per-route counters.
class RouteMetrics {
  const RouteMetrics({
    this.method,
    this.pattern,
    this.count,
    this.errors,
    this.authFailures,
    this.totalMs,
    this.histogram = const [],
  });

  factory RouteMetrics.fromJson(JsonMap json) => RouteMetrics(
    method: json.stringOrNull('method'),
    pattern: json.stringOrNull('pattern'),
    count: json.intOrNull('count'),
    errors: json.intOrNull('errors'),
    authFailures: json.intOrNull('auth_failures'),
    totalMs: json.intOrNull('total_ms'),
    histogram: json.intListOrEmpty('histogram'),
  );

  final String? method;
  final String? pattern;
  final int? count;
  final int? errors;
  final int? authFailures;
  final int? totalMs;
  final List<int> histogram;

  JsonMap toJson() => {
    'method': method,
    'pattern': pattern,
    'count': count,
    'errors': errors,
    'auth_failures': authFailures,
    'total_ms': totalMs,
    'histogram': histogram,
  };
}

/// OFF enrichment cache counters (present only when enrichment is enabled).
class OffCacheStats {
  const OffCacheStats({this.hits, this.misses});

  factory OffCacheStats.fromJson(JsonMap json) => OffCacheStats(
    hits: json.intOrNull('hits'),
    misses: json.intOrNull('misses'),
  );

  final int? hits;
  final int? misses;

  JsonMap toJson() => {'hits': hits, 'misses': misses};
}
