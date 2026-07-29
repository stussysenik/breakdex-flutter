import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/services/entity_names_service.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/models/add_flow_order.dart';
import 'package:breakdex/core/models/move_creation.dart';
import 'package:breakdex/core/state_machines/move_creation/provider.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/core/services/video_service.dart';
import 'package:breakdex/features/add/widgets/clip_metadata_form.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';
import 'package:breakdex/shared/widgets/video_picker_sheet.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/core/design/icons.dart';

class AddScreen extends ConsumerWidget {
  const AddScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final entityNames = ref.watch(entityNamesProvider);
    // The choices are rows in the content band, not a bespoke hero layout:
    // one column, one rhythm, identical to every other screen's first section.
    return AppScreen(
      title: AppLocalizations.of(context).addContentTitle,
      children: [
        AppSection(
          first: true,
          key: const Key('add-choices'),
          children: [
            _ChoiceCard(
              identifier: 'add-move-card',
              icon: AppIcon.video.resolve(context),
              label: entityNames.moveSingular,
              onTap: () => _startClipFlow(context, ref),
            ),
            _ChoiceCard(
              identifier: 'add-combo-card',
              icon: AppIcon.discover.resolve(context),
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
    return showModalBottomSheet<ClipMetadataResult>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      isScrollControlled: true,
      builder: (_) => ClipMetadataForm(pickResult: pickResult),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.identifier,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  /// Stable handle for E2E drivers. The rendered label is
  /// entity-name-configurable, so text is not a selector these cards can offer.
  final String identifier;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      identifier: identifier,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          // Two block-grid rows tall (72), so the card lands on the same
          // rhythm as every other tappable row in the app.
          constraints: const BoxConstraints(minHeight: AppLayout.headerHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.cardPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: colorScheme.surfaceContainerHighest,
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: colorScheme.onSurface),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: AppTypography.titleSmall)),
              AppIconView(
                AppIcon.forward,
                size: 20,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
