
import 'package:breakdex/core/services/native_share_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareChannel = MethodChannel('com.breakdex/share_sheet');
  late List<MethodCall> log;

  setUp(() {
    log = [];
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, (final call) async {
          log.add(call);
          return null;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, null);
  });

  test(
    'shareText sends text, subject, and origin to native iOS bridge',
    () async {
      await NativeShareSheet.shareText(
        text: 'Breakdex summary',
        subject: 'Summary',
        sharePositionOrigin: const Rect.fromLTWH(10, 20, 30, 40),
      );

      expect(log, hasLength(1));
      expect(log.single.method, 'shareText');

      final args = Map<String, dynamic>.from(log.single.arguments as Map);
      expect(args['text'], 'Breakdex summary');
      expect(args['subject'], 'Summary');
      expect(args['originX'], 10.0);
      expect(args['originY'], 20.0);
      expect(args['originWidth'], 30.0);
      expect(args['originHeight'], 40.0);
    },
  );

  test('shareFiles sends file paths to native iOS bridge', () async {
    await NativeShareSheet.shareFiles(
      filePaths: const ['/tmp/breakdex-export.json'],
      subject: 'Backup',
    );

    expect(log, hasLength(1));
    expect(log.single.method, 'shareFiles');

    final args = Map<String, dynamic>.from(log.single.arguments as Map);
    expect(args['paths'], ['/tmp/breakdex-export.json']);
    expect(args['subject'], 'Backup');
  });
}
