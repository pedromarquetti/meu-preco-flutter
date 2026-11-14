import 'package:flutter_web_plugins/url_strategy.dart';

/// Keeps Web routes in the URL fragment (`/repo/#/products/42`).
///
/// The fragment never reaches the server, so project Pages hosting can serve
/// the application shell from the repository root and still support deep links
/// and refreshes.
void configureWebUrlStrategy() {
  setUrlStrategy(const HashUrlStrategy());
}
