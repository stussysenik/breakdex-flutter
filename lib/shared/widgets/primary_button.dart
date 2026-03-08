import 'package:flutter/material.dart';
import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: onPressed == null ? const [] : AppShadows.raised(brightness),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            textStyle: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
