# Spec: Breakdex Web Workbench (Production)

## Objective
Transition from the read-only prototype (`web-mirror`) to a production-grade Web Workbench. This is fundamentally a different application from the mobile app—it is an **admin/utility workspace** for the breakdancing ecosystem. 

It provides an Obsidian/Notion-style tiled canvas for heavy data manipulation, bulk editing, planning (Labs/Combos), and visualizing the move graph (Aura Links). It retains the pristine, dark, spacing-heavy design language of the prototype but brings in production power.

## Core Assumptions & Decisions
1. **Never Delete the Prototype:** We will keep `web-mirror` around for reference.
2. **The Tech Stack:** 
   - **UI:** Flutter Web (CanvasKit/Skia) to effortlessly achieve the complex tiling/split-screen routing while reusing our existing `lib/core/design`.
   - **Backend:** **Supabase** (as stated in `TECHSTACK.md`). We will use PostgreSQL + Row Level Security for production sync, dropping the Firebase test-bed.
   - **Local State:** `drift` + `sqlite3_wasm` (Offline-first. The web app works immediately and syncs in the background).
   - **Rust/Wasm:** Reserved for heavy processing tasks (e.g., local video thumbnailing in browser, fast path-finding algorithms for the flow graph).
3. **The UX Paradigm:** "Atomic Stacking". A multi-pane layout where the user can split the screen (e.g., Video on left, bulk tag editor in middle, Flow graph on right).
4. **Templating:** "Blanks" (Lab templates) where users can create practice sessions that are filled with content later.

## Commands
*To be run from the root or workbench directory once scaffolded:*
- **Dev:** `flutter run -d chrome --web-renderer canvaskit`
- **Build:** `flutter build web --web-renderer canvaskit --release`
- **Test:** `flutter test`

## Project Structure
To keep the mobile app lean while sharing the core logic, we will introduce a modular approach to the current repo:
```text
lib/
 ├── core/          → Shared domain, database (Drift), and sync logic (Supabase)
 ├── shared/        → Shared design system, widgets, theme
 ├── features/      → Mobile-specific feature modules
 └── workbench/     → WEB-SPECIFIC: The admin/tiled application shell
      ├── shell/    → Tiled window manager / Pane system
      ├── bulk/     → Bulk metadata editors
      └── graph/    → High-performance node/edge visualizers
```

## Code Style
- **Data-Oriented:** UI must be a pure function of state. Use Riverpod for state.
- **Strict Typing:** No implicit dynamic.
- **Example (Pane Routing):**
```dart
class WorkbenchShell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panes = ref.watch(activePanesProvider);
    return SplitView(
      children: panes.map((pane) => PaneContainer(child: pane.buildWidget())).toList(),
    );
  }
}
```

## Testing Strategy
- **Unit Tests:** All Rust/Wasm interop functions must have tests. All Drift sync logic must be unit tested.
- **Widget Tests:** Test the drag-and-drop and pane-splitting interactions.
- **E2E:** Maestro doesn't cover web as easily, so we will use Flutter Integration Tests for the web critical paths (login, open pane, edit move, sync).

## Boundaries
- **Always do:** Maintain the existing design system (`AppColors.darkBg`, etc.). Ensure offline-first capabilities (write to local DB first, then sync).
- **Ask first:** Before introducing new cloud providers. Before changing the global Drift schema (must ensure mobile doesn't break).
- **Never do:** Delete the `web-mirror` directory. Block the main thread with heavy computations (use Web Workers or Rust/Wasm).

## Success Criteria
1. Web app boots successfully via `flutter run -d chrome`.
2. A user can open a split-pane view (e.g., Move List + Flow Graph).
3. Changes made in the web UI update the local IndexedDB/SQLite via Drift.
4. The UI adheres strictly to the existing dark-mode design system.

## Open Questions
- **Auth Provider:** Supabase Auth or Google Sign-in directly? (We'll default to Supabase Auth to keep the stack unified).
