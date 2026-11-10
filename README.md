# Meu Preço

<!--toc:start-->

- [Meu Preço](#meu-preço)
  - [Scope and status](#scope-and-status)
  - [UI Flow](#ui-flow)
  - [API docs](#api-docs)
  - [Configuration](#configuration)
  - [Visual system and icons](#visual-system-and-icons)
  - [Local validation](#local-validation)
    - [Start a local API](#start-a-local-api)
    - [Quality gates](#quality-gates)
    - [Builds](#builds)
    - [Android signing](#android-signing)
    - [Release assumptions](#release-assumptions)
    - [Web limitations](#web-limitations)
  - [GitHub Actions and releases](#github-actions-and-releases)
    - [Release workflow](#release-workflow)
  - [Architecture](#architecture)
  - [Documentation](#documentation)

<!--toc:end-->

A Flutter front end for the Meu Preço API, supporting Android and Web first,
with iOS build validation kept available.

## Scope and status

- [x] Login, registration, secure session restoration, logout, and token
      refresh.
- [x] Runtime server selection and persistent API configuration.
- [x] NFC-e QR/manual input, camera fallback, preview, captcha, line resolution,
      dry-run, commit, and cleanup.
- [x] Product search, product details, exact decimal price history, and graph.
- [x] Admin users, role management, review queue, and batch assignment.
- [x] Light/Dark/System theme selection with persisted preference.
- [x] Centralized Material 3 visual system seeded from the brand icon, with
      Android/Web/iOS/macOS launcher icons generated from
      `assets/main_icon.png`.
- [x] Portuguese localization, responsive layouts, and accessibility-oriented
      loading/error/empty states.
- [x] Code-quality, accessibility, localization, and release audit.
- [ ] Consistent screen/component animations with reduced-motion support.
- [x] Local signed Android release APK builds with reproducible, secret-free
      signing configuration.
- [ ] Google Playstore publish? - This is a maybe step. will check this later
- [ ] GitHub Actions CI, signed artifact builds, Web artifacts, and optional iOS
      validation.

## UI Flow

```text
<On initial app boot, the user should be presented with a 'select server' screen>
user log-in
|    |
|   ▼
|   Home Page
|      └─► Scan new NFCe ─► User presented with either Scan QR with camera or paste the NFCe key
|     └─► Search for product ─► User can search for product
|                                └─► Product page ─► graph of historical prices + list of prices
▼
Admin Page
    └─► Register user screen
    └─► Resolve `uid_uncertain`
```

## API docs

This front end uses [Meu Preço](https://github.com/pedromarquetti/meu-preco) as
a backend. The Swagger docs can be also found
[here](https://pedromarquetti.github.io/meu-preco)

## Configuration

The app talks to a single
[Meu Preço API](https://github.com/pedromarquetti/meu-preco) origin. On first
boot it always asks for a server on the **select server** screen and only moves
on to login after `GET /healthz` succeeds. The origin can be changed later on
the Settings page without rebuilding.

For deployments, bake a default origin (and optional request timeout) into the
build with `--dart-define`:

```sh
flutter build apk \
  --dart-define=API_ORIGIN=https://api.meupreco.example \
  --dart-define=API_TIMEOUT_SECONDS=30
```

- `API_ORIGIN` — default API origin (defaults to `http://localhost:8080`).
- `API_TIMEOUT_SECONDS` — request timeout (defaults to `20`).

The versioned prefix `/api/v1` is applied automatically; a pasted origin that
already contains it is normalized so it is never duplicated.

## Visual system and icons

The Material 3 color schemes, typography, shape, spacing, elevation, input,
button, and focus styles are centralized in `lib/core/theme/app_theme.dart`.
Feature widgets use `Theme.of(context)` roles and never introduce raw brand
colors of their own. The palette is derived from the app icon
(`assets/main_icon.svg`), whose background is a green-to-blue gradient:

- `AppTheme.brandGreen` `#00C853` (gradient start)
- `AppTheme.brandBlue` `#0091EA` (gradient end, used as the Material 3 seed)
- `AppTheme.brandGradient` — the brand's signature green→blue gradient

Light and dark schemes are both generated from the brand seed.
`ThemeMode.system` is the default; the user's System/Light/Dark choice is
persisted and survives a cold start. `AppTheme.cameraOverlay` is the single
overlay color for content drawn on top of the live camera preview.

Launcher icons for Android (including adaptive icons), Web (favicon + PWA
icons), iOS, macOS, and Windows are generated from `assets/main_icon.png` using
`flutter_launcher_icons`. Regenerate them after changing the source icon:

```sh
dart run flutter_launcher_icons
```

## Local validation

### Start a local API

The app expects a [Meu Preço API](https://github.com/pedromarquetti/meu-preco)
on a single origin and only proceeds past the **select server** screen after
`GET /healthz` succeeds. Run the backend locally (default
`http://localhost:8080`) and point the app at it on first boot, or bake it in
with `--dart-define=API_ORIGIN=...`.

The test suite ships a complete in-process fake API
(`test/fake_api_server.dart`) bound to a loopback port, so integration tests
never require the real backend. To run only the fake-server integration tests:

```sh
flutter test test/fake_server_integration_test.dart
```

The fake server seeds a known account used by the integration tests:

- **Identifier:** `ada@example.com` (also accepted as the account name)
- **Password:** `secret123`

These are test-only fixtures and must never be reused in a real deployment.

### Quality gates

Run the same quality gates used by CI:

```sh
flutter pub get --enforce-lockfile
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

### Builds

Build Android and Web validation artifacts with an explicit API origin:

```sh
flutter build apk --debug \
  --dart-define=API_ORIGIN=https://api.meupreco.example

flutter build web \
  --dart-define=API_ORIGIN=https://api.meupreco.example
```

Host the Web build under a sub-path by passing the base href:

```sh
flutter build web \
  --base-href=/meupreco/ \
  --dart-define=API_ORIGIN=https://api.meupreco.example
```

The debug APK does not require a project release keystore and is suitable for
development or device testing. The first release target is a directly
installable signed APK, not Google Play. A release APK requires a stable Android
upload/release key.

### Android signing

Release signing reads `android/key.properties`, which is ignored by Git and must
never be committed alongside the keystore, passwords, or signing secrets. When
the file is absent the release build falls back to the debug signing key and
emits a build warning, so local and CI debug builds keep working without
secrets. `key.properties` should define:

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

`storeFile` may be an absolute path (developer machine) or a path relative to
`android/` (portable, CI workspace). Version code and version name are read from
`pubspec.yaml` and must increase monotonically for distribution.

To generate a new upload keystore with `keytool` (use a strong password and
store it in a password manager; keep an encrypted backup outside the
repository):

```sh
keytool -genkeypair -v \
  -keystore android/upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Build and verify the signed release locally before adding GitHub Actions release
jobs:

```sh
flutter clean
flutter pub get
flutter build apk --release \
  --dart-define=API_ORIGIN=https://api.meupreco.example
scripts/verify_android_apk.sh
```

`-PrequireReleaseSigning=true` turns the debug-key fallback into a hard failure,
which CI should pass so a real release can never be produced without signing
material:

```sh
flutter build apk --release \
  -PrequireReleaseSigning=true \
  --dart-define=API_ORIGIN=https://api.meupreco.example
```

R8 reported missing Google Play Core classes from Flutter's deferred component
integration. This app does not use deferred components (no `deferred-components`
configuration exists), so only the minimal, reviewed `-dontwarn` suppressions
are kept in `android/app/proguard-rules.pro`; no Play Core dependency is added
and no runtime classes are required. Re-review those rules if the Flutter
embedding is upgraded.

`scripts/verify_android_apk.sh [apk]` checks that the artifact exists, is
signed, is **not** signed by the Android debug key, and reports/exposes its
package id, version, and label without printing any secret.

### Release assumptions

- Production builds talk to an explicitly configured HTTPS origin; the release
  network security configuration trusts only system certificate authorities and
  blocks cleartext. The debug build allows cleartext to `localhost`,
  `127.0.0.1`, and `10.0.2.2` for local development.
- Android releases use a stable upload key with the same identity retained for
  upgrades; losing it prevents updating an already-installed app. Google Play
  App Signing and Play Console publishing are intentionally deferred — the
  current release target is a signed, directly installable APK (an AAB is added
  later in CI).
- No credentials or environment secrets are committed;
  `/android/key.properties`, keystores, and `.env` files are ignored.

### Web limitations

- **CORS** — the backend must allow the hosting origin; the browser enforces
  cross-origin rules the app cannot bypass.
- **Camera** — browser camera access requires a secure (HTTPS) context and a
  user grant; when it is unavailable the app falls back to pasting the QR
  payload or typing the access key manually.
- **Browser storage** — session and preferences use browser storage
  (localStorage-backed), which is per-origin and can be cleared by the user or
  the browser, unlike the platform keystore used on Android.

## GitHub Actions and releases

CI installs the exact Flutter version declared in `pubspec.yaml`
(`environment.flutter`), restores cached Flutter/Pub dependencies, and runs
`flutter pub get --enforce-lockfile` before the remaining Flutter commands.

The GH workflows provide:

- Pull-request formatting, analysis, tests, Android debug build, and Web build.
- Tagged signed Android APK and Web artifacts.
- macOS iOS unsigned build validation, with signed App Store deployment only
  after Apple Developer credentials and provisioning are configured.
- Protected production environments for signing and deployment secrets.

### Release workflow

- **Trigger:** a pushed tag matching `v*.*.*`, or a manual `workflow_dispatch`.
- **Version check:** for tag pushes, the tag without the leading `v` must equal
  the base version in `pubspec.yaml` (the part before `+`). A mismatched tag
  fails before any artifact job runs.
- **Validation gates:** formatting, analysis, tests, Android debug build, and
  Web build run before the signed Android, Web, and unsigned iOS jobs.
- **Artifacts:** the Android job uploads `android-release-apk` containing
  `app-release.apk`; the Web job uploads `web-release` containing the built Web
  bundle rooted at `index.html`.
- **Publication:** only tag pushes create a GitHub Release. Manual dispatch
  builds and uploads workflow artifacts without publishing a release. Release
  assets are `app-release.apk` and `web-release.zip`; re-running a release
  updates the existing release and overwrites its assets.
- **iOS:** `macos-latest` runs an unsigned validation build. Signed iOS
  distribution requires Apple credentials in a protected environment and is not
  automated here.
- **Environments and inputs:** `android-release`, `web-release`, and `release`
  are protected environments. `vars.API_ORIGIN` is required, and the Android
  release job needs `ANDROID_KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_ALIAS`,
  and `KEY_PASSWORD` secrets.

Google Play publishing is deliberately deferred. The first CI/CD milestone is a
signed APK that can be installed directly. App Bundle generation, Play App
Signing, Play Console upload, and store release automation will be planned
separately after the APK pipeline is stable.

## Architecture

The code is organised by feature with a shared `core`:

- `lib/core/{config,http,errors,storage,ui}` — runtime configuration, the HTTP
  pipeline, typed failures, storage abstractions, and shared UI primitives.
- `lib/features/{auth,home,server,settings,nfce,products,admin}` — one folder
  per user-facing flow.
- `lib/app` — composition root (dependency injection), router, and app shell.

All API configuration lives in a single immutable `AppConfig`, created at the
app boundary so tests can substitute fakes for storage, health checks, and
networking.

## Documentation

- API documentation can be found
  [here](https://pedromarquetti.github.io/meu-preco)
