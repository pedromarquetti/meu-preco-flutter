import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'scanner_status.dart';

/// Nullable access to `navigator.mediaDevices`, which is undefined outside a
/// secure context (plain HTTP, including a LAN address).
extension on web.Navigator {
  @JS('mediaDevices')
  external web.MediaDevices? get mediaDevicesNullable;
}

/// Reports whether this browser can open a camera at all.
///
/// The camera itself is opened exactly once, by the scanner preview. Firefox
/// for Android fails with `NotReadableError` when `getUserMedia` runs again
/// immediately after a stream is stopped (Mozilla bug 1667635), so probing the
/// device here would break the preview on those phones. The preview reports
/// start failures through its `onError` callback instead.
Future<ScannerStatus> webCameraStatus() async {
  if (web.window.navigator.mediaDevicesNullable == null) {
    return const ScannerStatus(ScannerAvailability.unavailable);
  }
  return const ScannerStatus.ready();
}
