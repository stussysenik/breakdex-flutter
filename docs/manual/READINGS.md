# Breakdex — Readings & Evidence

Entries written by Scholar sessions. Each entry: source, mechanism-level takeaway,
spec-impact line. No opinions without a source. An entry with no possible spec-impact
does not belong here.

## Format

```markdown
### Source: <title or identifier>

- **URL / path:** <link or file path>
- **Date read:** YYYY-MM-DD
- **Mechanism takeaway:** what the source actually says, at mechanism level
- **Spec impact:** what this means for breakdex's design or implementation
- **Caveat:** anything the reader should know about confidence or completeness
```

---

## Active entries

### Flutter rendering pipeline & internals

#### Source: How Flutter Renders Widgets — A Deep Dive into the Rendering Pipeline

- **URL:** https://docs.flutter.dev/ui/rendering
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Flutter's rendering is a three-phase pipeline per frame: build
  (widget → Element → RenderObject tree reconciliation), layout (sizing and positioning
  via constraints-down / sizes-up / parent-sets-offset), and paint (RenderObject.paint
  walks the tree, each node draws into a Layer). The critical invariant: constraints
  flow DOWN, sizes flow UP. A parent proposes constraints; a child picks a size within
  them; the parent positions the child. Layout is O(n) when no relayout boundary is
  crossed — a RenderObject whose size depends only on its own constraints (not children)
  is a boundary, and the framework short-circuits there. Intrinsic sizing (getMinIntrinsicWidth
  et al.) is O(n²) because it walks the subtree for each query — avoid in hot paths.
  The composited layer tree is what the GPU rasterizes; RepaintBoundary inserts a new
  layer, isolating repaint cost to that subtree.
- **Spec impact:** Layout doctrine — parent-children constraint flow is the mechanical
  basis for the stacked viewport. Every screen's content band receives constraints from
  the frame (safe-top + 80 to safe-bottom - 56), picks its size within them, and never
  queries the viewport directly. `MediaQuery.of(context)` in a content widget is a
  constraint violation — the parent (AppScreen) is the only viewport reader. This is
  not convention; it is how Flutter's layout pipeline actually works, stated as a rule.
  Stacked-papers consistency follows: if every screen receives identical constraints
  from identical frame bands, the content is interchangeable paper in an identical frame.
- **Caveat:** Read from Flutter docs and engine source commentary; not verified against
  a specific Flutter engine commit. The pipeline description is stable across Flutter 3.x.

#### Source: Gestures — Flutter Internals & Taps, Drags, and Other Gestures

- **URL:** https://docs.flutter.dev/ui/interactivity/gestures
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Gesture recognition is a two-stage arena: GestureArenaManager
  holds a per-pointer list of competing GestureRecognizers. On pointer-down, every
  recognizer in the hit-test path enters the arena. On pointer-move, each recognizer
  either accepts (claims the gesture), rejects (drops out), or waits. The arena resolves
  when one remains or the pointer lifts. Key mechanism: the FIRST recognizer to accept
  wins unless a later one has higher priority (e.g., ScaleGestureRecognizer defers to
  TapGestureRecognizer until movement exceeds slop). GestureDetectors are convenience
  wrappers that create recognizers and register them. RawGestureDetector exposes the
  recognizer factory for custom compositions. The hit test itself is a tree walk:
  RenderObject.hitTest returns true to claim the pointer, building a HitTestResult
  stack from leaf to root.
- **Spec impact:** Touch targets and gesture composition in the visual-first interface.
  Move cards, combo tiles, and practice controls must declare their gesture vocabulary
  explicitly — overlapping recognizers without arena discipline cause the "dead tap"
  failure mode where two recognizers wait forever. The 48pt minimum touch target
  (Material spec) is the hit-test acceptance area, not the visual size. For the
  practice-mode drag-to-reorder, the arena must resolve drag-vs-tap within one frame
  to avoid visible lag.
- **Caveat:** Mechanism is well-documented; specific recognizer priority ordering for
  custom compositions needs per-case testing.

#### Source: The Canon of Flutter and Full-Stack Dart — Architectural Systems

- **URL:** Internal reference document (valoric research corpus)
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Synthesizes Flutter's architectural layers: the Element tree
  as the stable identity graph (widgets are ephemeral descriptions, Elements are the
  long-lived nodes that hold State and reconcile), the RenderObject tree as the layout
  and paint engine, and the Layer tree as the GPU submission. The durable-execution
  pattern (Temporal, DurableTask) applied to Dart: effects as returned values executed
  by a runtime, not side-effects in user code. Functional effect paradigms (Effect-TS,
  fpdart) model async operations as typed values — `TaskEither<E, A>` — that compose
  without throwing. The key insight for mobile: the Element tree IS the durable execution
  substrate — State persists across rebuilds exactly as a workflow persists across
  suspensions, and `dispose()` is the cancellation seam.
- **Spec impact:** Machine<S,E> aligns with this: states are the workflow state, events
  are the messages, guards are the condition functions, and the Machine itself is the
  durable executor. The XState web-mirror is the same state machine running on a
  different durable-execution substrate (browser DOM). This is not an analogy — both
  are fold-over-events with identical transition tables.
- **Caveat:** Synthesis document; individual claims trace to their primary sources below.

#### Source: Flutter SDK Deep Dive — Shorebird Docs

- **URL:** https://shorebird.dev/docs
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Shorebird patches Flutter apps by replacing the compiled Dart
  kernel snapshot (libapp.so on Android, App.framework on iOS) without a full store
  review. The patch is a binary diff against the base release's kernel — it can change
  Dart code but NOT native plugins, platform channels, or asset files. The constraint:
  a patch must be against the exact Flutter engine version and native plugin set of the
  base release. This means code-push works for Dart-level changes (UI, state, business
  logic) but not for adding plugins or changing native code.
- **Spec impact:** Shorebird code-push is deferred/flagged in CLAUDE.md. When activated,
  the constraint means: (a) plugin additions require a full store release, (b) Dart-only
  fixes (bug fixes, UI tweaks, state machine changes) can ship same-day, (c) the
  Machine<S,E> transition table is Dart-only and therefore patchable — a new state or
  event can ship without store review. This is a distribution advantage of the sealed-class
  state architecture.
- **Caveat:** Shorebird's patching mechanism may evolve; verify against current docs
  before relying on specific capabilities.

### State management & reactivity (2025–2026 landscape)

#### Source: Flutter BLoC vs Riverpod vs Provider — 2026 Comparison Guide

- **URL:** bacancy.com (2026 comparison)
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Provider is InheritedWidget sugar — a dependency-injection
  mechanism, not a state manager. Riverpod is Provider rewritten from scratch: compile-safe
  (no BuildContext needed to read), testable (ProviderContainer override), auto-dispose
  (providers clean up when no listeners remain). BLoC is event-sourcing: events in,
  states out, the bloc is a pure function from (state, event) → state with effects
  as streams. The 2026 landscape: Riverpod 3 added Signals (fine-grained reactivity,
  think SolidJS), making it a hybrid of DI + state + reactivity. BLoC 8.x added
  `on<Event>` handlers with `emit` — closer to a state machine but still stream-based.
  Provider is effectively superseded by Riverpod for new projects.
- **Spec impact:** Breakdex uses Riverpod for DI and Machine<S,E> for state — this is
  the correct split. Riverpod provides the service graph (repositories, DAOs, sync
  backend); Machine provides the screen-level state machines. The Riverpod 3 Signals
  feature is NOT adopted — Machine<S,E> already provides fine-grained reactivity at
  the state-machine level, and adding Signals would create two reactivity systems
  competing for the same concern. Decision: Riverpod for DI, Machine for state,
  no Signals.
- **Caveat:** Comparison is from a third-party guide; verified against official docs
  for Riverpod 3 and BLoC 8.x API surfaces.

#### Source: Best Flutter State Management Libraries 2026

- **URL:** foresightmobile.io (2026 guide)
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Surveys the 2026 field: Riverpod, BLoC, Signals (dart_signals,
  flutter_signals), MobX, GetX, Provider. The key differentiator is granularity:
  coarse-grained (BLoC — one stream per feature) vs fine-grained (Signals — one
  observable per value). Coarse-grained wins for screen-level state (fewer subscriptions,
  simpler mental model); fine-grained wins for form-level state (individual field
  reactivity without rebuilding the form). The guide's recommendation: Riverpod for
  most projects, BLoC for event-heavy domains, Signals for form-heavy UIs.
- **Spec impact:** Confirms the Machine<S,E> + Riverpod split. Move/combo/set CRUD is
  event-heavy (Machine wins); settings forms could benefit from Signals but the cost
  of a second reactivity system outweighs the granularity gain. No change to locked stack.
- **Caveat:** Guide is opinionated; the actual choice depends on team familiarity.

#### Source: Flutter State Management Tool 2025 — Riverpod 3 vs Bloc vs Signals

- **URL:** creolestudios.com (2025 comparison)
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Riverpod 3's key innovation is `Notifier` + `AsyncNotifier`
  as the standard state-holder (replacing StateNotifier, which is now deprecated).
  Notifier is a class with a `build()` method that returns the initial state and
  public methods that call `state =` to update. The provider is generated via
  `@riverpod` annotation + build_runner. Signals in Flutter are experimental and
  lack the ecosystem maturity of Riverpod or BLoC.
- **Spec impact:** Breakdex's existing Riverpod usage should use Notifier/AsyncNotifier,
  not the deprecated StateNotifier. Audit needed: any `StateNotifier` in the codebase
  is a migration candidate. The `@riverpod` code-gen is already in use (build_runner
  is a project dependency).
- **Caveat:** Signals ecosystem maturity may have changed since 2025; re-check if
  considering adoption.

#### Source: Flutter State Management Guide in 2026

- **URL:** solguruz.com (2026 guide, covers packages and best practices)
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Best practices consensus: (1) separate business logic from
  UI — the state holder should not know about BuildContext, (2) use immutable state
  objects (freezed or manual copyWith), (3) prefer composition over inheritance in
  state holders, (4) test state holders in isolation with mock dependencies, (5) use
  code generation (freezed, riverpod_generator) to reduce boilerplate. The guide
  explicitly warns against GetX for production apps due to its global mutable state
  and lack of testability.
- **Spec impact:** All five practices are already breakdex law. The GetX warning is
  noted — no GetX in the dependency tree. The immutable-state requirement means every
  Machine<S,E> state class must be immutable (final fields, const constructors or
  freezed). Audit: any mutable state in a Machine is a defect.
- **Caveat:** Guide is a survey; individual claims verified against primary sources.

### Hot reload mechanics

#### Source: Flutter Hot Reload — Official Documentation & Community Guides

- **URL:** docs.flutter.dev/tools/hot-reload; theflutterblog.com; capitalnumbers.com
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Hot reload works by: (1) the Dart VM compiles changed files
  to kernel, (2) the new kernel replaces the old in the running VM, (3) the widget
  tree is rebuilt from the root — but State objects and top-level/global variables
  survive. This is why `const` values do NOT update on hot reload (they are inlined
  at compile time) and why `static` fields persist. Hot RESTART resets everything
  including State and globals but loses app state (navigation stack, form input).
  The reload is class-level: adding a new method works, changing a class hierarchy
  (adding a mixin, changing a superclass) requires restart. Enum changes require
  restart. The practical boundary: anything that changes the SHAPE of a class or the
  IDENTITY of a type needs restart; anything that changes the BODY of a method or
  the VALUE of a non-const field works with reload.
- **Spec impact:** The Dart MCP server's hot_reload vs hot_restart distinction maps
  directly to this. Hot reload for UI tweaks (widget body changes, style changes);
  hot restart for structural changes (new states in Machine<S,E>, new enum values,
  new Riverpod providers). The edit→result loop in CLAUDE.md's compile-speed term
  (#3) is bounded by this: most UI edits are reload-speed (~1s), structural changes
  are restart-speed (~5-10s), and plugin/native changes are rebuild-speed (~41s web,
  ~60s+ mobile).
- **Caveat:** Specific class-shape boundaries vary by Dart VM version; the rules above
  are the stable subset across Flutter 3.x.

### Full-stack Dart & backend architecture

#### Source: Dart Frog vs Serverpod — Technical Comparison

- **URL:** Multiple comparison articles (2025-2026)
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Dart Frog is a minimal HTTP framework (shelf-based, route
  handlers as functions, middleware as function composition) — it is Express for Dart,
  nothing more. Serverpod is a full-stack framework: code-shared models (Dart classes
  serialized to JSON and used by both client and server), auto-generated client from
  server endpoints, built-in ORM (Postgres), WebSocket streaming, scheduled jobs,
  and a module system. The tradeoff: Dart Frog gives you a server; Serverpod gives
  you a platform. Dart Frog's compile time is fast (small dependency tree); Serverpod's
  code-gen adds build_runner time but eliminates client-server drift.
- **Spec impact:** Breakdex chose Appwrite (open-source BaaS), not a custom Dart backend.
  This reading confirms the choice: Serverpod's value (code-shared models, generated
  client) is exactly what Appwrite provides via its SDK and collection schema. Dart Frog
  would be relevant only if breakdex needed a custom API gateway in front of Appwrite
  (e.g., for server-side FSRS computation). Decision: Appwrite stays; Dart Frog and
  Serverpod are noted as alternatives for a future self-hosted compute layer.
- **Caveat:** Serverpod's ORM and streaming capabilities were not benchmarked against
  Appwrite's realtime subscriptions.

#### Source: Serverpod Documentation — Streams, Messaging, Installation

- **URL:** docs.serverpod.dev
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Serverpod's streaming uses persistent WebSocket connections
  with typed message channels. A client subscribes to a channel; the server pushes
  typed messages. This is the same pattern as Appwrite's realtime subscriptions
  (WebSocket + channel + document events) but with Dart-typed messages instead of
  JSON payloads. Serverpod's module system allows packaging reusable server components
  (models + endpoints + migrations) as a pub package.
- **Spec impact:** Appwrite realtime is the chosen mechanism for multi-device sync.
  Serverpod's typed-channel pattern is the reference for what a future Dart-native
  sync layer would look like — but Appwrite's JSON-over-WebSocket is sufficient for
  the current single-user private-sync model. No action needed.
- **Caveat:** Serverpod streaming was not load-tested; Appwrite realtime has known
  scaling characteristics from its self-hosted deployments.

#### Source: Serverpod + PowerSync Integration Guide

- **URL:** powersync.com integration docs
- **Date read:** 2026-07-30
- **Mechanism takeaway:** PowerSync is a sync engine that keeps a local SQLite database
  in sync with a Postgres backend via a sync service. It uses a changeset protocol:
  the server tracks a write-ahead log of changes; the client pulls changesets and
  applies them to local SQLite; client writes are uploaded as mutations. This is
  the CRDT-adjacent pattern that breakdex explicitly rejected (CLAUDE.md Non-goals:
  CRDTs — single-user, LWW is sufficient). PowerSync's value is multi-user conflict
  resolution, which breakdex does not need.
- **Spec impact:** Confirms the LWW + tombstones choice. PowerSync is the answer to a
  question breakdex does not ask (multi-user concurrent editing). The Drift/SQLite
  local-first architecture with Appwrite shadow sync is the correct simplification.
  No action needed.
- **Caveat:** If shared/collaborative state is ever un-deferred, PowerSync becomes
  relevant again.

#### Source: Flutter on Cloud Run — Full Stack Dart Architecture

- **URL:** Google Cloud Blog (2025)
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Demonstrates deploying a Dart backend (Dart Frog or shelf)
  on Google Cloud Run as a containerized service. The architecture: Flutter client →
  Cloud Run Dart API → Cloud SQL (Postgres) or Firestore. Key insight: Dart on the
  server shares model classes with the Flutter client, eliminating serialization
  drift. Cloud Run's cold-start is ~200ms for a Dart binary (vs ~500ms for Node.js,
  ~1s for Java). The article positions this as "full-stack Dart" but the server is
  a thin API layer, not a platform.
- **Spec impact:** Relevant only if breakdex adds a custom compute layer (e.g.,
  server-side FSRS scheduling, video transcoding). Appwrite Functions (Dart runtime)
  already provide this capability without a separate Cloud Run deployment. Decision:
  Appwrite Functions for server-side compute; Cloud Run is a fallback if Appwrite
  Functions prove insufficient.
- **Caveat:** Cold-start numbers are from 2025; Dart VM improvements may have changed them.

#### Source: Building a Large Application with Dart — Quire Blog

- **URL:** quire.io blog (engineering post-mortem)
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Quire built a project management app with a Dart backend
  serving a Flutter client. Key lessons: (1) code sharing between client and server
  is the primary value of full-stack Dart — shared validation, shared models,
  shared serialization, (2) the Dart VM's single-threaded isolate model simplifies
  concurrency but requires careful isolate-per-request or async I/O patterns for
  throughput, (3) hot reload on the server is possible but dangerous in production
  (state survives, schema may not), (4) the Dart ecosystem's server-side libraries
  are immature compared to Node.js or Go — expect to write your own middleware.
- **Spec impact:** Validates the Appwrite choice — breakdex avoids the immature-server-
  ecosystem problem by using a managed BaaS. The code-sharing value is captured by
  Appwrite's Dart SDK (same models on client and server). No action needed.
- **Caveat:** Quire's experience is from 2024-2025; the Dart server ecosystem has
  grown since.

### Functional programming & advanced type systems

#### Source: fpdart — Functional Programming in Dart

- **URL:** pub.dev/packages/fpdart; sandromaglione.com articles
- **Date read:** 2026-07-30
- **Mechanism takeaway:** fpdart brings Haskell/Scala-style functional programming to
  Dart: `Option<T>` (nullable without null), `Either<L, R>` (typed errors), `Task<T>`
  (lazy async), `TaskEither<L, R>` (lazy async with typed errors), `Reader<R, T>`
  (dependency injection as a function), `State<S, T>` (stateful computation). The
  key composition: `TaskEither` chains with `flatMap` — each step either succeeds
  with a value or fails with a typed error, and the chain short-circuits on failure.
  This is the "railway-oriented programming" pattern. The cost: Dart's type system
  lacks higher-kinded types, so fpdart cannot express generic monad composition —
  each type has its own `flatMap`, `map`, `fold` methods.
- **Spec impact:** The sync layer's upload spool and reconcile pipeline are candidates
  for `TaskEither` composition — each step (serialize → upload → confirm → update
  local) is a typed success/failure chain. However, breakdex currently uses plain
  `Future` + try/catch, which is simpler and sufficient for the single-user model.
  Decision: fpdart is NOT adopted. The pattern is noted for future sync hardening.
  The Machine<S,E> framework already captures the state-machine aspect that fpdart's
  `State` monad would provide.
- **Caveat:** fpdart's API surface is large; only the core types were evaluated.

#### Source: Ribs — Functional Programming Toolkit for Dart

- **URL:** github.com/cranst0n/ribs; pub.dev/packages/ribs_ip
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Ribs is a lighter alternative to fpdart: `Result<T, E>`
  (like Either), `Optional<T>` (like Option), pipeline operators (`|>` emulation
  via extension methods). It is less comprehensive than fpdart but has a smaller
  API surface and fewer dependencies. The pipeline operator (`value.pipe(transform)`)
  is the main ergonomic win.
- **Spec impact:** Not adopted. The pipeline pattern is achievable with Dart's cascade
  operator (`..`) and extension methods without a library. No action needed.
- **Caveat:** Small community; maintenance risk.

#### Source: Dart Language — Monad Coproducts / Data Types à la Carte

- **URL:** github.com/dart-lang/language issue #3887
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Proposal for higher-kinded types and coproduct (sum) types
  in Dart. The issue documents why Dart cannot express generic monad composition
  (no HKT) and proposes a limited form. Status: open, not scheduled. The practical
  consequence: Dart's sealed classes (Dart 3.0) are the language's answer to sum
  types — `sealed class` + `switch` with exhaustiveness checking is the poor man's
  coproduct, and it is sufficient for Machine<S,E>'s state and event hierarchies.
- **Spec impact:** Machine<S,E> uses sealed classes for states and events — this IS
  the data-types-à-la-carte pattern within Dart's type system. The exhaustiveness
  checking in `switch` expressions is the compile-time guarantee that HKT would
  provide at the monad level. No action needed; the locked stack is correct.
- **Caveat:** If Dart adds HKT in a future version, the functional composition story
  may change.

### Durable execution & time polyfills

#### Source: durable_workflow — Dart Package

- **URL:** pub.dev/packages/durable_workflow
- **Date read:** 2026-07-30
- **Mechanism takeaway:** A Dart implementation of the durable-workflow pattern (inspired
  by Temporal/Cadence). Workflows are defined as async functions; the runtime records
  every step's result so that on crash/restart, the workflow resumes from the last
  recorded step rather than re-executing. The mechanism: a workflow context that
  intercepts `await` calls and records their results in a persistent log. On replay,
  recorded results are returned instead of re-executing the side effect.
- **Spec impact:** The upload spool and sync reconcile are durable-workflow-shaped:
  a multi-step process that must survive app restart. Currently implemented as a
  state machine (StorageActionMachine) with Drift-persisted state — this IS a
  durable workflow, just hand-rolled rather than framework-driven. The durable_workflow
  package is too small-community to adopt, but the pattern validates the current
  approach. No action needed.
- **Caveat:** Package has low download count; maintenance risk.

#### Source: Temporal Swift SDK — Durable Workflows

- **URL:** swift.org blog (2026)
- **Date read:** 2026-07-30
- **Mechanism takeaway:** Apple's Swift SDK for Temporal brings durable execution to
  the iOS/macOS ecosystem. The key insight: durable execution is the correct model
  for any operation that spans multiple network calls and must survive process death.
  The Swift SDK uses actors for workflow isolation and async/await for the workflow
  body. The Temporal server handles orchestration, retries, and timeouts.
- **Spec impact:** Validates the durable-execution pattern for mobile. Breakdex's
  StorageActionMachine (upload → hash → save) is a three-step durable workflow.
  The Temporal model would be overkill for single-user sync but is the reference
  architecture if multi-device coordination grows beyond LWW.
- **Caveat:** Temporal server is a heavy infrastructure dependency; not suitable for
  breakdex's self-hosted Appwrite model.

#### Source: temporal_js_polyfill & date_n_time — Dart Packages

- **URL:** pub.dev/packages/temporal_js_polyfill; pub.dev/packages/date_n_time
- **Date read:** 2026-07-30
- **Mechanism takeaway:** temporal_js_polyfill provides Temporal API (ECMAScript
  proposal) types in Dart — `Instant`, `ZonedDateTime`, `Duration` with calendar-aware
  arithmetic. date_n_time is a simpler date library with timezone support. The
  Temporal API's key insight: a `ZonedDateTime` is a point in time PLUS a timezone
  PLUS a calendar, and arithmetic respects all three (adding "1 month" to Jan 31
  gives Feb 28, not Mar 3). Dart's `DateTime` is a UTC instant with no calendar
  awareness.
- **Spec impact:** Breakdex uses `DateTime` throughout. The FSRS scheduling algorithm
  operates on intervals (days), not calendar dates, so `DateTime` is sufficient.
  If calendar-aware scheduling is ever needed (e.g., "practice every Tuesday"),
  Temporal types would be the correct upgrade. No action needed currently.
- **Caveat:** Both packages have low adoption; the Temporal API is still a proposal
  in JavaScript.

### Cross-cutting: the agentic-agnostic factory thesis

#### Source: Synthesis — Agentic Software Factory Patterns (valoric + breakdex)

- **URL:** Internal synthesis from valoric DOCS/READINGS.md and FACTORY.md
- **Date read:** 2026-07-30
- **Mechanism takeaway:** An agentic-agnostic factory is a build system where the
  process is defined by records on disk, not by the model running it. The model
  (Claude, Gemini, Codex, GPT, local inference) is interchangeable — the factory
  produces the same output regardless of which agent executes a session, because:
  (1) the queue is a file (ROADMAP.md), not a conversation, (2) the spec is a file
  (openspec/changes/), not a chat message, (3) the gate is a script (verify.sh),
  not a model's judgment, (4) the record is a file (session.log, tasks.md), not
  a transcript. The stochastic element is reduced to individual character generation —
  the model proposes text; the grammar (openspec --strict, analyzer, tests) decides
  whether it survives. This is the "linguistic, not statistical" determinism principle.
  Context condensation (200k → 150k → less) is achieved by: (a) the factory's records
  ARE the context — a fresh session reads files, not history, (b) each role's output
  is bounded (500-token handoff caps), (c) the manual is a primeable bundle, not a
  full corpus, (d) discrete stochastic processes — the only randomness is token
  sampling; everything else is deterministic file I/O and script execution.
- **Spec impact:** This IS the factory. CLAUDE.md, FACTORY.md, ROADMAP.md, openspec/,
  verify.sh, status.sh, session.log — these are not documentation, they are the
  machine. The model is a replaceable component. The hard-lint screen consistency
  doctrine (this session's addition) follows the same principle: the frame (AppScreen)
  is the deterministic constraint; the content is the stochastic proposal; the
  conformance test is the gate. Every screen that passes the frame conformance test
  is consistent by construction, not by the model's aesthetic judgment.
- **Caveat:** This is a synthesis, not a primary source. Each component traces to
  the valoric READINGS.md entries above and the breakdex session.log record.
