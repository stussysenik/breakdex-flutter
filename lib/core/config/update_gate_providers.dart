import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/app_metadata.dart';
import 'package:breakdex/core/config/remote_config.dart';
import 'package:breakdex/core/config/remote_config_providers.dart';
import 'package:breakdex/core/config/update_gate.dart';

/// The running build number, as an int.
///
/// Sourced from [AppMetadata.buildNumber] — this repo's single build identity
/// (also what the app reports to users via `AppMetadata.footerLabel`), so the
/// gate compares against the version the app actually presents. A non-numeric
/// value degrades to `0`, which makes the gate un-fireable (fail-open, never
/// locks a user out on a parse error).
///
/// Overridable in tests to simulate any build without touching a platform
/// channel; a future platform read (`package_info_plus`) can replace the body
/// here without changing any consumer.
final currentBuildProvider = Provider<int>((final ref) {
  return int.tryParse(AppMetadata.buildNumber) ?? 0;
});

/// The live update-gate decision: recomputed whenever the remote config or the
/// build number changes. Reads the best-known config synchronously
/// (`valueOrNull ?? defaults`) so the gate is inert at launch and upgrades once
/// the live row arrives.
final updateGateProvider = Provider<UpdateGate>((final ref) {
  final config =
      ref.watch(remoteConfigProvider).valueOrNull ?? const RemoteConfig.defaults();
  return UpdateGate.evaluate(
    config: config,
    currentBuild: ref.watch(currentBuildProvider),
  );
});
