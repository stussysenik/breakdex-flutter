// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';

import '../../core/design/spacing.dart';
import '../../core/utils/loading_state_machine.dart';
import 'app_loader.dart';

/// Renders a visual representation of a [LoadingStateMachine] state.
///
/// Each state produces a different UI:
/// - [Idle]: Empty (returns nothing visible)
/// - [Loading]: Animated shimmer/skeleton placeholder
/// - [Downloading]: Linear progress bar with percentage
/// - [Ready]: Renders [builder] with the data
/// - [Timeout]: Warning card with retry option
/// - [Error]: Error card with optional retry button
/// - [Retrying]: Loading indicator with attempt counter
class LoadingStateWidget<T> extends StatelessWidget {
  const LoadingStateWidget({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.shimmerChild,
  });

  final LoadingStateMachine<T> state;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final Widget? shimmerChild;

  @override
  Widget build(final BuildContext context) {
    return state.map(
      idle: (_) => const SizedBox.shrink(),
      loading: (_) => _LoadingShimmer(child: shimmerChild),
      downloading: (final d) => _DownloadingBar(progress: d.progress),
      ready: (final r) => builder(r.data as T),
      timeout: (final t) => _TimeoutCard(onRetry: onRetry),
      error: (final e) => _ErrorCard(
        message: e.message,
        retryable: e.retryable,
        onRetry: onRetry,
      ),
      retrying: (final r) => _RetryingWidget(
        attempt: r.attempt,
        maxAttempts: r.maxAttempts,
      ),
    );
  }
}

class _LoadingShimmer extends StatefulWidget {
  const _LoadingShimmer({this.child});

  final Widget? child;

  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.shimmerLoop,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (final context, final child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child ??
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
        );
      },
    );
  }
}

class _DownloadingBar extends StatelessWidget {
  const _DownloadingBar({required this.progress});

  final double progress;

  @override
  Widget build(final BuildContext context) {
    final percentage = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Downloading $percentage%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TimeoutCard extends StatelessWidget {
  const _TimeoutCard({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: Colors.amber, size: 32),
          const SizedBox(height: 8),
          Text(
            'Connection timed out',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.retryable,
    this.onRetry,
  });

  final String message;
  final bool retryable;
  final VoidCallback? onRetry;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
            textAlign: TextAlign.center,
          ),
          if (retryable && onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RetryingWidget extends StatelessWidget {
  const _RetryingWidget({
    required this.attempt,
    required this.maxAttempts,
  });

  final int attempt;
  final int maxAttempts;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoader(semanticLabel: 'Retrying'),
          const SizedBox(height: 8),
          Text(
            'Retrying... ($attempt/$maxAttempts)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
