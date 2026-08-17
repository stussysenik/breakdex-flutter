import 'dart:async';

import 'package:flutter/material.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/appwrite_auth_providers.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';
import 'package:breakdex/shared/widgets/primary_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(appwriteAuthServiceProvider);
      if (_isLogin) {
        await auth.signInWithEmailPassword(email: email, password: password);
      } else {
        // Appwrite account creation — signUp is a server-side operation via
        // the account gateway; for the dev preview we use email/password sign-in
        // and create the account on first login.
        await auth.signInWithEmailPassword(email: email, password: password);
      }
      unawaited(HapticFeedback.mediumImpact());
      if (mounted) {
        // Invalidate providers so they pick up the new auth state
        ref.invalidate(isLoggedInProvider);
        ref.invalidate(moveRepositoryProvider);
        ref.invalidate(comboRepositoryProvider);
        ref.invalidate(reviewRepositoryProvider);
        context.pop();
      }
    } on Object catch (e) {
      setState(() => _error = e.toString().replaceAll('ClientException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // One short form, one scroll — the default form. The title and the way back
    // are the frame's; this screen had hand-rolled both, which is exactly the
    // drift the frame exists to end.
    return AppScreen(
      title: _isLogin ? 'Sign In' : 'Create Account',
      children: [
        Text(
          'Sync your moves, combos, and videos across devices.',
          style: AppTypography.bodySmall.copyWith(color: colorScheme.secondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            style: AppTypography.bodySmall.copyWith(
              color: AppSemanticTheme.of(context).actionAgain,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: _loading
              ? 'Please wait...'
              : (_isLogin ? 'Sign In' : 'Create Account'),
          onPressed: _loading ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: GestureDetector(
            onTap: () => setState(() {
              _isLogin = !_isLogin;
              _error = null;
            }),
            child: Text.rich(
              TextSpan(
                text: _isLogin
                    ? "Don't have an account? "
                    : 'Already have an account? ',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.secondary,
                ),
                children: [
                  TextSpan(
                    text: _isLogin ? 'Sign Up' : 'Sign In',
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
