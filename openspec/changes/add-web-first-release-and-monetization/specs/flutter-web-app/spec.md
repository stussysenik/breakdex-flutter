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
