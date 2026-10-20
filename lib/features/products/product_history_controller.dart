import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/models/models.dart';
import 'data/product_repository.dart';

/// Loads a product plus its price history, with an optional date range.
///
/// Points are kept in chronological order so the chart and the list agree on
/// the same sequence, and an inverted range is rejected before any request.
class ProductHistoryController extends ChangeNotifier {
  ProductHistoryController({
    required ProductRepository repository,
    required this.productId,
  }) : _repository = repository; // ignore: prefer_initializing_formals

  final ProductRepository _repository;
  final int productId;

  ProductView? _product;
  List<PricePointView> _points = const <PricePointView>[];
  List<UnitStats> _aggregate = const <UnitStats>[];
  DateTime? _from;
  DateTime? _to;
  bool _loading = false;
  AppException? _error;

  ProductView? get product => _product;
  List<PricePointView> get points => _points;
  List<UnitStats> get aggregate => _aggregate;
  DateTime? get from => _from;
  DateTime? get to => _to;
  bool get isLoading => _loading;
  AppException? get error => _error;

  /// Loads the history, replacing [from] and [to] when both are supplied.
  Future<void> load({DateTime? from, DateTime? to}) async {
    final resolvedFrom = from ?? _from;
    final resolvedTo = to ?? _to;
    if (resolvedFrom != null &&
        resolvedTo != null &&
        resolvedFrom.isAfter(resolvedTo)) {
      _error = const ValidationException(code: 'invalid_date_range');
      _loading = false;
      notifyListeners();
      return Future<void>.value();
    }

    _from = resolvedFrom;
    _to = resolvedTo;
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final history = await _repository.history(
        productId,
        from: _from,
        to: _to,
      );
      _product = history.product;
      _points = List<PricePointView>.unmodifiable(_sorted(history.points));
      _aggregate = List<UnitStats>.unmodifiable(history.aggregate);
    } catch (error) {
      _error = error is AppException
          ? error
          : ServerException(message: '$error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Clears the date range and reloads the full history.
  Future<void> clearRange() {
    _from = null;
    _to = null;
    return load();
  }

  /// Orders points oldest-first using the receipt issue time, falling back to
  /// the log time, so equal timestamps keep their API order.
  List<PricePointView> _sorted(List<PricePointView> points) {
    final indexed = points.toList(growable: true);
    final order = <PricePointView, int>{
      for (final (index, point) in indexed.indexed) point: index,
    };
    indexed.sort((a, b) {
      final byDate = _moment(a).compareTo(_moment(b));
      if (byDate != 0) return byDate;
      return (order[a] ?? 0).compareTo(order[b] ?? 0);
    });
    return indexed;
  }

  DateTime _moment(PricePointView point) =>
      point.loggedAt ??
      point.issuedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
