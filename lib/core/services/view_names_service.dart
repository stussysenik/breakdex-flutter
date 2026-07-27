import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:breakdex/core/services/settings_service.dart';

const _defaultViewNames = {'list': 'List', 'grid': 'Gallery', 'title': 'Arsenal'};

final viewNamesProvider =
    NotifierProvider<ViewNamesNotifier, Map<String, String>>(
  ViewNamesNotifier.new,
);

class ViewNamesNotifier extends Notifier<Map<String, String>> {
  static const _key = 'view_names';

  @override
  Map<String, String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final json = prefs.getString(_key);
    if (json == null) return Map.from(_defaultViewNames);
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map((final k, final v) => MapEntry(k, v as String));
    } on Object catch (_) {
      return Map.from(_defaultViewNames);
    }
  }

  Future<void> rename(final String key, final String newName) async {
    final updated = Map<String, String>.from(state);
    updated[key] = newName;
    state = updated;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, jsonEncode(updated));
  }
}
