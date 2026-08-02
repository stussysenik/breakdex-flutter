import 'package:flutter/material.dart';

import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/models/asset_residency.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';

/// One line of type stating where a clip's bytes live and which way they move.
///
/// Text, not a chip: a filled pill would make residency a different *kind* of
/// object from the metadata rows beside it, and the eye would compare shapes
/// instead of reading the fact (the de-chipping ruling, task 10.1). It borrows
/// the Video Info panel's row grammar — icon, bold label, value — so it reads
/// as one more fact about the clip rather than an alert bolted on.
///
/// Location and direction are rendered as separate spans because they are
/// separate facts (task 8.2); only the direction span takes the error role, so
/// a failed upload does not paint the place the file is safely sitting in red.
class AssetResidencyLine extends StatelessWidget {
  const AssetResidencyLine({super.key, required this.residency});

  final AssetResidency residency;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final places = residency.cloudPlaces.map((final p) => p.label);

    final location = switch (residency.state) {
      AssetResidencyState.untracked => l10n.residencyUntracked,
      AssetResidencyState.localOnly => l10n.residencyThisDeviceOnly,
      AssetResidencyState.cloudOnly => l10n.residencyCloudOnly(
        _join(residency.cloudPlaces),
      ),
      _ => [l10n.residencyThisDevice, ...places].join(' · '),
    };

    final (direction, isError) = switch (residency.state) {
      AssetResidencyState.failed => (
        l10n.residencyUploadFailed(_join(residency.failedPlaces)),
        true,
      ),
      AssetResidencyState.pending => (
        l10n.residencySending(_join(residency.pendingPlaces)),
        false,
      ),
      _ => (null, false),
    };

    final base = AppTypography.caption;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon.resolve(context), size: 14, color: colorScheme.secondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${l10n.mdMetaStored}: ',
            style: base.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: base.copyWith(color: colorScheme.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (direction != null)
                  Text(
                    direction,
                    style: base.copyWith(
                      color: isError
                          ? colorScheme.error
                          : colorScheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppIcon get _icon => switch (residency.state) {
    AssetResidencyState.untracked => AppIcon.help,
    AssetResidencyState.localOnly => AppIcon.storage,
    AssetResidencyState.pending => AppIcon.upload,
    AssetResidencyState.uploaded => AppIcon.cloudDone,
    AssetResidencyState.failed => AppIcon.warning,
    AssetResidencyState.cloudOnly => AppIcon.cloud,
  };

  static String _join(final List<CloudPlace> places) =>
      places.map((final p) => p.label).join(', ');
}
