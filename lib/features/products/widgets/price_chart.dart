import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Renders a product's price curve.
///
/// The series is ordered and measured with [Decimal] so equal-looking prices
/// with different precision stay exact; values are converted to `double` only
/// when mapping them onto pixel geometry. Every label keeps the original
/// decimal string.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.points});

  /// Chronological price points (already sorted).
  final List<PricePointView> points;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final samples = <(int, Decimal, PricePointView)>[
      for (final (index, point) in points.indexed)
        if ((point.comparablePricePerUnit ??
                point.pricePerUnit ??
                point.unitPrice) !=
            null)
          (
            index,
            point.comparablePricePerUnit ??
                point.pricePerUnit ??
                point.unitPrice!,
            point,
          ),
    ];

    if (samples.length < 2) {
      return EmptyChartPlaceholder(message: strings.priceChartTooShort);
    }

    var min = samples.first.$2;
    var max = samples.first.$2;
    for (final sample in samples) {
      if (sample.$2.compareTo(min) < 0) min = sample.$2;
      if (sample.$2.compareTo(max) > 0) max = sample.$2;
    }

    final unit = samples.first.$3.comparableUnit ?? samples.first.$3.unit ?? '';
    final semanticsLabel = strings.priceChartSemantics(
      min.amount,
      max.amount,
      unit,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.productPriceGraphLabel,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Semantics(
              label: semanticsLabel,
              image: true,
              child: AspectRatio(
                aspectRatio: 2.2,
                child: CustomPaint(
                  painter: _PriceLinePainter(
                    samples: samples,
                    min: min,
                    max: max,
                    lineColor: theme.colorScheme.primary,
                    gridColor: theme.colorScheme.outlineVariant,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _RangeCaption(min: min, max: max, unit: unit),
          ],
        ),
      ),
    );
  }
}

/// Shown when a product has too few priced points to draw a curve.
class EmptyChartPlaceholder extends StatelessWidget {
  const EmptyChartPlaceholder({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.productPriceGraphLabel,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Text(
              message ?? strings.priceChartTooShort,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _RangeCaption extends StatelessWidget {
  const _RangeCaption({
    required this.min,
    required this.max,
    required this.unit,
  });

  final Decimal min;
  final Decimal max;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget cell(String label, String value) => Expanded(
      child: Column(
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
      ),
    );

    final suffix = unit.isEmpty ? '' : '/$unit';
    return Row(
      children: [
        cell(strings.priceChartMinLabel, '${min.amount}$suffix'),
        const SizedBox(width: 16),
        cell(strings.priceChartMaxLabel, '${max.amount}$suffix'),
      ],
    );
  }
}

class _PriceLinePainter extends CustomPainter {
  const _PriceLinePainter({
    required this.samples,
    required this.min,
    required this.max,
    required this.lineColor,
    required this.gridColor,
  });

  final List<(int, Decimal, PricePointView)> samples;
  final Decimal min;
  final Decimal max;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final fraction in const <double>[0, 0.5, 1]) {
      final y = size.height * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), grid);

    if (samples.isEmpty || size.isEmpty) return;

    final low = double.parse(min.amount);
    var high = double.parse(max.amount);
    if (high <= low) high = low + 1;

    final firstX = samples.first.$1.toDouble();
    final lastX = samples.last.$1.toDouble();
    final spanX = (lastX - firstX).abs() < 0.001 ? 1.0 : lastX - firstX;

    Offset toOffset((int, Decimal, PricePointView) sample) {
      final x = ((sample.$1 - firstX) / spanX) * size.width;
      final ratio = (double.parse(sample.$2.amount) - low) / (high - low);
      final y = size.height - ratio * size.height;
      return Offset(x, y.clamp(0.0, size.height));
    }

    final path = Path()
      ..moveTo(toOffset(samples.first).dx, toOffset(samples.first).dy);
    for (final sample in samples.skip(1)) {
      final offset = toOffset(sample);
      path.lineTo(offset.dx, offset.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2
        ..color = lineColor,
    );

    final dot = Paint()..color = lineColor;
    for (final sample in samples) {
      canvas.drawCircle(toOffset(sample), 3, dot);
    }
  }

  @override
  bool shouldRepaint(_PriceLinePainter oldDelegate) =>
      oldDelegate.samples != samples ||
      oldDelegate.min != min ||
      oldDelegate.max != max ||
      oldDelegate.lineColor != lineColor;
}
