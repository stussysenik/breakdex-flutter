import 'package:breakdex/core/design/icons.dart';
import 'package:flutter_test/flutter_test.dart';

/// Find a rendered [AppIconView] by its semantic [AppIcon].
///
/// Widget tests must assert the *semantic* icon, never the `IconData` a
/// particular pack happens to resolve it to — otherwise swapping packs
/// (material ↔ lucide) reds the suite without any behavior changing.
Finder findAppIcon(final AppIcon icon) => find.byWidgetPredicate(
  (final widget) => widget is AppIconView && widget.icon == icon,
  description: 'AppIconView(${icon.name})',
);
