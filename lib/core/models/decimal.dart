import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';

/// A decimal-safe number backed by its exact textual representation.
///
/// The Meu Preço API sends money (and quantities) as decimal strings precisely
/// so clients never introduce floating-point error. [Decimal] keeps the raw
/// value and compares/serializes it without ever converting to `double`.
///
/// Use the [Money] alias for monetary values to make intent explicit.
@immutable
class Decimal implements Comparable<Decimal> {
  const Decimal(this.amount);

  /// Parses [input], throwing [SerializationException] when it is not a plain
  /// decimal literal.
  factory Decimal.parse(String input) {
    final trimmed = input.trim();
    if (!_pattern.hasMatch(trimmed)) {
      throw SerializationException(message: 'Invalid decimal value: "$input"');
    }
    return Decimal(trimmed);
  }

  /// Decodes a value from JSON. Accepts the API's decimal strings, and also
  /// `num` for lenient payload handling.
  factory Decimal.fromJson(Object? value) {
    if (value is String) return Decimal.parse(value);
    if (value is num) return Decimal.parse(value.toString());
    throw SerializationException(
      message: 'Expected a decimal string, got ${value.runtimeType}',
    );
  }

  static final RegExp _pattern = RegExp(r'^[+-]?\d+(\.\d+)?$');

  /// The exact textual value as received (e.g. `"12.50"`).
  final String amount;

  bool get isNegative => _scaled.isNegative;

  bool get isZero => _scaled.units == BigInt.zero;

  String toJson() => amount;

  /// Compares two values numerically without floating-point conversion.
  @override
  int compareTo(Decimal other) => _scaled.compareTo(other._scaled);

  /// Canonical form used for equality/hashing: no sign, no leading zeros and
  /// no trailing fractional zeros (e.g. `"010.50"` -> `"10.5"`).
  String get normalized {
    var digits = amount;
    var negative = false;
    if (digits.startsWith('-')) {
      negative = true;
      digits = digits.substring(1);
    } else if (digits.startsWith('+')) {
      digits = digits.substring(1);
    }

    final dot = digits.indexOf('.');
    var integerPart = dot == -1 ? digits : digits.substring(0, dot);
    var fractionPart = dot == -1 ? '' : digits.substring(dot + 1);

    integerPart = integerPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (integerPart.isEmpty) integerPart = '0';
    fractionPart = fractionPart.replaceFirst(RegExp(r'0+$'), '');

    final magnitude = fractionPart.isEmpty
        ? integerPart
        : '$integerPart.$fractionPart';
    return negative && magnitude != '0' ? '-$magnitude' : magnitude;
  }

  _Scaled get _scaled => _Scaled.parse(amount);

  @override
  bool operator ==(Object other) =>
      other is Decimal && normalized == other.normalized;

  @override
  int get hashCode => normalized.hashCode;

  @override
  String toString() => amount;
}

/// A monetary amount. Alias for [Decimal]; money is decimal-safe by design.
typedef Money = Decimal;

/// Sign + magnitude + scale representation used for exact comparison.
class _Scaled {
  const _Scaled(this.units, this.scale);

  factory _Scaled.parse(String input) {
    var digits = input;
    var sign = BigInt.one;
    if (digits.startsWith('-')) {
      sign = BigInt.from(-1);
      digits = digits.substring(1);
    } else if (digits.startsWith('+')) {
      digits = digits.substring(1);
    }

    final dot = digits.indexOf('.');
    final scale = dot == -1 ? 0 : digits.length - dot - 1;
    final raw = dot == -1
        ? digits
        : digits.substring(0, dot) + digits.substring(dot + 1);
    return _Scaled(sign * BigInt.parse(raw), scale);
  }

  final BigInt units;
  final int scale;

  bool get isNegative => units.isNegative;

  int compareTo(_Scaled other) {
    final widest = scale > other.scale ? scale : other.scale;
    final left = units * _tenPow(widest - scale);
    final right = other.units * _tenPow(widest - other.scale);
    return left.compareTo(right);
  }

  static BigInt _tenPow(int exponent) =>
      exponent == 0 ? BigInt.one : BigInt.from(10).pow(exponent);
}
