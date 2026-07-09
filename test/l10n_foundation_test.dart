import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 5.1 — proves the localization pipeline is wired and that localized
/// strings compose the user's parametric nouns (entityNamesProvider) via
/// placeholders, which is the contract Phase 5.2 string extraction relies on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('English is a supported locale and the delegate loads it', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
    expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
  });

  test('appTitle resolves', () {
    expect(l10n.appTitle, 'Breakdex');
  });

  test('emptyLibraryTitle composes the caller-supplied parametric plural noun', () {
    expect(l10n.emptyLibraryTitle('Moves'), 'No Moves yet');
    // A renamed data-bank flows straight through the same localized template.
    expect(l10n.emptyLibraryTitle('Freezes'), 'No Freezes yet');
  });

  test('itemCount honors grammatical number and the parametric nouns', () {
    expect(l10n.itemCount(0, 'Move', 'Moves'), 'No Moves');
    expect(l10n.itemCount(1, 'Move', 'Moves'), '1 Move');
    expect(l10n.itemCount(3, 'Move', 'Moves'), '3 Moves');
    // Custom singular/plural nouns compose identically.
    expect(l10n.itemCount(1, 'Combo', 'Combos'), '1 Combo');
    expect(l10n.itemCount(5, 'Combo', 'Combos'), '5 Combos');
  });
}
