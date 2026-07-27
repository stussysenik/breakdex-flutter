import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:breakdex/core/services/settings_service.dart';

/// The user-facing nouns for the two data-banks (Moves and Combos).
///
/// These are DISPLAY names only. The on-disk video layout (`Moves/`, `Combos/`
/// directories) is a storage contract and is never touched by renaming — see
/// `video_path_resolver.dart`. A user renaming "Moves" to "Tricks" changes what
/// tabs, titles, and dialogs read, not where a single byte lives.
class EntityNames {
  const EntityNames({
    required this.moveSingular,
    required this.movePlural,
    required this.comboSingular,
    required this.comboPlural,
  });

  final String moveSingular;
  final String movePlural;
  final String comboSingular;
  final String comboPlural;

  static const defaults = EntityNames(
    moveSingular: 'Move',
    movePlural: 'Moves',
    comboSingular: 'Combo',
    comboPlural: 'Combos',
  );

  String forField(final EntityNameField field) => switch (field) {
        EntityNameField.moveSingular => moveSingular,
        EntityNameField.movePlural => movePlural,
        EntityNameField.comboSingular => comboSingular,
        EntityNameField.comboPlural => comboPlural,
      };
}

/// The four renameable noun forms. Named so persistence keys are stable.
enum EntityNameField { moveSingular, movePlural, comboSingular, comboPlural }

final entityNamesProvider =
    NotifierProvider<EntityNamesNotifier, EntityNames>(EntityNamesNotifier.new);

class EntityNamesNotifier extends Notifier<EntityNames> {
  static const _key = 'entity_names';

  @override
  EntityNames build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _fromOverrides(_readOverrides(prefs.getString(_key)));
  }

  /// Set a single noun form. An empty/blank value clears the override,
  /// restoring that form's default (self-confirming: change it, see it).
  Future<void> rename(final EntityNameField field, final String value) async {
    final trimmed = value.trim();
    final prefs = ref.read(sharedPreferencesProvider);
    final overrides = _readOverrides(prefs.getString(_key));
    if (trimmed.isEmpty || trimmed == EntityNames.defaults.forField(field)) {
      overrides.remove(field.name);
    } else {
      overrides[field.name] = trimmed;
    }
    state = _fromOverrides(overrides);
    if (overrides.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, jsonEncode(overrides));
    }
  }

  /// Restore every noun to its default (clears all overrides).
  Future<void> reset() async {
    state = EntityNames.defaults;
    await ref.read(sharedPreferencesProvider).remove(_key);
  }

  Map<String, String> _readOverrides(final String? json) {
    if (json == null) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map((final k, final v) => MapEntry(k, v as String));
    } on Object catch (_) {
      return {};
    }
  }

  EntityNames _fromOverrides(final Map<String, String> o) => EntityNames(
        moveSingular:
            o[EntityNameField.moveSingular.name] ??
                EntityNames.defaults.moveSingular,
        movePlural:
            o[EntityNameField.movePlural.name] ??
                EntityNames.defaults.movePlural,
        comboSingular:
            o[EntityNameField.comboSingular.name] ??
                EntityNames.defaults.comboSingular,
        comboPlural:
            o[EntityNameField.comboPlural.name] ??
                EntityNames.defaults.comboPlural,
      );
}
