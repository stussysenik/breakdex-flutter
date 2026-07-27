# Domain Source Map (task 3.1)

Survey of the current tree, mapped to target domains. **Nothing is moved by this
artifact.** It is the input to the mechanical batches in tasks 3.2–3.5, and it answers
the umbrella design's open question about final domain folder names.

Measured at commit `0f41657`: 417 hand-written `.dart` files (+25 generated) under
`lib/`, split `lib/core` 258 · `lib/features` 145 · `lib/shared` 31 · `lib/dev` 4.
Fan-in counts below are `grep -rl` over `lib` **and** `test`.

## Blocker found: `lib/` uses relative imports almost exclusively

Import census of `lib/` (2607 `import` lines):

| Kind | Count |
| --- | --- |
| `dart:` | 139 |
| `package:` third-party | 786 |
| `package:breakdex/…` | **4** |
| relative (`'x.dart'`, `'../x.dart'`) | **1678** |

`test/` is the inverse: 604 `package:breakdex/…` vs 65 relative.

This decides the mechanics of every batch. With relative imports, moving one folder
rewrites edges in *both* directions — the moved files' own imports **and** every sibling
that reached them by `../`. With `package:` imports, a move is a single path find-replace,
mechanically verifiable by grep.

**Therefore task 3.2's first slice must be import normalization, not a folder move:**

1. Add `always_use_package_imports: true` to `analysis_options.yaml` (not currently set;
   `flutter_lints` does not enable it).
2. `dart fix --apply` — the rule ships a fix producer, so this is generated, not hand-typed.
3. `flutter analyze` 0/0 and the full `flutter test` suite green in the same commit.

That commit changes 1678 import lines and zero behavior. It is large in LOC and trivial in
risk, and it makes batches 2–8 small and greppable. Doing the moves first would invert
that trade. **Owner call:** this is a new prerequisite task the umbrella did not name —
recommended as `3.2.0` ahead of the existing 3.2.

## Target domains — recommendation

The umbrella design named eight buckets with two unresolved names. Resolution:

| Question | Ruling proposed here | Why |
| --- | --- | --- |
| `sets` vs `labs` | **`sets`** is the domain; Lab screens are its UI surface | The locked atom model is move → combo → set. `lab` is the surface name, not the atom. Milestones/achievements/aura are progression, not sets — they go to `progress`. |
| `backup` vs `media` | **both**: `media` owns bytes + playback, `backup` owns durability | They are genuinely different concerns with different failure modes. `media` = import/edit/play/thumbnail. `backup` = canonical paths, manifest, cloud fan-out, orphan restore, janitor. Folding them hides the durability seam that this product's data-safety posture rests on. |
| `kernel` scope | **pure primitives + platform seams only** | `Machine<S,E>`, `Failure`, `AppClock`, the `io.dart`/`native_*` conditional-import seams, and remote config/entitlement. No domain services. If a file knows what a "move" is, it is not kernel. |

Resulting domain list (10, not 8 — `drill` and `progress` were implicit in `sets/labs`):

`moves` · `combos` · `sets` · `drill` · `progress` · `media` · `backup` · `sync` · `auth` · `kernel` · `ui`

`ui` is the shared-widget + design-token layer, kept separate from `kernel` because it
has a Flutter dependency and `kernel` should stay widget-free.

## The map

### `moves`

| Current path | Notes |
| --- | --- |
| `features/move_list/` (8) | library screen, grid/row cells, date-line format |
| `features/move_detail/` (4) | |
| `features/move_category/` (2) | |
| `features/move_analysis/` (6) | pose/vision analysis surface |
| `features/add/` (2) | move-creation entry screen |
| `features/breakdex/` (2) | dex browse surface over moves |
| `core/state_machines/move_creation/`, `move_detail/` (5) | |
| `core/services/move_creation_service.dart`, `entity_names_service.dart`, `categories_service.dart` | |
| `core/database/tables/moves.dart`, `daos/moves_dao.dart` | |
| `core/models/move_creation.dart`, `move_archive_reason.dart`, `move_detail_caption.dart`, `library_*.dart` (5) | `library_*` are move-list projections |

### `combos`

| Current path | Notes |
| --- | --- |
| `features/combos/` (3), `features/combo_detail/` (6), `features/create_combo/` (2) | |
| `core/state_machines/combo_list/`, `combo_detail/` (5) | |
| `core/database/tables/combos.dart`, `combo_moves.dart`, `combo_plans.dart`, `combo_note_entries.dart` + their DAOs | |
| `core/models/combo_stats.dart` | |
| `shared/widgets/combo_step_line.dart`, `beat_grid.dart` | beat grid rides `count` on the atoms |

### `sets`

| Current path | Notes |
| --- | --- |
| `features/lab/` — `set_builder.dart`, `lab_screen`, `lab_detail_screen` | Lab is the set-authoring surface |
| `core/database/tables/sets.dart`, `set_items.dart`, `labs.dart`, `lab_moves.dart`, `lab_entries.dart` + DAOs | `labs` tables are the legacy name for the same atom — do **not** rename tables; only the Dart folder moves |
| `core/services/deck_service.dart`, `core/database/tables/decks.dart`, `deck_moves.dart` | decks are a set variant used by review |

### `drill`

| Current path | Notes |
| --- | --- |
| `features/flashcard_review/` (20) | |
| `features/battle/` (7), `features/party/` (5) | party still carries the 2 quarantined flaky tests |
| `core/services/fsrs_service.dart`, `fsrs_migration_service.dart`, `manual_review_state_service.dart`, `reviewable_naming_service.dart` | |
| `core/database/tables/reviews.dart`, `fsrs_cards.dart`, `battle_results.dart` + DAOs | |
| `core/models/reviewable_item.dart` (fan-in 16), `learning_state.dart`, `fsrs_settings.dart`, `review_card_display_settings.dart` | |

### `progress`

| Current path | Notes |
| --- | --- |
| `features/stats/` (10) | |
| `features/flow/` (11) | aura graph + transitions |
| `core/services/achievement_service.dart`, `stats_export_service.dart` | `achievementServiceProvider` is currently misplaced under `features/lab/providers/` — CLAUDE.md's colocation rule fixes it here |
| `core/database/tables/achievements.dart`, `milestones.dart`, `aura_links.dart`, `aura_presets.dart` + DAOs | |

### `media`

| Current path | Notes |
| --- | --- |
| `features/video_editor/` (9), `features/instax_viewer/` (3) | |
| `core/services/video_service.dart` (fan-in 12), `video_path_resolver.dart`, `video_storage_gate.dart`, `media_playback_coordinator.dart`, `thumbnail_load_coordinator.dart`, `native_video_*.dart` (3), `native_share_sheet.dart`, `native_bridge.dart` | |
| `core/services/swing_detector.dart`, `vision_ml.dart`, `scene_3d.dart` | analysis/render over media bytes |
| `core/models/pose_frame.dart`, `pose_joint.dart` | |
| `shared/widgets/video_player_widget.dart`, `video_picker_sheet.dart`, `metadata_video_picker_sheet.dart`, `quick_video_viewer.dart`, `move_photos_section.dart`, `scene_3d_view.dart` | |

### `backup`

| Current path | Notes |
| --- | --- |
| `core/services/canonical_folder_service.dart`, `canonical_import_gate.dart`, `canonical_reconcile_service.dart`, `app_storage_paths.dart` | |
| `core/services/storage_orchestrator.dart`, `storage_action_machine.dart`, `storage_janitor.dart`, `media_cleanup_service.dart`, `blackbox_service.dart`, `metadata_backup_service.dart`, `database_recovery_service.dart` | |
| `core/services/provenance_service.dart`, `provenance_journal_service.dart`, `provenance_report_service.dart` | |
| `core/sync/` — `asset_*.dart` (4), `cloud_provider*.dart` (2), `gdrive_setup_service.dart`, `icloud_setup_service.dart`, `integrity_verifier.dart`, `local_copy_reconciler.dart`, `manifest_*.dart` (2), `on_demand_downloader.dart`, `orphan_restore_service.dart`, `sandbox_hash_index.dart`, `space_manager.dart`, `safety_guard.dart`, `legacy_asset_migration.dart`, `video_*.dart` (3), `codecs/` | byte-durability half of what today lives under `core/sync` |
| `core/database/tables/asset_copies.dart`, `asset_manifest.dart`, `provenance_events.dart` + DAOs | |
| `core/models/canonical_asset.dart`, `canonical_path.dart`, `provenance_report.dart` | |
| `features/settings/canonical_trash_screen*.dart`, `recently_deleted_screen.dart` | |
| `shared/widgets/provenance_trail_widget.dart`, `source_origin_badge.dart` | |

### `sync`

| Current path | Notes |
| --- | --- |
| `core/services/sync_service.dart`, `hydrate_on_login_providers.dart`, `delete_state_machine.dart`, `import_state_machine.dart` | |
| `core/sync/` — `sync_backend.dart`, `backends/`, `backfill/`, `background_sync_manager.dart`, `network_policy.dart`, `sync_diagnostics.dart`, `tombstone_cleaner.dart`, `providers/` | metadata-sync half of `core/sync` |
| `core/state_machines/sync/` | |
| `core/database/tables/sync_log.dart`, `sync_operations.dart`, `sync_providers.dart` + DAOs | |
| `core/models/sync_progress.dart`; `core/providers/sync_providers.dart` | |
| `features/sync_onboarding/` (1); `features/settings/sync_status_screen*.dart`, `sync_providers_screen.dart` | |
| `shared/widgets/sync_progress_bar.dart` | |

### `auth`

| Current path | Notes |
| --- | --- |
| `features/auth/` (3) | |
| `core/services/auth_service.dart`, `appwrite_auth_service.dart`, `appwrite_account_gateway.dart`, `appwrite_auth_providers.dart`, `legacy_identity_*.dart` (3) | |
| `core/config/appwrite_env.dart` | |

### `kernel`

| Current path | Notes |
| --- | --- |
| `core/state_machines/machine.dart` (fan-in 18) | the framework itself; per-domain machines move to their domains |
| `core/domain/failures/` | |
| `core/utils/` (9) — `app_clock.dart`, `diagnostics.dart`, `filesystem_utils.dart`, `loading_state_machine.dart`, `pid_controller.dart`, `share_sheet.dart`, `stall_detector.dart`, `time_format.dart`, `transfer_rate_estimator.dart` | |
| `core/platform/` (13) — the `io.dart`/`native_*.dart`/`web_support.dart` conditional-import seams | see the "dart:io compiles on web" gotcha; these are degradation seams, not compile enablers |
| `core/config/` — `remote_config*.dart` (3), `entitlement*.dart` (2), `update_gate*.dart` (2), `checkout.dart`, `appwrite_remote_config_source.dart`, `widgets/` | |
| `core/services/connectivity_service.dart`, `boot_coordinator.dart`, `settings_service.dart`, `view_names_service.dart`, `deep_link_resolver.dart`, `automation_fixture_service.dart` | app-level services with no domain knowledge |
| `core/app_metadata.dart`, `core/web/`, `firebase_options.dart` | |
| `core/state_machines/recovery/` | `recovery_bloc` — the one Bloc left; not `Machine<S,E>` |

### `ui`

| Current path | Notes |
| --- | --- |
| `core/design/` (5, 1027 LOC) — `colors`, `depth`, `spacing`, `theme` (fan-in 39), `typography` | must keep conforming to `docs/design/TOKENS.md` |
| `core/navigation/` (2) — `app_router.dart` (340 LOC), `app_route_observer.dart` | |
| `shared/widgets/` minus the domain-specific widgets listed above | ~15 genuinely shared: `action_tile`, `app_loader`, `app_segmented_control`, `bottom_nav_shell`, `button_previews`, `celebration_overlay`, `color_setting_tile`, `debug_label`, `loading_state_widget`, `logs_section`, `notes_section`, `pressable`, `primary_button`, `secondary_button`, `settings_gear_button`, `settings_list_group`, `shake_detector`, `state_pill`, `timeline_node`, `wip_badge` |
| `core/providers/theme_providers.dart`, `learning_state_label_providers.dart`, `review_card_display_providers.dart`, `video_playback_preferences_providers.dart` | colocate each with its service per CLAUDE.md |
| `features/settings/` remainder (~14 direct) | settings shell; sub-screens follow their domains |
| `features/dev/`, `lib/dev/` (5) | dev-only surfaces; stay out of the domain tree |

## Cross-cutting files that do not move yet

Four files are the restructure's real risk, all with high fan-in. They are **excluded
from batches 3.2–3.4** and handled last:

| File | LOC | Fan-in | Why it is hard |
| --- | --- | --- | --- |
| `core/database/database.dart` | — (+71 in tree) | **208** | single `AppDatabase` over 26 tables; splitting it per domain means splitting Drift codegen. Keep one database, move only DAOs — and DAOs only after their domain lands. |
| `core/providers.dart` | 673 | **115** | the monolith CLAUDE.md already deprecates. Drain it by colocation as each domain moves; keep it as a compatibility re-export (task 3.3) until fan-in reaches 0, then delete (task 3.5). |
| `main.dart` | 606 | — | boot wiring touching every domain; rewrite once at the end, not per batch. |
| `core/data/repositories.dart` + `drift_repositories.dart` + `sync_aware_repositories.dart` | 570 | 10 | the 3-layer abstract→drift→sync-aware decorator stack spans all domains. Reached only by relative `../data/repositories.dart` imports from `core/services/*` and `core/sync/*`, so it is invisible to a `package:`-path grep until normalization lands. Split per domain only after both `sync` and the domain have landed. |

Other fan-in worth knowing: `core/design/theme.dart` 50 · `core/state_machines/machine.dart`
23 · `core/platform/` 14 · `core/models/reviewable_item.dart` 11.

## Batch order for 3.2–3.4

Ordered by fan-in ascending, so each batch's imports are mechanically fixable:

0. **Import normalization** (see the blocker section above) — must land first.
1. **`kernel/platform` + `kernel/utils`** — leaf-most, no domain knowledge. This is 3.2's
   first folder move: `core/platform/` imports nothing but `dart:`, `package:flutter`,
   three pub packages, and its own siblings (verified), so the move is 14 inbound import
   lines and zero outbound risk.
2. `ui` design tokens + genuinely-shared widgets.
3. `auth` (13 files, isolated behind `auth_service`).
4. `progress`, then `sets`, then `drill` — leaf feature surfaces.
5. `media`, then `backup` — the `core/sync` split is the one judgement call here; do it
   as a single commit that only moves files, so a revert is clean.
6. `sync`.
7. `moves`, then `combos` — highest fan-in, last.
8. `main.dart` rewire, then compat-export removal (3.5).

Every batch: files moved + imports updated only. Zero behavior edits, `./verify.sh` green
in the same commit, `tasks.md` ticked in the same commit.

## NOT PROVEN by this artifact

That the proposed folder names are owner-approved; that any file listed here compiles in
its new location; that `core/sync`'s media/metadata split has no hidden circular
dependency. This is a map, not a move.
