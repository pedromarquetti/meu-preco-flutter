# Meu Preço

<!--toc:start-->

- [Meu Preço](#meu-preço)
  - [Scope and status](#scope-and-status)
  - [UI Flow](#ui-flow)
  - [API docs](#api-docs)
  - [Configuration](#configuration)
  - [Local validation](#local-validation)
  - [GitHub Actions and releases](#github-actions-and-releases)
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
- [x] Portuguese localization, responsive layouts, and accessibility-oriented
      loading/error/empty states.
- [ ] Code-quality, accessibility, localization, and release audit.
- [ ] Consistent screen/component animations with reduced-motion support.
- [ ] GitHub Actions CI, Android/Web artifacts, and optional iOS validation.
- [ ] Android production signing and protected release deployment.

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

## Local validation

Run the same quality gates used by CI:

```sh
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Build Android and Web validation artifacts with an explicit API origin:

```sh
flutter build apk --debug \
  --dart-define=API_ORIGIN=https://api.meupreco.example

flutter build web \
  --dart-define=API_ORIGIN=https://api.meupreco.example
```

The debug APK does not require a project release keystore and is suitable for
development or device testing. A production release APK/AAB requires a stable
Android upload/release key. The keystore, `android/key.properties`, passwords,
and signing secrets must never be committed.

## GitHub Actions and releases

The GH workflows will provide:

- Pull-request formatting, analysis, tests, Android debug build, and Web build.
- Tagged release Android AAB/APK and Web artifacts.
- macOS iOS unsigned build validation, with signed App Store deployment only
  after Apple Developer credentials and provisioning are configured.
- Protected production environments for signing and deployment secrets.

Android Google Play releases should use a stable upload key with Google Play App
Signing enabled. GitHub Actions should build an AAB for Play distribution; an
APK is intended for direct installation or testing.

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
