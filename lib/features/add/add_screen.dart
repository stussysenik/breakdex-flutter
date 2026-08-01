import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/services/entity_names_service.dart';
import 'package:breakdex/core/models/add_flow_order.dart';
import 'package:breakdex/core/models/move_creation.dart';
import 'package:breakdex/core/state_machines/move_creation/provider.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/core/services/video_service.dart';
import 'package:breakdex/features/add/widgets/clip_metadata_form.dart';
import 'package:breakdex/shared/widgets/app_row.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';
import 'package:breakdex/shared/widgets/video_picker_sheet.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/app_sheet.dart';

class AddScreen extends ConsumerWidget {
  const AddScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entityNames = ref.watch(entityNamesProvider);
    // The choices are rows in the content band, not a bespoke hero layout:
    // one column, one rhythm, identical to every other screen's first section.
    // The section label above them is not decoration — it is the same
    // orientation cue Settings and Drill print, and its absence here was the
    // only reason this screen read as a different kind of page.
    return AppScreen(
      title: l10n.addContentTitle,
      children: [
        AppSection(
          first: true,
          title: l10n.addSectionCreate,
          key: const Key('add-choices'),
          children: [
            AppRow(
              identifier: 'add-move-card',
              label: entityNames.moveSingular,
              onTap: () => _startClipFlow(context, ref),
            ),
            AppRow(
              identifier: 'add-combo-card',
              label: entityNames.comboSingular,
              onTap: () => context.push<String>('/create-combo'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _startClipFlow(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    final pickResult = await VideoPickerSheet.show(context);
    if (pickResult == null || !context.mounted) return;

    final order = ref.read(addFlowOrderProvider);

    // Trim-first: route straight into the editor from the picker. Cancelling the
    // editor falls back to the picked clip, so the record shape is unchanged.
    String? editedPath;
    if (order == AddFlowOrder.editWhileAdding) {
      editedPath = await context.push<String>(
        '/video-editor',
        extra: {'videoPath': pickResult.localPath},
      );
      if (!context.mounted) return;
    }

    final metadata = await _showMetadataSheet(context, ref, pickResult);
    if (metadata == null || !context.mounted) return;

    final notifier = ref.read(moveCreationStateProvider.notifier);
    notifier.start(
      CreateMoveRequest(
        name: metadata.name,
        category: metadata.category,
        localVideoPath: resolveAddFlowVideoPath(
          order: order,
          pickedPath: pickResult.localPath,
          editedPath: editedPath,
        ),
        originalVideoName: pickResult.originalFileName,
        videoFileSize: pickResult.fileSize,
        videoCreationDate: pickResult.creationDate,
        count: metadata.count,
        learningState: metadata.learningState.dbValue,
      ),
    );
  }

  Future<ClipMetadataResult?> _showMetadataSheet(
    final BuildContext context,
    final WidgetRef ref,
    final VideoPickResult pickResult,
  ) {
    return showAppSheet<ClipMetadataResult>(
      context: context,
      builder: (_) => ClipMetadataForm(pickResult: pickResult),
    );
  }
}
