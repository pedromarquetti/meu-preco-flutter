import 'url_strategy_stub.dart'
    if (dart.library.js_interop) 'url_strategy_web.dart'
    as platform;

/// Selects the browser URL strategy used by the Web build.
///
/// GitHub Pages is static hosting without SPA rewrites. Hash-based routes keep
/// every request on the repository base path, so refreshes and direct links
/// work without a `404.html` fallback that would also answer missing asset
/// requests with the application shell.
void configureWebUrlStrategy() => platform.configureWebUrlStrategy();
