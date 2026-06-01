import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/stats_providers.dart';
import 'widgets/progress_explorer.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final statsAsync = ref.watch(statsBundleProvider);

    return Scaffold(
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (final error, _) => Center(child: Text('Error: $error')),
          data: (final stats) => ProgressExplorer(stats: stats),
        ),
      ),
    );
  }
}
