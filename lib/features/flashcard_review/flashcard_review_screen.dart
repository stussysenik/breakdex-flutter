import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/models/reviewable_item.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/features/flashcard_review/drill_session_screen.dart';
import 'package:breakdex/features/flashcard_review/providers/review_providers.dart';
import 'package:breakdex/features/flashcard_review/widgets/mastery_prescreen.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';
import 'package:breakdex/shared/widgets/app_segmented_control.dart';

/// The Drill tab: pick what to practise, then hand the viewport over.
///
/// Two surfaces, one route — the prescreen is a screen on the frame, and the
/// session is a frameless surface that lives in its own file
/// ([DrillSessionScreen]). The branch is a *provider*, not a route, so ending a
/// session unmounts the session widget and its state goes with it; nothing here
/// has to be reset by hand.
class FlashcardReviewScreen extends ConsumerWidget {
  const FlashcardReviewScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (ref.watch(reviewSessionActiveProvider)) {
      return const DrillSessionScreen();
    }

    final l10n = AppLocalizations.of(context);
    final reviewMode = ref.watch(reviewModeProvider);

    return AppScreen.fill(
      title: l10n.revDrill,
      pinned: AppSegmentedControl<ReviewMode>(
        items: [
          AppSegmentedControlItem(
            value: ReviewMode.review,
            icon: AppIcon.grid.resolve(context),
            label: l10n.revReviewSegment,
          ),
          AppSegmentedControlItem(
            value: ReviewMode.deck,
            icon: AppIcon.study.resolve(context),
            label: l10n.revDeckSegment,
          ),
        ],
        selectedValue: reviewMode,
        onChanged: (final mode) =>
            ref.read(reviewModeProvider.notifier).set(mode),
      ),
      child: MasteryPrescreen(
        source: reviewMode == ReviewMode.deck
            ? ReviewSessionSource.deck
            : ReviewSessionSource.stateBased,
      ),
    );
  }
}
