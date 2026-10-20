import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/models.dart';
import '../../core/ui/empty_view.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/loading_view.dart';
import '../../l10n/generated/app_localizations.dart';
import 'product_history_controller.dart';
import 'widgets/price_chart.dart';

/// Product header, price chart, aggregates, and dated history entries.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductHistoryController? _controller;

  @override
  void initState() {
    super.initState();
    final id = int.tryParse(widget.productId);
    if (id == null) return;
    _controller = ProductHistoryController(
      repository: context.appDependencies.productsRepository,
      productId: id,
    );
    _controller!.load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final controller = _controller;
    if (controller == null) return;
    final picked = await _pickDate(context, controller.from);
    if (picked == null) return;
    await controller.load(from: picked, to: controller.to);
  }

  Future<void> _pickEnd() async {
    final controller = _controller;
    if (controller == null) return;
    final picked = await _pickDate(context, controller.to);
    if (picked == null) return;
    await controller.load(from: controller.from, to: picked);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final controller = _controller;
    if (controller == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.productDetailTitle)),
        body: ErrorView(title: strings.productNotFound),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.productDetailTitle)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _buildBody(strings, controller),
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations strings,
    ProductHistoryController controller,
  ) {
    final product = controller.product;
    if (controller.isLoading && product == null) {
      return const LoadingView();
    }
    final error = controller.error;
    if (error != null && product == null) {
      return ErrorView.fromException(
        error,
        onRetry: controller.load,
        retryLabel: strings.retryAction,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (product != null) _ProductHeader(product: product),
        const SizedBox(height: 12),
        _DateRangeCard(
          controller: controller,
          onPickStart: _pickStart,
          onPickEnd: _pickEnd,
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          _InlineError(error: error, onRetry: controller.load),
        ],
        const SizedBox(height: 12),
        PriceChart(points: controller.points),
        const SizedBox(height: 12),
        if (controller.aggregate.isNotEmpty)
          _AggregateCard(aggregate: controller.aggregate),
        const SizedBox(height: 12),
        Text(
          strings.productHistoryTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (controller.points.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: EmptyView(
              icon: Icons.timeline,
              title: strings.productHistoryEmpty,
            ),
          )
        else
          ...controller.points.reversed.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PricePointTile(point: point),
            ),
          ),
      ],
    );
  }

  static Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = DateTime(2000);
    var candidate = initial == null
        ? today
        : DateTime(initial.year, initial.month, initial.day);
    if (candidate.isAfter(today)) candidate = today;
    if (candidate.isBefore(firstDate)) candidate = firstDate;
    return showDatePicker(
      context: context,
      initialDate: candidate,
      firstDate: firstDate,
      lastDate: today,
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final ProductView product;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final meta = <String>[
      if (product.brand != null && product.brand!.isNotEmpty)
        '${strings.productBrandLabel}: ${product.brand}',
      if (product.unit != null && product.unit!.isNotEmpty)
        '${strings.productUnitLabel}: ${product.unit}',
      if (product.gtin != null && product.gtin!.isNotEmpty)
        '${strings.productGtinLabel}: ${product.gtin}',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name ?? '—', style: theme.textTheme.titleLarge),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                meta.join(' • '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateRangeCard extends StatelessWidget {
  const _DateRangeCard({
    required this.controller,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final ProductHistoryController controller;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final hasRange = controller.from != null || controller.to != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onPickStart,
              icon: const Icon(Icons.event),
              label: Text(
                '${strings.productHistoryFromLabel}: '
                '${_formatDate(controller.from)}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: onPickEnd,
              icon: const Icon(Icons.event_available),
              label: Text(
                '${strings.productHistoryToLabel}: '
                '${_formatDate(controller.to)}',
              ),
            ),
            if (hasRange)
              TextButton.icon(
                onPressed: controller.clearRange,
                icon: const Icon(Icons.clear),
                label: Text(strings.productHistoryClearRangeAction),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.error, required this.onRetry});

  final AppException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ErrorView.describeError(error) ?? strings.errorLabel,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(strings.retryAction)),
          ],
        ),
      ),
    );
  }
}

class _AggregateCard extends StatelessWidget {
  const _AggregateCard({required this.aggregate});

  final List<UnitStats> aggregate;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.productAggregateTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final (index, stats) in aggregate.indexed) ...[
              Text(
                stats.unit ?? '—',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (stats.count != null)
                    _StatCell(
                      label: strings.productAggregateCountLabel,
                      value: '${stats.count}',
                    ),
                  if (stats.min != null)
                    _StatCell(
                      label: strings.productAggregateMinLabel,
                      value: stats.min!.amount,
                    ),
                  if (stats.avg != null)
                    _StatCell(
                      label: strings.productAggregateAvgLabel,
                      value: stats.avg!.amount,
                    ),
                  if (stats.max != null)
                    _StatCell(
                      label: strings.productAggregateMaxLabel,
                      value: stats.max!.amount,
                    ),
                  if (stats.last != null)
                    _StatCell(
                      label: strings.productAggregateLastLabel,
                      value: stats.last!.amount,
                    ),
                ],
              ),
              if (index < aggregate.length - 1) const Divider(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}

class _PricePointTile extends StatelessWidget {
  const _PricePointTile({required this.point});

  final PricePointView point;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final price = point.comparablePricePerUnit ?? point.pricePerUnit;
    final unit = point.comparableUnit ?? point.unit;
    final priceText = price == null
        ? '—'
        : (unit == null || unit.isEmpty
              ? price.amount
              : '${price.amount}/$unit');
    final store = point.supermarket?.legalName;
    final qty = point.qty == null
        ? null
        : '${strings.productQtyLabel}: ${point.qty!.amount}'
              '${point.unit == null ? '' : ' ${point.unit}'}';

    return Card(
      child: ListTile(
        title: Text(priceText, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (store != null && store.isNotEmpty)
              Text('${strings.productSupermarketLabel}: $store'),
            Text(
              '${strings.productLoggedAtLabel}: '
              '${_formatDate(point.loggedAt ?? point.issuedAt)}',
            ),
            if (qty != null) Text(qty),
          ],
        ),
        trailing: point.totalPrice == null
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    strings.productTotalPriceLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    point.totalPrice!.amount,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}
