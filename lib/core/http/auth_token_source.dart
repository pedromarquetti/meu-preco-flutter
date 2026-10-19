/// Supplies the current access token and can rotate it when it has expired.
///
/// Implemented by the authentication session so the HTTP layer can recover from
/// a `401` without depending on feature code.
abstract interface class AuthTokenSource {
  /// The current access token, or `null` when signed out.
  String? get accessToken;

  /// Attempts a single (shared) refresh and reports whether a usable access
  /// token is available afterwards.
  Future<bool> refreshAccessToken();
}
