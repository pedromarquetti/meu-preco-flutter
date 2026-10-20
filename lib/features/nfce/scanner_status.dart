/// Why a camera scan cannot proceed, or that it can.
///
/// The screen renders a distinct recovery path per value instead of a single
/// error string, so a user who denied the permission sees an actionable
/// message (and, where the OS allows it, a link to settings) rather than a
/// generic "camera unavailable".
enum ScannerAvailability {
  /// A camera is present and permission has been granted.
  ready,

  /// No camera-based scanner is bundled for this platform/session.
  unavailable,

  /// The user has not been asked yet (or was asked and the dialog is pending).
  permissionNotRequested,

  /// The user denied this request but the OS can ask again.
  permissionDenied,

  /// The user denied permanently; only the OS settings can change it.
  permissionDeniedForever,

  /// Camera hardware is missing or unusable on this device.
  noCamera,

  /// The camera failed to initialize for an unexpected reason.
  error,
}

/// The outcome of preparing the camera before showing a preview.
///
/// Preparing is split from scanning so the screen can gate the preview behind a
/// permission decision and surface the exact reason when it cannot start.
class ScannerStatus {
  const ScannerStatus(this.availability, {this.message});

  const ScannerStatus.ready() : this(ScannerAvailability.ready);

  /// Whether a live preview can be shown and scanned.
  final ScannerAvailability availability;

  /// Optional platform detail for diagnostics (never the primary copy).
  final String? message;

  bool get isReady => availability == ScannerAvailability.ready;

  /// Whether the OS still allows re-prompting for camera access.
  bool get canRetryPermission =>
      availability == ScannerAvailability.permissionDenied;

  /// Whether only the OS settings screen can restore camera access.
  bool get requiresSettings =>
      availability == ScannerAvailability.permissionDeniedForever;
}
