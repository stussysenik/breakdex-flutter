enum AppMode {
  anki,
  party;

  static AppMode fromString(final String? value) => switch (value) {
        'party' => AppMode.party,
        _ => AppMode.anki,
      };

  String get displayName => switch (this) {
        AppMode.anki => 'Anki',
        AppMode.party => 'Party',
      };
}
