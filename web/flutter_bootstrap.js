{{flutter_js}}
{{flutter_build_config}}

// The Flutter service worker is deprecated and can serve stale bundles after a
// rebuild. This app does not need offline caching, so load without registering
// a service worker. This also keeps local rebuilds and GitHub Pages deploys
// deterministic.
_flutter.loader.load();
