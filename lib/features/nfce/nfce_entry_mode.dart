/// How the user chose to provide the receipt identifier on entry.
enum NfceEntryMode {
  /// Read the QR code (camera, or pasting its payload when unavailable).
  scan,

  /// Type the 44-digit access key.
  key;

  /// Parses the `mode` query parameter, defaulting to [NfceEntryMode.scan].
  static NfceEntryMode fromQuery(String? value) =>
      value == NfceEntryMode.key.name ? NfceEntryMode.key : NfceEntryMode.scan;
}
