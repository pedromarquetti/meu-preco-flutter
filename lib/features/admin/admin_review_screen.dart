import 'package:flutter/material.dart';
import 'package:meu_preco_frontend/features/products/data/product_repository.dart';

import '../../app/app_scope.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/models.dart';
import '../../core/ui/empty_view.dart';
import '../../core/ui/error_messages.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/loading_view.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../features/admin/widgets/product_edit_block.dart';
import 'data/admin_repository.dart';
import 'review_decision.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

enum _BatchAssignStep { select, edit }

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  late final ProductRepository _productRepository =
      context.appDependencies.productsRepository;
  late final AdminRepository _repository =
      context.appDependencies.adminRepository;
  List<ReviewItem> _items = [];
  bool _loading = true;
  Object? _error;
  _BatchAssignStep _step = _BatchAssignStep.select;
  final List<ReviewDecision> _decisions = [];

  /// Tracks loading status and errors for each item in Step 2.
  final Map<int, bool> _loadingDecisions = {}; // priceLogId -> isLoading
  final Map<int, Object?> _errorMessages = {}; // priceLogId -> error

  /// Guards product-detail loads so a stale response cannot overwrite newer
  /// state after the selection changed or Step 2 was re-entered.
  int _detailsGeneration = 0;
  final Map<int, int> _detailRequests = {};

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _detailsGeneration++;
    _detailRequests.clear();
    setState(() {
      _loading = true;
      _error = null;
      _step = _BatchAssignStep.select;
      _decisions.clear();
      _loadingDecisions.clear();
      _errorMessages.clear();
      _submitting = false;
    });
    try {
      final page = await _repository.listNeedsReview();
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _fetchProductDetails(
    ReviewDecision decision,
    int generation,
  ) async {
    final id = decision.priceLogId;
    if (id == null) return;

    final token = (_detailRequests[id] ?? 0) + 1;
    _detailRequests[id] = token;
    setState(() {
      _loadingDecisions[id] = true;
      _errorMessages.remove(id);
    });

    try {
      final product = await _productRepository.getProduct(id);
      if (!mounted || !_isCurrentDetail(id, token, generation)) return;
      setState(() {
        final index = _decisions.indexWhere((d) => d.priceLogId == id);
        if (index == -1) {
          _loadingDecisions[id] = false;
          return;
        }
        final current = _decisions[index];
        final suggestion =
            _nonEmpty(current.reviewItem?.suggestedStem) ??
            _nonEmpty(current.reviewItem?.description);
        final currentName = _nonEmpty(current.name);
        final nameIsUneditedSuggestion =
            currentName == null ||
            (suggestion != null &&
                currentName.toLowerCase() == suggestion.toLowerCase());

        _decisions[index] = current.copyWith(
          loadedProduct: product,
          // Existing products must show their persisted values. A name the
          // admin already typed is kept untouched.
          name: nameIsUneditedSuggestion
              ? (_nonEmpty(product.name) ?? current.name)
              : current.name,
          action: product.id == null
              ? InternalAssignmentAction.create
              : InternalAssignmentAction.updateExisting,
        );
        _loadingDecisions[id] = false;
      });
    } on NotFoundException {
      if (!mounted || !_isCurrentDetail(id, token, generation)) return;
      // A queue row without a linked product is the normal create path.
      setState(() {
        final index = _decisions.indexWhere((d) => d.priceLogId == id);
        if (index != -1) {
          _decisions[index] = _decisions[index].copyWith(
            action: InternalAssignmentAction.create,
          );
        }
        _loadingDecisions[id] = false;
      });
    } catch (e) {
      if (!mounted || !_isCurrentDetail(id, token, generation)) return;
      setState(() {
        _errorMessages[id] = e;
        _loadingDecisions[id] = false;
      });
    }
  }

  bool _isCurrentDetail(int id, int token, int generation) =>
      generation == _detailsGeneration && _detailRequests[id] == token;

  void _goToStep2() {
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (_decisions.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(strings.adminNoSelection)));
      return;
    }

    setState(() {
      _step = _BatchAssignStep.edit;
      _detailsGeneration++;
      _detailRequests.clear();
      _loadingDecisions.clear();
      _errorMessages.clear();
    });

    final generation = _detailsGeneration;
    for (final decision in _decisions) {
      if (decision.priceLogId != null) {
        _fetchProductDetails(decision, generation);
      }
    }
  }

  void _backToSelection() {
    if (_submitting) return;
    setState(() {
      _step = _BatchAssignStep.select;
      // Cancel any in-flight detail load; the selection is re-fetched when
      // Step 2 is entered again.
      _detailsGeneration++;
      _detailRequests.clear();
      _loadingDecisions.clear();
      _errorMessages.clear();
    });
  }

  /// Number of items that can actually be selected (have a log id).
  int get _selectableCount =>
      _items.where((item) => item.priceLogId != null).length;

  bool get _allSelected =>
      _selectableCount > 0 && _decisions.length == _selectableCount;

  bool get _hasPendingDetails =>
      _loadingDecisions.values.any((loading) => loading) ||
      _errorMessages.isNotEmpty;

  void _toggleSelection(ReviewItem item, bool selected) {
    final id = item.priceLogId;
    if (id == null) return;
    setState(() {
      if (selected) {
        final alreadySelected = _decisions.any((d) => d.priceLogId == id);
        if (!alreadySelected) {
          _decisions.add(ReviewDecision.createFromItem(item));
        }
      } else {
        _decisions.removeWhere((d) => d.priceLogId == id);
        _loadingDecisions.remove(id);
        _errorMessages.remove(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _decisions.clear();
      } else {
        _decisions
          ..clear()
          ..addAll(
            _items
                .where((item) => item.priceLogId != null)
                .map(ReviewDecision.createFromItem),
          );
      }
      _loadingDecisions.clear();
      _errorMessages.clear();
    });
  }

  Future<void> _assignAll() async {
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (_submitting) return;
    if (_decisions.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(strings.adminNoSelection)));
      return;
    }

    final decisions =
        _decisions.where((decision) => decision.priceLogId != null).toList()
          ..sort((a, b) => a.priceLogId!.compareTo(b.priceLogId!));

    if (decisions.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(strings.adminNoSelection)));
      return;
    }

    // Validate required display values before mutating anything.
    for (final decision in decisions) {
      if (_effectiveName(decision) == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.adminReviewNameRequired)),
        );
        return;
      }
      if (_effectiveUnit(decision) == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.adminReviewUnitRequired)),
        );
        return;
      }
    }

    final targetByLogId = <int, int>{};
    final updatePatches = <int, ProductPatch>{};
    final mergePairs = <({int from, int to})>{};

    // Honour explicit merge decisions first.
    final groupedDecisions = <ReviewDecision>[];
    for (final decision in decisions) {
      if (decision.action != InternalAssignmentAction.merge) {
        groupedDecisions.add(decision);
        continue;
      }
      final fromId = decision.loadedProduct?.id;
      final toId = decision.targetProductId;
      if (fromId == null || toId == null || fromId == toId) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.adminReviewMergeTargetRequired)),
        );
        return;
      }
      mergePairs.add((from: fromId, to: toId));
      targetByLogId[decision.priceLogId!] = toId;
    }

    // Classify same-name decisions. The lowest existing product ID is the
    // retained target; every other existing product is absorbed into it.
    final groups = <String, List<ReviewDecision>>{};
    for (final decision in groupedDecisions) {
      final name = _effectiveName(decision)!;
      groups.putIfAbsent(name.toLowerCase(), () => []).add(decision);
    }

    for (final group in groups.values) {
      final existing =
          group.where((decision) => decision.loadedProduct?.id != null).toList()
            ..sort(
              (a, b) => a.loadedProduct!.id!.compareTo(b.loadedProduct!.id!),
            );
      if (existing.isEmpty) continue;

      final masterId = existing.first.loadedProduct!.id!;
      final masterPatch = _updatePatchFor(existing.first);
      if (masterPatch != null) {
        updatePatches[masterId] = masterPatch;
      }

      for (final decision in existing.skip(1)) {
        final fromId = decision.loadedProduct!.id!;
        if (fromId != masterId) {
          mergePairs.add((from: fromId, to: masterId));
        }
      }

      for (final decision in group) {
        targetByLogId[decision.priceLogId!] = masterId;
      }
    }

    // Every selected price log must still be resolved, including the rows
    // whose duplicate products are being merged.
    final assignments = <Assignment>[];
    for (final decision in decisions) {
      final logId = decision.priceLogId!;
      final targetId = targetByLogId[logId];
      if (targetId != null) {
        assignments.add(
          Assignment(
            id: logId,
            action: AssignmentAction.existing,
            productId: targetId,
          ),
        );
      } else {
        assignments.add(
          Assignment(
            id: logId,
            action: AssignmentAction.create,
            name: _effectiveName(decision),
            brand: _effectiveBrand(decision),
            unit: _effectiveUnit(decision),
          ),
        );
      }
    }

    setState(() => _submitting = true);
    final failures = <Object>[];
    var mergedCount = 0;
    var updatedCount = 0;
    BatchAssignResult? batchResult;

    try {
      final orderedMerges = mergePairs.toList()
        ..sort((a, b) {
          final byFrom = a.from.compareTo(b.from);
          return byFrom != 0 ? byFrom : a.to.compareTo(b.to);
        });
      for (final pair in orderedMerges) {
        try {
          await _repository.mergeProducts(pair.from, pair.to);
          mergedCount++;
        } catch (e) {
          failures.add(e);
        }
      }

      final orderedUpdates = updatePatches.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in orderedUpdates) {
        try {
          await _repository.updateProduct(entry.key, entry.value);
          updatedCount++;
        } catch (e) {
          failures.add(e);
        }
      }

      if (assignments.isNotEmpty) {
        try {
          batchResult = await _repository.batchAssign(assignments);
        } catch (e) {
          failures.add(e);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }

    if (!mounted) return;

    if (failures.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${strings.adminReviewPartialFailure}: '
            '${localizedErrorMessage(strings, failures.first)}',
          ),
        ),
      );
      return;
    }

    final summary = <String>[
      '${strings.adminAssigned}: ${batchResult?.assigned ?? 0}',
      '${strings.adminCreated}: ${batchResult?.created ?? 0}',
      if (mergedCount > 0) '${strings.adminMerged}: $mergedCount',
      if (updatedCount > 0) '${strings.adminUpdated}: $updatedCount',
    ];
    messenger.showSnackBar(SnackBar(content: Text(summary.join(', '))));
    await _load();
  }

  String? _effectiveName(ReviewDecision decision) =>
      _nonEmpty(decision.name) ?? _nonEmpty(decision.loadedProduct?.name);

  String? _effectiveBrand(ReviewDecision decision) =>
      _nonEmpty(decision.brand) ?? _nonEmpty(decision.loadedProduct?.brand);

  String? _effectiveUnit(ReviewDecision decision) =>
      _nonEmpty(decision.unit) ?? _nonEmpty(decision.loadedProduct?.unit);

  ProductPatch? _updatePatchFor(ReviewDecision decision) {
    final product = decision.loadedProduct;
    if (product == null || product.id == null) return null;

    final name = _effectiveName(decision);
    final brand = _effectiveBrand(decision);
    final unit = _effectiveUnit(decision);
    final patch = ProductPatch(
      name: name != null && name != product.name ? name : null,
      brand: brand != null && brand != product.brand ? brand : null,
      unit: unit != null && unit != product.unit ? unit : null,
    );
    if (patch.name == null && patch.brand == null && patch.unit == null) {
      return null;
    }
    return patch;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(error: _error, onRetry: _load);
    }
    if (_items.isEmpty) return EmptyView(title: strings.emptyLabel);

    if (_step == _BatchAssignStep.edit) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                TextButton(
                  onPressed: _submitting ? null : _backToSelection,
                  child: Text(strings.goBack),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _submitting || _hasPendingDetails
                      ? null
                      : _assignAll,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(strings.adminBatchAssign),
                ),
              ],
            ),
          ),
          Expanded(child: _buildEditBlocks(context)),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: _toggleSelectAll,
                child: Text(
                  _allSelected
                      ? strings.adminClearSelection
                      : strings.adminSelectAll,
                ),
              ),
              FilledButton.icon(
                onPressed: _goToStep2,
                icon: const Icon(Icons.arrow_forward),
                label: Text(strings.adminBatchAssign),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final id = item.priceLogId;
                return CheckboxListTile(
                  value:
                      id != null &&
                      _decisions.any((decision) => decision.priceLogId == id),
                  onChanged: id == null
                      ? null
                      : (value) => _toggleSelection(item, value == true),
                  title: Text(item.description ?? item.suggestedStem ?? '-'),
                  subtitle: Text(
                    '${item.storeName ?? ''} • ${item.totalPrice ?? ''}',
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditBlocks(BuildContext context) {
    final strings = AppLocalizations.of(context);

    if (_decisions.isEmpty) {
      return Center(child: Text(strings.adminNoSelection));
    }

    return ListView.builder(
      itemCount: _decisions.length,
      itemBuilder: (context, index) {
        final decision = _decisions[index];
        final item = decision.reviewItem;
        final id = decision.priceLogId;

        if (id == null) {
          return const SizedBox.shrink();
        }

        if (_loadingDecisions[id] ?? false) {
          return Card(
            key: ValueKey(id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(strings.adminReviewLoadingDetails),
                ],
              ),
            ),
          );
        }

        final detailsError = _errorMessages[id];
        if (detailsError != null) {
          return Card(
            key: ValueKey(id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.adminReviewDetailsError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(localizedErrorMessage(strings, detailsError)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: () =>
                          _fetchProductDetails(decision, _detailsGeneration),
                      icon: const Icon(Icons.refresh),
                      label: Text(strings.retryAction),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final suggestedName =
            _nonEmpty(item?.suggestedStem) ?? _nonEmpty(item?.description);

        return Card(
          key: ValueKey(id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${strings.description}: ${item?.description ?? '-'}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                if (item != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${item.storeName ?? '-'} • ${item.totalPrice ?? '-'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                ProductEditBlock(
                  initialProduct: decision.loadedProduct,
                  suggestedName: suggestedName,
                  initialName: decision.name,
                  initialBrand: decision.brand,
                  initialUnit: decision.unit,
                  onChanged: (patch) {
                    setState(() {
                      final currentIndex = _decisions.indexWhere(
                        (d) => d.priceLogId == id,
                      );
                      if (currentIndex == -1) return;
                      _decisions[currentIndex] = _decisions[currentIndex]
                          .copyWith(
                            name: patch.name,
                            brand: patch.brand,
                            unit: patch.unit,
                          );
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
