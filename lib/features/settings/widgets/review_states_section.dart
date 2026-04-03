import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/color_setting_tile.dart';
import '../../../shared/widgets/settings_list_group.dart';

const reviewStatePresetColors = [
  Color(0xFFC46F6F),
  Color(0xFFC4A84F),
  Color(0xFF9F8B5E),
  Color(0xFF6FAF6F),
  Color(0xFF5F9F8F),
  Color(0xFF6F90C4),
  Color(0xFF7C7FC2),
  Color(0xFF8E97A1),
  Color(0xFF756C63),
  Color(0xFF56616D),
];

class ReviewStatesSection extends ConsumerWidget {
  const ReviewStatesSection({super.key, required this.onRename});

  final void Function(LearningState state, String currentLabel) onRename;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = ref.watch(learningStateLabelsProvider);
    final colors = ref.watch(learningStateColorsProvider);

    return SettingsListGroup(
      children: [
        for (final state in LearningState.values)
          SettingsListRow(
            onTap: () =>
                onRename(state, resolveLearningStateLabel(labels, state)),
            leading: _StateSwatch(color: colors.forState(state)),
            title: resolveLearningStateLabel(labels, state),
            subtitle: _subtitleFor(labels, state),
            trailing: _StateRowTrailing(
              hex: formatColorHex(colors.forState(state)),
              onColorTap: () => _showColorPicker(context, ref, state),
            ),
          ),
      ],
    );
  }

  String? _subtitleFor(Map<LearningState, String> labels, LearningState state) {
    final current = resolveLearningStateLabel(labels, state);
    final original = defaultLearningStateLabels[state] ?? state.displayText;
    if (current == original) return null;
    return 'Default: $original';
  }

  Future<void> _showColorPicker(
    BuildContext context,
    WidgetRef ref,
    LearningState state,
  ) async {
    final label = resolveLearningStateLabel(
      ref.read(learningStateLabelsProvider),
      state,
    );
    final currentColor = ref.read(learningStateColorsProvider).forState(state);
    final selected = await showColorEditorDialog(
      context,
      initialColor: currentColor,
      title: '$label Color',
      subtitle:
          'Choose any color for $label. Quick picks, spectrum tuning, hex, and RGBA sliders stay in sync.',
      presets: reviewStatePresetColors,
    );
    if (selected == null) return;
    await HapticFeedback.mediumImpact();
    await ref
        .read(learningStateColorsProvider.notifier)
        .setColor(state, selected);
  }
}

class _StateSwatch extends StatelessWidget {
  const _StateSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.14)),
      ),
    );
  }
}

class _StateRowTrailing extends StatelessWidget {
  const _StateRowTrailing({required this.hex, required this.onColorTap});

  final String hex;
  final VoidCallback onColorTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hex,
          style: AppTypography.caption.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: onColorTap,
          behavior: HitTestBehavior.opaque,
          child: Icon(
            Icons.palette_outlined,
            size: 18,
            color: colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}
