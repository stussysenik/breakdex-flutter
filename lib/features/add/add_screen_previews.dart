// Preview entries for the /add flow. Safe to edit — add @Preview variants
// (sizes, brightness, seeded states) as you iterate on these surfaces.
//
// The flow is three surfaces in order: AddScreen (choose what to add) →
// VideoPickerSheet (choose a source) → ClipMetadataForm (author the record).
// The optional trim step between the last two is a route, not a sheet; its
// previews live in `video_editor_screen_previews.dart`.
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:breakdex/core/services/video_service.dart';
import 'package:breakdex/dev/preview_harness.dart';
import 'package:breakdex/features/add/add_screen.dart';
import 'package:breakdex/features/add/widgets/clip_metadata_form.dart';
import 'package:breakdex/shared/widgets/video_picker_sheet.dart';

@Preview(name: '1 · AddScreen · light', group: 'add', wrapper: wrapLight)
Widget addScreenLight() => const AddScreen();

@Preview(name: '1 · AddScreen · dark', group: 'add', wrapper: wrapDark)
Widget addScreenDark() => const AddScreen();

/// Source picker as it opens on a first add.
///
/// The scaffold renders on web, where `supportsVideoCaptureAndImport` is false,
/// so the tiles come up disabled under the unavailable notice. That is the
/// truthful web build rather than a preview artifact — run the flow on a device
/// to exercise the tiles live.
@Preview(
  name: '2 · VideoPickerSheet · light',
  group: 'add',
  size: Size(390, 520),
  wrapper: wrapLight,
)
Widget videoPickerSheetLight() => const VideoPickerSheet();

@Preview(
  name: '2 · VideoPickerSheet · dark',
  group: 'add',
  size: Size(390, 520),
  wrapper: wrapDark,
)
Widget videoPickerSheetDark() => const VideoPickerSheet();

/// Re-pick entry: a previous clip is named, so the sheet retitles and carries a
/// ghost card above the sources.
@Preview(
  name: '2 · VideoPickerSheet · re-pick',
  group: 'add',
  size: Size(390, 600),
  wrapper: wrapLight,
)
Widget videoPickerSheetRepick() =>
    const VideoPickerSheet(previousVideoName: 'six_step_drill.mov');

/// Stand-in for a clip the user just picked. The path resolves to nothing, so
/// the player renders its status card instead of video — the metadata layout
/// below it is what these previews are for.
const _pickedClip = VideoPickResult(
  localPath: '/preview/six_step_drill.mov',
  originalFileName: 'six_step_drill.mov',
  fileSize: 8_412_160,
  duration: 4.2,
);

/// The same clip arriving with no filename, so the name field starts empty and
/// the save button holds its disabled state.
const _unnamedClip = VideoPickResult(localPath: '/preview/untitled.mov');

@Preview(
  name: '3 · ClipMetadataForm · light',
  group: 'add',
  size: Size(390, 844),
  wrapper: wrapLight,
)
Widget clipMetadataFormLight() =>
    const ClipMetadataForm(pickResult: _pickedClip);

@Preview(
  name: '3 · ClipMetadataForm · dark',
  group: 'add',
  size: Size(390, 844),
  wrapper: wrapDark,
)
Widget clipMetadataFormDark() =>
    const ClipMetadataForm(pickResult: _pickedClip);

@Preview(
  name: '3 · ClipMetadataForm · empty name',
  group: 'add',
  size: Size(390, 844),
  wrapper: wrapLight,
)
Widget clipMetadataFormEmpty() =>
    const ClipMetadataForm(pickResult: _unnamedClip);
