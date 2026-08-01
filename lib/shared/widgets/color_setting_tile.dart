import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/app_dialog.dart';

String formatColorHex(final Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

Color? tryParseColorHex(final String input) {
  final normalized = input.trim().replaceAll('#', '');
  if (normalized.length != 6 && normalized.length != 8) return null;

  final buffer = StringBuffer();
  if (normalized.length == 6) buffer.write('FF');
  buffer.write(normalized.toUpperCase());

  final value = int.tryParse(buffer.toString(), radix: 16);
  return value == null ? null : Color(value);
}

Future<Color?> showColorEditorDialog(
  final BuildContext context, {
  required final Color initialColor,
  final String? title,
  final String? subtitle,
  final List<Color> presets = const [],
}) {
  return showAppDialog<Color>(
    context: context,
    builder: (_) => _ColorEditorDialog(
      initialColor: initialColor,
      title: title,
      subtitle: subtitle,
      presets: presets,
    ),
  );
}

class ColorSettingTile extends StatelessWidget {
  const ColorSettingTile({
    super.key,
    required this.title,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIconView(AppIcon.edit, size: 18, color: colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorEditorDialog extends StatefulWidget {
  const _ColorEditorDialog({
    required this.initialColor,
    required this.title,
    required this.presets,
    this.subtitle,
  });

  final Color initialColor;
  final String? title;
  final String? subtitle;
  final List<Color> presets;

  @override
  State<_ColorEditorDialog> createState() => _ColorEditorDialogState();
}

class _ColorEditorDialogState extends State<_ColorEditorDialog> {
  late Color _color;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
    _hexController = TextEditingController(text: formatColorHex(_color));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _setColor(final Color color) {
    setState(() {
      _color = color;
      _hexController.text = formatColorHex(_color);
    });
  }

  void _updateFromHsv({
    final double? hue,
    final double? saturation,
    final double? value,
    final double? alpha,
  }) {
    final hsv = HSVColor.fromColor(_color);
    _setColor(
      HSVColor.fromAHSV(
        alpha ?? hsv.alpha,
        hue ?? hsv.hue,
        saturation ?? hsv.saturation,
        value ?? hsv.value,
      ).toColor(),
    );
  }

  void _applyHex(final String value) {
    final parsed = tryParseColorHex(value);
    if (parsed != null) {
      _setColor(parsed);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final hsv = HSVColor.fromColor(_color);
    final previewFg =
        ThemeData.estimateBrightnessForColor(_color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? l10n.setColorPickerDefaultTitle,
                style: AppTypography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: _color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _color.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Aa',
                          style: AppTypography.titleSmall.copyWith(
                            color: previewFg,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      formatColorHex(_color),
                      style: AppTypography.titleSmall.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.setColorHexLabel,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _hexController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
                ],
                decoration: InputDecoration(
                  hintText: '#AARRGGBB',
                  helperText: l10n.setColorHexHelper,
                  prefixIcon: const AppIconView(AppIcon.notes),
                ),
                onSubmitted: _applyHex,
                onChanged: (final value) {
                  final hexLength = value.replaceAll('#', '').length;
                  if (hexLength == 6 || hexLength == 8) {
                    _applyHex(value);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.setColorSpectrumLabel,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _GradientChannelSlider(
                label: l10n.setColorHueLabel,
                value: hsv.hue,
                min: 0,
                max: 360,
                thumbColor: HSVColor.fromAHSV(
                  hsv.alpha,
                  hsv.hue,
                  1,
                  1,
                ).toColor(),
                gradientColors: const [
                  Color(0xFFFF1744),
                  Color(0xFFFF9100),
                  Color(0xFFFFEA00),
                  Color(0xFF00E676),
                  Color(0xFF00B0FF),
                  Color(0xFF7C4DFF),
                  Color(0xFFFF1744),
                ],
                formatter: (final value) => '${value.round()}°',
                onChanged: (final value) => _updateFromHsv(hue: value),
              ),
              _GradientChannelSlider(
                label: l10n.setColorSaturationLabel,
                value: hsv.saturation * 100,
                min: 0,
                max: 100,
                thumbColor: _color,
                gradientColors: [
                  HSVColor.fromAHSV(hsv.alpha, hsv.hue, 0, hsv.value).toColor(),
                  HSVColor.fromAHSV(hsv.alpha, hsv.hue, 1, hsv.value).toColor(),
                ],
                formatter: (final value) => '${value.round()}%',
                onChanged: (final value) =>
                    _updateFromHsv(saturation: value / 100),
              ),
              _GradientChannelSlider(
                label: l10n.setColorValueLabel,
                value: hsv.value * 100,
                min: 0,
                max: 100,
                thumbColor: _color,
                gradientColors: [
                  Colors.black,
                  HSVColor.fromAHSV(
                    hsv.alpha,
                    hsv.hue,
                    hsv.saturation,
                    1,
                  ).toColor(),
                ],
                formatter: (final value) => '${value.round()}%',
                onChanged: (final value) => _updateFromHsv(value: value / 100),
              ),
              if (widget.presets.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.setColorQuickPicksLabel,
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: widget.presets.map((final preset) {
                    final selected = preset.toARGB32() == _color.toARGB32();
                    return GestureDetector(
                      onTap: () => _setColor(preset),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: preset,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Colors.white
                                : colorScheme.outline.withValues(alpha: 0.16),
                            width: selected ? 2.5 : 1,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: preset.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _ChannelSlider(
                label: l10n.setColorOpacityLabel,
                value: (_color.a * 255).roundToDouble(),
                min: 0,
                max: 255,
                activeColor: colorScheme.primary,
                onChanged: (final value) => _updateFromHsv(alpha: value / 255),
              ),
              _ChannelSlider(
                label: l10n.setColorRedLabel,
                value: (_color.r * 255).roundToDouble(),
                min: 0,
                max: 255,
                activeColor: Colors.red,
                onChanged: (final value) =>
                    _setColor(_color.withRed(value.round())),
              ),
              _ChannelSlider(
                label: l10n.setColorGreenLabel,
                value: (_color.g * 255).roundToDouble(),
                min: 0,
                max: 255,
                activeColor: Colors.green,
                onChanged: (final value) =>
                    _setColor(_color.withGreen(value.round())),
              ),
              _ChannelSlider(
                label: l10n.setColorBlueLabel,
                value: (_color.b * 255).roundToDouble(),
                min: 0,
                max: 255,
                activeColor: Colors.blue,
                onChanged: (final value) =>
                    _setColor(_color.withBlue(value.round())),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.setColorCancelButton),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _color),
                    child: Text(l10n.setColorSaveButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelSlider extends StatelessWidget {
  const _ChannelSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value.round().toString(),
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              thumbColor: activeColor,
              overlayColor: activeColor.withValues(alpha: 0.18),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientChannelSlider extends StatelessWidget {
  const _GradientChannelSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.thumbColor,
    required this.gradientColors,
    required this.formatter,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final Color thumbColor;
  final List<Color> gradientColors;
  final String Function(double value) formatter;
  final ValueChanged<double> onChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatter(value),
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Center(
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        gradient: LinearGradient(colors: gradientColors),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 12,
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    disabledActiveTrackColor: Colors.transparent,
                    disabledInactiveTrackColor: Colors.transparent,
                    thumbColor: thumbColor,
                    overlayColor: thumbColor.withValues(alpha: 0.18),
                  ),
                  child: Slider(
                    value: value.clamp(min, max),
                    min: min,
                    max: max,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
