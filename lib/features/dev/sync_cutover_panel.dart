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
import '../../core/services/appwrite_auth_providers.dart';
import '../../core/services/settings_service.dart' show sharedPreferencesProvider;
import '../../core/services/sync_service.dart';

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
