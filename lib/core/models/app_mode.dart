enum AppMode {
  anki,
  party;

  // Fresh installs (absent key) default to party; a persisted 'anki' is honoured
  // explicitly so an existing user's stored choice is never overridden.
  static AppMode fromString(final String? value) => switch (value) {
        'anki' => AppMode.anki,
        _ => AppMode.party,
      };

  String get displayName => switch (this) {
        AppMode.anki => 'Anki',
        AppMode.party => 'Party',
      };
}
