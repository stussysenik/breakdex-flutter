import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application title shown to the OS (task switcher, window chrome).
  ///
  /// In en, this message translates to:
  /// **'Breakdex'**
  String get appTitle;

  /// Empty-state heading. Composes the user's parametric plural noun (see entityNamesProvider) via a placeholder so localization and the custom-noun setting cooperate.
  ///
  /// In en, this message translates to:
  /// **'No {itemPlural} yet'**
  String emptyLibraryTitle(String itemPlural);

  /// Count label that respects grammatical number and the user's parametric nouns. Proves the ICU-plural + placeholder pipeline is wired.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No {itemPlural}} =1{1 {itemSingular}} other{{count} {itemPlural}}}'**
  String itemCount(int count, String itemSingular, String itemPlural);

  /// Bottom-nav tab: the Breakdex library home.
  ///
  /// In en, this message translates to:
  /// **'Breakdex'**
  String get navBreakdex;

  /// Bottom-nav tab: add content.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get navAdd;

  /// Bottom-nav tab: review/practice.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get navReview;

  /// Bottom-nav tab: statistics.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// Bottom-nav tab: settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Add screen large app-bar title.
  ///
  /// In en, this message translates to:
  /// **'Add Content'**
  String get addContentTitle;

  /// Form field label: the item's name.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get fieldNameLabel;

  /// Placeholder text in the name field on the add sheet.
  ///
  /// In en, this message translates to:
  /// **'e.g. Flare, Windmill...'**
  String get addNameHint;

  /// Form field label: category.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get fieldCategoryLabel;

  /// Form field label: beat count.
  ///
  /// In en, this message translates to:
  /// **'BEAT COUNT'**
  String get fieldBeatCountLabel;

  /// Form field label: learning status.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get fieldStatusLabel;

  /// Primary save button on the add sheet. Composes the user's parametric noun (moveSingular, upper-cased by the caller) via a placeholder rather than concatenation.
  ///
  /// In en, this message translates to:
  /// **'SAVE {entity}'**
  String saveEntityButton(String entity);

  /// Validation error when the chosen name collides with an existing move or combo.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" already exists.'**
  String nameTakenError(String name);

  /// Move-detail caption showing the app-managed album filename for the move's clip.
  ///
  /// In en, this message translates to:
  /// **'Album · {filename}'**
  String mdAlbumLabel(String filename);

  /// Section header above the clip's technical metadata.
  ///
  /// In en, this message translates to:
  /// **'VIDEO INFO'**
  String get mdVideoInfoHeader;

  /// Metadata row label: when the clip was recorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get mdMetaRecorded;

  /// Metadata row label: the clip's file size.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get mdMetaFileSize;

  /// Metadata row label: the clip's original filename.
  ///
  /// In en, this message translates to:
  /// **'Original Name'**
  String get mdMetaOriginalName;

  /// Metadata row label: the clip's duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get mdMetaDuration;

  /// Metadata row label: the clip's pixel resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get mdMetaResolution;

  /// Section header above the move's action tiles.
  ///
  /// In en, this message translates to:
  /// **'ACTIONS'**
  String get mdActionsHeader;

  /// Action tile: open the video editor.
  ///
  /// In en, this message translates to:
  /// **'Edit Video'**
  String get mdActionEditVideo;

  /// Action tile: share the clip.
  ///
  /// In en, this message translates to:
  /// **'Share Video'**
  String get mdActionShareVideo;

  /// Action tile: remove the clip from this move.
  ///
  /// In en, this message translates to:
  /// **'Remove Video'**
  String get mdActionRemoveVideo;

  /// Action tile: attach a clip when none exists.
  ///
  /// In en, this message translates to:
  /// **'Add Video'**
  String get mdActionAddVideo;

  /// Action tile / rename-overlay title. Composes the user's parametric singular noun.
  ///
  /// In en, this message translates to:
  /// **'Rename {entity}'**
  String mdRenameEntity(String entity);

  /// Action tile: duplicate the current item. Composes the parametric singular noun.
  ///
  /// In en, this message translates to:
  /// **'Duplicate {entity}'**
  String mdDuplicateEntity(String entity);

  /// Action tile / destructive link to delete the item. Composes the parametric singular noun; the caller controls casing.
  ///
  /// In en, this message translates to:
  /// **'Delete {entity}'**
  String mdDeleteEntity(String entity);

  /// Progress overlay while the item is being deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get mdOverlayDeleting;

  /// Progress overlay while the item is being renamed.
  ///
  /// In en, this message translates to:
  /// **'Renaming...'**
  String get mdOverlayRenaming;

  /// Progress overlay while the learning state is saved.
  ///
  /// In en, this message translates to:
  /// **'Updating state...'**
  String get mdOverlayUpdatingState;

  /// Progress overlay while the category is saved.
  ///
  /// In en, this message translates to:
  /// **'Updating category...'**
  String get mdOverlayUpdatingCategory;

  /// Progress overlay while the beat count is saved.
  ///
  /// In en, this message translates to:
  /// **'Updating count...'**
  String get mdOverlayUpdatingCount;

  /// Progress overlay while notes are saved.
  ///
  /// In en, this message translates to:
  /// **'Saving notes...'**
  String get mdOverlaySavingNotes;

  /// Progress overlay while photos are saved.
  ///
  /// In en, this message translates to:
  /// **'Updating photos...'**
  String get mdOverlayUpdatingPhotos;

  /// Progress overlay while duplicating. Composes the parametric noun (caller lower-cases it).
  ///
  /// In en, this message translates to:
  /// **'Duplicating {entity}...'**
  String mdOverlayDuplicatingEntity(String entity);

  /// Delete-confirmation body when the move belongs to combos. Composes parametric nouns and the combo count/example.
  ///
  /// In en, this message translates to:
  /// **'This {entity} is currently used in {count} {comboPlural} (e.g. {comboName}). Deleting it will permanently delete this {entity}, its video, and remove it from those {comboPlural}!'**
  String mdDeleteUsedInCombos(
    String entity,
    int count,
    String comboPlural,
    String comboName,
  );

  /// Delete-confirmation body when the move is not used in any combo.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this {entity} and its video.'**
  String mdDeleteConfirmBody(String entity);

  /// Delete-confirmation overlay title. Composes the parametric singular noun.
  ///
  /// In en, this message translates to:
  /// **'Delete {entity}?'**
  String mdDeleteConfirmTitle(String entity);

  /// Confirm button on the delete overlay.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get mdConfirmDelete;

  /// Acknowledge button on informational overlays.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get mdConfirmOk;

  /// Confirm button on the remove-video overlay.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get mdConfirmRemove;

  /// Title of the generic error overlay.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get mdErrorTitle;

  /// Title shown when syncing the clip to the device album fails.
  ///
  /// In en, this message translates to:
  /// **'Album Sync Failed'**
  String get mdAlbumSyncFailedTitle;

  /// Remove-video confirmation overlay title.
  ///
  /// In en, this message translates to:
  /// **'Remove Video?'**
  String get mdRemoveVideoTitle;

  /// Remove-video confirmation body. Composes the parametric noun (caller lower-cases it).
  ///
  /// In en, this message translates to:
  /// **'The video will be removed from this {entity} but kept in your local storage.'**
  String mdRemoveVideoBody(String entity);

  /// Accessibility label for the category badge button.
  ///
  /// In en, this message translates to:
  /// **'Change category from {category}'**
  String mdSemanticChangeCategory(String category);

  /// Accessibility label for the beat-count badge button.
  ///
  /// In en, this message translates to:
  /// **'Change count from {count}'**
  String mdSemanticChangeCount(int count);

  /// Suffix after the numeric beat count (note the leading space).
  ///
  /// In en, this message translates to:
  /// **' counts'**
  String get mdCountsSuffix;

  /// Card title when the move's original video file cannot be found.
  ///
  /// In en, this message translates to:
  /// **'Video Missing'**
  String get mdVideoMissingTitle;

  /// Card body when the move's original video file cannot be found.
  ///
  /// In en, this message translates to:
  /// **'The original video couldn\'t be found.'**
  String get mdVideoMissingBody;

  /// Video-missing card action: record a new clip.
  ///
  /// In en, this message translates to:
  /// **'Re-record'**
  String get mdMissingReRecord;

  /// Video-missing card action: import a clip from the library.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get mdMissingImport;

  /// Cloud-clip placeholder detail line when idle.
  ///
  /// In en, this message translates to:
  /// **'Tap to download and play'**
  String get mdCloudTapToDownload;

  /// Cloud-clip placeholder detail line when a download has stalled.
  ///
  /// In en, this message translates to:
  /// **'Stalled — retrying…'**
  String get mdCloudStalled;

  /// Cloud-clip placeholder detail line while a download is being prepared.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get mdCloudPreparing;

  /// Cloud-clip placeholder headline fallback while downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get mdCloudDownloading;

  /// Cloud-clip placeholder headline when the clip is stored remotely and idle.
  ///
  /// In en, this message translates to:
  /// **'Video stored in cloud'**
  String get mdCloudStored;

  /// Cancel button shared across move-detail overlays.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mdCancel;

  /// Category picker overlay title. Composes the parametric singular noun.
  ///
  /// In en, this message translates to:
  /// **'{entity} Category'**
  String mdMoveCategoryTitle(String entity);

  /// Category picker: create a new category.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get mdAddNew;

  /// New-category dialog title.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get mdNewCategoryTitle;

  /// New-category dialog: name field hint.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get mdCategoryNameHint;

  /// New-category dialog: color picker tile title.
  ///
  /// In en, this message translates to:
  /// **'Category color'**
  String get mdCategoryColorTile;

  /// Color editor dialog title for a category color.
  ///
  /// In en, this message translates to:
  /// **'Category Color'**
  String get mdCategoryColorDialogTitle;

  /// Color editor dialog subtitle for a category color.
  ///
  /// In en, this message translates to:
  /// **'Pick any color for this category label.'**
  String get mdCategoryColorDialogSubtitle;

  /// Validation error when the category name is blank.
  ///
  /// In en, this message translates to:
  /// **'Category name cannot be empty.'**
  String get mdCategoryNameEmpty;

  /// Confirm button on the new-category dialog.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get mdAdd;

  /// Beat-count editor overlay title.
  ///
  /// In en, this message translates to:
  /// **'Update Count'**
  String get mdUpdateCountTitle;

  /// Save button shared across move-detail overlays.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mdSave;

  /// Rename overlay title when the chosen name collides.
  ///
  /// In en, this message translates to:
  /// **'Name Conflict'**
  String get mdNameConflictTitle;

  /// Rename overlay body explaining the name collision. Composes the parametric nouns (caller lower-cases them).
  ///
  /// In en, this message translates to:
  /// **'The name \"{name}\" is already taken by another {move} or {combo}.'**
  String mdNameConflictBody(String name, String move, String combo);

  /// Rename overlay: name field hint.
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get mdRenameHint;

  /// Confirmation sheet title when leaving a review session mid-way.
  ///
  /// In en, this message translates to:
  /// **'End session?'**
  String get revEndSessionTitle;

  /// Progress line in the end-session confirmation sheet.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reviewed {reviewed} of {total} cards.'**
  String revReviewedOfCards(int reviewed, int total);

  /// End-session sheet: keep reviewing.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get revContinue;

  /// End-session sheet: end the session.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get revEnd;

  /// Review tab header.
  ///
  /// In en, this message translates to:
  /// **'Drill'**
  String get revDrill;

  /// Review-mode segmented control: spaced-repetition review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get revReviewSegment;

  /// Review-mode segmented control: custom decks.
  ///
  /// In en, this message translates to:
  /// **'Deck'**
  String get revDeckSegment;

  /// Inline error message when review data fails to load.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String revError(String error);

  /// Prompt on the review card's watch stage.
  ///
  /// In en, this message translates to:
  /// **'Watch the clip, then move to assessment.'**
  String get revWatchClip;

  /// Button to advance from watching to assessment.
  ///
  /// In en, this message translates to:
  /// **'Assess'**
  String get revAssess;

  /// Empty-state message when a targeted item was deleted. Composes the parametric noun (caller lower-cases it).
  ///
  /// In en, this message translates to:
  /// **'That {entity} is no longer available'**
  String revEntityNoLongerAvailable(String entity);

  /// Return to the review list from an empty targeted session.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get revBack;

  /// Empty-state heading when the library has no items to review.
  ///
  /// In en, this message translates to:
  /// **'Your breakdex is empty'**
  String get revBreakdexEmpty;

  /// Empty-state hint pointing at the Arsenal tab. Composes the parametric plural noun (caller lower-cases it).
  ///
  /// In en, this message translates to:
  /// **'Add {items} from the Arsenal tab to start reviewing'**
  String revAddFromArsenal(String items);

  /// Empty-state CTA to add the first item. Composes the parametric singular noun.
  ///
  /// In en, this message translates to:
  /// **'Add a {entity}'**
  String revAddEntity(String entity);

  /// Empty-state message when no deck is selected.
  ///
  /// In en, this message translates to:
  /// **'Pick a deck to start a review session'**
  String get revPickDeck;

  /// Empty-state message when the selected deck matches no cards.
  ///
  /// In en, this message translates to:
  /// **'\"{deckName}\" has no matching cards'**
  String revDeckNoMatchingCards(String deckName);

  /// Empty-state message for a state-filtered session. Composes the state label and the parametric singular noun (caller lower-cases the noun).
  ///
  /// In en, this message translates to:
  /// **'No {stateLabel} {kind} cards available'**
  String revNoStateCardsAvailable(String stateLabel, String kind);

  /// Empty-state message when nothing is due. Composes the parametric singular noun (caller lower-cases it).
  ///
  /// In en, this message translates to:
  /// **'No due {kind} cards available for this session'**
  String revNoDueCardsAvailable(String kind);

  /// Return to the review dashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Review'**
  String get revBackToReview;

  /// Session-complete celebration heading.
  ///
  /// In en, this message translates to:
  /// **'Great work!'**
  String get revGreatWork;

  /// Session-complete summary of how many cards were reviewed.
  ///
  /// In en, this message translates to:
  /// **'All {count} cards reviewed'**
  String revAllCardsReviewed(int count);

  /// Restart the same review session.
  ///
  /// In en, this message translates to:
  /// **'Review Again'**
  String get revReviewAgain;

  /// Celebration when a move advances to the 'sprouting' mastery tier.
  ///
  /// In en, this message translates to:
  /// **'🌱 {name} is sprouting!'**
  String revTierSprouting(String name);

  /// Celebration when a move advances to the 'growing' mastery tier.
  ///
  /// In en, this message translates to:
  /// **'🌿 {name} is growing!'**
  String revTierGrowing(String name);

  /// Celebration when a move reaches the 'mastered' mastery tier.
  ///
  /// In en, this message translates to:
  /// **'💎 {name} mastered!'**
  String revTierMastered(String name);

  /// Generic celebration when a move advances a mastery tier.
  ///
  /// In en, this message translates to:
  /// **'{name} leveled up!'**
  String revTierLeveledUp(String name);

  /// Combo assessment label anchoring the active step and move name.
  ///
  /// In en, this message translates to:
  /// **'Step {step} · {name}'**
  String revStep(int step, String name);

  /// Create-deck sheet title / create button.
  ///
  /// In en, this message translates to:
  /// **'Create Deck'**
  String get revCreateDeck;

  /// Edit-deck sheet title / menu action.
  ///
  /// In en, this message translates to:
  /// **'Edit Deck'**
  String get revEditDeck;

  /// Create-deck sheet: name field hint.
  ///
  /// In en, this message translates to:
  /// **'Deck name'**
  String get revDeckNameHint;

  /// Deck type chip: auto-populated smart deck.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get revSmart;

  /// Deck type chip: hand-picked manual deck.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get revManual;

  /// Smart-deck filter section: category filter.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get revCategories;

  /// Smart-deck filter section: FSRS card-state filter.
  ///
  /// In en, this message translates to:
  /// **'Card States'**
  String get revCardStates;

  /// Smart-deck toggle: limit to cards that are due.
  ///
  /// In en, this message translates to:
  /// **'Due only'**
  String get revDueOnly;

  /// Manual-deck section header to pick items. Composes the parametric plural noun.
  ///
  /// In en, this message translates to:
  /// **'Select {items}'**
  String revSelectEntity(String items);

  /// Create-deck section header: cards per session.
  ///
  /// In en, this message translates to:
  /// **'Session Size'**
  String get revSessionSize;

  /// Session-size chip meaning no limit.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get revAll;

  /// Save button when editing an existing deck.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get revSaveChanges;

  /// Manual-deck selector empty state. Composes the parametric plural noun (caller lower-cases it).
  ///
  /// In en, this message translates to:
  /// **'No {items} available'**
  String revNoEntityAvailable(String items);

  /// Item schedule detail: rating-preview section header.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Schedule'**
  String get revUpcomingSchedule;

  /// Item schedule detail: expandable FSRS stats header.
  ///
  /// In en, this message translates to:
  /// **'Advanced Algorithm Stats'**
  String get revAdvancedStats;

  /// Item schedule detail: start reviewing this item immediately.
  ///
  /// In en, this message translates to:
  /// **'Review Now'**
  String get revReviewNow;

  /// Item schedule detail note that combo review is schedule-only. Composes the parametric singular noun.
  ///
  /// In en, this message translates to:
  /// **'{entity} sessions still open in the schedule view only.'**
  String revComboSessionsScheduleOnly(String entity);

  /// FSRS coefficient bar label: stability.
  ///
  /// In en, this message translates to:
  /// **'Stability'**
  String get revStability;

  /// FSRS coefficient bar label: difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get revDifficulty;

  /// FSRS coefficient bar label: retrievability.
  ///
  /// In en, this message translates to:
  /// **'Retrievability'**
  String get revRetrievability;

  /// FSRS stat chip: repetitions.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get revReps;

  /// FSRS stat chip: lapses.
  ///
  /// In en, this message translates to:
  /// **'Lapses'**
  String get revLapses;

  /// FSRS stat chip: current interval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get revInterval;

  /// Mastery prescreen: basic-practice toggle title.
  ///
  /// In en, this message translates to:
  /// **'BASIC PRACTICE'**
  String get revBasicPractice;

  /// Basic-practice toggle subtitle when enabled.
  ///
  /// In en, this message translates to:
  /// **'BYPASSING FSRS (MATH)'**
  String get revBypassingFsrs;

  /// Basic-practice toggle subtitle when disabled.
  ///
  /// In en, this message translates to:
  /// **'FSRS ACTIVE (DUE ONLY)'**
  String get revFsrsActive;

  /// Mastery prescreen empty-state heading.
  ///
  /// In en, this message translates to:
  /// **'Your Arsenal is empty'**
  String get revArsenalEmpty;

  /// Mastery prescreen empty-state hint. Composes the parametric plural noun (caller lower-cases it).
  ///
  /// In en, this message translates to:
  /// **'Add {items} to start your practice journey.'**
  String revAddToStartJourney(String items);

  /// Mastery prescreen: custom decks section header.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM DECKS'**
  String get revCustomDecks;

  /// Deck context menu: delete the deck.
  ///
  /// In en, this message translates to:
  /// **'Delete Deck'**
  String get revDeleteDeck;

  /// Empty state when the user has no custom decks.
  ///
  /// In en, this message translates to:
  /// **'No custom decks yet'**
  String get revNoCustomDecks;

  /// CTA to create the first custom deck.
  ///
  /// In en, this message translates to:
  /// **'CREATE FIRST DECK'**
  String get revCreateFirstDeck;

  /// Review dashboard header in basic-practice mode. Composes the parametric plural noun (caller upper-cases it).
  ///
  /// In en, this message translates to:
  /// **'ALL {items} (BASIC PRACTICE)'**
  String revAllEntityBasicPractice(String items);

  /// Review dashboard header for the box breakdown. Composes the parametric plural noun (caller upper-cases it).
  ///
  /// In en, this message translates to:
  /// **'{items} BOXES'**
  String revEntityBoxes(String items);

  /// Review dashboard: total-due row label.
  ///
  /// In en, this message translates to:
  /// **'TOTAL DUE'**
  String get revTotalDue;

  /// Review dashboard CTA when nothing is due.
  ///
  /// In en, this message translates to:
  /// **'ALL BOXES EMPTY'**
  String get revAllBoxesEmpty;

  /// Review dashboard CTA to start basic practice.
  ///
  /// In en, this message translates to:
  /// **'START BASIC PRACTICE'**
  String get revStartBasicPractice;

  /// Review dashboard CTA to review all due cards.
  ///
  /// In en, this message translates to:
  /// **'REVIEW ALL DUE'**
  String get revReviewAllDue;

  /// Accessibility label for a rating button (Again/Hard/Good/Easy).
  ///
  /// In en, this message translates to:
  /// **'Rate {rating}'**
  String revRate(String rating);

  /// Schedule view summary when nothing is due today.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get revAllCaughtUp;

  /// Schedule view summary of how many items are due today.
  ///
  /// In en, this message translates to:
  /// **'{count} due today'**
  String revDueTodayCount(int count);

  /// Schedule view section header for today's items.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get revDueTodayHeader;

  /// Schedule view section header for a specific date.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String revDueDate(String date);

  /// Count of items due on the selected date.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String revItemCount(int count);

  /// Schedule view empty state for today.
  ///
  /// In en, this message translates to:
  /// **'No items due today'**
  String get revNoItemsDueToday;

  /// Schedule view empty state for a non-today date.
  ///
  /// In en, this message translates to:
  /// **'No items due on this date'**
  String get revNoItemsDueOnDate;

  /// Schedule empty-state heading. Composes the parametric plural noun (caller lower-cases it).
  ///
  /// In en, this message translates to:
  /// **'Add {items} to start training'**
  String revAddToStartTraining(String items);

  /// Schedule empty-state body. Composes the parametric plural noun (caller lower-cases it).
  ///
  /// In en, this message translates to:
  /// **'Record your breakdancing {items}, then review with spaced repetition.'**
  String revRecordMoves(String items);

  /// Schedule empty-state CTA to the Arsenal tab.
  ///
  /// In en, this message translates to:
  /// **'Go to Arsenal'**
  String get revGoToArsenal;

  /// SRS parameters card header.
  ///
  /// In en, this message translates to:
  /// **'FSRS Parameters'**
  String get revFsrsParameters;

  /// SRS parameters card: reset to defaults.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get revReset;

  /// SRS parameter label: desired retention.
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get revRetention;

  /// SRS parameter hint for the retention slider.
  ///
  /// In en, this message translates to:
  /// **'Higher = more frequent reviews, tighter recall.'**
  String get revRetentionHint;

  /// SRS parameter label: maximum interval.
  ///
  /// In en, this message translates to:
  /// **'Max interval'**
  String get revMaxInterval;

  /// SRS parameter label: interval fuzzing toggle.
  ///
  /// In en, this message translates to:
  /// **'Fuzzing'**
  String get revFuzzing;

  /// SRS parameter label: learning step presets.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get revLearning;

  /// SRS parameter label: relearning step presets.
  ///
  /// In en, this message translates to:
  /// **'Relearning'**
  String get revRelearning;

  /// SRS parameters card: forgetting-curve section header.
  ///
  /// In en, this message translates to:
  /// **'Forgetting curve'**
  String get revForgettingCurve;

  /// Legend for the forgetting-curve formula.
  ///
  /// In en, this message translates to:
  /// **'t = days elapsed, S = stability'**
  String get revForgettingCurveLegend;

  /// State picker sheet header. Composes the parametric singular noun (caller upper-cases it).
  ///
  /// In en, this message translates to:
  /// **'{entity} STATE'**
  String revMoveState(String entity);

  /// Badge marking the item's current learning state in the state picker.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get revCurrent;

  /// Inline error when the decks list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Error loading decks: {error}'**
  String revErrorLoadingDecks(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
