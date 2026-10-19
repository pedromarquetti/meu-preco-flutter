import '../../core/models/models.dart';

/// A captured NFC-e identifier, normalized for the draft request.
///
/// A bare 44-digit string is an access key; every other non-empty value is
/// treated as a QR payload so the backend can extract the key from the scanned
/// URL. Both kinds feed the same `/nfce/new` draft, so a camera scan, a pasted
/// payload, and a typed key all follow one flow.
class NfceInput {
  const NfceInput({required this.kind, required this.value});

  /// Classifies [raw], or returns `null` when it is blank.
  static NfceInput? tryParse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return NfceInput(
      kind: isAccessKey(value)
          ? NfceInputKind.accessKey
          : NfceInputKind.qrPayload,
      value: value,
    );
  }

  static final RegExp _accessKeyPattern = RegExp(r'^\d{44}$');

  /// Whether [raw] is exactly 44 digits (the NFC-e access-key shape).
  static bool isAccessKey(String raw) => _accessKeyPattern.hasMatch(raw.trim());

  final NfceInputKind kind;
  final String value;

  /// The `POST /nfce/new` body for this input.
  DraftRequest toDraftRequest() => switch (kind) {
    NfceInputKind.accessKey => DraftRequest(accessKey: value),
    NfceInputKind.qrPayload => DraftRequest(qrPayload: value),
  };
}

/// Discriminator for [NfceInput].
enum NfceInputKind { accessKey, qrPayload }
