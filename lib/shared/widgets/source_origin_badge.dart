import 'package:flutter/material.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/models/canonical_asset.dart';

class SourceOriginBadge extends StatelessWidget {
  const SourceOriginBadge({super.key, required this.source});
  final AssetSource source;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xxs),
      ),
      child: Text(source.label,
          style: AppTypography.caption.copyWith(
              color: _badgeColor, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
    );
  }

  Color get _badgeColor => switch (source) {
        AssetSource.camera => const Color(0xFFE04040),
        AssetSource.photos => const Color(0xFF4CAF50),
        AssetSource.files => const Color(0xFF2196F3),
        AssetSource.cloud => const Color(0xFF9C27B0),
        AssetSource.legacy => const Color(0xFF9E9E9E),
      };
}
