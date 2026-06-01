import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/theme.dart';
import '../../core/providers.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';

class StatePill extends ConsumerWidget {
  const StatePill({
    super.key,
    required this.state,
    this.overlay = false,
    this.onTap,
    this.showDisclosure = false,
    this.semanticsIdentifier,
  });

  final LearningState state;

  /// Overlay mode: semi-transparent background with a 1px border for
  /// high contrast on dark gradient scrims (video overlay).
  final bool overlay;
  final VoidCallback? onTap;
  final bool showDisclosure;
  final String? semanticsIdentifier;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final labels = ref.watch(learningStateLabelsProvider);
    final label = resolveLearningStateLabel(labels, state);
    final stateColor = AppSemanticTheme.of(context).colorForState(state);

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: overlay ? 0.20 : 0.15),
        borderRadius: BorderRadius.circular(20),
        border: overlay
            ? Border.all(color: stateColor.withValues(alpha: 0.40), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: stateColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: stateColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (showDisclosure) ...[
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 14, color: stateColor),
          ],
        ],
      ),
    );

    if (onTap == null && semanticsIdentifier == null) {
      return pill;
    }

    return Semantics(
      identifier: semanticsIdentifier,
      button: onTap != null,
      label: onTap == null ? label : 'Set review state to $label',
      child: onTap == null
          ? pill
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: pill,
              ),
            ),
    );
  }
}
