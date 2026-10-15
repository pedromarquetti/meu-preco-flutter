/// Compile-time defaults for the Meu Preço API connection.
///
/// Values are supplied through `--dart-define` so release builds for Android
/// and Web can target a configured API without source changes:
///
/// ```sh
/// flutter build apk \
///   --dart-define=API_ORIGIN=https://api.meupreco.example \
///   --dart-define=API_TIMEOUT_SECONDS=30
/// ```
class BuildConfig {
  const BuildConfig._();

  /// Default API origin baked into the build.
  static const String apiOrigin = String.fromEnvironment(
    'API_ORIGIN',
    defaultValue: 'http://localhost:8080',
  );

  /// Default request timeout baked into the build.
  static const Duration requestTimeout = Duration(
    seconds: int.fromEnvironment('API_TIMEOUT_SECONDS', defaultValue: 20),
  );
}
