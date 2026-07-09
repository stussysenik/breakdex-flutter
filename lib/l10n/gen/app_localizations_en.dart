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

  @override
  String get navBreakdex => 'Breakdex';

  @override
  String get navAdd => 'Add';

  @override
  String get navReview => 'Review';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get addContentTitle => 'Add Content';

  @override
  String get fieldNameLabel => 'NAME';

  @override
  String get addNameHint => 'e.g. Flare, Windmill...';

  @override
  String get fieldCategoryLabel => 'CATEGORY';

  @override
  String get fieldBeatCountLabel => 'BEAT COUNT';

  @override
  String get fieldStatusLabel => 'STATUS';

  @override
  String saveEntityButton(String entity) {
    return 'SAVE $entity';
  }

  @override
  String nameTakenError(String name) {
    return '\"$name\" already exists.';
  }

  @override
  String mdAlbumLabel(String filename) {
    return 'Album · $filename';
  }

  @override
  String get mdVideoInfoHeader => 'VIDEO INFO';

  @override
  String get mdMetaRecorded => 'Recorded';

  @override
  String get mdMetaFileSize => 'File Size';

  @override
  String get mdMetaOriginalName => 'Original Name';

  @override
  String get mdMetaDuration => 'Duration';

  @override
  String get mdMetaResolution => 'Resolution';

  @override
  String get mdActionsHeader => 'ACTIONS';

  @override
  String get mdActionEditVideo => 'Edit Video';

  @override
  String get mdActionShareVideo => 'Share Video';

  @override
  String get mdActionRemoveVideo => 'Remove Video';

  @override
  String get mdActionAddVideo => 'Add Video';

  @override
  String mdRenameEntity(String entity) {
    return 'Rename $entity';
  }

  @override
  String mdDuplicateEntity(String entity) {
    return 'Duplicate $entity';
  }

  @override
  String mdDeleteEntity(String entity) {
    return 'Delete $entity';
  }

  @override
  String get mdOverlayDeleting => 'Deleting...';

  @override
  String get mdOverlayRenaming => 'Renaming...';

  @override
  String get mdOverlayUpdatingState => 'Updating state...';

  @override
  String get mdOverlayUpdatingCategory => 'Updating category...';

  @override
  String get mdOverlayUpdatingCount => 'Updating count...';

  @override
  String get mdOverlaySavingNotes => 'Saving notes...';

  @override
  String get mdOverlayUpdatingPhotos => 'Updating photos...';

  @override
  String mdOverlayDuplicatingEntity(String entity) {
    return 'Duplicating $entity...';
  }

  @override
  String mdDeleteUsedInCombos(
    String entity,
    int count,
    String comboPlural,
    String comboName,
  ) {
    return 'This $entity is currently used in $count $comboPlural (e.g. $comboName). Deleting it will permanently delete this $entity, its video, and remove it from those $comboPlural!';
  }

  @override
  String mdDeleteConfirmBody(String entity) {
    return 'This will permanently delete this $entity and its video.';
  }

  @override
  String mdDeleteConfirmTitle(String entity) {
    return 'Delete $entity?';
  }

  @override
  String get mdConfirmDelete => 'Delete';

  @override
  String get mdConfirmOk => 'OK';

  @override
  String get mdConfirmRemove => 'Remove';

  @override
  String get mdErrorTitle => 'Error';

  @override
  String get mdAlbumSyncFailedTitle => 'Album Sync Failed';

  @override
  String get mdRemoveVideoTitle => 'Remove Video?';

  @override
  String mdRemoveVideoBody(String entity) {
    return 'The video will be removed from this $entity but kept in your local storage.';
  }

  @override
  String mdSemanticChangeCategory(String category) {
    return 'Change category from $category';
  }

  @override
  String mdSemanticChangeCount(int count) {
    return 'Change count from $count';
  }

  @override
  String get mdCountsSuffix => ' counts';

  @override
  String get mdVideoMissingTitle => 'Video Missing';

  @override
  String get mdVideoMissingBody => 'The original video couldn\'t be found.';

  @override
  String get mdMissingReRecord => 'Re-record';

  @override
  String get mdMissingImport => 'Import';

  @override
  String get mdCloudTapToDownload => 'Tap to download and play';

  @override
  String get mdCloudStalled => 'Stalled — retrying…';

  @override
  String get mdCloudPreparing => 'Preparing…';

  @override
  String get mdCloudDownloading => 'Downloading…';

  @override
  String get mdCloudStored => 'Video stored in cloud';

  @override
  String get mdCancel => 'Cancel';

  @override
  String mdMoveCategoryTitle(String entity) {
    return '$entity Category';
  }

  @override
  String get mdAddNew => 'Add New';

  @override
  String get mdNewCategoryTitle => 'New Category';

  @override
  String get mdCategoryNameHint => 'Category name';

  @override
  String get mdCategoryColorTile => 'Category color';

  @override
  String get mdCategoryColorDialogTitle => 'Category Color';

  @override
  String get mdCategoryColorDialogSubtitle =>
      'Pick any color for this category label.';

  @override
  String get mdCategoryNameEmpty => 'Category name cannot be empty.';

  @override
  String get mdAdd => 'Add';

  @override
  String get mdUpdateCountTitle => 'Update Count';

  @override
  String get mdSave => 'Save';

  @override
  String get mdNameConflictTitle => 'Name Conflict';

  @override
  String mdNameConflictBody(String name, String move, String combo) {
    return 'The name \"$name\" is already taken by another $move or $combo.';
  }

  @override
  String get mdRenameHint => 'Enter new name';

  @override
  String get revEndSessionTitle => 'End session?';

  @override
  String revReviewedOfCards(int reviewed, int total) {
    return 'You\'ve reviewed $reviewed of $total cards.';
  }

  @override
  String get revContinue => 'Continue';

  @override
  String get revEnd => 'End';

  @override
  String get revDrill => 'Drill';

  @override
  String get revReviewSegment => 'Review';

  @override
  String get revDeckSegment => 'Deck';

  @override
  String revError(String error) {
    return 'Error: $error';
  }

  @override
  String get revWatchClip => 'Watch the clip, then move to assessment.';

  @override
  String get revAssess => 'Assess';

  @override
  String revEntityNoLongerAvailable(String entity) {
    return 'That $entity is no longer available';
  }

  @override
  String get revBack => 'Back';

  @override
  String get revBreakdexEmpty => 'Your breakdex is empty';

  @override
  String revAddFromArsenal(String items) {
    return 'Add $items from the Arsenal tab to start reviewing';
  }

  @override
  String revAddEntity(String entity) {
    return 'Add a $entity';
  }

  @override
  String get revPickDeck => 'Pick a deck to start a review session';

  @override
  String revDeckNoMatchingCards(String deckName) {
    return '\"$deckName\" has no matching cards';
  }

  @override
  String revNoStateCardsAvailable(String stateLabel, String kind) {
    return 'No $stateLabel $kind cards available';
  }

  @override
  String revNoDueCardsAvailable(String kind) {
    return 'No due $kind cards available for this session';
  }

  @override
  String get revBackToReview => 'Back to Review';

  @override
  String get revGreatWork => 'Great work!';

  @override
  String revAllCardsReviewed(int count) {
    return 'All $count cards reviewed';
  }

  @override
  String get revReviewAgain => 'Review Again';

  @override
  String revTierSprouting(String name) {
    return '🌱 $name is sprouting!';
  }

  @override
  String revTierGrowing(String name) {
    return '🌿 $name is growing!';
  }

  @override
  String revTierMastered(String name) {
    return '💎 $name mastered!';
  }

  @override
  String revTierLeveledUp(String name) {
    return '$name leveled up!';
  }

  @override
  String revStep(int step, String name) {
    return 'Step $step · $name';
  }

  @override
  String get revCreateDeck => 'Create Deck';

  @override
  String get revEditDeck => 'Edit Deck';

  @override
  String get revDeckNameHint => 'Deck name';

  @override
  String get revSmart => 'Smart';

  @override
  String get revManual => 'Manual';

  @override
  String get revCategories => 'Categories';

  @override
  String get revCardStates => 'Card States';

  @override
  String get revDueOnly => 'Due only';

  @override
  String revSelectEntity(String items) {
    return 'Select $items';
  }

  @override
  String get revSessionSize => 'Session Size';

  @override
  String get revAll => 'All';

  @override
  String get revSaveChanges => 'Save Changes';

  @override
  String revNoEntityAvailable(String items) {
    return 'No $items available';
  }

  @override
  String get revUpcomingSchedule => 'Upcoming Schedule';

  @override
  String get revAdvancedStats => 'Advanced Algorithm Stats';

  @override
  String get revReviewNow => 'Review Now';

  @override
  String revComboSessionsScheduleOnly(String entity) {
    return '$entity sessions still open in the schedule view only.';
  }

  @override
  String get revStability => 'Stability';

  @override
  String get revDifficulty => 'Difficulty';

  @override
  String get revRetrievability => 'Retrievability';

  @override
  String get revReps => 'Reps';

  @override
  String get revLapses => 'Lapses';

  @override
  String get revInterval => 'Interval';

  @override
  String get revBasicPractice => 'BASIC PRACTICE';

  @override
  String get revBypassingFsrs => 'BYPASSING FSRS (MATH)';

  @override
  String get revFsrsActive => 'FSRS ACTIVE (DUE ONLY)';

  @override
  String get revArsenalEmpty => 'Your Arsenal is empty';

  @override
  String revAddToStartJourney(String items) {
    return 'Add $items to start your practice journey.';
  }

  @override
  String get revCustomDecks => 'CUSTOM DECKS';

  @override
  String get revDeleteDeck => 'Delete Deck';

  @override
  String get revNoCustomDecks => 'No custom decks yet';

  @override
  String get revCreateFirstDeck => 'CREATE FIRST DECK';

  @override
  String revAllEntityBasicPractice(String items) {
    return 'ALL $items (BASIC PRACTICE)';
  }

  @override
  String revEntityBoxes(String items) {
    return '$items BOXES';
  }

  @override
  String get revTotalDue => 'TOTAL DUE';

  @override
  String get revAllBoxesEmpty => 'ALL BOXES EMPTY';

  @override
  String get revStartBasicPractice => 'START BASIC PRACTICE';

  @override
  String get revReviewAllDue => 'REVIEW ALL DUE';

  @override
  String revRate(String rating) {
    return 'Rate $rating';
  }

  @override
  String get revAllCaughtUp => 'All caught up';

  @override
  String revDueTodayCount(int count) {
    return '$count due today';
  }

  @override
  String get revDueTodayHeader => 'Due Today';

  @override
  String revDueDate(String date) {
    return 'Due $date';
  }

  @override
  String revItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get revNoItemsDueToday => 'No items due today';

  @override
  String get revNoItemsDueOnDate => 'No items due on this date';

  @override
  String revAddToStartTraining(String items) {
    return 'Add $items to start training';
  }

  @override
  String revRecordMoves(String items) {
    return 'Record your breakdancing $items, then review with spaced repetition.';
  }

  @override
  String get revGoToArsenal => 'Go to Arsenal';

  @override
  String get revFsrsParameters => 'FSRS Parameters';

  @override
  String get revReset => 'Reset';

  @override
  String get revRetention => 'Retention';

  @override
  String get revRetentionHint =>
      'Higher = more frequent reviews, tighter recall.';

  @override
  String get revMaxInterval => 'Max interval';

  @override
  String get revFuzzing => 'Fuzzing';

  @override
  String get revLearning => 'Learning';

  @override
  String get revRelearning => 'Relearning';

  @override
  String get revForgettingCurve => 'Forgetting curve';

  @override
  String get revForgettingCurveLegend => 't = days elapsed, S = stability';

  @override
  String revMoveState(String entity) {
    return '$entity STATE';
  }

  @override
  String get revCurrent => 'CURRENT';

  @override
  String revErrorLoadingDecks(String error) {
    return 'Error loading decks: $error';
  }
}
