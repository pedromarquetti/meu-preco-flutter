import 'json.dart';

/// Pagination metadata shared by every list response (`page`, `limit`,
/// `total`, `total_pages`).
class Page {
  const Page({this.page, this.limit, this.total, this.totalPages});

  factory Page.fromJson(JsonMap json) => Page(
    page: json.intOrNull('page'),
    limit: json.intOrNull('limit'),
    total: json.intOrNull('total'),
    totalPages: json.intOrNull('total_pages'),
  );

  final int? page;
  final int? limit;
  final int? total;
  final int? totalPages;

  JsonMap toJson() => {
    'page': page,
    'limit': limit,
    'total': total,
    'total_pages': totalPages,
  };
}
