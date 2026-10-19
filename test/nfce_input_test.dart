import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/features/nfce/nfce_entry_mode.dart';
import 'package:meu_preco_frontend/features/nfce/nfce_input.dart';

import 'fakes.dart';

void main() {
  group('tryParse', () {
    test('recognizes a 44-digit access key', () {
      final input = NfceInput.tryParse(kSampleAccessKey);

      expect(input, isNotNull);
      expect(input!.kind, NfceInputKind.accessKey);
      expect(input.toDraftRequest().accessKey, kSampleAccessKey);
      expect(input.toDraftRequest().qrPayload, isNull);
    });

    test('trims surrounding whitespace and grouping separators', () {
      final input = NfceInput.tryParse('  $kSampleAccessKey  ');

      expect(input!.kind, NfceInputKind.accessKey);
      expect(input.value, kSampleAccessKey);
    });

    test('treats anything else as a QR payload', () {
      final input = NfceInput.tryParse('https://sefaz.example/qr?p=abc');

      expect(input, isNotNull);
      expect(input!.kind, NfceInputKind.qrPayload);
      expect(
        input.toDraftRequest().qrPayload,
        'https://sefaz.example/qr?p=abc',
      );
      expect(input.toDraftRequest().accessKey, isNull);
    });

    test('rejects an empty or blank value', () {
      expect(NfceInput.tryParse(''), isNull);
      expect(NfceInput.tryParse('   '), isNull);
    });

    test('rejects a key with the wrong number of digits', () {
      final input = NfceInput.tryParse('1234567890');

      expect(input!.kind, NfceInputKind.qrPayload);
      expect(NfceInput.isAccessKey('1234567890'), isFalse);
    });

    test('does not treat non-digit 44-character values as keys', () {
      final input = NfceInput.tryParse('X' * 44);

      expect(input!.kind, NfceInputKind.qrPayload);
    });
  });

  group('NfceEntryMode.fromQuery', () {
    test('maps the key mode', () {
      expect(NfceEntryMode.fromQuery('key'), NfceEntryMode.key);
    });

    test('defaults to scan for unknown or missing values', () {
      expect(NfceEntryMode.fromQuery('scan'), NfceEntryMode.scan);
      expect(NfceEntryMode.fromQuery(null), NfceEntryMode.scan);
      expect(NfceEntryMode.fromQuery('nonsense'), NfceEntryMode.scan);
    });
  });
}
