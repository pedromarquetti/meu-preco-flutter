/// Compile-time defaults for the Meu Preço API connection.
///
/// The API origin is intentionally not baked into the build. Every fresh
/// installation asks the user for a server and reuses the saved origin on later
/// launches. Only the request timeout can be tuned at build time:
///
/// ```sh
/// flutter build apk --dart-define=API_TIMEOUT_SECONDS=30
/// ```
class BuildConfig {
  const BuildConfig._();

  /// Default request timeout baked into the build.
  static const Duration requestTimeout = Duration(
    seconds: int.fromEnvironment('API_TIMEOUT_SECONDS', defaultValue: 20),
  );
}
