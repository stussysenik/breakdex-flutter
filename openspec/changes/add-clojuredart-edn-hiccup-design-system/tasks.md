## 1. Setup & Infrastructure

- [ ] 1.1 Add `cljd: ^1.0.0` to pubspec.yaml dev_dependencies
- [ ] 1.2 Create `lib/clojuredart/` directory structure
- [ ] 1.3 Verify cljd is installed: `cljd --version`
- [ ] 1.4 Create minimal empty namespace and verify it compiles
- [ ] 1.5 Configure build.yaml to run cljd before dart compile

## 2. Core Widgets (Hiccup)

- [ ] 2.1 Implement `hiccup.flutter` namespace with widget factory
- [ ] 2.2 Create `text` widget: `[:text "content"]` → `Text("content")`
- [ ] 2.3 Create `elevated-button` widget with onPressed
- [ ] 2.4 Create `column` and `row` layout widgets
- [ ] 2.5 Create `scaffold`, `appbar`, `center` wrappers
- [ ] 2.6 Add style mapping (keywords → Flutter properties)
- [ ] 2.7 Test widget compilation in isolation

## 3. State (DOP Atoms)

- [ ] 3.1 Implement `dop.atom` namespace
- [ ] 3.2 Create `defatom` macro for state definitions
- [ ] 3.3 Implement `swap!` and `reset!` operations
- [ ] 3.4 Add basic watcher system
- [ ] 3.5 Connect atoms to Flutter setState
- [ ] 3.6 Test atom state changes trigger UI rebuilds

## 4. Reactive Flow (FRP)

- [ ] 4.1 Extend watcher system with `:ui` key
- [ ] 4.2 Implement batch updates (transaction)
- [ ] 4.3 Add derived/select atoms (computed state)
- [ ] 4.4 Verify single rebuild for batch updates
- [ ] 4.5 Test unidirectional data flow

## 5. CRDT Sync

- [ ] 5.1 Implement `crdt.lww-register` namespace
- [ ] 5.2 Create `LWWRegister` record with timestamp
- [ ] 5.3 Implement `merge` protocol
- [ ] 5.4 Add offline storage for pending changes
- [ ] 5.5 Implement sync queue to Supabase
- [ ] 5.6 Test merge behavior with concurrent edits

## 6. Code Generation (Macros)

- [ ] 6.1 Implement `defmodel` macro for data models
- [ ] 6.2 Implement `defwidget` macro for reusable widgets
- [ ] 6.3 Add JSON serialization derive macro
- [ ] 6.4 Implement `inject` macro for DI
- [ ] 6.5 Test macros generate correct code

## 7. Feature Migration

- [ ] 7.1 Migrate Moves catalog (lib/features/move_list/) to ClojureDart
- [ ] 7.2 Migrate Move detail screen
- [ ] 7.3 Migrate Combos feature
- [ ] 7.4 Migrate Stats feature
- [ ] 7.5 Migrate Flashcard review system

## 8. Integration & Polish

- [ ] 8.1 Connect existing Drift database via interop
- [ ] 8.2 Wrap Supabase client for ClojureDart
- [ ] 8.3 Add video_player interop
- [ ] 8.4 Run full Flutter build verification
- [ ] 8.5 Test APK generation works
- [ ] 8.6 Document forkable stack setup

## 9. Cleanup

- [ ] 9.1 Remove old Dart widget files (after migration)
- [ ] 9.2 Verify no .dart files remain in migrated features
- [ ] 9.3 Archive old design system code
- [ ] 9.4 Run final build test