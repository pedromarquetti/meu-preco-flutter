# AGENTS.md — Meu Preço Frontend

## Purpose

This file provides implementation and review guidance for agents working in this
Flutter repository. Follow the repository's existing patterns before introducing
new abstractions, dependencies, or architecture.

## Project context

- This is a Flutter front end for the Meu Preço API.
- Android and Web are the primary supported platforms. Keep iOS, macOS, Linux,
  and Windows project structure buildable where practical.
- The app uses Material 3, Portuguese localization, runtime server selection,
  typed API models, repository interfaces, `Provider`, `go_router`, and
  `ChangeNotifier`-based controllers.
- The API origin is runtime-configurable and may also be supplied with
  `--dart-define`.
- API requests use `/api/v1` except process health endpoints such as `/healthz`
  and `/readyz`.
- Money values use decimal-safe model types. Never parse money through
  floating-point types.
- Supermarket functionality is intentionally out of scope unless explicitly
  requested.

## Before editing

1. Inspect both staged and unstaged changes:

   ```sh
   git status --short
   git diff --cached
   git diff
   ```

2. Read the relevant existing files and tests before designing a change.
3. Search for existing models, repositories, controllers, widgets, helpers,
   localization keys, and tests before adding anything.
4. Preserve unrelated work already present in the index or working tree. Never
   reset, checkout, clean, or overwrite another change without explicit
   approval.
5. Confirm the API contract before changing request paths, payloads, response
   models, authentication, or error handling.

## Architecture and responsibilities

Follow separation of concerns and keep responsibilities explicit:

- **Views/widgets** render state and forward user events. They may contain
  simple conditional rendering, layout, animation, and routing logic.
- **Controllers/view models** own feature UI state, commands, debounce,
  pagination, stale-response protection, and transformations needed by views.
- **Repositories** are the source of truth for domain data and API operations.
  Keep API serialization and typed error mapping at this boundary.
- **Services/clients** handle transport or platform integration and should not
  accumulate feature UI state.
- **Models** represent typed domain/request/response data and must remain
  null-safe and serialization-safe.

Do not put repository calls, business decisions, or complex asynchronous state
machines directly into reusable presentational widgets.

## Reuse and duplication rules

Avoid repeated methods, classes, widgets, and business logic.

Before creating a new method or class:

1. Search for an existing implementation with the same responsibility.
2. Reuse an existing model, repository method, controller, helper, or widget
   when its contract fits.
3. If two implementations are nearly identical, extract the shared behavior
   instead of copying it.
4. Keep feature-specific behavior in the parent and shared presentation in a
   reusable widget.
5. Do not create speculative abstractions used by only one caller unless they
   clearly isolate complex behavior or are required for testing.
6. Do not create duplicate “search”, “result tile”, “loading”, “error”, or
   “empty” widgets when an existing shared component already serves that role.

Prefer reusable `StatelessWidget` or focused `StatefulWidget` components over
large build methods or local widget-builder functions when a UI piece has its
own responsibility, state, lifecycle, or repeated use. Flutter's performance
guidance specifically recommends reusable widgets and localizing rebuilds.

For product lists, preserve this layering:

- `ProductSearchController`: query, debounce, pagination, loading, errors, and
  stale-response protection.
- `ProductSearchInput`: search-field presentation and controller connection.
- `ProductList`: reusable product-result list rendering and click forwarding.
- `ProductResultTile`: one product row's presentation.
- Parent screen/widget: navigation, modal dismissal, selection meaning, editing,
  merge direction, and API commands.

Reusable widgets should receive data and callbacks. They should not reach into
repositories or decide what a selected item means.

## Flutter and Dart implementation practices

- Use sound null safety. Prefer guards and typed values over `!`, `dynamic`,
  `Object` casts, or `as` when a proper type/guard is available.
- Follow `flutter_lints` and the existing `analysis_options.yaml`.
- Use `const` constructors and `const` subtrees where they are valid.
- Keep `build()` methods focused. Split independently changing or reusable UI
  into widgets.
- Localize `setState` to the smallest stateful subtree that needs rebuilding.
- Use lazy lists (`ListView.builder`, `ListView.separated`, slivers) for
  potentially long lists.
- Use stable keys for dynamic list items when identity matters.
- Dispose controllers, focus nodes, timers, subscriptions, and owned resources.
- A widget must not dispose an injected controller it does not own.
- Remove listeners before disposing their notifier/controller.
- Guard asynchronous UI continuations with `mounted` where needed.
- Protect search and pagination against stale responses and duplicate requests.
- Do not swallow exceptions, silently return success-shaped fallbacks, or use
  broad catches without repository-standard error mapping.
- Surface actionable errors through the existing typed error and localized
  error-message patterns.
- Keep API paths, request fields, response parsing, and model names aligned with
  the backend contract.
- Do not use raw brand colors when a theme role or named theme token exists.
- Keep user-facing text in ARB localization files. Regenerate generated
  localization files whenever ARB changes.
- Keep comments rare and explain only non-obvious constraints or decisions.
- Use `// TODO(username): ...` only for actionable, tracked follow-up work.
- Use lowercase_with_underscores file names and existing import conventions.

## UI, responsive design, and accessibility

- Preserve the centralized Material 3 theme and theme roles.
- Design for phone, tablet, desktop, large text, keyboard focus, and Web.
- Use `SafeArea`, constraints, and scrollable layouts where content can exceed
  the viewport.
- Avoid unbounded nested scrollables and flex layouts that can overflow.
- Tappable targets should be at least 48x48 logical pixels.
- Provide semantic labels and meaningful accessibility announcements for
  controls, loading states, errors, and empty states.
- Verify focus order and keyboard activation for interactive controls.
- Maintain readable contrast; target at least 4.5:1 for normal text and controls
  except disabled content.
- Do not rely on color alone to communicate state.
- Test large text and narrow dimensions for `RenderFlex` overflow.
- Do not change user context unexpectedly while typing; use explicit actions
  where confirmation is needed.

## State and asynchronous work

- Make ownership explicit for every controller and resource.
- Cancel timers and subscriptions in `dispose`.
- Use generation/epoch/request guards when a late response could overwrite newer
  state.
- Do not call `setState` after disposal.
- Disable duplicate submissions while an irreversible or mutating operation is
  in flight.
- Preserve useful user state after recoverable failures so retry is possible.
- Keep loading, error, empty, and success states mutually clear.

## Testing expectations

Choose the smallest test layer that verifies the behavior:

- Unit tests for parsing, transformations, decisions, and controllers.
- Widget tests for rendering, interaction, callbacks, accessibility, and layout.
- Integration/fake-server tests for the HTTP pipeline, repository contracts,
  authentication, and important end-to-end flows.

Add focused regression tests for every behavior introduced or fixed. Prefer
testing public behavior and parent-child contracts over implementation details.
For reusable widgets, test:

- rendering of required and optional data;
- callback values and invocation count;
- loading/error/empty states where owned by the widget;
- stable identity and selection behavior;
- controller ownership and disposal;
- large-text and constrained-layout behavior.

Do not add tests that merely restate constants, trivial accessors, or framework
behavior.

## Mandatory validation after every code change

After each implementation or edit run, and before reporting completion, run:

```sh
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
git diff --check
```

For targeted work, run the focused test first, but still run the complete
quality gates before completion unless the user explicitly limits validation. If
a command fails:

1. Read and classify the failure.
2. Fix the root cause rather than weakening the check.
3. Rerun the failed command.
4. Rerun all mandatory checks after the fix.

For build or platform changes, also run the smallest relevant build, for
example:

```sh
flutter build apk --debug
flutter build web
flutter build ios --release --no-codesign
```

Run iOS builds on macOS only when the required runner is available. For signed
Android release work, require signing explicitly and verify the resulting APK:

```sh
flutter build apk --release -PrequireReleaseSigning=true
scripts/verify_android_apk.sh
```

Never claim tests or checks passed unless they actually completed successfully.
Report environment/tooling failures separately from code failures.

## Git and file-safety rules

- Do not commit unless explicitly requested.
- Do not amend commits unless explicitly requested.
- Do not rewrite history.
- Do not revert unrelated staged or unstaged changes.
- Do not commit secrets, keystores, passwords, tokens, `.env` files, or
  generated sensitive configuration.
- Keep generated localization and other generated files synchronized with their
  source files.
- Use precise, surgical changes and avoid unrelated cleanup.

## Useful project commands

```sh
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test test/fake_server_integration_test.dart
flutter build apk --debug --dart-define=API_ORIGIN=https://api.example
flutter build web --dart-define=API_ORIGIN=https://api.example
dart run flutter_launcher_icons
```

## Authoritative references

These recommendations are based on current official Dart and Flutter guidance:

- Flutter architecture: <https://docs.flutter.dev/app-architecture/guide>
- Flutter testing: <https://docs.flutter.dev/testing/overview>
- Flutter accessibility: <https://docs.flutter.dev/ui/accessibility>
- Flutter performance best practices:
  <https://docs.flutter.dev/perf/best-practices>
- Dart linter rules: <https://dart.dev/tools/linter-rules>
- Flutter adaptive and responsive design:
  <https://docs.flutter.dev/ui/adaptive-responsive>
