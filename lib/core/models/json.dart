import '../errors/app_exception.dart';
import 'decimal.dart';

/// A decoded JSON object (`jsonDecode`'s map form).
typedef JsonMap = Map<String, dynamic>;

/// Typed field readers for [JsonMap] with consistent, actionable errors.
///
/// Models decode through these helpers so a malformed payload raises a
/// [SerializationException] naming the offending field instead of failing with
/// an opaque cast error deep in feature code.
extension JsonMapReader on JsonMap {
  String stringValue(String key) {
    final value = this[key];
    if (value is String) return value;
    throw _error(key, 'String', value);
  }

  String? stringOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is String) return value;
    throw _error(key, 'String?', value);
  }

  int intValue(String key) {
    final value = this[key];
    if (value is int) return value;
    if (value is num && value == value.roundToDouble()) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw _error(key, 'int', value);
  }

  int? intOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num && value == value.roundToDouble()) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw _error(key, 'int?', value);
  }

  double doubleValue(String key) {
    final value = this[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw _error(key, 'double', value);
  }

  double? doubleOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw _error(key, 'double?', value);
  }

  bool boolValue(String key) {
    final value = this[key];
    if (value is bool) return value;
    throw _error(key, 'bool', value);
  }

  bool? boolOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is bool) return value;
    throw _error(key, 'bool?', value);
  }

  DateTime dateTimeValue(String key) {
    final value = this[key];
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw _error(key, 'ISO-8601 date-time', value);
  }

  DateTime? dateTimeOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw _error(key, 'ISO-8601 date-time?', value);
  }

  Decimal decimalValue(String key) => Decimal.fromJson(this[key]);

  Decimal? decimalOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    return Decimal.fromJson(value);
  }

  JsonMap objectValue(String key) {
    final value = this[key];
    if (value is JsonMap) return value;
    throw _error(key, 'object', value);
  }

  JsonMap? objectOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is JsonMap) return value;
    throw _error(key, 'object?', value);
  }

  List<JsonMap> objectListValue(String key) {
    final value = this[key];
    if (value is List) {
      return value
          .map((item) {
            if (item is JsonMap) return item;
            throw _error(key, 'list of objects', item);
          })
          .toList(growable: false);
    }
    throw _error(key, 'list of objects', value);
  }

  List<JsonMap> objectListOrEmpty(String key) {
    final value = this[key];
    if (value == null) return const <JsonMap>[];
    return objectListValue(key);
  }

  List<int> intListOrEmpty(String key) {
    final value = this[key];
    if (value == null) return const <int>[];
    if (value is List) {
      return value
          .map((item) {
            if (item is int) return item;
            if (item is num) return item.toInt();
            throw _error(key, 'list of ints', item);
          })
          .toList(growable: false);
    }
    throw _error(key, 'list of ints', value);
  }

  Map<String, int> intMapOrEmpty(String key) {
    final value = this[key];
    if (value == null) return const <String, int>{};
    if (value is Map) {
      return value.map((mapKey, mapValue) {
        if (mapValue is int) return MapEntry(mapKey.toString(), mapValue);
        if (mapValue is num) {
          return MapEntry(mapKey.toString(), mapValue.toInt());
        }
        throw _error(key, 'map of ints', mapValue);
      });
    }
    throw _error(key, 'map of ints', value);
  }
}

SerializationException _error(String key, String expected, Object? value) {
  return SerializationException(
    message: 'Field "$key" expected $expected, but got ${value.runtimeType}',
  );
}

/// Removes `null` values so request payloads omit absent optional fields.
JsonMap withoutNulls(JsonMap json) {
  json.removeWhere((_, value) => value == null);
  return json;
}
