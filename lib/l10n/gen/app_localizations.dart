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

  /// Add screen section label above the content-type choices.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get addSectionCreate;

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

  /// Metadata row label: where the clip's bytes live and which way they are moving.
  ///
  /// In en, this message translates to:
  /// **'Stored'**
  String get mdMetaStored;

  /// Residency location: the clip is on the local device.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get residencyThisDevice;

  /// Residency: the clip exists nowhere but this device — no cloud copy.
  ///
  /// In en, this message translates to:
  /// **'This device only'**
  String get residencyThisDeviceOnly;

  /// Residency: the copy ledger has no record for this clip, so nothing is claimed about where it lives.
  ///
  /// In en, this message translates to:
  /// **'Not tracked yet'**
  String get residencyUntracked;

  /// Residency direction: an upload is in flight to the named places.
  ///
  /// In en, this message translates to:
  /// **'sending to {places}'**
  String residencySending(String places);

  /// Residency direction: the last upload to the named places failed.
  ///
  /// In en, this message translates to:
  /// **'upload failed — {places}'**
  String residencyUploadFailed(String places);

  /// Residency: the clip's bytes are verified in the cloud but absent locally, so playing it needs a download.
  ///
  /// In en, this message translates to:
  /// **'{places} only — not on this device'**
  String residencyCloudOnly(String places);

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

  /// Settings: back affordance in the header (screen-reader label + visible text) when settings is pushed (not a tab).
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get setBack;

  /// Settings: generic reset button that restores a personalization panel to its defaults (accent, rating colors, card fill, review states).
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get setReset;

  /// Settings: generic add/confirm button for creating a move category.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get setAdd;

  /// Settings: generic cancel button that dismisses a dialog without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get setCancel;

  /// Settings: generic save button that commits a rename/edit dialog.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get setSave;

  /// Settings: acknowledge button dismissing an informational dialog.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get setOk;

  /// Settings: compact seconds readout for the party shake-cycle slider (value already formatted, e.g. '3.5').
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String setSecondsSuffix(String seconds);

  /// Settings section header (rendered upper-cased) for practice/review controls.
  ///
  /// In en, this message translates to:
  /// **'Practice & Review'**
  String get setSectionPractice;

  /// Settings: subtitle under the Practice & Review section header.
  ///
  /// In en, this message translates to:
  /// **'Learning engine, view composer, and session controls.'**
  String get setSectionPracticeSubtitle;

  /// Settings section header (rendered upper-cased) for appearance controls.
  ///
  /// In en, this message translates to:
  /// **'Visuals & Style'**
  String get setSectionVisuals;

  /// Settings: subtitle under the Visuals & Style section header.
  ///
  /// In en, this message translates to:
  /// **'Theme, typography, colors, and global labels.'**
  String get setSectionVisualsSubtitle;

  /// Settings section header (rendered upper-cased) for library/data controls.
  ///
  /// In en, this message translates to:
  /// **'Library & Data'**
  String get setSectionLibrary;

  /// Settings: subtitle under the Library & Data section header.
  ///
  /// In en, this message translates to:
  /// **'Categories, backups, and photo library access.'**
  String get setSectionLibrarySubtitle;

  /// Settings panel title: app-mode segmented picker.
  ///
  /// In en, this message translates to:
  /// **'App Mode'**
  String get setPanelAppMode;

  /// Settings panel title: FSRS learning-engine toggle.
  ///
  /// In en, this message translates to:
  /// **'Learning Engine'**
  String get setPanelLearningEngine;

  /// Settings panel title: quiet-mode (mute videos) toggle.
  ///
  /// In en, this message translates to:
  /// **'Quiet Mode'**
  String get setPanelQuietMode;

  /// Settings panel title wrapping the review-card display composer.
  ///
  /// In en, this message translates to:
  /// **'Review View Composer'**
  String get setPanelViewComposer;

  /// Settings panel title: party-mode shake/cycle controls.
  ///
  /// In en, this message translates to:
  /// **'Party Mode'**
  String get setPanelPartyMode;

  /// Settings panel title: video-editor selection toggle.
  ///
  /// In en, this message translates to:
  /// **'Video Editor'**
  String get setPanelVideoEditor;

  /// Settings panel title: add-flow order segmented picker.
  ///
  /// In en, this message translates to:
  /// **'Add Flow'**
  String get setPanelAddFlow;

  /// Settings panel title: what the move detail screen captions a move's name with (date, filename, id, or nothing).
  ///
  /// In en, this message translates to:
  /// **'Move Caption'**
  String get setPanelMoveCaption;

  /// Settings panel title: show/hide the stats tab toggle.
  ///
  /// In en, this message translates to:
  /// **'Stats Tab'**
  String get setPanelStatsTab;

  /// Settings panel title: light/dark/system theme picker.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get setPanelAppTheme;

  /// Settings panel title: accessible-palette picker.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get setPanelAccessibility;

  /// Settings panel title: font-family chooser.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get setPanelTypography;

  /// Settings panel title: learning-state labels/colors editor.
  ///
  /// In en, this message translates to:
  /// **'Review States'**
  String get setPanelReviewStates;

  /// Settings panel title grouping accent/rating/fill color editors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get setPanelColors;

  /// Settings panel title: page-title and data-bank name customization.
  ///
  /// In en, this message translates to:
  /// **'Global Labels'**
  String get setPanelGlobalLabels;

  /// Settings panel title: move-category management.
  ///
  /// In en, this message translates to:
  /// **'Move Categories'**
  String get setPanelMoveCategories;

  /// Settings panel title: export/import/clear data actions.
  ///
  /// In en, this message translates to:
  /// **'Backup & Reset'**
  String get setPanelBackupReset;

  /// Settings panel title: photo-library access status.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get setPanelPhotoLibrary;

  /// Settings panel title linking to the full color-packs management screen.
  ///
  /// In en, this message translates to:
  /// **'Color Packs'**
  String get setPanelColorPacks;

  /// Color Packs settings panel: page title at the top of the full-screen panel.
  ///
  /// In en, this message translates to:
  /// **'Color Packs'**
  String get setColorPacksRouteTitle;

  /// Color Packs panel: subtitle explaining the relationship between packs and accessibility overlays.
  ///
  /// In en, this message translates to:
  /// **'Choose a color pack or customize individual colors. Accessible palettes take priority over pack signals.'**
  String get setColorPacksSubtitle;

  /// Color Packs panel: label for the currently selected pack display.
  ///
  /// In en, this message translates to:
  /// **'Current pack'**
  String get setColorPacksSelectPack;

  /// Color Packs panel: label for a collection section heading.
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String setColorPacksCollection(String name);

  /// Color Packs: name of the seasonal collections group.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get setColorPacksCollectionSeasonal;

  /// Color Packs: collection section heading with a year label.
  ///
  /// In en, this message translates to:
  /// **'{year} Collection'**
  String setColorPacksCollectionYear(String year);

  /// Color Packs: display name for the default classic pack.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get setColorPacksDefaultName;

  /// Color Packs: display name for the monochrome grayscale pack.
  ///
  /// In en, this message translates to:
  /// **'Monochrome'**
  String get setColorPacksMonoName;

  /// Color Packs panel: shown when the accessible palette is not standard, informing the user that pack signal colors are overridden by the accessibility guarantee.
  ///
  /// In en, this message translates to:
  /// **'Your accessibility settings are overriding signal colors for this pack.'**
  String get setColorPacksAccessibleOverride;

  /// Color Packs: a color override passes the WCAG contrast threshold.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get setColorPacksContrastPass;

  /// Color Packs: a color override does not meet the WCAG contrast threshold.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get setColorPacksContrastFail;

  /// Color Packs: the computed WCAG contrast ratio shown inline, e.g. '4.5:1'.
  ///
  /// In en, this message translates to:
  /// **'{ratio}:1'**
  String setColorPacksContrastRatio(String ratio);

  /// Color Packs: label for the per-role color override picker button.
  ///
  /// In en, this message translates to:
  /// **'Override'**
  String get setColorPacksOverrideColor;

  /// Color Packs: dialog title for overriding a specific color role.
  ///
  /// In en, this message translates to:
  /// **'Override {role}'**
  String setColorPacksOverrideTitle(String role);

  /// Color Packs: subtitle in the per-role override dialog explaining how overrides interact with packs and contrast.
  ///
  /// In en, this message translates to:
  /// **'Choose any color. The pack provides the default; your override takes priority. Contrast is shown but not enforced.'**
  String get setColorPacksOverrideSubtitle;

  /// Color Packs: button to clear all per-role overrides for the current pack.
  ///
  /// In en, this message translates to:
  /// **'Reset overrides'**
  String get setColorPacksResetOverrides;

  /// Settings: label for the global accent-color editor (sub-panel title and the color tile/dialog title).
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get setAccentColorLabel;

  /// Settings: sub-panel title for the review rating-color editors.
  ///
  /// In en, this message translates to:
  /// **'Rating Colors'**
  String get setRatingColorsLabel;

  /// Settings: label for the review-card frame fill editor (sub-panel title and the color tile/dialog title).
  ///
  /// In en, this message translates to:
  /// **'Review Card Fill'**
  String get setReviewCardFillLabel;

  /// Settings Global Labels: action-tile showing the current customizable library page title.
  ///
  /// In en, this message translates to:
  /// **'Arsenal Title: {name}'**
  String setLabelArsenalTitle(String name);

  /// Settings Global Labels: action-tile showing the user's custom plural noun for moves.
  ///
  /// In en, this message translates to:
  /// **'Moves data-bank: {name}'**
  String setLabelMovesDataBank(String name);

  /// Settings Global Labels: action-tile showing the user's custom plural noun for combos.
  ///
  /// In en, this message translates to:
  /// **'Combos data-bank: {name}'**
  String setLabelCombosDataBank(String name);

  /// Settings Backup & Reset: share a plain-text stats summary.
  ///
  /// In en, this message translates to:
  /// **'Export Stats Summary'**
  String get setActionExportStats;

  /// Settings Backup & Reset: export the full library as a JSON backup file.
  ///
  /// In en, this message translates to:
  /// **'Export Full JSON Backup'**
  String get setActionExportJson;

  /// Settings Backup & Reset: snackbar confirming a JSON export, with the record count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Exported 1 record} other{Exported {count} records}}'**
  String setExportedRecords(int count);

  /// Settings Backup & Reset: import a JSON backup file.
  ///
  /// In en, this message translates to:
  /// **'Import from JSON'**
  String get setActionImportJson;

  /// Settings Backup & Reset: open the recently-deleted archive; shows a count badge when non-zero.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Recently Deleted} other{Recently Deleted ({count})}}'**
  String setActionRecentlyDeleted(int count);

  /// Settings Backup & Reset: open the system-status and logs screen.
  ///
  /// In en, this message translates to:
  /// **'System Status & Logs'**
  String get setActionSystemStatus;

  /// Settings Backup & Reset: destructive action opening the clear-all-data confirmation.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get setActionClearData;

  /// Settings: clear-all-data confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data?'**
  String get setClearTitle;

  /// Settings: clear-all-data dialog body explaining the deletion and the automatic pre-clear backup.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes all moves, reviews, combos, and battle results. A backup will be created automatically before clearing.'**
  String get setClearBody;

  /// Settings: clear-all-data dialog prompt asking the user to type the literal control word DELETE (which stays untranslated) to enable the confirm button.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm:'**
  String get setClearConfirmPrompt;

  /// Settings: destructive confirm button in the clear-all-data dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear Everything'**
  String get setClearConfirmButton;

  /// Settings: snackbar naming the auto-backup file written before data is cleared.
  ///
  /// In en, this message translates to:
  /// **'Pre-clear backup saved to {file}'**
  String setClearBackupSaved(String file);

  /// Settings import: fallback snackbar when a chosen file fails validation and carries no specific error.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file'**
  String get setImportInvalid;

  /// Settings import: mode-selection dialog title.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get setImportTitle;

  /// Settings import: dialog line summarizing the record counts found in the backup; the categories clause is appended only when present.
  ///
  /// In en, this message translates to:
  /// **'Found {moves} moves, {reviews} reviews, {combos} combos, {battles} battle results{categories}.'**
  String setImportSummary(
    int moves,
    int reviews,
    int combos,
    int battles,
    String categories,
  );

  /// Settings import: optional trailing clause appended to the import summary when the backup includes categories.
  ///
  /// In en, this message translates to:
  /// **', {count} categories'**
  String setImportSummaryCategories(int count);

  /// Settings import: label above the replace/merge mode buttons.
  ///
  /// In en, this message translates to:
  /// **'Import mode:'**
  String get setImportModeLabel;

  /// Settings import: replace-all mode button.
  ///
  /// In en, this message translates to:
  /// **'Replace All (overwrite existing, keep extras)'**
  String get setImportModeReplace;

  /// Settings import: merge mode button.
  ///
  /// In en, this message translates to:
  /// **'Merge (skip duplicates, keep everything)'**
  String get setImportModeMerge;

  /// Settings import: success snackbar with imported record count; the relink clause is appended when some moves need their video re-linked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 record{relink}} other{Imported {count} records{relink}}}'**
  String setImported(int count, String relink);

  /// Settings import: optional trailing clause noting how many imported moves are missing their video and need re-linking.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{ (1 move needs video re-linking)} other{ ({count} moves need video re-linking)}}'**
  String setImportedRelink(int count);

  /// Settings import: error snackbar with the raw error text.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String setImportFailed(String error);

  /// Settings: category action-sheet option to rename/edit a category.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get setCategoryEdit;

  /// Settings: category action-sheet option to delete a non-default category.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get setCategoryDelete;

  /// Settings: rename-category dialog title.
  ///
  /// In en, this message translates to:
  /// **'Rename Category'**
  String get setRenameCategoryTitle;

  /// Settings: hint text in the category-name text field (rename and add dialogs).
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get setCategoryNameHint;

  /// Settings: color-tile title inside the category rename/add dialog.
  ///
  /// In en, this message translates to:
  /// **'Category color'**
  String get setCategoryColorTile;

  /// Settings: title of the color-editor dialog opened for a category.
  ///
  /// In en, this message translates to:
  /// **'Category Color'**
  String get setCategoryColorEditorTitle;

  /// Settings: subtitle in the category color-editor dialog.
  ///
  /// In en, this message translates to:
  /// **'Pick any color for this category label.'**
  String get setCategoryColorEditorSubtitle;

  /// Settings: validation snackbar when a category name is blank.
  ///
  /// In en, this message translates to:
  /// **'Category name cannot be empty.'**
  String get setCategoryNameEmpty;

  /// Settings: validation snackbar when a category name collides with an existing one.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" already exists.'**
  String setCategoryExists(String name);

  /// Settings: add-category dialog title.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get setNewCategoryTitle;

  /// Settings: dialog title shown when trying to delete a category that still has moves.
  ///
  /// In en, this message translates to:
  /// **'Category In Use'**
  String get setCategoryInUseTitle;

  /// Settings: dialog body asking the user to reassign the moves still in a category before it can be deleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Reassign the 1 move in \"{name}\" before deleting it.} other{Reassign the {count} moves in \"{name}\" before deleting it.}}'**
  String setCategoryInUseBody(int count, String name);

  /// Settings Global Labels: rename-page-title dialog title.
  ///
  /// In en, this message translates to:
  /// **'Rename Page Title'**
  String get setRenamePageTitle;

  /// Settings Global Labels: hint text in the page-title field.
  ///
  /// In en, this message translates to:
  /// **'Page title'**
  String get setPageTitleHint;

  /// Settings Global Labels: rename-data-bank dialog title (edits the custom singular/plural nouns).
  ///
  /// In en, this message translates to:
  /// **'Rename data-bank'**
  String get setRenameDataBankTitle;

  /// Settings Global Labels: label for the singular-noun field.
  ///
  /// In en, this message translates to:
  /// **'Singular'**
  String get setSingularLabel;

  /// Settings Global Labels: example hint for the singular-noun field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Move'**
  String get setSingularHint;

  /// Settings Global Labels: label for the plural-noun field.
  ///
  /// In en, this message translates to:
  /// **'Plural'**
  String get setPluralLabel;

  /// Settings Global Labels: example hint for the plural-noun field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Moves'**
  String get setPluralHint;

  /// Settings Global Labels: helper text clarifying that renaming nouns is display-only and never touches saved videos.
  ///
  /// In en, this message translates to:
  /// **'Display only — leave a field blank to restore its default. Your saved videos are never renamed.'**
  String get setDataBankHelp;

  /// Settings Review States: rename-learning-state dialog title, composing the state's default label.
  ///
  /// In en, this message translates to:
  /// **'Rename {label}'**
  String setRenameStateTitle(String label);

  /// Settings: category-row meta tag marking the built-in default category.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get setCategoryDefault;

  /// Settings: category-row meta tag when no moves use the category.
  ///
  /// In en, this message translates to:
  /// **'Unused'**
  String get setCategoryUnused;

  /// Settings: category-row meta showing how many moves use the category.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 move} other{{count} moves}}'**
  String setCategoryMoveCount(int count);

  /// Settings Photo Library: access status when permission has not been requested yet.
  ///
  /// In en, this message translates to:
  /// **'Not Determined'**
  String get setPhotoStatusNotDetermined;

  /// Settings Photo Library: access status when restricted by device policy.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get setPhotoStatusRestricted;

  /// Settings Photo Library: access status when the user denied access.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get setPhotoStatusDenied;

  /// Settings Photo Library: access status when full library access is granted.
  ///
  /// In en, this message translates to:
  /// **'Full Access'**
  String get setPhotoStatusFullAccess;

  /// Settings Photo Library: access status when only a limited selection is granted.
  ///
  /// In en, this message translates to:
  /// **'Limited Access'**
  String get setPhotoStatusLimited;

  /// Settings Photo Library: access status when it cannot be determined.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get setPhotoStatusUnknown;

  /// Settings Photo Library: subtitle prompting the user to grant access.
  ///
  /// In en, this message translates to:
  /// **'Tap to request access'**
  String get setPhotoDescNotDetermined;

  /// Settings Photo Library: subtitle prompting the user to open OS settings (denied/restricted).
  ///
  /// In en, this message translates to:
  /// **'Tap to open Settings'**
  String get setPhotoDescOpenSettings;

  /// Settings Photo Library: subtitle when full access is granted.
  ///
  /// In en, this message translates to:
  /// **'All photos available'**
  String get setPhotoDescAuthorized;

  /// Settings Photo Library: subtitle when access is limited to a selection.
  ///
  /// In en, this message translates to:
  /// **'Some photos may be unavailable'**
  String get setPhotoDescLimited;

  /// Settings Photo Library: subtitle when access status is unknown.
  ///
  /// In en, this message translates to:
  /// **'Could not determine access'**
  String get setPhotoDescUnknown;

  /// Settings Photo Library: subtitle while the access status is loading.
  ///
  /// In en, this message translates to:
  /// **'Checking access…'**
  String get setPhotoChecking;

  /// Settings Photo Library: subtitle when the access-status check errors.
  ///
  /// In en, this message translates to:
  /// **'Unable to check access'**
  String get setPhotoUnableCheck;

  /// Settings Party Mode: label for the shake-cycle duration slider.
  ///
  /// In en, this message translates to:
  /// **'Shake cycle duration'**
  String get setShakeCycleDuration;

  /// Settings Party Mode: title for the combo-mode toggle.
  ///
  /// In en, this message translates to:
  /// **'Combo mode'**
  String get setComboModeTitle;

  /// Settings Party Mode: description for the combo-mode toggle.
  ///
  /// In en, this message translates to:
  /// **'Shake to discover random combos instead of moves'**
  String get setComboModeDesc;

  /// Settings Video Editor: title for the simplified-editor toggle.
  ///
  /// In en, this message translates to:
  /// **'Use simplified editor'**
  String get setSimplifiedEditorTitle;

  /// Settings Video Editor: description for the simplified-editor toggle.
  ///
  /// In en, this message translates to:
  /// **'Switch to the legacy editor if the robust editor is unstable.'**
  String get setSimplifiedEditorDesc;

  /// Settings Learning Engine: title for the FSRS toggle.
  ///
  /// In en, this message translates to:
  /// **'FSRS (Spaced Repetition)'**
  String get setFsrsTitle;

  /// Settings Learning Engine: description when FSRS smart scheduling is on.
  ///
  /// In en, this message translates to:
  /// **'Smart scheduling enabled'**
  String get setFsrsEnabledDesc;

  /// Settings Learning Engine: description when FSRS is off (manual progression).
  ///
  /// In en, this message translates to:
  /// **'Manual progression only'**
  String get setFsrsDisabledDesc;

  /// Settings Party Mode: title for the shake-to-discover toggle.
  ///
  /// In en, this message translates to:
  /// **'Shake to Discover'**
  String get setShakeDiscoverTitle;

  /// Settings Party Mode: description for the shake-to-discover toggle.
  ///
  /// In en, this message translates to:
  /// **'Shake your device to shuffle items in Party mode.'**
  String get setShakeDiscoverDesc;

  /// Settings Quiet Mode: title for the keep-music-playing toggle.
  ///
  /// In en, this message translates to:
  /// **'Keep music playing'**
  String get setQuietModeTitle;

  /// Settings Quiet Mode: description for the keep-music-playing toggle.
  ///
  /// In en, this message translates to:
  /// **'Videos will start muted to avoid interrupting your music.'**
  String get setQuietModeDesc;

  /// Settings Stats Tab: title for the show-stats-tab toggle.
  ///
  /// In en, this message translates to:
  /// **'Show Stats Tab'**
  String get setStatsTabTitle;

  /// Settings Stats Tab: description for the show-stats-tab toggle.
  ///
  /// In en, this message translates to:
  /// **'Enable the insights tab in the bottom navigation.'**
  String get setStatsTabDesc;

  /// Settings: subtitle in the accent-color editor dialog.
  ///
  /// In en, this message translates to:
  /// **'Choose any accent color for the app chrome.'**
  String get setAccentEditorSubtitle;

  /// Settings: review-card fill subtitle when no custom color is set (default white).
  ///
  /// In en, this message translates to:
  /// **'Default (white)'**
  String get setFillDefault;

  /// Settings: subtitle in the review-card fill color-editor dialog.
  ///
  /// In en, this message translates to:
  /// **'Tint the review card frame. Applies to your next card.'**
  String get setFillEditorSubtitle;

  /// Settings Rating Colors: label for the 'again' rating row (upper-cased).
  ///
  /// In en, this message translates to:
  /// **'AGAIN'**
  String get setRatingAgain;

  /// Settings Rating Colors: label for the 'hard' rating row (upper-cased).
  ///
  /// In en, this message translates to:
  /// **'HARD'**
  String get setRatingHard;

  /// Settings Rating Colors: label for the 'good' rating row (upper-cased).
  ///
  /// In en, this message translates to:
  /// **'GOOD'**
  String get setRatingGood;

  /// Settings Rating Colors: label for the 'easy' rating row (upper-cased).
  ///
  /// In en, this message translates to:
  /// **'EASY'**
  String get setRatingEasy;

  /// Settings Rating Colors: color-editor dialog title, composing the rating label.
  ///
  /// In en, this message translates to:
  /// **'{label} Color'**
  String setRatingColorTitle(String label);

  /// Settings Rating Colors: color-editor dialog subtitle, composing the rating label.
  ///
  /// In en, this message translates to:
  /// **'Choose any color for the {label} rating button.'**
  String setRatingColorSubtitle(String label);

  /// All-caps section header for the review card display composer settings group.
  ///
  /// In en, this message translates to:
  /// **'REVIEW VIEW COMPOSER'**
  String get setViewComposerTitle;

  /// Subtitle under the review view composer header explaining that toggles customize the practice view layout.
  ///
  /// In en, this message translates to:
  /// **'Modular layout — toggle elements to create your ideal practice view.'**
  String get setViewComposerSubtitle;

  /// Title for the toggle that mutes Breakdex clips so the user's own music keeps playing.
  ///
  /// In en, this message translates to:
  /// **'Keep music playing'**
  String get setViewKeepMusicTitle;

  /// Subtitle explaining the keep-music-playing toggle mutes app video clips.
  ///
  /// In en, this message translates to:
  /// **'Keep Breakdex clips muted so your music can keep playing.'**
  String get setViewKeepMusicSubtitle;

  /// Title for the toggle that shows the move or combo name on the review card.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get setViewTitleTitle;

  /// Subtitle explaining the title toggle displays the move or combo name on the review card.
  ///
  /// In en, this message translates to:
  /// **'Show the move or combo name on the card.'**
  String get setViewTitleSubtitle;

  /// Title for the toggle that shows the learning-state pill on the review card.
  ///
  /// In en, this message translates to:
  /// **'State pill'**
  String get setViewStatePillTitle;

  /// Subtitle explaining the state pill toggle shows the current NEW, LEARNING, or MASTERY status pill.
  ///
  /// In en, this message translates to:
  /// **'Show the current NEW / LEARNING / MASTERY pill.'**
  String get setViewStatePillSubtitle;

  /// Title for the toggle that shows move category labels on the review card.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get setViewCategoryTitle;

  /// Subtitle explaining the category toggle shows move category labels such as TOPROCK or FOOTWORK.
  ///
  /// In en, this message translates to:
  /// **'Show move categories like TOPROCK or FOOTWORK.'**
  String get setViewCategorySubtitle;

  /// Title for the toggle that shows the step-navigation timeline when reviewing combos.
  ///
  /// In en, this message translates to:
  /// **'Combo timeline'**
  String get setViewComboTimelineTitle;

  /// Subtitle explaining the combo timeline toggle shows step navigation while reviewing combos.
  ///
  /// In en, this message translates to:
  /// **'Show step navigation when reviewing combos.'**
  String get setViewComboTimelineSubtitle;

  /// Title for the toggle that shows the active combo step name under the timeline.
  ///
  /// In en, this message translates to:
  /// **'Step label'**
  String get setViewStepLabelTitle;

  /// Subtitle explaining the step label toggle shows the active combo step name beneath the timeline.
  ///
  /// In en, this message translates to:
  /// **'Show the active combo step name under the timeline.'**
  String get setViewStepLabelSubtitle;

  /// Title for the toggle that shows playback speed and loop controls on the review card.
  ///
  /// In en, this message translates to:
  /// **'Speed + loop controls'**
  String get setViewPlaybackControlsTitle;

  /// Subtitle explaining the playback controls toggle shows loop and speed controls on the review card.
  ///
  /// In en, this message translates to:
  /// **'Show loop and speed controls on the card.'**
  String get setViewPlaybackControlsSubtitle;

  /// Learning-mode toggle label for the built-in default set of learning states (as opposed to the user's custom set).
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get setStatesModeDefault;

  /// Learning-mode toggle label that switches the review states section to the user's custom learning states.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get setStatesModeCustom;

  /// Subtitle under a user-created learning-state row, marking it as a custom (non-default) state.
  ///
  /// In en, this message translates to:
  /// **'Custom state'**
  String get setStatesCustomStateSubtitle;

  /// Title of the list row that opens the dialog for creating a new custom learning state.
  ///
  /// In en, this message translates to:
  /// **'Add Custom State'**
  String get setStatesAddTitle;

  /// Subtitle under the 'Add Custom State' row explaining that it creates a new learning category.
  ///
  /// In en, this message translates to:
  /// **'Create a new learning category'**
  String get setStatesAddSubtitle;

  /// Subtitle shown under a renamed learning state, reminding the user of the state's original built-in label.
  ///
  /// In en, this message translates to:
  /// **'Default: {label}'**
  String setStatesDefaultLabel(String label);

  /// Title of the color-editor dialog for a learning state, composing the state's current label.
  ///
  /// In en, this message translates to:
  /// **'{label} Color'**
  String setStatesColorTitle(String label);

  /// Explanatory subtitle in the learning-state color-editor dialog, naming the state whose color is being edited.
  ///
  /// In en, this message translates to:
  /// **'Choose any color for {label}. Quick picks, spectrum tuning, hex, and RGBA sliders stay in sync.'**
  String setStatesColorSubtitle(String label);

  /// Title of the dialog for creating a brand-new custom learning state.
  ///
  /// In en, this message translates to:
  /// **'New Custom State'**
  String get setStatesNewTitle;

  /// Placeholder hint text in the text field where the user types a custom learning state's name.
  ///
  /// In en, this message translates to:
  /// **'State name'**
  String get setStatesNameHint;

  /// Title of the color-picker tile inside the custom-state create/edit dialog.
  ///
  /// In en, this message translates to:
  /// **'State color'**
  String get setStatesColorTileTitle;

  /// Title of the color-editor dialog opened from the custom-state create/edit dialog.
  ///
  /// In en, this message translates to:
  /// **'Custom State Color'**
  String get setStatesCustomColorTitle;

  /// Short subtitle in the custom-state color-editor dialog inviting the user to pick any color.
  ///
  /// In en, this message translates to:
  /// **'Pick any color.'**
  String get setStatesCustomColorSubtitle;

  /// Button that dismisses the custom-state create or edit dialog without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get setStatesCancel;

  /// Confirm button that creates the new custom learning state in the create dialog.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get setStatesAdd;

  /// Title of the dialog for editing an existing custom learning state.
  ///
  /// In en, this message translates to:
  /// **'Edit Custom State'**
  String get setStatesEditTitle;

  /// Confirm button that saves changes to an existing custom learning state in the edit dialog.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get setStatesSave;

  /// Default title for the color-picker dialog, used when a caller does not supply its own title.
  ///
  /// In en, this message translates to:
  /// **'Choose Color'**
  String get setColorPickerDefaultTitle;

  /// Section label above the hex color code text field in the color-picker dialog.
  ///
  /// In en, this message translates to:
  /// **'Hex'**
  String get setColorHexLabel;

  /// Helper text under the hex field telling the user which hex formats are accepted (6-digit RGB or 8-digit alpha-RGB).
  ///
  /// In en, this message translates to:
  /// **'RRGGBB or AARRGGBB'**
  String get setColorHexHelper;

  /// Section label above the hue/saturation/value gradient sliders in the color-picker dialog.
  ///
  /// In en, this message translates to:
  /// **'Spectrum'**
  String get setColorSpectrumLabel;

  /// Accessibility and display label for the hue slider in the color-picker dialog.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get setColorHueLabel;

  /// Accessibility and display label for the saturation slider in the color-picker dialog.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get setColorSaturationLabel;

  /// Accessibility and display label for the brightness/value slider in the color-picker dialog.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get setColorValueLabel;

  /// Section label above the preset color swatches in the color-picker dialog.
  ///
  /// In en, this message translates to:
  /// **'Quick picks'**
  String get setColorQuickPicksLabel;

  /// Accessibility and display label for the opacity (alpha) slider in the color-picker dialog.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get setColorOpacityLabel;

  /// Accessibility and display label for the red RGB channel slider in the color-picker dialog.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get setColorRedLabel;

  /// Accessibility and display label for the green RGB channel slider in the color-picker dialog.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get setColorGreenLabel;

  /// Accessibility and display label for the blue RGB channel slider in the color-picker dialog.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get setColorBlueLabel;

  /// Label for the button that dismisses the color-picker dialog without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get setColorCancelButton;

  /// Label for the button that confirms and returns the chosen color from the color-picker dialog.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get setColorSaveButton;

  /// Cloud-sync settings panel: section header above the backup-provider list.
  ///
  /// In en, this message translates to:
  /// **'VIDEO BACKUP'**
  String get setSyncSectionHeader;

  /// Sync health: how many live videos still lack a verified cloud copy (Video Backup subtitle + Sync Status header). Computed from the database, never a default.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 video waiting to back up} other{{count} videos waiting to back up}}'**
  String setSyncPendingCount(int count);

  /// Sync health: shown only when the database proves zero videos lack a verified cloud copy.
  ///
  /// In en, this message translates to:
  /// **'All synced'**
  String get setSyncAllSynced;

  /// Sync health: transient label while the pending-backup count is still being read from the database.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get setSyncChecking;

  /// Sync Status: section header above the per-video backup detail list.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get setSyncVideosHeader;

  /// Sync Status: shown when the asset manifest holds no live videos, so there is nothing to back up.
  ///
  /// In en, this message translates to:
  /// **'No videos are being tracked yet.'**
  String get setSyncNoVideosTracked;

  /// Sync Status summary chip: videos whose bytes are moving right now.
  ///
  /// In en, this message translates to:
  /// **'{count} uploading'**
  String setSyncTallyUploading(int count);

  /// Sync Status summary chip: videos queued or untouched — nothing moving yet.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String setSyncTallyWaiting(int count);

  /// Sync Status summary chip: videos whose last upload failed and will be attempted again.
  ///
  /// In en, this message translates to:
  /// **'{count} retrying'**
  String setSyncTallyRetrying(int count);

  /// Sync Status summary chip: videos under a terminal verdict — bytes provably nowhere (task 4.4). The sweep skips them, so 'can't' is a kept promise; the verdict is revoked automatically when the bytes re-home (restore/re-import).
  ///
  /// In en, this message translates to:
  /// **'{count} can\'t be backed up'**
  String setSyncTallyStuck(int count);

  /// Sync Status summary chip: videos a cloud provider holds a verified copy of.
  ///
  /// In en, this message translates to:
  /// **'{count} backed up'**
  String setSyncTallyBackedUp(int count);

  /// Sync Status row: byte progress of the active transfer for one video.
  ///
  /// In en, this message translates to:
  /// **'{transferred} of {total} · {percent}%'**
  String setSyncDetailUploading(String transferred, String total, int percent);

  /// Sync Status row: the transfer began but no bytes have been reported yet, so no percentage is shown rather than a fabricated 0%.
  ///
  /// In en, this message translates to:
  /// **'Starting · {total}'**
  String setSyncDetailStarting(String total);

  /// Sync Status row: an upload operation exists but has not started.
  ///
  /// In en, this message translates to:
  /// **'Queued · {total}'**
  String setSyncDetailQueued(String total);

  /// Sync Status row: no cloud copy, nothing queued, nothing failed.
  ///
  /// In en, this message translates to:
  /// **'Not backed up · {total}'**
  String setSyncDetailPending(String total);

  /// Sync Status row: last upload failed, engine will retry, error text known.
  ///
  /// In en, this message translates to:
  /// **'Retrying after: {error}'**
  String setSyncDetailRetrying(String error);

  /// Sync Status row: last upload failed with no recorded error text; engine will retry.
  ///
  /// In en, this message translates to:
  /// **'Retrying after a failed upload'**
  String get setSyncDetailRetryingUnknown;

  /// Sync Status row: terminal verdict (bytes nowhere, task 4.4) with error text. Honest since 4.4: queueUpload consults the verdict, so the sweep really does not re-queue this asset until its bytes re-home.
  ///
  /// In en, this message translates to:
  /// **'Won\'t retry — {error}'**
  String setSyncDetailStuck(String error);

  /// Sync Status row: terminal verdict (bytes nowhere, task 4.4) with no recorded error text.
  ///
  /// In en, this message translates to:
  /// **'Won\'t retry — the video file is nowhere on this device'**
  String get setSyncDetailStuckUnknown;

  /// Cloud-sync settings: row title for the iCloud Drive backup provider.
  ///
  /// In en, this message translates to:
  /// **'iCloud Drive'**
  String get setSyncProviderIcloudTitle;

  /// Cloud-sync settings: row title for the Google Drive backup provider.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get setSyncProviderGdriveTitle;

  /// Cloud-sync settings: row title for the S3-compatible backup provider (coming soon).
  ///
  /// In en, this message translates to:
  /// **'S3 Compatible'**
  String get setSyncProviderS3Title;

  /// Cloud-sync settings: action tile that forces a fresh manifest push to the connected cloud provider.
  ///
  /// In en, this message translates to:
  /// **'Re-upload library now'**
  String get setSyncReuploadTile;

  /// Cloud-sync settings: action tile that opens the sync-status screen.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get setSyncStatusTile;

  /// Cloud-sync settings: action tile that opens the free-up-space screen.
  ///
  /// In en, this message translates to:
  /// **'Free Up Space'**
  String get setSyncFreeSpaceTile;

  /// Cloud-sync settings: action tile that opens the backup help/explainer screen.
  ///
  /// In en, this message translates to:
  /// **'How Backup Works'**
  String get setSyncHelpTile;

  /// Cloud-sync settings: transient snackbar shown while the library manifest is being re-uploaded.
  ///
  /// In en, this message translates to:
  /// **'Re-uploading library…'**
  String get setSyncReuploading;

  /// Cloud-sync settings: snackbar confirming the library manifest was re-uploaded successfully.
  ///
  /// In en, this message translates to:
  /// **'Library re-uploaded — refresh the web mirror'**
  String get setSyncReuploadSuccess;

  /// Cloud-sync settings: snackbar shown when re-upload is attempted but no cloud provider is connected.
  ///
  /// In en, this message translates to:
  /// **'No cloud provider connected to upload to'**
  String get setSyncReuploadNoProvider;

  /// Cloud-sync settings: snackbar shown when the library re-upload throws; includes the raw error text.
  ///
  /// In en, this message translates to:
  /// **'Re-upload failed: {error}'**
  String setSyncReuploadFailed(String error);

  /// Drive row subtitle naming the Google account that holds the video backup, so the user always knows where their videos live.
  ///
  /// In en, this message translates to:
  /// **'Connected · {email}'**
  String setSyncGdriveConnectedAccount(String email);

  /// Drive row subtitle on web, where Google Drive video backup cannot be set up — the row renders unavailable instead of offering a sign-in that can only fail.
  ///
  /// In en, this message translates to:
  /// **'Backup runs from your phone'**
  String get setSyncGdriveWebUnavailable;

  /// Cloud-sync settings: snackbar confirming Google Drive was newly connected.
  ///
  /// In en, this message translates to:
  /// **'Google Drive connected'**
  String get setSyncGdriveConnected;

  /// Cloud-sync settings: snackbar shown when Google Drive is tapped to enable but was already connected.
  ///
  /// In en, this message translates to:
  /// **'Google Drive is already connected'**
  String get setSyncGdriveAlreadyConnected;

  /// Cloud-sync settings: snackbar shown when the user cancels the Google sign-in flow while enabling Drive.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled'**
  String get setSyncGdriveCancelled;

  /// Cloud-sync settings: title of the confirmation dialog for disconnecting Google Drive.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Google Drive?'**
  String get setSyncDisconnectTitle;

  /// Cloud-sync settings: body of the disconnect-Google-Drive confirmation dialog explaining what happens to existing and future backups.
  ///
  /// In en, this message translates to:
  /// **'Videos already backed up to Drive stay there. New videos won’t back up until you reconnect and sign in again.'**
  String get setSyncDisconnectBody;

  /// Cloud-sync settings: cancel button in the disconnect-Google-Drive confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get setSyncDisconnectCancel;

  /// Cloud-sync settings: confirm button in the disconnect-Google-Drive confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get setSyncDisconnectConfirm;

  /// Cloud-sync settings: snackbar confirming Google Drive was disconnected.
  ///
  /// In en, this message translates to:
  /// **'Google Drive disconnected'**
  String get setSyncGdriveDisconnected;

  /// Cloud-sync settings: snackbar confirming iCloud Drive was newly enabled.
  ///
  /// In en, this message translates to:
  /// **'iCloud Drive enabled'**
  String get setSyncIcloudEnabled;

  /// Cloud-sync settings: snackbar shown when iCloud is tapped to enable but was already enabled.
  ///
  /// In en, this message translates to:
  /// **'iCloud Drive is already enabled'**
  String get setSyncIcloudAlreadyEnabled;

  /// Cloud-sync settings: snackbar instructing the user how to turn on iCloud Drive at the OS level when it is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Enable iCloud Drive in iOS Settings > [your name] > iCloud'**
  String get setSyncIcloudNotAvailable;

  /// Cloud-sync settings: trailing status label on a provider row that is connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get setSyncStatusConnected;

  /// Cloud-sync settings: trailing status label on a provider row that is available to enable.
  ///
  /// In en, this message translates to:
  /// **'Tap to enable'**
  String get setSyncStatusTapToEnable;

  /// Cloud-sync settings: trailing status label on a provider row that is unavailable on this device.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get setSyncStatusNotAvailable;

  /// Cloud-sync settings: trailing status label on a provider row that is not yet supported (e.g. S3).
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get setSyncStatusComingSoon;

  /// Library sort control: order by when the move or combo was added to the library (newest first).
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get librarySortAdded;

  /// Library sort control: order by when the video was actually filmed (newest first).
  ///
  /// In en, this message translates to:
  /// **'Filmed'**
  String get librarySortFilmed;

  /// Library sort control: order by when the move or combo was last practiced or edited (most recent first).
  ///
  /// In en, this message translates to:
  /// **'Practiced'**
  String get librarySortPracticed;

  /// Library sort control: order alphabetically by name.
  ///
  /// In en, this message translates to:
  /// **'A–Z'**
  String get librarySortAlphabetical;

  /// Shown on the combos tab when the filmed-date sort is active. Combos are not filmed, so the list falls back to the added date and says so rather than faking a capture date.
  ///
  /// In en, this message translates to:
  /// **'{combos} have no filmed date — showing most recently added.'**
  String libraryFilmedFallbackForCombos(String combos);

  /// Library month-section header for the calendar month the user is currently in.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get libraryMonthThis;

  /// Library month-section header for the calendar month immediately before the current one.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get libraryMonthLast;

  /// Library row/tile date line when the item's date for the active sort is the current calendar day.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get libraryDateToday;

  /// Library row/tile date line when the item's date for the active sort is the previous calendar day.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get libraryDateYesterday;

  /// Library row/tile date line for the recent past, two to six calendar days back. One day back reads as 'Yesterday' instead.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} days ago}}'**
  String libraryDateDaysAgo(int count);

  /// Library row subtitle when the shown date is when the item was added to the library. The date is already localized and may be relative ('3 days ago') or absolute ('Jan 5, 2026').
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String libraryDateAdded(String date);

  /// Library row subtitle when the shown date is when the video was actually filmed. Only used when a capture date really exists; an item without one is labeled with libraryDateAdded instead.
  ///
  /// In en, this message translates to:
  /// **'Filmed {date}'**
  String libraryDateFilmed(String date);

  /// Library row subtitle when the shown date is when the item was last practiced or edited.
  ///
  /// In en, this message translates to:
  /// **'Practiced {date}'**
  String libraryDatePracticed(String date);

  /// Library category tile date line, in place of a date, when the category holds no items. Deliberately does not name the entity: that noun is user-configurable, so it cannot be baked into a translated string.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get libraryCategoryEmpty;

  /// Settings Backup & Reset: generic error snackbar when an async data action throws.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String setError(String error);
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
