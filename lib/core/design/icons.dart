import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Semantic icon vocabulary for Breakdex.
///
/// Every name states a **meaning** a screen can articulate. No name describes
/// stroke, weight, or terminal — that is the pack's job. Adding a name here
/// means adding a case in every pack in the same commit.
enum AppIcon {
  // ── Navigation ──────────────────────────────────────────────────────────
  back,
  forward,
  close,
  menu,
  expandMore,
  expandLess,
  search,
  more,
  settings,
  filter,
  up,
  down,
  forwardIos,
  backIos,

  // ── Actions ─────────────────────────────────────────────────────────────
  add,
  delete,
  edit,
  save,
  share,
  check,
  copy,
  refresh,
  download,
  upload,
  remove,
  link,

  // ── Video / Media ───────────────────────────────────────────────────────
  video,
  videoOff,
  play,
  pause,
  skip,
  replay,
  repeat,
  shuffle,
  volume,
  volumeOff,
  music,
  photo,
  camera,

  // ── Review / Learning ──────────────────────────────────────────────────
  star,
  schedule,
  calendar,
  timer,
  school,
  celebration,
  flashcard,
  rate,

  // ── Status ──────────────────────────────────────────────────────────────
  error,
  warning,
  info,
  help,
  success,
  empty,
  cloud,
  cloudDone,

  // ── Sync / Storage ──────────────────────────────────────────────────────
  sync,
  storage,
  folder,
  trash,
  restore,
  drive,

  // ── Content / Lab ───────────────────────────────────────────────────────
  lab,
  move,
  combo,
  graph,
  timeline,
  insight,
  achievement,
  discover,
  notes,

  // ── Layout ──────────────────────────────────────────────────────────────
  grid,
  list,
  sort,
  fullscreen,
  fullscreenExit,
  glance,
  scan,
  study,

  // ── Places ──────────────────────────────────────────────────────────────
  /// The catalogue itself — the index of everything you know. A book, not a
  /// grid: the grid described the *layout* of the screen, which stops being
  /// true the moment the screen changes shape.
  library,

  /// Where practice happens. The training floor, not the act of studying.
  dojo,
}

/// An icon pack resolves every [AppIcon] to an [IconData].
///
/// Resolution is a `switch` with **no `default`**, so Dart's exhaustiveness
/// check makes an incomplete pack a compile error — completeness is proven by
/// the compiler, not asserted in review.
abstract class IconPack {
  IconData resolve(AppIcon icon);
}

/// Default Material Design icon pack.
///
/// Glyph-preserving for every semantic name fed by exactly one Material glyph.
/// Where two or more Material glyphs collapse into one semantic name, the
/// surviving glyph is chosen deliberately (see `docs/design/TOKENS.md` →
/// Iconography → collapse ledger).
final class MaterialPack implements IconPack {
  @override
  IconData resolve(final AppIcon icon) => switch (icon) {
    // Navigation
    AppIcon.back => Icons.chevron_left_rounded,
    AppIcon.forward => Icons.chevron_right_rounded,
    AppIcon.close => Icons.close_rounded,
    AppIcon.menu => Icons.linear_scale_rounded,
    AppIcon.expandMore => Icons.expand_more_rounded,
    AppIcon.expandLess => Icons.expand_less_rounded,
    AppIcon.search => Icons.search_rounded,
    AppIcon.more => Icons.more_horiz_rounded,
    AppIcon.settings => Icons.settings_outlined,
    AppIcon.filter => Icons.filter_list_rounded,
    AppIcon.up => Icons.arrow_upward_rounded,
    AppIcon.down => Icons.arrow_downward_rounded,
    AppIcon.forwardIos => Icons.arrow_forward_ios_rounded,
    AppIcon.backIos => Icons.arrow_back_ios_new,

    // Actions
    AppIcon.add => Icons.add_rounded,
    AppIcon.delete => Icons.delete_outline,
    AppIcon.edit => Icons.edit_outlined,
    AppIcon.save => Icons.save_alt_outlined,
    AppIcon.share => Icons.ios_share,
    AppIcon.check => Icons.check_rounded,
    AppIcon.copy => Icons.copy_rounded,
    AppIcon.refresh => Icons.refresh,
    AppIcon.download => Icons.cloud_download_outlined,
    AppIcon.upload => Icons.cloud_upload_outlined,
    AppIcon.remove => Icons.remove_rounded,
    AppIcon.link => Icons.link_rounded,

    // Video / Media
    AppIcon.video => Icons.videocam_rounded,
    AppIcon.videoOff => Icons.videocam_off,
    AppIcon.play => Icons.play_circle_filled_rounded,
    AppIcon.pause => Icons.pause_circle_filled_rounded,
    AppIcon.skip => Icons.skip_next_rounded,
    AppIcon.replay => Icons.replay_rounded,
    AppIcon.repeat => Icons.repeat_rounded,
    AppIcon.shuffle => Icons.shuffle,
    AppIcon.volume => Icons.volume_up_rounded,
    AppIcon.volumeOff => Icons.volume_off_rounded,
    AppIcon.music => Icons.music_note_rounded,
    AppIcon.photo => Icons.photo_library_outlined,
    AppIcon.camera => Icons.camera_alt,

    // Review / Learning
    AppIcon.star => Icons.star_rounded,
    AppIcon.schedule => Icons.schedule_rounded,
    AppIcon.calendar => Icons.calendar_today_rounded,
    AppIcon.timer => Icons.timer_outlined,
    AppIcon.school => Icons.school,
    AppIcon.celebration => Icons.celebration_outlined,
    AppIcon.flashcard => Icons.auto_awesome_rounded,
    AppIcon.rate => Icons.recommend_rounded,

    // Status
    AppIcon.error => Icons.error_outline,
    AppIcon.warning => Icons.warning_amber_rounded,
    AppIcon.info => Icons.info_outline_rounded,
    AppIcon.help => Icons.help_outline,
    AppIcon.success => Icons.check_circle_rounded,
    AppIcon.empty => Icons.pending_outlined,
    AppIcon.cloud => Icons.cloud_outlined,
    AppIcon.cloudDone => Icons.cloud_done_outlined,

    // Sync / Storage
    AppIcon.sync => Icons.sync,
    AppIcon.storage => Icons.storage_outlined,
    AppIcon.folder => Icons.folder_outlined,
    AppIcon.trash => Icons.delete_outline,
    AppIcon.restore => Icons.restore_from_trash_outlined,
    AppIcon.drive => Icons.add_to_drive_outlined,

    // Content / Lab
    AppIcon.lab => Icons.science_outlined,
    AppIcon.move => Icons.sports_martial_arts,
    AppIcon.combo => Icons.playlist_play_rounded,
    AppIcon.graph => Icons.bar_chart_rounded,
    AppIcon.timeline => Icons.timeline_rounded,
    AppIcon.insight => Icons.insights_rounded,
    AppIcon.achievement => Icons.auto_awesome_motion_outlined,
    AppIcon.discover => Icons.auto_awesome,
    AppIcon.notes => Icons.notes_rounded,

    // Layout
    AppIcon.grid => Icons.grid_view_rounded,
    AppIcon.list => Icons.view_list_rounded,
    AppIcon.sort => Icons.sort_by_alpha_rounded,
    AppIcon.fullscreen => Icons.fullscreen_rounded,
    AppIcon.fullscreenExit => Icons.fullscreen_exit_rounded,
    AppIcon.glance => Icons.view_agenda_rounded,
    AppIcon.scan => Icons.grid_view_rounded,
    AppIcon.study => Icons.layers_rounded,

    // Places
    AppIcon.library => Icons.menu_book_rounded,
    AppIcon.dojo => Icons.self_improvement,
  };
}

/// Lucide icon pack — the hand-drawn, even-stroke family.
///
/// MIT license, 160/160 pub points. Every name is hand-mapped to the closest
/// Lucide equivalent; if a name has no perfect match, the closest semantic
/// analogue is used and noted in TOKENS.md.
final class LucidePack implements IconPack {
  @override
  IconData resolve(final AppIcon icon) => switch (icon) {
    // Navigation
    AppIcon.back => LucideIcons.chevronLeft,
    AppIcon.forward => LucideIcons.chevronRight,
    AppIcon.close => LucideIcons.x,
    AppIcon.menu => LucideIcons.menu,
    AppIcon.expandMore => LucideIcons.chevronDown,
    AppIcon.expandLess => LucideIcons.chevronUp,
    AppIcon.search => LucideIcons.search,
    AppIcon.more => LucideIcons.moreHorizontal,
    AppIcon.settings => LucideIcons.settings,
    AppIcon.filter => LucideIcons.slidersHorizontal,
    AppIcon.up => LucideIcons.arrowUp,
    AppIcon.down => LucideIcons.arrowDown,
    AppIcon.forwardIos => LucideIcons.chevronsRight,
    AppIcon.backIos => LucideIcons.chevronsLeft,

    // Actions
    AppIcon.add => LucideIcons.plus,
    AppIcon.delete => LucideIcons.trash2,
    AppIcon.edit => LucideIcons.pencil,
    AppIcon.save => LucideIcons.save,
    AppIcon.share => LucideIcons.share2,
    AppIcon.check => LucideIcons.check,
    AppIcon.copy => LucideIcons.copy,
    AppIcon.refresh => LucideIcons.refreshCw,
    AppIcon.download => LucideIcons.download,
    AppIcon.upload => LucideIcons.upload,
    AppIcon.remove => LucideIcons.minus,
    AppIcon.link => LucideIcons.link,

    // Video / Media
    AppIcon.video => LucideIcons.video,
    AppIcon.videoOff => LucideIcons.videoOff,
    AppIcon.play => LucideIcons.play,
    AppIcon.pause => LucideIcons.pause,
    AppIcon.skip => LucideIcons.skipForward,
    AppIcon.replay => LucideIcons.rotateCcw,
    AppIcon.repeat => LucideIcons.repeat,
    AppIcon.shuffle => LucideIcons.shuffle,
    AppIcon.volume => LucideIcons.volume2,
    AppIcon.volumeOff => LucideIcons.volumeX,
    AppIcon.music => LucideIcons.music,
    AppIcon.photo => LucideIcons.image,
    AppIcon.camera => LucideIcons.camera,

    // Review / Learning
    AppIcon.star => LucideIcons.star,
    AppIcon.schedule => LucideIcons.clock,
    AppIcon.calendar => LucideIcons.calendar,
    AppIcon.timer => LucideIcons.timer,
    AppIcon.school => LucideIcons.graduationCap,
    AppIcon.celebration => LucideIcons.partyPopper,
    AppIcon.flashcard => LucideIcons.zap,
    AppIcon.rate => LucideIcons.thumbsUp,

    // Status
    AppIcon.error => LucideIcons.alertCircle,
    AppIcon.warning => LucideIcons.alertTriangle,
    AppIcon.info => LucideIcons.info,
    AppIcon.help => LucideIcons.helpCircle,
    AppIcon.success => LucideIcons.checkCircle,
    AppIcon.empty => LucideIcons.inbox,
    AppIcon.cloud => LucideIcons.cloud,
    AppIcon.cloudDone => LucideIcons.cloudCheck,

    // Sync / Storage
    AppIcon.sync => LucideIcons.refreshCw,
    AppIcon.storage => LucideIcons.hardDrive,
    AppIcon.folder => LucideIcons.folder,
    AppIcon.trash => LucideIcons.trash2,
    AppIcon.restore => LucideIcons.archive,
    AppIcon.drive => LucideIcons.database,

    // Content / Lab
    AppIcon.lab => LucideIcons.flaskConical,
    AppIcon.move => LucideIcons.dumbbell,
    AppIcon.combo => LucideIcons.listMusic,
    AppIcon.graph => LucideIcons.barChart3,
    AppIcon.timeline => LucideIcons.clock,
    AppIcon.insight => LucideIcons.lightbulb,
    AppIcon.achievement => LucideIcons.trophy,
    AppIcon.discover => LucideIcons.compass,
    AppIcon.notes => LucideIcons.fileText,

    // Layout
    AppIcon.grid => LucideIcons.layoutGrid,
    AppIcon.list => LucideIcons.list,
    AppIcon.sort => LucideIcons.arrowUpDown,
    AppIcon.fullscreen => LucideIcons.maximize2,
    AppIcon.fullscreenExit => LucideIcons.minimize2,
    AppIcon.glance => LucideIcons.eye,
    AppIcon.scan => LucideIcons.scanLine,
    AppIcon.study => LucideIcons.bookOpen,

    // Places
    AppIcon.library => LucideIcons.book,
    AppIcon.dojo => LucideIcons.swords,
  };
}

/// Apple's Cupertino (SF-derived) pack — the **default**.
///
/// Shipped as the default so the icon vocabulary is identical on Android and
/// web, not just on iOS. Flutter bundles `CupertinoIcons` as a font asset, so
/// these glyphs render the same on every platform rather than deferring to a
/// host icon set — that platform-independence is the whole reason this is the
/// default pack rather than an iOS-only branch.
///
/// A handful of semantic names have no Cupertino glyph (`videoOff` has no
/// slashed camera). Those resolve to the nearest honest analogue and are noted
/// inline; a wrong-but-close glyph beats a missing one, and the collapse is
/// recorded rather than hidden.
final class CupertinoPack implements IconPack {
  @override
  IconData resolve(final AppIcon icon) => switch (icon) {
    // Navigation
    AppIcon.back => CupertinoIcons.chevron_back,
    AppIcon.forward => CupertinoIcons.chevron_forward,
    AppIcon.close => CupertinoIcons.xmark,
    AppIcon.menu => CupertinoIcons.line_horizontal_3,
    AppIcon.expandMore => CupertinoIcons.chevron_down,
    AppIcon.expandLess => CupertinoIcons.chevron_up,
    AppIcon.search => CupertinoIcons.search,
    AppIcon.more => CupertinoIcons.ellipsis,
    AppIcon.settings => CupertinoIcons.gear,
    AppIcon.filter => CupertinoIcons.line_horizontal_3_decrease,
    AppIcon.up => CupertinoIcons.arrow_up,
    AppIcon.down => CupertinoIcons.arrow_down,
    AppIcon.forwardIos => CupertinoIcons.chevron_right,
    AppIcon.backIos => CupertinoIcons.chevron_left,

    // Actions
    AppIcon.add => CupertinoIcons.plus,
    AppIcon.delete => CupertinoIcons.trash,
    AppIcon.edit => CupertinoIcons.pencil,
    AppIcon.save => CupertinoIcons.tray_arrow_down,
    AppIcon.share => CupertinoIcons.share,
    AppIcon.check => CupertinoIcons.checkmark,
    AppIcon.copy => CupertinoIcons.doc_on_doc,
    AppIcon.refresh => CupertinoIcons.arrow_clockwise,
    AppIcon.download => CupertinoIcons.cloud_download,
    AppIcon.upload => CupertinoIcons.cloud_upload,
    AppIcon.remove => CupertinoIcons.minus,
    AppIcon.link => CupertinoIcons.link,

    // Video / Media
    AppIcon.video => CupertinoIcons.videocam,
    // No slashed-camera glyph in Cupertino; `nosign` reads as "not recording".
    AppIcon.videoOff => CupertinoIcons.nosign,
    AppIcon.play => CupertinoIcons.play_fill,
    AppIcon.pause => CupertinoIcons.pause_fill,
    AppIcon.skip => CupertinoIcons.forward_end_fill,
    AppIcon.replay => CupertinoIcons.arrow_counterclockwise,
    AppIcon.repeat => CupertinoIcons.repeat,
    AppIcon.shuffle => CupertinoIcons.shuffle,
    AppIcon.volume => CupertinoIcons.speaker_2_fill,
    AppIcon.volumeOff => CupertinoIcons.speaker_slash_fill,
    AppIcon.music => CupertinoIcons.music_note,
    AppIcon.photo => CupertinoIcons.photo,
    AppIcon.camera => CupertinoIcons.camera,

    // Review / Learning
    AppIcon.star => CupertinoIcons.star_fill,
    AppIcon.schedule => CupertinoIcons.clock,
    AppIcon.calendar => CupertinoIcons.calendar,
    AppIcon.timer => CupertinoIcons.timer,
    AppIcon.school => CupertinoIcons.book,
    AppIcon.celebration => CupertinoIcons.sparkles,
    AppIcon.flashcard => CupertinoIcons.square_stack_3d_up,
    AppIcon.rate => CupertinoIcons.hand_thumbsup,

    // Status
    AppIcon.error => CupertinoIcons.exclamationmark_circle,
    AppIcon.warning => CupertinoIcons.exclamationmark_triangle,
    AppIcon.info => CupertinoIcons.info_circle,
    AppIcon.help => CupertinoIcons.question_circle,
    AppIcon.success => CupertinoIcons.checkmark_circle_fill,
    AppIcon.empty => CupertinoIcons.tray,
    AppIcon.cloud => CupertinoIcons.cloud,
    AppIcon.cloudDone => CupertinoIcons.cloud_fill,

    // Sync / Storage
    AppIcon.sync => CupertinoIcons.arrow_2_circlepath,
    AppIcon.storage => CupertinoIcons.tray_full,
    AppIcon.folder => CupertinoIcons.folder,
    AppIcon.trash => CupertinoIcons.trash,
    AppIcon.restore => CupertinoIcons.arrow_uturn_left,
    AppIcon.drive => CupertinoIcons.archivebox,

    // Content / Lab
    AppIcon.lab => CupertinoIcons.lab_flask,
    AppIcon.move => CupertinoIcons.person_alt,
    AppIcon.combo => CupertinoIcons.list_bullet,
    AppIcon.graph => CupertinoIcons.chart_bar,
    AppIcon.timeline => CupertinoIcons.waveform_path,
    AppIcon.insight => CupertinoIcons.lightbulb,
    AppIcon.achievement => CupertinoIcons.rosette,
    AppIcon.discover => CupertinoIcons.compass,
    AppIcon.notes => CupertinoIcons.doc_text,

    // Layout
    AppIcon.grid => CupertinoIcons.square_grid_2x2,
    AppIcon.list => CupertinoIcons.list_bullet,
    AppIcon.sort => CupertinoIcons.arrow_up_arrow_down,
    AppIcon.fullscreen => CupertinoIcons.fullscreen,
    AppIcon.fullscreenExit => CupertinoIcons.fullscreen_exit,
    AppIcon.glance => CupertinoIcons.rectangle_grid_1x2,
    AppIcon.scan => CupertinoIcons.viewfinder,
    AppIcon.study => CupertinoIcons.square_stack,

    // Places
    AppIcon.library => CupertinoIcons.book,
    // The training floor. `sportscourt` is the only Cupertino glyph that means
    // a place you practise in rather than an activity you perform.
    AppIcon.dojo => CupertinoIcons.sportscourt,
  };
}

/// Identifies a pack for persistence and lookup.
///
/// Stored as a string key in SharedPreferences (`icon_pack`). The `fromKey`
/// factory tolerates unknown values so removing a pack never bricks a client.
enum IconPackId {
  cupertino,
  material,
  lucide;

  /// Unknown and absent keys both fall to [cupertino] — the default pack, so a
  /// client that has never chosen one gets the same vocabulary on every OS.
  static IconPackId fromKey(final String? key) => switch (key) {
    'lucide' => IconPackId.lucide,
    'material' => IconPackId.material,
    _ => IconPackId.cupertino,
  };

  String get key => name;

  IconPack build() => switch (this) {
    IconPackId.cupertino => CupertinoPack(),
    IconPackId.material => MaterialPack(),
    IconPackId.lucide => LucidePack(),
  };
}

/// [ThemeExtension] that carries the active [IconPack].
///
/// Built from `iconPackProvider` in `theme.dart`. Widgets read it through
/// `AppIcon.resolve(context)` and never watch the provider directly.
final class AppIconPackTheme extends ThemeExtension<AppIconPackTheme> {
  const AppIconPackTheme(this.pack);

  final IconPack pack;

  static AppIconPackTheme of(final BuildContext context) {
    final ext = Theme.of(context).extension<AppIconPackTheme>();
    if (ext != null) return ext;
    return AppIconPackTheme(MaterialPack());
  }

  @override
  AppIconPackTheme copyWith({final IconPack? pack}) {
    return AppIconPackTheme(pack ?? this.pack);
  }

  @override
  AppIconPackTheme lerp(
    final ThemeExtension<AppIconPackTheme>? other,
    final double t,
  ) {
    if (other is! AppIconPackTheme) return this;
    return AppIconPackTheme(other.pack);
  }
}

/// Resolve this icon using the active pack from [context].
extension AppIconResolve on AppIcon {
  IconData resolve(final BuildContext context) =>
    AppIconPackTheme.of(context).pack.resolve(this);
}

/// Thin widget rendering an [AppIcon] from the active pack.
///
/// Prefer this over `AppIconView(AppIcon.foo)` for the common case:
/// it carries the default [size] and [color] so those stop being restated at
/// every call site.
final class AppIconView extends StatelessWidget {
  const AppIconView(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final AppIcon icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Icon(
          icon.resolve(context),
          size: size ?? theme.iconTheme.size ?? 24,
          color: color ?? theme.iconTheme.color,
        ),
      ),
    );
  }
}
