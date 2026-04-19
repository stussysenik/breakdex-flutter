## Why

Flutter's class-based widget system creates verbose boilerplate (StatelessWidget/StatefulWidget hierarchies) that obscures the underlying data flow. This increases friction for contributors, makes forkability difficult, and creates dependency on build_runner for code generation. ClojureDart provides a data-first paradigm where UI is a pure projection of EDN state, enabling Structure (Hiccup) + State (DOP atoms) + Flow (FRP/CRDT). This unification reduces complexity while increasing composability.

## What Changes

- Introduce ClojureDart as the primary design system language
- Replace all Dart widget classes with Hiccup-style data structures
- Implement DOP (Data-Oriented Programming) state with Clojure atoms
- Add FRP data flow with reactive watchers and CRDT sync
- Replace build_runner with Clojure macros for compile-time code generation
- Create forkable stack that compiles to native Flutter

## Capabilities

### New Capabilities
- `clojuredart-compiler`: ClojureDart integration with Flutter build pipeline
- `hiccup-widgets`: Data-driven widget composition as pure EDN structures
- `dop-state`: Atom-based state management replacing Riverpod/BLoC
- `frp-flow`: Functional reactive data flow with watchers
- `crdt-sync`: Conflict-free replicated data types for offline sync
- `clojure-macros`: Compile-time code generation replacing build_runner

### Modified Capabilities
- (none - this is a greenfield implementation)

## Impact

- **New Dependencies**: cljd (ClojureDart compiler)
- **Code Changes**: lib/clojuredart/ (new), lib/features/* (migrated)
- **Build Pipeline**: Add cljd build phase before dart compile
- **Breaking**: All existing lib/*.dart files migrated to .cljd