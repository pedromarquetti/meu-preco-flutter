import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/models.dart';
import '../../core/ui/empty_view.dart';
import '../../core/ui/error_messages.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/loading_view.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../features/admin/widgets/product_edit_block.dart';
import 'data/admin_repository.dart';

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
  final List<ReviewItem> _selectedReviewItems = <ReviewItem>[];
  final Map<int, ProductPatch> _productPatches = <int, ProductPatch>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _step = _BatchAssignStep.select;
      _selectedReviewItems.clear();
      _productPatches.clear();
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

  void _goToStep2() {
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (_selectedReviewItems.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(strings.adminNoSelection)));
      return;
    }

    setState(() {
      _step = _BatchAssignStep.edit;
    });
  }

  /// Number of items that can actually be selected (have a log id).
  int get _selectableCount =>
      _items.where((item) => item.priceLogId != null).length;

  bool get _allSelected =>
      _selectableCount > 0 && _selectedReviewItems.length == _selectableCount;

  Future<void> _assignAll() async {
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final assignments = <Assignment>[];
    for (final item in _items) {
      if (item.priceLogId != null && _selectedReviewItems.contains(item)) {
        final patch = _productPatches[item.priceLogId!];
        assignments.add(
          Assignment(
            id: item.priceLogId!,
            action: AssignmentAction.create,
            name: patch?.name ?? item.suggestedStem ?? item.description ?? '',
            unit: patch?.unit ?? item.unit ?? '',
            brand: patch?.brand,
          ),
        );
      }
    }

    if (assignments.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(strings.adminNoSelection)));
      return;
    }

    try {
      final result = await _repository.batchAssign(assignments);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${strings.adminAssigned}: ${result.assigned ?? 0}, ${strings.adminCreated}: ${result.created ?? 0}',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(localizedErrorMessage(strings, e))),
      );
    }
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
                  onPressed: () {
                    setState(() {
                      _selectedReviewItems.clear();
                      _productPatches.clear();
                      _step = _BatchAssignStep.select;
                    });
                  },
                  child: Text(strings.goBack),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _assignAll,
                  icon: const Icon(Icons.check),
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
                onPressed: () {
                  setState(() {
                    if (_allSelected) {
                      _selectedReviewItems.clear();
                    } else {
                      _selectedReviewItems
                        ..clear()
                        ..addAll(
                          _items.where((item) => item.priceLogId != null),
                        );
                    }
                  });
                },
                child: Text(
                  _allSelected
                      ? strings.adminClearSelection
                      : strings.adminSelectAll,
                ),
              ),
              FilledButton.icon(
                onPressed: _goToStep2,
                icon: const Icon(Icons.arrow_forward),
                // TODO: conditionally style this button? Maybe make this button dim if no items are selected
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
                  value: id != null && _selectedReviewItems.contains(item),
                  onChanged: id == null
                      ? null
                      : (v) {
                          setState(() {
                            if (v == true) {
                              _selectedReviewItems.add(item);
                            } else {
                              _selectedReviewItems.remove(item);
                            }
                          });
                        },
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

    if (_selectedReviewItems.isEmpty) {
      return Center(child: Text(strings.loadingLabel));
    }

    return ListView.builder(
      itemCount: _selectedReviewItems.length,
      itemBuilder: (context, index) {
        final item = _selectedReviewItems[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${strings.batchAssignSuggestedName}: ${item.suggestedStem ?? item.description ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${strings.description}: ${item.description}',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                ProductEditBlock(
                  initialProduct: item,
                  suggestedName: item.suggestedStem ?? item.description ?? '',
                  onSave: (patch) {
                    if (patch != null) {
                      _productPatches[item.priceLogId!] = patch;
                    }
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
