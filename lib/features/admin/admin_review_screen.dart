import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/models.dart';
import '../../core/ui/empty_view.dart';
import '../../core/ui/error_messages.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/loading_view.dart';
import '../../l10n/generated/app_localizations.dart';
import 'data/admin_repository.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

enum _BatchAssignStep {
  select,
  edit,
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  late final AdminRepository _repository =
      context.appDependencies.adminRepository;
  List<ReviewItemView> _items = const [];
  bool _loading = true;
  Object? _error;
  final Set<int> _selected = {};
  _BatchAssignStep _step = _BatchAssignStep.select;
  final List<ProductView> _selectedProducts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _selected.clear();
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
    if (_selected.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(strings.adminNoSelection)));
      return;
    }
    setState(() {
      _step = _BatchAssignStep.edit;
    });
  }

  Future<void> _batchAssign() async {
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_selected.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(strings.adminNoSelection)));
      return;
    }
    // For now, create new products for selected items
    final assignments = <Assignment>[];
    for (final item in _items) {
      if (item.priceLogId != null && _selected.contains(item.priceLogId)) {
        assignments.add(
          Assignment(
            id: item.priceLogId!,
            action: AssignmentAction.create,
            name: item.suggestedStem ?? item.description ?? '',
            unit: item.unit ?? '',
          ),
        );
      }
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
      if (mounted) {
        setState(() {
          _step = _BatchAssignStep.select;
        });
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(localizedErrorMessage(strings, e))),
      );
    }
  }

  /// Number of items that can actually be selected (have a log id).
  int get _selectableCount =>
      _items.where((item) => item.priceLogId != null).length;

  bool get _allSelected =>
      _selectableCount > 0 && _selected.length == _selectableCount;

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
                      _step = _BatchAssignStep.select;
                    });
                  },
                  child: Text(strings.goBack),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _batchAssign,
                  icon: const Icon(Icons.check),
                  label: Text(strings.adminBatchAssign),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Step 2: Edit & Assign - To be implemented'),
            ),
          ),
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
                      _selected.clear();
                    } else {
                      for (final item in _items) {
                        if (item.priceLogId != null) {
                          _selected.add(item.priceLogId!);
                        }
                      }
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
                  value: id != null && _selected.contains(id),
                  onChanged: id == null
                      ? null
                      : (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(id);
                            } else {
                              _selected.remove(id);
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
}
