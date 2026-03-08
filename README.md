# Breakdex-Flutter

Breakdex is a pocket video database for dance moves, combos, and spaced-repetition review. The app combines a move library, combo builder, video editing, deck-based practice, and review analytics in one Flutter app with native iOS bridges for media workflows.

## Product Surface

- `Arsenal` stores atomic moves and combo sequences with category semantics intact.
- `Review` supports state-based sessions and deck-based sessions with per-card progression.
- `Stats` tracks card counts, response quality, timeline history, and retention.
- `Settings` controls viewing mode, sync, and presentation options.

## Screenshots

### Arsenal

![Arsenal](e2e-screenshots/01-arsenal-tab.png)

### Review Prescreen

![Review Prescreen](e2e-screenshots/review-prescreen.png)

### Deck Review

![Deck Review](e2e-screenshots/review-deck-current.png)

### Review Completion

![Review Completion](e2e-screenshots/review-completion.png)

### Stats

![Stats](e2e-screenshots/03-stats-tab.png)

## Run

```bash
flutter pub get
flutter run
```

For release mode on a connected device:

```bash
flutter run --release -d <device-id>
```

## Verification

```bash
flutter analyze
flutter build ios --simulator
maestro test --include-tags=review .maestro/
```
