import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/models/models.dart';
import 'data/product_repository.dart';

/// Debounced, paginated product search.
///
/// Typing restarts a [debounce] window instead of firing a request per
/// keystroke, and every response is checked against a generation counter so a
/// slower older request can never overwrite a newer result.
class ProductSearchController extends ChangeNotifier {
  ProductSearchController({
    required ProductRepository repository,
    this.debounce = const Duration(milliseconds: 350),
    this.pageSize = 20,
  }) : _repository = repository; // ignore: prefer_initializing_formals

  final ProductRepository _repository;

  /// Quiet period required after the last keystroke.
  final Duration debounce;

  /// Page size requested from the API.
  final int pageSize;

  Timer? _debounceTimer;
  int _generation = 0;
  String _query = '';
  List<ProductView> _results = const <ProductView>[];
  Page? _pageInfo;
  bool _loading = false;
  bool _loadingMore = false;
  AppException? _error;

  String get query => _query;
  List<ProductView> get results => _results;
  Page? get pageInfo => _pageInfo;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  AppException? get error => _error;

  /// Whether another page can be requested for the current result set.
  bool get canLoadMore {
    if (_loading || _loadingMore) return false;
    final info = _pageInfo;
    if (info == null || _results.isEmpty) return false;
    final total = info.totalPages;
    if (total == null) return true;
    return (info.page ?? 1) < total;
  }

  /// Replaces the search term, restarting the debounce window.
  void setQuery(String value) {
    final normalized = value.trim();
    _debounceTimer?.cancel();
    if (normalized == _query) return;
    _query = normalized;
    if (normalized.isEmpty) {
      _generation++;
      _results = const <ProductView>[];
      _pageInfo = null;
      _error = null;
      _loading = false;
      _loadingMore = false;
      notifyListeners();
      return;
    }
    _debounceTimer = Timer(debounce, () {
      _search(reset: true);
    });
  }

  /// Re-runs the current query from the first page.
  Future<void> retry() {
    _debounceTimer?.cancel();
    return _search(reset: true);
  }

  /// Requests the next page, appending it to the current results.
  Future<void> loadMore() {
    if (!canLoadMore) return Future<void>.value();
    return _search(reset: false);
  }

  Future<void> _search({required bool reset}) async {
    if (_query.isEmpty) return Future<void>.value();
    if (!reset && !canLoadMore) return Future<void>.value();

    final generation = ++_generation;
    final page = reset ? 1 : (_pageInfo?.page ?? 1) + 1;
    _loading = reset;
    _loadingMore = !reset;
    if (reset) _error = null;
    notifyListeners();

    try {
      final result = await _repository.search(
        q: _query,
        page: page,
        limit: pageSize,
      );
      if (generation != _generation) return;
      _results = reset
          ? List<ProductView>.unmodifiable(result.items)
          : List<ProductView>.unmodifiable([..._results, ...result.items]);
      _pageInfo = result.page;
      _error = null;
    } catch (error) {
      if (generation != _generation) return;
      _error = error is AppException
          ? error
          : ServerException(message: '$error');
    } finally {
      if (generation == _generation) {
        _loading = false;
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
