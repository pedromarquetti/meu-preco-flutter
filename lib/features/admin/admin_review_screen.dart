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
import 'widgets/review_queue_item_card.dart';
import 'widgets/review_target_selector.dart';

/// The step of batch assignment flow (selection → edit).
enum _BatchAssignStep { select, edit }

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

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
            alreadyProcessed ? strings.adminReviewAlreadyProcessed : '$error',
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

    // Filter to decisions with valid log IDs and sort for deterministic processing.
    final decisions = _decisions.where((d) => d.priceLogId != null).toList()
      ..sort((a, b) => a.priceLogId!.compareTo(b.priceLogId!));

    if (decisions.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(strings.adminNoSelection)));
      return;
    }

    // Validate every decision before sending anything. A proposed target is an
    // existing assignment too: it must carry the proposal product id.
    final validationFailures = <int, String>{};
    for (final decision in decisions) {
      final id = decision.priceLogId!;
      if (decision.isCreate) {
        if (decision.name?.trim().isEmpty != false) {
          validationFailures[id] = strings.adminReviewNameRequired;
        } else if (decision.unit?.trim().isEmpty != false) {
          validationFailures[id] = strings.adminReviewUnitRequired;
        }
      } else if (decision.targetProductId == null ||
          decision.targetProductId! <= 0) {
        validationFailures[id] = strings.adminReviewMergeTargetRequired;
      }
    }

    if (validationFailures.isNotEmpty) {
      // Show all per-row errors at once so the admin can fix them in context.
      final errorLines = validationFailures.entries
          .map((e) => Text(e.value))
          .toList();
      messenger.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const SizedBox(height: 4), ...errorLines],
          ),
          duration: const Duration(seconds: 10),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    BatchAssignResult? batchResult;
    Object? failure;

    try {
      // Build one assignment per decision. This deliberately performs no
      // product update, grouping, or merge.
      final assignments = <Assignment>[
        for (final decision in decisions)
          if (decision.isCreate)
            Assignment(
              id: decision.priceLogId!,
              action: AssignmentAction.create,
              name: decision.name!.trim(),
              brand: _trimOrNull(decision.brand),
              unit: decision.unit!.trim(),
            )
          else
            Assignment(
              id: decision.priceLogId!,
              action: AssignmentAction.existing,
              productId: decision.targetProductId!,
            ),
      ];
      batchResult = await _repository.batchAssign(assignments);
    } catch (e) {
      failure = e;
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }

    if (!mounted) return;

    // Keep the draft for ordinary failures so the admin can correct or retry
    // without selecting and editing every row again.
    if (failure != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${strings.adminAssignmentFailureRetained} '
            '${localizedErrorMessage(strings, failure)}',
          ),
        ),
      );
      final code = failure is AppException ? failure.code : null;
      final errorCode = ApiErrorCode.fromWire(code);
      if (errorCode == ApiErrorCode.alreadyProcessed ||
          errorCode == ApiErrorCode.notFound) {
        await _load();
      }
      return;
    }

    final summary = <String>[
      '${strings.adminAssigned}: ${batchResult?.assigned ?? 0}',
      '${strings.adminCreated}: ${batchResult?.created ?? 0}',
      strings.adminProposalPublishHint,
    ];
    messenger.showSnackBar(SnackBar(content: Text(summary.join('. '))));

    // Reload the queue to reflect new assignments.
    await _load();
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: _submitting ? null : _backToSelection,
                      child: Text(strings.goBack),
                    ),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _assignAll,
                      icon: _submitting
                          ? const CircularProgressIndicator(strokeWidth: 2)
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

                // Gating: approve/reject only for non-rejected proposals with a log ID.
                final canReview = item.isProposal && id != null;
                final canContinue = canReview && !item.isRejected;

                return ReviewQueueItemCard(
                  key: ValueKey('review-${item.priceLogId}-${item.line}'),
                  item: item,
                  selected: selected,
                  onSelectionChanged: (value) => _toggleSelection(item, value),
                  proposer: item.resolvedBy == null
                      ? null
                      : _proposers[item.resolvedBy],
                  reviewing: reviewing,
                  onApprove: canContinue
                      ? () =>
                            _reviewProposal(item, PriceLogReviewAction.approve)
                      : null,
                  onReject: canContinue
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

        if (id == null || item == null) {
          return const SizedBox.shrink();
        }

        final proposer = item.resolvedBy == null
            ? null
            : _proposers[item.resolvedBy];

        return Card(
          key: ValueKey('decision-$id'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${strings.description}: ${item.description ?? '-'}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
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
                const SizedBox(height: 12),
                ReviewTargetSelector(
                  item: item,
                  decision: decision,
                  searchSource: _repository,
                  onTargetChanged: (updated) {
                    setState(() {
                      final currentIndex = _decisions.indexWhere(
                        (d) => d.priceLogId == id,
                      );
                      if (currentIndex == -1) return;
                      _decisions[currentIndex] = updated;
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
