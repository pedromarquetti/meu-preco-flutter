import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/errors/api_error_code.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/models.dart';
import '../../core/ui/empty_view.dart';
import '../../core/ui/error_messages.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/loading_view.dart';
import '../../l10n/generated/app_localizations.dart';
import 'data/admin_repository.dart';
import 'review_decision.dart';
import 'widgets/product_edit_block.dart';
import 'widgets/review_queue_item_card.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

enum _BatchAssignStep { select, edit }

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  late final AdminRepository _repository =
      context.appDependencies.adminRepository;
  List<ReviewItem> _items = [];
  bool _loading = true;
  Object? _error;
  _BatchAssignStep _step = _BatchAssignStep.select;
  final List<ReviewDecision> _decisions = [];
  final Map<int, bool> _reviewingProposals = {}; // priceLogId -> isLoading

  /// Proposer accounts resolved from `resolved_by`, keyed by user id.
  final Map<int, UserView> _proposers = {};
  final Set<int> _proposersLoading = {};

  /// Guards proposer lookups so a stale response cannot write into a newer
  /// queue after a refresh.
  int _proposerGeneration = 0;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _proposerGeneration++;
    final generation = _proposerGeneration;
    setState(() {
      _loading = true;
      _error = null;
      _step = _BatchAssignStep.select;
      _decisions.clear();
      _reviewingProposals.clear();
      _proposers.clear();
      _proposersLoading.clear();
      _submitting = false;
    });
    try {
      final page = await _repository.listNeedsReview();
      if (!mounted || generation != _proposerGeneration) return;
      setState(() {
        _items = page.items;
        _loading = false;
      });
      _resolveProposers();
    } catch (e) {
      if (!mounted || generation != _proposerGeneration) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// Resolves every distinct proposer in the background. Attribution is
  /// informational, so the queue renders immediately and falls back to the
  /// raw user id when a lookup fails.
  void _resolveProposers() {
    final generation = _proposerGeneration;
    final ids =
        <int>{
          for (final item in _items)
            if (item.isProposal && item.resolvedBy != null) item.resolvedBy!,
        }..removeWhere(
          (id) => _proposers.containsKey(id) || _proposersLoading.contains(id),
        );

    if (ids.isEmpty) return;

    setState(() => _proposersLoading.addAll(ids));
    for (final id in ids) {
      unawaited(_resolveProposer(id, generation));
    }
  }

  Future<void> _resolveProposer(int id, int generation) async {
    try {
      final user = await _repository.findUser(id);
      if (!mounted || generation != _proposerGeneration) return;
      setState(() {
        _proposersLoading.remove(id);
        if (user != null) _proposers[id] = user;
      });
    } catch (_) {
      // A failed lookup must not break the queue; the card shows `#id`.
      if (!mounted || generation != _proposerGeneration) return;
      setState(() => _proposersLoading.remove(id));
    }
  }

  Future<void> _reviewProposal(
    ReviewItem item,
    PriceLogReviewAction action,
  ) async {
    final id = item.priceLogId;
    if (id == null || _reviewingProposals[id] == true) return;
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _reviewingProposals[id] = true);
    try {
      await _repository.reviewPriceLog(priceLogId: id, action: action);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(strings.adminReviewDecisionSuccess)),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      final alreadyProcessed =
          error is ConflictException &&
          ApiErrorCode.fromWire(error.code) == ApiErrorCode.alreadyProcessed;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            alreadyProcessed
                ? strings.adminReviewAlreadyProcessed
                : localizedErrorMessage(strings, error),
          ),
        ),
      );
      if (alreadyProcessed) {
        // Another admin won the race: the queue is stale, so reload it.
        await _load();
      } else {
        setState(() => _reviewingProposals[id] = false);
      }
    }
  }

  void _goToStep2() {
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (_decisions.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(strings.adminNoSelection)));
      return;
    }

    setState(() => _step = _BatchAssignStep.edit);
  }

  void _backToSelection() {
    if (_submitting) return;
    setState(() => _step = _BatchAssignStep.select);
  }

  /// Number of items that can actually be selected (have a log id).
  int get _selectableCount =>
      _items.where((item) => item.priceLogId != null).length;

  bool get _allSelected =>
      _selectableCount > 0 && _decisions.length == _selectableCount;

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

    // Validate required target/display values before mutating anything.
    for (final decision in decisions) {
      if (decision.isCreate) {
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
      } else if (decision.targetProductId == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.adminReviewMergeTargetRequired)),
        );
        return;
      }
    }

    final targetByLogId = <int, int>{};
    final updatePatches = <int, ProductPatch>{};
    final mergePairs = <({int from, int to})>{};

    // Same-name non-create decisions still converge on the lowest product id.
    // Create decisions stay independent: selecting one must never patch or
    // merge an existing product as a side effect.
    final groups = <String, List<ReviewDecision>>{};
    for (final decision in decisions) {
      if (decision.isCreate) continue;
      final name = _effectiveName(decision);
      if (name == null) continue;
      groups.putIfAbsent(name.toLowerCase(), () => []).add(decision);
    }

    for (final group in groups.values) {
      final existing =
          group.where((decision) => decision.targetProductId != null).toList()
            ..sort((a, b) => a.targetProductId!.compareTo(b.targetProductId!));
      if (existing.isEmpty) continue;

      final masterId = existing.first.targetProductId!;
      final masterPatch = _updatePatchFor(existing.first);
      if (masterPatch != null) {
        updatePatches[masterId] = masterPatch;
      }

      for (final decision in existing.skip(1)) {
        final fromId = decision.targetProductId!;
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
      if (decision.isCreate) {
        assignments.add(
          Assignment(
            id: logId,
            action: AssignmentAction.create,
            name: _effectiveName(decision),
            brand: _effectiveBrand(decision),
            unit: _effectiveUnit(decision),
          ),
        );
        continue;
      }

      final targetId = targetByLogId[logId] ?? decision.targetProductId;
      assignments.add(
        Assignment(
          id: logId,
          action: AssignmentAction.existing,
          productId: targetId,
        ),
      );
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
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${summary.join(', ')}. ${strings.adminProposalPublishHint}',
        ),
      ),
    );
    await _load();
  }

  String? _effectiveName(ReviewDecision decision) =>
      _nonEmpty(decision.name) ?? _nonEmpty(decision.targetProduct?.name);

  String? _effectiveBrand(ReviewDecision decision) =>
      _nonEmpty(decision.brand) ?? _nonEmpty(decision.targetProduct?.brand);

  String? _effectiveUnit(ReviewDecision decision) =>
      _nonEmpty(decision.unit) ?? _nonEmpty(decision.targetProduct?.unit);

  ProductPatch? _updatePatchFor(ReviewDecision decision) {
    final product = decision.targetProduct;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: _submitting ? null : _backToSelection,
                      child: Text(strings.goBack),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _assignAll,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    strings.adminSelectedCount(_decisions.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    strings.adminProposalPublishHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                final selected =
                    id != null &&
                    _decisions.any((decision) => decision.priceLogId == id);
                final reviewing = id != null && _reviewingProposals[id] == true;
                final canReview = item.isProposal && id != null;
                final proposer = item.resolvedBy == null
                    ? null
                    : _proposers[item.resolvedBy];

                return ReviewQueueItemCard(
                  key: ValueKey('review-${item.priceLogId}-${item.line}'),
                  item: item,
                  selected: selected,
                  onSelectionChanged: (value) => _toggleSelection(item, value),
                  proposer: proposer,
                  reviewing: reviewing,
                  onApprove: canReview
                      ? () =>
                            _reviewProposal(item, PriceLogReviewAction.approve)
                      : null,
                  onReject: canReview && !item.isRejected
                      ? () => _reviewProposal(item, PriceLogReviewAction.reject)
                      : null,
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

        final suggestedName =
            _nonEmpty(item?.suggestedStem) ?? _nonEmpty(item?.description);
        final proposer = item?.resolvedBy == null
            ? null
            : _proposers[item!.resolvedBy];

        return Card(
          key: ValueKey('decision-$id'),
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
                  if (item.isProposal && item.resolvedBy != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      proposalAuthorLabel(strings, item, proposer),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                ProductEditBlock(
                  initialProduct: decision.targetProduct,
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
