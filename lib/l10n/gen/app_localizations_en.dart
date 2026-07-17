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

  @override
  String get setBack => 'Back';

  @override
  String get setReset => 'Reset';

  @override
  String get setAdd => 'Add';

  @override
  String get setCancel => 'Cancel';

  @override
  String get setSave => 'Save';

  @override
  String get setOk => 'OK';

  @override
  String setSecondsSuffix(String seconds) {
    return '${seconds}s';
  }

  @override
  String get setSectionPractice => 'Practice & Review';

  @override
  String get setSectionPracticeSubtitle =>
      'Learning engine, view composer, and session controls.';

  @override
  String get setSectionVisuals => 'Visuals & Style';

  @override
  String get setSectionVisualsSubtitle =>
      'Theme, typography, colors, and global labels.';

  @override
  String get setSectionLibrary => 'Library & Data';

  @override
  String get setSectionLibrarySubtitle =>
      'Categories, backups, and photo library access.';

  @override
  String get setPanelAppMode => 'App Mode';

  @override
  String get setPanelLearningEngine => 'Learning Engine';

  @override
  String get setPanelQuietMode => 'Quiet Mode';

  @override
  String get setPanelViewComposer => 'Review View Composer';

  @override
  String get setPanelPartyMode => 'Party Mode';

  @override
  String get setPanelVideoEditor => 'Video Editor';

  @override
  String get setPanelAddFlow => 'Add Flow';

  @override
  String get setPanelStatsTab => 'Stats Tab';

  @override
  String get setPanelAppTheme => 'App Theme';

  @override
  String get setPanelAccessibility => 'Accessibility';

  @override
  String get setPanelTypography => 'Typography';

  @override
  String get setPanelReviewStates => 'Review States';

  @override
  String get setPanelColors => 'Colors';

  @override
  String get setPanelGlobalLabels => 'Global Labels';

  @override
  String get setPanelMoveCategories => 'Move Categories';

  @override
  String get setPanelBackupReset => 'Backup & Reset';

  @override
  String get setPanelPhotoLibrary => 'Photo Library';

  @override
  String get setAccentColorLabel => 'Accent Color';

  @override
  String get setRatingColorsLabel => 'Rating Colors';

  @override
  String get setReviewCardFillLabel => 'Review Card Fill';

  @override
  String setLabelArsenalTitle(String name) {
    return 'Arsenal Title: $name';
  }

  @override
  String setLabelMovesDataBank(String name) {
    return 'Moves data-bank: $name';
  }

  @override
  String setLabelCombosDataBank(String name) {
    return 'Combos data-bank: $name';
  }

  @override
  String get setActionExportStats => 'Export Stats Summary';

  @override
  String get setActionExportJson => 'Export Full JSON Backup';

  @override
  String setExportedRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Exported $count records',
      one: 'Exported 1 record',
    );
    return '$_temp0';
  }

  @override
  String get setActionImportJson => 'Import from JSON';

  @override
  String setActionRecentlyDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recently Deleted ($count)',
      zero: 'Recently Deleted',
    );
    return '$_temp0';
  }

  @override
  String get setActionSystemStatus => 'System Status & Logs';

  @override
  String get setActionClearData => 'Clear All Data';

  @override
  String get setClearTitle => 'Clear All Data?';

  @override
  String get setClearBody =>
      'This permanently deletes all moves, reviews, combos, and battle results. A backup will be created automatically before clearing.';

  @override
  String get setClearConfirmPrompt => 'Type DELETE to confirm:';

  @override
  String get setClearConfirmButton => 'Clear Everything';

  @override
  String setClearBackupSaved(String file) {
    return 'Pre-clear backup saved to $file';
  }

  @override
  String get setImportInvalid => 'Invalid backup file';

  @override
  String get setImportTitle => 'Import Backup';

  @override
  String setImportSummary(
    int moves,
    int reviews,
    int combos,
    int battles,
    String categories,
  ) {
    return 'Found $moves moves, $reviews reviews, $combos combos, $battles battle results$categories.';
  }

  @override
  String setImportSummaryCategories(int count) {
    return ', $count categories';
  }

  @override
  String get setImportModeLabel => 'Import mode:';

  @override
  String get setImportModeReplace =>
      'Replace All (overwrite existing, keep extras)';

  @override
  String get setImportModeMerge => 'Merge (skip duplicates, keep everything)';

  @override
  String setImported(int count, String relink) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count records$relink',
      one: 'Imported 1 record$relink',
    );
    return '$_temp0';
  }

  @override
  String setImportedRelink(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' ($count moves need video re-linking)',
      one: ' (1 move needs video re-linking)',
    );
    return '$_temp0';
  }

  @override
  String setImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get setCategoryEdit => 'Edit category';

  @override
  String get setCategoryDelete => 'Delete category';

  @override
  String get setRenameCategoryTitle => 'Rename Category';

  @override
  String get setCategoryNameHint => 'Category name';

  @override
  String get setCategoryColorTile => 'Category color';

  @override
  String get setCategoryColorEditorTitle => 'Category Color';

  @override
  String get setCategoryColorEditorSubtitle =>
      'Pick any color for this category label.';

  @override
  String get setCategoryNameEmpty => 'Category name cannot be empty.';

  @override
  String setCategoryExists(String name) {
    return '\"$name\" already exists.';
  }

  @override
  String get setNewCategoryTitle => 'New Category';

  @override
  String get setCategoryInUseTitle => 'Category In Use';

  @override
  String setCategoryInUseBody(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reassign the $count moves in \"$name\" before deleting it.',
      one: 'Reassign the 1 move in \"$name\" before deleting it.',
    );
    return '$_temp0';
  }

  @override
  String get setRenamePageTitle => 'Rename Page Title';

  @override
  String get setPageTitleHint => 'Page title';

  @override
  String get setRenameDataBankTitle => 'Rename data-bank';

  @override
  String get setSingularLabel => 'Singular';

  @override
  String get setSingularHint => 'e.g. Move';

  @override
  String get setPluralLabel => 'Plural';

  @override
  String get setPluralHint => 'e.g. Moves';

  @override
  String get setDataBankHelp =>
      'Display only — leave a field blank to restore its default. Your saved videos are never renamed.';

  @override
  String setRenameStateTitle(String label) {
    return 'Rename $label';
  }

  @override
  String get setCategoryDefault => 'Default';

  @override
  String get setCategoryUnused => 'Unused';

  @override
  String setCategoryMoveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves',
      one: '1 move',
    );
    return '$_temp0';
  }

  @override
  String get setPhotoStatusNotDetermined => 'Not Determined';

  @override
  String get setPhotoStatusRestricted => 'Restricted';

  @override
  String get setPhotoStatusDenied => 'Denied';

  @override
  String get setPhotoStatusFullAccess => 'Full Access';

  @override
  String get setPhotoStatusLimited => 'Limited Access';

  @override
  String get setPhotoStatusUnknown => 'Unknown';

  @override
  String get setPhotoDescNotDetermined => 'Tap to request access';

  @override
  String get setPhotoDescOpenSettings => 'Tap to open Settings';

  @override
  String get setPhotoDescAuthorized => 'All photos available';

  @override
  String get setPhotoDescLimited => 'Some photos may be unavailable';

  @override
  String get setPhotoDescUnknown => 'Could not determine access';

  @override
  String get setPhotoChecking => 'Checking access…';

  @override
  String get setPhotoUnableCheck => 'Unable to check access';

  @override
  String get setShakeCycleDuration => 'Shake cycle duration';

  @override
  String get setComboModeTitle => 'Combo mode';

  @override
  String get setComboModeDesc =>
      'Shake to discover random combos instead of moves';

  @override
  String get setSimplifiedEditorTitle => 'Use simplified editor';

  @override
  String get setSimplifiedEditorDesc =>
      'Switch to the legacy editor if the robust editor is unstable.';

  @override
  String get setFsrsTitle => 'FSRS (Spaced Repetition)';

  @override
  String get setFsrsEnabledDesc => 'Smart scheduling enabled';

  @override
  String get setFsrsDisabledDesc => 'Manual progression only';

  @override
  String get setShakeDiscoverTitle => 'Shake to Discover';

  @override
  String get setShakeDiscoverDesc =>
      'Shake your device to shuffle items in Party mode.';

  @override
  String get setQuietModeTitle => 'Keep music playing';

  @override
  String get setQuietModeDesc =>
      'Videos will start muted to avoid interrupting your music.';

  @override
  String get setStatsTabTitle => 'Show Stats Tab';

  @override
  String get setStatsTabDesc =>
      'Enable the insights tab in the bottom navigation.';

  @override
  String get setAccentEditorSubtitle =>
      'Choose any accent color for the app chrome.';

  @override
  String get setFillDefault => 'Default (white)';

  @override
  String get setFillEditorSubtitle =>
      'Tint the review card frame. Applies to your next card.';

  @override
  String get setRatingAgain => 'AGAIN';

  @override
  String get setRatingHard => 'HARD';

  @override
  String get setRatingGood => 'GOOD';

  @override
  String get setRatingEasy => 'EASY';

  @override
  String setRatingColorTitle(String label) {
    return '$label Color';
  }

  @override
  String setRatingColorSubtitle(String label) {
    return 'Choose any color for the $label rating button.';
  }

  @override
  String get setViewComposerTitle => 'REVIEW VIEW COMPOSER';

  @override
  String get setViewComposerSubtitle =>
      'Modular layout — toggle elements to create your ideal practice view.';

  @override
  String get setViewKeepMusicTitle => 'Keep music playing';

  @override
  String get setViewKeepMusicSubtitle =>
      'Keep Breakdex clips muted so your music can keep playing.';

  @override
  String get setViewTitleTitle => 'Title';

  @override
  String get setViewTitleSubtitle => 'Show the move or combo name on the card.';

  @override
  String get setViewStatePillTitle => 'State pill';

  @override
  String get setViewStatePillSubtitle =>
      'Show the current NEW / LEARNING / MASTERY pill.';

  @override
  String get setViewCategoryTitle => 'Category';

  @override
  String get setViewCategorySubtitle =>
      'Show move categories like TOPROCK or FOOTWORK.';

  @override
  String get setViewComboTimelineTitle => 'Combo timeline';

  @override
  String get setViewComboTimelineSubtitle =>
      'Show step navigation when reviewing combos.';

  @override
  String get setViewStepLabelTitle => 'Step label';

  @override
  String get setViewStepLabelSubtitle =>
      'Show the active combo step name under the timeline.';

  @override
  String get setViewPlaybackControlsTitle => 'Speed + loop controls';

  @override
  String get setViewPlaybackControlsSubtitle =>
      'Show loop and speed controls on the card.';

  @override
  String get setStatesModeDefault => 'Default';

  @override
  String get setStatesModeCustom => 'Custom';

  @override
  String get setStatesCustomStateSubtitle => 'Custom state';

  @override
  String get setStatesAddTitle => 'Add Custom State';

  @override
  String get setStatesAddSubtitle => 'Create a new learning category';

  @override
  String setStatesDefaultLabel(String label) {
    return 'Default: $label';
  }

  @override
  String setStatesColorTitle(String label) {
    return '$label Color';
  }

  @override
  String setStatesColorSubtitle(String label) {
    return 'Choose any color for $label. Quick picks, spectrum tuning, hex, and RGBA sliders stay in sync.';
  }

  @override
  String get setStatesNewTitle => 'New Custom State';

  @override
  String get setStatesNameHint => 'State name';

  @override
  String get setStatesColorTileTitle => 'State color';

  @override
  String get setStatesCustomColorTitle => 'Custom State Color';

  @override
  String get setStatesCustomColorSubtitle => 'Pick any color.';

  @override
  String get setStatesCancel => 'Cancel';

  @override
  String get setStatesAdd => 'Add';

  @override
  String get setStatesEditTitle => 'Edit Custom State';

  @override
  String get setStatesSave => 'Save';

  @override
  String get setColorPickerDefaultTitle => 'Choose Color';

  @override
  String get setColorHexLabel => 'Hex';

  @override
  String get setColorHexHelper => 'RRGGBB or AARRGGBB';

  @override
  String get setColorSpectrumLabel => 'Spectrum';

  @override
  String get setColorHueLabel => 'Hue';

  @override
  String get setColorSaturationLabel => 'Saturation';

  @override
  String get setColorValueLabel => 'Value';

  @override
  String get setColorQuickPicksLabel => 'Quick picks';

  @override
  String get setColorOpacityLabel => 'Opacity';

  @override
  String get setColorRedLabel => 'Red';

  @override
  String get setColorGreenLabel => 'Green';

  @override
  String get setColorBlueLabel => 'Blue';

  @override
  String get setColorCancelButton => 'Cancel';

  @override
  String get setColorSaveButton => 'Save';

  @override
  String get setSyncSectionHeader => 'VIDEO BACKUP';

  @override
  String setSyncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos waiting to back up',
      one: '1 video waiting to back up',
    );
    return '$_temp0';
  }

  @override
  String get setSyncAllSynced => 'All synced';

  @override
  String get setSyncChecking => 'Checking…';

  @override
  String get setSyncProviderIcloudTitle => 'iCloud Drive';

  @override
  String get setSyncProviderGdriveTitle => 'Google Drive';

  @override
  String get setSyncProviderS3Title => 'S3 Compatible';

  @override
  String get setSyncReuploadTile => 'Re-upload library now';

  @override
  String get setSyncStatusTile => 'Sync Status';

  @override
  String get setSyncFreeSpaceTile => 'Free Up Space';

  @override
  String get setSyncHelpTile => 'How Backup Works';

  @override
  String get setSyncReuploading => 'Re-uploading library…';

  @override
  String get setSyncReuploadSuccess =>
      'Library re-uploaded — refresh the web mirror';

  @override
  String get setSyncReuploadNoProvider =>
      'No cloud provider connected to upload to';

  @override
  String setSyncReuploadFailed(String error) {
    return 'Re-upload failed: $error';
  }

  @override
  String get setSyncGdriveConnected => 'Google Drive connected';

  @override
  String get setSyncGdriveAlreadyConnected =>
      'Google Drive is already connected';

  @override
  String get setSyncGdriveCancelled => 'Google sign-in was cancelled';

  @override
  String get setSyncDisconnectTitle => 'Disconnect Google Drive?';

  @override
  String get setSyncDisconnectBody =>
      'Videos already backed up to Drive stay there. New videos won’t back up until you reconnect and sign in again.';

  @override
  String get setSyncDisconnectCancel => 'Cancel';

  @override
  String get setSyncDisconnectConfirm => 'Disconnect';

  @override
  String get setSyncGdriveDisconnected => 'Google Drive disconnected';

  @override
  String get setSyncIcloudEnabled => 'iCloud Drive enabled';

  @override
  String get setSyncIcloudAlreadyEnabled => 'iCloud Drive is already enabled';

  @override
  String get setSyncIcloudNotAvailable =>
      'Enable iCloud Drive in iOS Settings > [your name] > iCloud';

  @override
  String get setSyncStatusConnected => 'Connected';

  @override
  String get setSyncStatusTapToEnable => 'Tap to enable';

  @override
  String get setSyncStatusNotAvailable => 'Not available';

  @override
  String get setSyncStatusComingSoon => 'Coming soon';

  @override
  String setError(String error) {
    return 'Error: $error';
  }
}
