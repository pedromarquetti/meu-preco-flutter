import 'scanner_status.dart';

/// Non-web platforms request the camera through `permission_handler` in
/// `CameraCodeScanner`, so this fallback is never reached there.
Future<ScannerStatus> webCameraStatus() async =>
    const ScannerStatus(ScannerAvailability.unavailable);
