/// Platform seam for reading an NFC-e QR code with a device camera.
///
/// Concrete camera implementations live behind this interface so the ingestion
/// flow can run unchanged on platforms without camera support (notably Web) by
/// falling back to pasting the QR payload or typing the access key. The camera
/// module is intentionally not bundled here: the app ships the fallback path
/// and can add a real scanner without touching feature code.
abstract interface class CodeScanner {
  /// Whether a camera-based scanner is usable in this build/session.
  bool get isAvailable;

  /// Scans a single QR code and returns its raw payload, or `null` when the
  /// scan is cancelled or no scanner is available.
  Future<String?> scan();
}

/// [CodeScanner] placeholder used when no camera module is wired up.
class UnavailableCodeScanner implements CodeScanner {
  const UnavailableCodeScanner();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> scan() async => null;
}
