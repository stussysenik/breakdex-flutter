import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/utils/diagnostics.dart';
import 'package:breakdex/features/settings/system_status_screen.dart';

/// Guards the fix for a panel that rendered four hardcoded lines: the feed must
/// show what the app actually logged, and Copy must hand over a redacted export.
///
/// Only the feed is pumped — the full screen watches boot/storage providers that
/// would need the whole app graph, and this is a claim about the log panel.
void main() {
  late List<MethodCall> clipboardCalls;

  setUp(() {
    DiagnosticsLog.clearBuffer();
    DiagnosticsLog.configure(captureThreshold: LogLevel.debug);
    clipboardCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (final call) async {
      if (call.method == 'Clipboard.setData') clipboardCalls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> pumpFeed(final WidgetTester tester) => tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: SizedBox(height: 400, child: SystemStatusScreen.debugFeed)),
          ),
        ),
      );

  testWidgets('renders records the app actually logged', (final tester) async {
    DiagnosticsLog.info('Sync', 'push ok move — 3 upsert(s), 0 delete(s)');
    await pumpFeed(tester);

    expect(find.textContaining('push ok move'), findsOneWidget);
    expect(find.textContaining('SYNC'), findsOneWidget);
    // The old fiction must be gone.
    expect(find.textContaining('Core subsystems online'), findsNothing);
  });

  testWidgets('says so when nothing is retained, and disables Copy',
      (final tester) async {
    await pumpFeed(tester);

    expect(find.text('Nothing retained yet.'), findsOneWidget);
    final copy = tester.widget<TextButton>(
      find.byKey(const ValueKey('copy-diagnostics')),
    );
    expect(copy.onPressed, isNull);
  });

  testWidgets('Copy puts a redacted export on the clipboard',
      (final tester) async {
    DiagnosticsLog.info('Auth', 'session=supersecrettoken established');
    await pumpFeed(tester);

    await tester.tap(find.byKey(const ValueKey('copy-diagnostics')));
    await tester.pump();

    expect(clipboardCalls, hasLength(1));
    final text = clipboardCalls.single.arguments['text'] as String;
    expect(text, contains('<redacted>'));
    expect(text, isNot(contains('supersecrettoken')));
  });

  testWidgets('redacts in the on-screen feed too, not only on copy',
      (final tester) async {
    DiagnosticsLog.info('Auth', 'signed in as someone@gmail.com');
    await pumpFeed(tester);

    expect(find.textContaining('<redacted>@gmail.com'), findsOneWidget);
    expect(find.textContaining('someone@'), findsNothing);
  });
}
