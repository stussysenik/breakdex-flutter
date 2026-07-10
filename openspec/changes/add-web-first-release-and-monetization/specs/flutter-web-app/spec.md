# flutter-web-app

## ADDED Requirements

### Requirement: Flutter Web is a released application surface

The Flutter codebase SHALL build and serve as the web application from the same source as mobile,
with the local data layer running on WASM sqlite (OPFS persistence) and schema migrations
identical to device builds. The Next.js studio remains a separate owner-facing surface; this
capability is the consumer product.

#### Scenario: Web build is releasable
- **WHEN** CI runs `flutter build web` on a tagged release
- **THEN** the build succeeds and the deployed app boots to a working library in a browser with no install

#### Scenario: Local data survives reload
- **WHEN** a web user creates a move and reloads the page
- **THEN** the move is still present (OPFS-persisted database)

### Requirement: Platform gaps degrade visibly

The system SHALL make platform-only features (native video export, secure storage, photo library
access) degrade visibly on web: the affordance is hidden or explicitly labeled unavailable. A
platform gap SHALL never be a silent no-op or a crash.

#### Scenario: iOS-only feature on web
- **WHEN** a web user reaches a flow whose implementation is iOS-only
- **THEN** the UI either omits the affordance or labels it unavailable on this platform, and the surrounding flow remains usable

### Requirement: The shared compile graph is platform-neutral

Every Dart library reachable from `main.dart` OR from any `@Preview` SHALL NOT import `dart:io` or
`dart:ffi` directly. Platform-specific I/O (filesystem, native SQLite via FFI) SHALL sit behind a
conditional-import seam (`x.dart` facade selecting `x_native.dart` / `x_web.dart`) so the web
target compiles cleanly. As a consequence, `flutter widget-preview` — which renders **only** on
web — SHALL compile and render the project's previews in Chrome against an in-memory WASM database.

#### Scenario: Web compile has no native leak
- **WHEN** `flutter build web` (or the widget-preview scaffold) compiles the app
- **THEN** no `dart:io` / `Only JS interop members may be 'external'` (FFI) errors occur, because all such usage is behind native-only conditional seams

#### Scenario: Widget previews render on web
- **WHEN** a developer runs `flutter widget-preview start`
- **THEN** the previews render in Chrome, each screen backed by a fresh in-memory WASM SQLite database seeded by the preview harness
