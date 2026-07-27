import 'package:meta/meta.dart';

import 'package:breakdex/core/config/remote_config.dart';

/// The update-prompt decision, derived **purely** from a [RemoteConfig] snapshot
/// and the running build number. Three total states — no impossible ones — so a
/// consumer `switch`es exhaustively and the compiler proves every case is handled.
///
/// Precedence, evaluated in [UpdateGate.evaluate]:
///  1. **Hard block** — `currentBuild < minSupportedBuild`. The running build is
///     below the supported floor and must update before continuing (blocking).
///  2. **Soft nag** — supported, but `latestBuild > currentBuild`. A newer build
///     exists; nudge, don't block (dismissible).
///  3. **None** — otherwise. This is also the inert default path: a
///     [RemoteConfig.defaults] has `minSupportedBuild == 0` and `latestBuild == 0`,
///     and a real `currentBuild` is `>= 0`, so neither branch can fire.
///
/// Acceptance invariant (1R.3): **never blocks while
/// `minSupportedBuild <= currentBuild`** — the hard-block branch is strictly `<`.
sealed class UpdateGate {
  const UpdateGate();

  /// Evaluate the gate for [currentBuild] against [config].
  factory UpdateGate.evaluate({
    required final RemoteConfig config,
    required final int currentBuild,
  }) {
    if (currentBuild < config.minSupportedBuild) {
      return UpdateGateHardBlock(
        message: _resolveMessage(config.updateMessage, _defaultBlockMessage),
      );
    }
    if (config.latestBuild > currentBuild) {
      return UpdateGateSoftNag(
        message: _resolveMessage(config.updateMessage, _defaultNagMessage),
      );
    }
    return const UpdateGateNone();
  }

  /// Prefer the owner-authored [updateMessage]; fall back to the compiled copy
  /// when it is absent or blank (an empty remote string must not show an empty
  /// prompt).
  static String _resolveMessage(final String? updateMessage, final String fallback) {
    final trimmed = updateMessage?.trim();
    return (trimmed == null || trimmed.isEmpty) ? fallback : trimmed;
  }

  static const String _defaultBlockMessage =
      'This version of Breakdex is no longer supported. Please update to keep going.';
  static const String _defaultNagMessage =
      'A new version of Breakdex is available.';
}

/// No update action required — render nothing.
final class UpdateGateNone extends UpdateGate {
  const UpdateGateNone();
}

/// A newer build exists but the current one is still supported: dismissible nudge.
@immutable
final class UpdateGateSoftNag extends UpdateGate {
  const UpdateGateSoftNag({required this.message});

  final String message;

  @override
  bool operator ==(final Object other) =>
      other is UpdateGateSoftNag && other.message == message;

  @override
  int get hashCode => Object.hash(UpdateGateSoftNag, message);
}

/// The running build is below the supported floor: blocking prompt, no dismiss.
@immutable
final class UpdateGateHardBlock extends UpdateGate {
  const UpdateGateHardBlock({required this.message});

  final String message;

  @override
  bool operator ==(final Object other) =>
      other is UpdateGateHardBlock && other.message == message;

  @override
  int get hashCode => Object.hash(UpdateGateHardBlock, message);
}
