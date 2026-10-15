# Meu Preço

A Flutter front-end only implementation for the Meu Preço API

## Scope/Features

- [ ] **Login** - Login API flow
- [ ] **Storage** - Saving the necessary data for auth
- [ ] **backend config** - User must be able to point this front end to their
      desired API
- [ ] **Settings page** - unify all frontend configs into Settings page
- [ ] **Submit flow** - Scan NFCe -> send to `/nfce/new` -> present parsed
      data + 'what the user needs to fix' -> send final data to `submit`.
- [ ] **Product search** - Search for a specific product
- [ ] **Data viewer** - View price log for product -> render as a list of
      historical prices
- [ ] **Graph** - Implement graph for price log
- [ ] **Icons** - Implement app icons for all platforms
- [ ] Android Build
- [ ] Web Build

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

The app talks to a single Meu Preço API origin. On first boot it always asks
for a server on the **select server** screen and only moves on to login after
`GET /healthz` succeeds. The origin can be changed later on the Settings page
without rebuilding.

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

## Architecture

The code is organised by feature with a shared `core`:

- `lib/core/{config,http,errors,storage,ui}` — runtime configuration, the HTTP
  pipeline, typed failures, storage abstractions, and shared UI primitives.
- `lib/features/{auth,home,server,settings,nfce,products,supermarkets,admin}` —
  one folder per user-facing flow.
- `lib/app` — composition root (dependency injection), router, and app shell.

All API configuration lives in a single immutable `AppConfig`, created at the
app boundary so tests can substitute fakes for storage, health checks, and
networking.
