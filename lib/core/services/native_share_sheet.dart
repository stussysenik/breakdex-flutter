import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'native_bridge.dart';

/// Presents the system share sheet.
///
/// On iOS this uses Breakdex's native UIKit bridge so popover presentation is
/// fully controlled by the app. Other platforms fall back to `share_plus`.
class NativeShareSheet extends NativeBridge {
  NativeShareSheet._() : super('share_sheet', hasEventChannel: false);

  static final NativeShareSheet _instance = NativeShareSheet._();

  static Future<void> shareText({
    required String text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      await Share.share(
        text,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      );
      return;
    }

    await _instance.invoke<void>('shareText', {
      'text': text,
      'subject': subject,
      ..._originArgs(sharePositionOrigin),
    });
  }

  static Future<void> shareFiles({
    required List<String> filePaths,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      await Share.shareXFiles(
        filePaths.map(XFile.new).toList(),
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      );
      return;
    }

    await _instance.invoke<void>('shareFiles', {
      'paths': filePaths,
      'subject': subject,
      ..._originArgs(sharePositionOrigin),
    });
  }

  static Map<String, double> _originArgs(Rect? origin) {
    if (origin == null) return const {};

    return {
      'originX': origin.left,
      'originY': origin.top,
      'originWidth': origin.width,
      'originHeight': origin.height,
    };
  }
}
