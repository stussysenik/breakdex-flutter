## Context

**Background:** Breakdex is a Flutter app with extensive Dart widget classes (StatelessWidget/StatefulWidget), Riverpod state management, Drift database, and Supabase backend. The codebase has ~100+ Dart files with significant boilerplate.

**Current State:**
- Widgets: `lib/**/*.dart` - deep class hierarchies
- State: Riverpod providers (`ref.watch`, `StateNotifier`)
- DB: Drift with generated code (build_runner)
- Sync: Supabase + local Drift

**Constraints:**
- Must compile to valid Flutter `.apk`/`.app`
- Must maintain existing Supabase sync behavior
- Team needs to understand / fork the stack

## Goals / Non-Goals

**Goals:**
- Replace class-based widgets with Hiccup data structures
- Implement DOP state (atoms) as primary state management
- Add CRDT sync for offline-first capability
- Create forkable, composable design system
- Eliminate build_runner dependency

**Non-Goals:**
- Change Supabase API contract
- Modify Drift schema (keep for compatibility)
- Support iOS (focus on Android first)
- Maintain mixed .dart + .cljd - go full ClojureDart

## Decisions

### Decision 1: Build Pipeline

**Choice:** `cljd` compile → Flutter build

```bash
# Pipeline
cljd compile lib/clojuredart/ → lib/.generated/
flutter build apk --split-per-abel
```

**Rationale:** ClojureDart outputs standard Dart code. We compile to `.cljd` files first, generating `.dart` that Flutter can consume normally.

**Alternative:** Mixed .dart + .cljd - rejected due to complexity.

### Decision 2: State Architecture

**Choice:** Clojure atoms → Flutter widget rebuilds

```clojure
(def state-atom (atom {:count 0}))

;; UI watches atom, triggers setState on change
(add-watch state-atom :ui
  (fn [_ _ _ new]
    (setState! new)))
```

**Rationale:** Atoms provide identity + value semantics. Watchers enable FRP flow without explicit providers.

**Alternative:** Keep Riverpod - rejected (we want DOP paradigm shift).

### Decision 3: CRDT Implementation

**Choice:** Custom Yjs-inspired LWW (Last-Writer-Wins) register

```clojure
(defprotocol CRDT
  (merge [this other])
  (timestamp [this]))

(defrecord LWWRegister [value timestamp]
  CRDT
  (merge [this other]
    (if (> (:timestamp other) (:timestamp this))
      other this)))
```

**Rationale:** Simpler than full Automerge. Sufficient for move/combo sync.

**Alternative:** Automerge - too heavy for mobile.

### Decision 4: Macro vs build_runner

**Choice:** Clojure macros for code gen

```clojure
(defmacro defmodel [name fields]
  `(defrecord ~name [~@fields]))

;; Usage: (defmodel Move [id name video-url])
;; Expands to: (defrecord Move [id name video-url])
```

**Rationale:** Macros run at compile time. No external tool needed.

### Decision 5: Migration Strategy

**Choice:** Feature-by-feature rewrite

```
Phase 1: Core widgets (Button, Card, Text)
Phase 2: State layer (atoms + CRDT)
Phase 3: Features (Moves → Combos → Stats)
Phase 4: Full migration
```

**Rationale:** Big bang rewrite is too risky. Each feature validates the pipeline.

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|---|---|---|
| cljd toolchain unstable | Build breaks | Pin cljd version, have fallback |
| No IDE support | Debugging hard | Generate .dart for inspection |
| Performance | UI lag from atom watchers | Profile, optimize bindings |
| Ecosystem gaps | Missing packages | Write interop manually |
| Team learning curve | Slow velocity | Document + examples |

## Migration Plan

1. **Setup** (Day 1):
   - Add cljd to pubspec.yaml
   - Create `lib/clojuredart/` directory
   - Verify empty compilation works

2. **Core** (Day 2-3):
   - Create `hiccup.flutter` namespace
   - Implement basic widgets (Text, Button, Column, Row)
   - Test in isolation

3. **State** (Day 4-5):
   - Implement atom + watcher system
   - Add CRDT primitives
   - Connect to Flutter state

4. **Feature Migration** (Week 2+):
   - Migrate Moves catalog first
   - Then Combos
   - Then Stats/Review

## Open Questions

1. **How to handle video_player interop?** - Need to call Flutter VideoPlayer from ClojureDart
2. **Drift integration?** - Keep as-is or rewrite? Decision: Keep Drift, call from ClojureDart
3. **Supabase client?** - Use existing Dart SDK, wrap in Clojure namespace