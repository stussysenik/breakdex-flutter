import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'primary_button.dart';
import 'secondary_button.dart';

// Widget previews for the shared button components. Run `flutter widget-preview
// start` (or open the Widget Preview panel in your IDE) to render these.
//
// The buttons size to `double.infinity` width, so each preview is wrapped in a
// padded, fixed-width box to give them bounded constraints.

Widget _frame(final Widget child) => Padding(
  padding: const EdgeInsets.all(16),
  child: SizedBox(width: 280, child: child),
);

@Preview(name: 'Primary · enabled', size: Size(320, 90))
Widget primaryButtonEnabled() =>
    _frame(PrimaryButton(label: 'Continue', onPressed: () {}));

@Preview(name: 'Primary · disabled', size: Size(320, 90))
Widget primaryButtonDisabled() =>
    _frame(const PrimaryButton(label: 'Continue', onPressed: null));

@Preview(name: 'Primary · dark', size: Size(320, 90), brightness: Brightness.dark)
Widget primaryButtonDark() =>
    _frame(PrimaryButton(label: 'Continue', onPressed: () {}));

@Preview(name: 'Secondary · enabled', size: Size(320, 90))
Widget secondaryButtonEnabled() =>
    _frame(SecondaryButton(label: 'Skip', onPressed: () {}));

@Preview(name: 'Secondary · dark', size: Size(320, 90), brightness: Brightness.dark)
Widget secondaryButtonDark() =>
    _frame(SecondaryButton(label: 'Skip', onPressed: () {}));
