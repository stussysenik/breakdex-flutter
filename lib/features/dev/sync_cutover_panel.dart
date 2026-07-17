/// Dev-only sync-cutover panel (task 2.2, gated by [kDevSyncPanelEnabled]).
///
/// The per-entity dual-write / dual-read cutover prefs (`SyncService` constants)
/// have **no runtime writer** — only tests flip them, so M.4's "flip dual-write
/// → soak → flip dual-read" is unexecutable on a device (design D5). This panel
/// is that missing switch-hand: it reads every cutover pref, shows its persisted
/// value, and flips it live via `SharedPreferences.setBool`. Deliberately dumb —
/// no new state machine, just a settings surface over existing prefs
/// (UI = f(state)). It sources its keys **from `SyncService`** (single source;
/// no duplicated key strings), and a footer names the signed-in user so the
/// operator always knows whose space they are mutating.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart'
    show fullBackfillServiceProvider, syncDiagnosticsProvider, syncServiceProvider;
import '../../core/services/appwrite_auth_providers.dart';
import '../../core/services/settings_service.dart' show sharedPreferencesProvider;
import '../../core/services/sync_service.dart';
import '../../core/sync/backfill/sync_backfill_service.dart'
    show BackfillReport, SyncBackfillService;

/// One cutover entity: a label, the shared dual-**write** pref key (null for
/// `fsrsCards` — it is derived server-side and never pushed, so read-only), and
/// the dual-**read** pref key. Keys come straight from [SyncService] constants.
class _CutoverEntity {
  const _CutoverEntity({required this.label, this.writeKey, required this.readKey});

  final String label;
  final String? writeKey;
  final String readKey;
}

/// The full cutover set, in the runbook's flip order (moves → combos → reviews →
/// fsrs → decks → notes). Paired entities (combos+comboMoves, decks+deckMoves,
/// note-entry pair) share one write + one read switch by design — they cut over
/// together — so each appears once here.
const List<_CutoverEntity> _kCutoverEntities = [
  _CutoverEntity(
    label: 'Moves',
    writeKey: SyncService.movesDualWritePrefKey,
    readKey: SyncService.movesDualReadPrefKey,
  ),
  _CutoverEntity(
    label: 'Combos (+ combo-moves)',
    writeKey: SyncService.combosDualWritePrefKey,
    readKey: SyncService.combosDualReadPrefKey,
  ),
  _CutoverEntity(
    label: 'Reviews',
    writeKey: SyncService.reviewsDualWritePrefKey,
    readKey: SyncService.reviewsDualReadPrefKey,
  ),
  _CutoverEntity(
    label: 'FSRS cards (read-only — derived server-side)',
    readKey: SyncService.fsrsCardsDualReadPrefKey,
  ),
  _CutoverEntity(
    label: 'Decks (+ deck-moves)',
    writeKey: SyncService.decksDualWritePrefKey,
    readKey: SyncService.decksDualReadPrefKey,
  ),
  _CutoverEntity(
    label: 'Note entries',
    writeKey: SyncService.noteEntriesDualWritePrefKey,
    readKey: SyncService.noteEntriesDualReadPrefKey,
  ),
];

class SyncCutoverPanel extends ConsumerStatefulWidget {
  const SyncCutoverPanel({super.key});

  @override
  ConsumerState<SyncCutoverPanel> createState() => _SyncCutoverPanelState();
}

class _SyncCutoverPanelState extends ConsumerState<SyncCutoverPanel> {
  late final SharedPreferences _prefs = ref.read(sharedPreferencesProvider);

  bool _valueOf(final String key) => _prefs.getBool(key) ?? false;

  Future<void> _set(final String key, final bool value) async {
    await _prefs.setBool(key, value);
    if (mounted) setState(() {}); // re-read persisted values into the toggles
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Reactive identity — reflects the live session (UI = f(state)); resolves to
    // null when signed out. The user has already signed in before reaching this
    // dev surface, so this is normally already-resolved.
    final user = ref.watch(currentAppwriteUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Sync cutover (dev)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenEdge),
          children: [
            Text(
              'Flip dual-write, soak, then dual-read — one entity at a time '
              '(runbook order). Flipping a switch back OFF is the instant '
              'rollback to local-only.',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final entity in _kCutoverEntities) ...[
              _EntityCard(
                entity: entity,
                writeValue:
                    entity.writeKey == null ? null : _valueOf(entity.writeKey!),
                readValue: _valueOf(entity.readKey),
                onWrite: entity.writeKey == null
                    ? null
                    : (final v) => _set(entity.writeKey!, v),
                onRead: (final v) => _set(entity.readKey, v),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.sm),
            _BackfillSection(signedIn: user != null),
            const SizedBox(height: AppSpacing.md),
            _HydrateSection(signedIn: user != null),
            const SizedBox(height: AppSpacing.md),
            const _DiagnosticsSection(),
            const SizedBox(height: AppSpacing.md),
            _IdentityFooter(userId: user?.id, email: user?.email),
          ],
        ),
      ),
    );
  }
}

/// One entity's cutover controls: a dual-write switch (absent for read-only
/// entities) and a dual-read switch, each labelled with its exact pref key so
/// the operator can cross-check against `SyncService`.
class _EntityCard extends StatelessWidget {
  const _EntityCard({
    required this.entity,
    required this.writeValue,
    required this.readValue,
    required this.onWrite,
    required this.onRead,
  });

  final _CutoverEntity entity;
  final bool? writeValue;
  final bool readValue;
  final ValueChanged<bool>? onWrite;
  final ValueChanged<bool> onRead;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entity.label,
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (entity.writeKey != null)
            _PrefSwitch(
              title: 'Dual-write',
              prefKey: entity.writeKey!,
              value: writeValue ?? false,
              onChanged: onWrite!,
            ),
          _PrefSwitch(
            title: 'Dual-read',
            prefKey: entity.readKey,
            value: readValue,
            onChanged: onRead,
          ),
        ],
      ),
    );
  }
}

/// A single labelled switch bound to one pref key. Its [ValueKey] is the pref
/// key itself, so a test can flip an exact switch and assert on that exact pref.
class _PrefSwitch extends StatelessWidget {
  const _PrefSwitch({
    required this.title,
    required this.prefKey,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String prefKey;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                prefKey,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Switch(
          key: ValueKey(prefKey),
          value: value,
          activeThumbColor: colorScheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// The takeover trigger (M.3 / rehearsal R2): runs every entity's backfill —
/// the non-destructive local→shadow copy under the signed-in user — and reports
/// per-entity row/batch counts, which IS the M.3 parity evidence. The service
/// is resolved lazily on tap (never at build), and the button is disabled while
/// signed out: a backfill with no session would be rejected server-side anyway
/// (the Functions stamp the trusted user id), so the panel forecloses it.
class _BackfillSection extends ConsumerStatefulWidget {
  const _BackfillSection({required this.signedIn});

  final bool signedIn;

  @override
  ConsumerState<_BackfillSection> createState() => _BackfillSectionState();
}

class _BackfillSectionState extends ConsumerState<_BackfillSection> {
  bool _running = false;
  List<BackfillReport> _reports = const [];
  String? _error;

  /// Runbook order (moves → combos → reviews → decks → notes); structural rows
  /// (combo-moves, deck-moves) ride right after their parent.
  static List<Future<BackfillReport> Function()> _steps(
    final SyncBackfillService service,
  ) => [
        service.backfillMoves,
        service.backfillCombos,
        service.backfillComboMoves,
        service.backfillReviews,
        service.backfillDecks,
        service.backfillDeckMoves,
        service.backfillMoveNoteEntries,
        service.backfillComboNoteEntries,
      ];

  Future<void> _run() async {
    setState(() {
      _running = true;
      _reports = const [];
      _error = null;
    });
    final done = <BackfillReport>[];
    try {
      for (final step in _steps(ref.read(fullBackfillServiceProvider))) {
        done.add(await step());
        if (!mounted) return;
        setState(() => _reports = List.unmodifiable(done));
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backfill (takeover)',
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Copies every local row into the signed-in user\'s backend space '
            '(non-destructive, idempotent — safe to re-run). Row counts below '
            'are the M.3 parity evidence.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            key: const ValueKey('backfill-now'),
            onPressed: widget.signedIn && !_running ? _run : null,
            child: Text(_running ? 'Backfilling…' : 'Backfill now'),
          ),
          if (!widget.signedIn) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sign in first — backfill writes into the signed-in user\'s space.',
              style: AppTypography.caption.copyWith(color: colorScheme.secondary),
            ),
          ],
          for (final report in _reports) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${report.entityType.name}: ${report.recordCount} rows · '
              '${report.batchCount} batches',
              key: ValueKey('backfill-report-${report.entityType.name}'),
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Failed: $_error',
              key: const ValueKey('backfill-error'),
              style: AppTypography.bodySmall.copyWith(color: colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

/// The inbound mirror of [_BackfillSection] (M.6 / rehearsal R-pull): force-pulls
/// every entity from the backend into local Drift via
/// [SyncService.hydrateAllFromBackend] — bypassing the dual-read kill-switches —
/// and reports per-entity applied/failed. This is the debug hand for the same
/// hydration that fires automatically on login; on a fresh device (empty local
/// db) `applied` == the row counts the backend holds. Disabled while signed out.
class _HydrateSection extends ConsumerStatefulWidget {
  const _HydrateSection({required this.signedIn});

  final bool signedIn;

  @override
  ConsumerState<_HydrateSection> createState() => _HydrateSectionState();
}

class _HydrateSectionState extends ConsumerState<_HydrateSection> {
  bool _running = false;
  List<({String label, int applied, int failed})> _reports = const [];
  String? _error;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _reports = const [];
      _error = null;
    });
    try {
      final reports =
          await ref.read(syncServiceProvider).hydrateAllFromBackend();
      if (mounted) setState(() => _reports = reports);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hydrate (inbound)',
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pulls every backend row into this device\'s local library '
            '(LWW-merged, safe to re-run). Runs automatically on sign-in — this '
            'button is the manual/debug trigger.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            key: const ValueKey('pull-now'),
            onPressed: widget.signedIn && !_running ? _run : null,
            child: Text(_running ? 'Pulling…' : 'Pull from backend now'),
          ),
          if (!widget.signedIn) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sign in first — hydrate reads the signed-in user\'s space.',
              style: AppTypography.caption.copyWith(color: colorScheme.secondary),
            ),
          ],
          for (final report in _reports) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${report.label}: ${report.applied} applied'
              '${report.failed != 0 ? ' · ${report.failed} failed' : ''}',
              key: ValueKey('pull-report-${report.label}'),
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Failed: $_error',
              key: const ValueKey('pull-error'),
              style: AppTypography.bodySmall.copyWith(color: colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

/// Video-backup ground truth (task 1.5): dumps manifest counts, copies by
/// provider×status, and operations by status — the state behind the sync
/// health verdict, as inspectable evidence. Also debugPrints the report so it
/// lands in captured device logs.
class _DiagnosticsSection extends ConsumerStatefulWidget {
  const _DiagnosticsSection();

  @override
  ConsumerState<_DiagnosticsSection> createState() =>
      _DiagnosticsSectionState();
}

class _DiagnosticsSectionState extends ConsumerState<_DiagnosticsSection> {
  bool _running = false;
  String? _report;
  String? _error;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final report = await ref.read(syncDiagnosticsProvider).dump();
      debugPrint('[SyncDiagnostics]\n$report');
      if (mounted) setState(() => _report = report);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video-backup diagnostics',
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Manifest rows, copies by provider×status, operations by status — '
            'the raw state behind the sync health label. Also printed to the '
            'device log.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            key: const ValueKey('sync-diagnostics-dump'),
            onPressed: _running ? null : _run,
            child: Text(_running ? 'Dumping…' : 'Dump backup state'),
          ),
          if (_report != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _report!,
              key: const ValueKey('sync-diagnostics-report'),
              style: AppTypography.caption.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Failed: $_error',
              key: const ValueKey('sync-diagnostics-error'),
              style: AppTypography.bodySmall.copyWith(color: colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

/// Read-only footer naming whose space the toggles above mutate. `(none)` when
/// no session is live — flipping prefs with no user signed in mutates nothing
/// remote, but the operator should still see that state.
class _IdentityFooter extends StatelessWidget {
  const _IdentityFooter({required this.userId, required this.email});

  final String? userId;
  final String? email;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final who = userId == null ? '(not signed in)' : '$email · $userId';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 18, color: colorScheme.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Mutating space: $who',
              key: const ValueKey('sync-cutover-identity'),
              style: AppTypography.caption.copyWith(color: colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
