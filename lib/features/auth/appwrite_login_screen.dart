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

import 'package:breakdex/core/config/appwrite_env.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/services/appwrite_auth_providers.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart';

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
              // Dev-only email/password path (task 1.3). Flag OFF ⇒ this subtree
              // is never constructed, so release builds tree-shake it away and
              // stay byte-identical (design D2). No registration affordance —
              // user #0 is minted owner-side (design D1).
              if (kDevEmailAuthEnabled) ...[
                const SizedBox(height: AppSpacing.lg),
                _DevEmailForm(onSignedIn: widget.onSignedIn),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Flag-gated dev sign-in form ([kDevEmailAuthEnabled]) — a minimal
/// email/password pair wired to [AppwriteAuthService.signInWithEmailPassword].
/// Manages its own loading/error so the primary Google flow above is untouched.
/// Design-system only; plain Fluid defaults (a dev surface earns no bespoke
/// motion). Sign-in only: no "create account" control (design D1).
class _DevEmailForm extends ConsumerStatefulWidget {
  const _DevEmailForm({this.onSignedIn});

  final VoidCallback? onSignedIn;

  @override
  ConsumerState<_DevEmailForm> createState() => _DevEmailFormState();
}

class _DevEmailFormState extends ConsumerState<_DevEmailForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(appwriteAuthServiceProvider).signInWithEmailPassword(
            email: _email.text.trim(),
            password: _password.text,
          );
      unawaited(HapticFeedback.mediumImpact());
      if (mounted) widget.onSignedIn?.call();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object catch (_) {
      if (mounted) setState(() => _error = 'Dev sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dev sign-in (user #0)',
          style: AppTypography.caption.copyWith(color: colorScheme.secondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const ValueKey('dev-email-field'),
          controller: _email,
          enabled: !_loading,
          autocorrect: false,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const ValueKey('dev-password-field'),
          controller: _password,
          enabled: !_loading,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loading ? null : _submit(),
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: AppTypography.bodySmall.copyWith(color: semantic.actionAgain),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            key: const ValueKey('dev-email-submit'),
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              textStyle:
                  AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            child: _loading
                ? const SizedBox(
                    key: ValueKey('dev-email-spinner'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign in with email'),
          ),
        ),
      ],
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
          color: Theme.of(context).colorScheme.primary,
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
