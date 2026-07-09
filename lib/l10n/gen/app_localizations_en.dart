// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Breakdex';

  @override
  String emptyLibraryTitle(String itemPlural) {
    return 'No $itemPlural yet';
  }

  @override
  String itemCount(int count, String itemSingular, String itemPlural) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count $itemPlural',
      one: '1 $itemSingular',
      zero: 'No $itemPlural',
    );
    return '$_temp0';
  }
}
