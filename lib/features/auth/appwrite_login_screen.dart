/// Appwrite identity login screen — task 3.2.
///
/// One action ("Continue with Google"), three states (idle / loading / error).
/// Design-system only (`AppColors`/`AppSpacing`/`AppTypography`, 8pt grid); no
/// additional providers. **Unwired** into routing until Phase 3.3 — [onSignedIn]
/// is the seam the wiring will fill (route home on success).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';
import '../../core/services/appwrite_auth_providers.dart';
import '../../core/services/appwrite_auth_service.dart';

class AppwriteLoginScreen extends ConsumerStatefulWidget {
  const AppwriteLoginScreen({super.key, this.onSignedIn});

  /// Invoked once a session lands. Null until 3.3 wires routing.
  final VoidCallback? onSignedIn;

  @override
  ConsumerState<AppwriteLoginScreen> createState() =>
      _AppwriteLoginScreenState();
}

class _AppwriteLoginScreenState extends ConsumerState<AppwriteLoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(appwriteAuthServiceProvider).signInWithGoogle();
      unawaited(HapticFeedback.mediumImpact());
      if (mounted) widget.onSignedIn?.call();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object catch (_) {
      if (mounted) setState(() => _error = 'Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticTheme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenEdge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AppMark(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Breakdex',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge
                    .copyWith(color: colorScheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in to sync your moves, combos, and videos across devices.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: colorScheme.secondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Fluid family — the error reveal rides an opacity/size transition
              // on the productive curve (AppMotion), never appearing abruptly.
              AnimatedSize(
                duration: AppMotion.moderate01,
                curve: AppMotion.fluid,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: AppMotion.moderate01,
                  switchInCurve: AppMotion.fluid,
                  switchOutCurve: AppMotion.fluid,
                  child: _error == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          key: const ValueKey('login-error'),
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall
                                .copyWith(color: semantic.actionAgain),
                          ),
                        ),
                ),
              ),
              _GoogleButton(
                loading: _loading,
                hasError: _error != null,
                onPressed: _loading ? null : _signIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Breakdex "B" monogram (accent square, Inter-Bold), matching `web/`.
class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Container(
        width: AppSpacing.xxxl + AppSpacing.xs, // 64 + 8 = 72 (8pt grid)
        height: AppSpacing.xxxl + AppSpacing.xs,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        // FittedBox scales the token glyph to the mark, so no raw fontSize
        // literal reaches the surface; white on the brand accent stays legible.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'B',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Continue with Google" — collapses the three states into one control:
/// idle → prompt, loading → spinner + disabled, error → "Try again".
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.loading,
    required this.hasError,
    required this.onPressed,
  });

  final bool loading;
  final bool hasError;
  final VoidCallback? onPressed;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    // onPrimary (not raw white) so an ink accent in the grayscale/monochrome
    // palettes keeps the label legible against a near-white fill.
    final onAccent = colorScheme.onPrimary;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: onPressed == null ? const [] : AppShadows.raised(brightness),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          key: const ValueKey('login-google-button'),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: onAccent,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            textStyle:
                AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          // Fluid family — the label⇄spinner swap crossfades on the productive
          // curve instead of hard-cutting between states.
          child: AnimatedSwitcher(
            duration: AppMotion.moderate01,
            switchInCurve: AppMotion.fluid,
            switchOutCurve: AppMotion.fluid,
            child: loading
                ? SizedBox(
                    key: const ValueKey('login-spinner'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: onAccent,
                    ),
                  )
                : Text(
                    hasError ? 'Try again' : 'Continue with Google',
                    key: const ValueKey('login-label'),
                  ),
          ),
        ),
      ),
    );
  }
}
