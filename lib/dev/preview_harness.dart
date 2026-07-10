import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/database.dart';
import '../core/design/theme.dart';
import '../core/providers.dart';
import '../core/services/settings_service.dart';
import '../shared/widgets/app_loader.dart';
import 'preview_db.dart';

/// Shared widget-preview harness for the whole app.
///
/// Full screens depend on Riverpod, a Drift database and SharedPreferences.
/// This harness stands up an **in-memory, seeded** copy of all three so any
/// screen can be dropped into a `@Preview` and rendered in isolation — no
/// device, no Firebase, no real files.
///
/// Use it as the `wrapper:` on a `@Preview` in a `*_previews.dart` file next to
/// the screen you're iterating on:
///
/// ```dart
/// @Preview(name: 'Settings', wrapper: wrapLight)
/// Widget settingsPreview() => const SettingsScreen();
/// ```
///
/// Pick [wrapLight] or [wrapDark] to preview either theme. The seeded database
/// is shared across every preview, so the sample data below is the same
/// everywhere. The known seeded ids are exported as [PreviewSeed] for screens
/// that take a `moveId` / `comboId` / `categoryName` constructor argument.
///
/// The wrappers are top-level functions (not static methods): the widget-preview
/// code generator references a `wrapper:` as a top-level tear-off, so a
/// `Class.staticMethod` form generates `Undefined name` errors in the scaffold.
Widget wrapLight(final Widget child) =>
    _PreviewHost(themeMode: ThemeMode.light, child: child);

/// Wraps [child] in the seeded app environment with the dark theme.
Widget wrapDark(final Widget child) =>
    _PreviewHost(themeMode: ThemeMode.dark, child: child);

/// Stable identifiers for the seeded sample data, for screens that need an
/// argument (e.g. `MoveDetailScreen(moveId: PreviewSeed.moveId)`).
abstract final class PreviewSeed {
  static const moveId = 'preview-move-1';
  static const comboId = 'preview-combo-1';
  static const labId = 'preview-lab-1';
  static const category = 'footwork';
  static const videoPath = '/preview/sample.mp4';
}

class _Backend {
  _Backend(this.db, this.prefs);
  final AppDatabase db;
  final SharedPreferences prefs;
}

// Built once and reused across every preview render in the session.
Future<_Backend>? _backendFuture;

Future<_Backend> _backend() => _backendFuture ??= _buildBackend();

Future<_Backend> _buildBackend() async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(await openPreviewExecutor());
  await _seed(db);
  return _Backend(db, prefs);
}

Future<void> _seed(final AppDatabase db) async {
  // Moves — varied learning states and categories so list/grid/state-pill UI
  // shows the full range.
  const moves = <(String, String, String, String)>[
    ('preview-move-1', 'Six Step', 'MASTERY', 'footwork'),
    ('preview-move-2', 'Baby Freeze', 'LEARNING', 'freeze'),
    ('preview-move-3', 'Windmill', 'LEARNING', 'power'),
    ('preview-move-4', 'CC to Coffee Grind', 'NEW', 'footwork'),
    ('preview-move-5', 'Air Flare', 'NEW', 'power'),
  ];
  for (final (id, name, state, category) in moves) {
    await db.into(db.moves).insert(
          MovesCompanion.insert(
            id: id,
            name: name,
            learningState: Value(state),
            category: Value(category),
            notes: Value('Sample notes for $name.'),
          ),
        );
  }

  // Combos + their ordered steps.
  await db.into(db.combos).insert(
        CombosCompanion.insert(
          id: 'preview-combo-1',
          name: 'Opening Flow',
          status: const Value('attempting'),
          notes: const Value('Toprock into a six step exit.'),
        ),
      );
  await db.into(db.combos).insert(
        CombosCompanion.insert(
          id: 'preview-combo-2',
          name: 'Power Round',
          status: const Value('landed'),
        ),
      );
  const steps = <(String, int, String, String)>[
    ('cm-1', 0, 'preview-combo-1', 'preview-move-1'),
    ('cm-2', 1, 'preview-combo-1', 'preview-move-2'),
    ('cm-3', 2, 'preview-combo-1', 'preview-move-4'),
    ('cm-4', 0, 'preview-combo-2', 'preview-move-3'),
    ('cm-5', 1, 'preview-combo-2', 'preview-move-5'),
  ];
  for (final (id, index, comboId, moveId) in steps) {
    await db.into(db.comboMoves).insert(
          ComboMovesCompanion.insert(
            id: id,
            sequenceIndex: index,
            comboId: comboId,
            moveId: moveId,
          ),
        );
  }

  // A lab so Lab screens have content.
  await db.into(db.labs).insert(
        LabsCompanion.insert(
          id: 'preview-lab-1',
          name: 'Combo Lab',
          status: const Value('attempting'),
          notes: const Value('Workshopping the opening flow.'),
        ),
      );

  // A few reviews so stats/progress screens render non-empty.
  const reviews = <(String, String, String, String)>[
    ('rv-1', 'good', 'session', 'preview-move-1'),
    ('rv-2', 'easy', 'session', 'preview-move-2'),
    ('rv-3', 'hard', 'schedule', 'preview-move-3'),
  ];
  for (final (id, rating, type, moveId) in reviews) {
    await db.into(db.reviews).insert(
          ReviewsCompanion.insert(
            id: id,
            rating: rating,
            reviewType: type,
            moveId: Value(moveId),
          ),
        );
  }
}

class _PreviewHost extends StatefulWidget {
  const _PreviewHost({required this.themeMode, required this.child});

  final ThemeMode themeMode;
  final Widget child;

  @override
  State<_PreviewHost> createState() => _PreviewHostState();
}

class _PreviewHostState extends State<_PreviewHost> {
  late final Future<_Backend> _future = _backend();

  @override
  Widget build(final BuildContext context) {
    return FutureBuilder<_Backend>(
      future: _future,
      builder: (final context, final snapshot) {
        // While loading/erroring, render a bare MaterialApp (no ProviderScope).
        // ProviderScope is only mounted once we have the final, fixed set of
        // overrides — Riverpod forbids changing the override count after mount.
        Widget shell(final Widget home) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: widget.themeMode,
              home: home,
            );

        if (snapshot.hasError) {
          return shell(
            Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Preview harness failed:\n${snapshot.error}'),
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return shell(
            const Scaffold(body: Center(child: AppLoader())),
          );
        }
        final backend = snapshot.data!;
        return ProviderScope(
          overrides: <Override>[
            databaseProvider.overrideWithValue(backend.db),
            sharedPreferencesProvider.overrideWithValue(backend.prefs),
          ],
          child: shell(widget.child),
        );
      },
    );
  }
}
