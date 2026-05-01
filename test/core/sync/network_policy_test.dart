import 'package:breakdex/core/services/connectivity_service.dart';
import 'package:breakdex/core/sync/network_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late NetworkPolicy policy;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    policy = NetworkPolicy(prefs);
  });

  group('NetworkPolicy', () {
    group('canTransfer', () {
      test('allows on WiFi regardless of size', () {
        final result = policy.canTransfer(
          1000 * 1024 * 1024, // 1 GB
          ConnectionType.wifi,
        );

        expect(result, TransferDecision.allow);
      });

      test('allows on Ethernet regardless of size', () {
        final result = policy.canTransfer(
          1000 * 1024 * 1024,
          ConnectionType.ethernet,
        );

        expect(result, TransferDecision.allow);
      });

      test('returns offline when no connection', () {
        final result = policy.canTransfer(1024, ConnectionType.none);

        expect(result, TransferDecision.offline);
      });

      test('returns waitForWifi on mobile when syncOnMobileData is false', () {
        // Default is false
        final result = policy.canTransfer(1024, ConnectionType.mobile);

        expect(result, TransferDecision.waitForWifi);
      });

      test(
        'allows user-initiated playback on mobile even when background sync is WiFi-only',
        () {
          final result = policy.canTransfer(
            1024,
            ConnectionType.mobile,
            intent: TransferIntent.userInitiatedPlayback,
          );

          expect(result, TransferDecision.allow);
        },
      );

      test(
        'allows on mobile when syncOnMobileData is true and under cap',
        () async {
          await policy.setSyncOnMobileData(true);

          final result = policy.canTransfer(
            1 * 1024 * 1024, // 1 MB — well under 100 MB cap
            ConnectionType.mobile,
          );

          expect(result, TransferDecision.allow);
        },
      );

      test('returns dataCapExceeded when mobile usage exceeds cap', () async {
        await policy.setSyncOnMobileData(true);
        await policy.setMobileDataCapMb(10); // 10 MB cap

        // Record usage near the cap
        await policy.recordMobileUsage(9 * 1024 * 1024); // 9 MB used

        // Trying to transfer 2 MB would exceed 10 MB cap
        final result = policy.canTransfer(
          2 * 1024 * 1024,
          ConnectionType.mobile,
        );

        expect(result, TransferDecision.dataCapExceeded);
      });

      test('allows on mobile when usage plus transfer is within cap', () async {
        await policy.setSyncOnMobileData(true);
        await policy.setMobileDataCapMb(100); // 100 MB cap

        await policy.recordMobileUsage(50 * 1024 * 1024); // 50 MB used

        // 10 MB transfer — 60 MB total, still under 100 MB
        final result = policy.canTransfer(
          10 * 1024 * 1024,
          ConnectionType.mobile,
        );

        expect(result, TransferDecision.allow);
      });
    });

    group('chunkSizeBytes', () {
      test('returns 5 MB for WiFi', () {
        expect(policy.chunkSizeBytes(ConnectionType.wifi), 5 * 1024 * 1024);
      });

      test('returns 1 MB for mobile', () {
        expect(policy.chunkSizeBytes(ConnectionType.mobile), 1 * 1024 * 1024);
      });

      test('returns 5 MB for ethernet', () {
        expect(policy.chunkSizeBytes(ConnectionType.ethernet), 5 * 1024 * 1024);
      });
    });

    group('throttleBytesPerSec', () {
      test('returns null (unlimited) for WiFi', () {
        expect(policy.throttleBytesPerSec(ConnectionType.wifi), isNull);
      });

      test('returns 256 KB/s for mobile', () {
        expect(policy.throttleBytesPerSec(ConnectionType.mobile), 256 * 1024);
      });
    });

    group('concurrency limits', () {
      test('maxConcurrentUploads: 2 on WiFi, 1 on mobile', () {
        expect(policy.maxConcurrentUploads(ConnectionType.wifi), 2);
        expect(policy.maxConcurrentUploads(ConnectionType.mobile), 1);
      });

      test('maxConcurrentDownloads: 3 on WiFi, 1 on mobile', () {
        expect(policy.maxConcurrentDownloads(ConnectionType.wifi), 3);
        expect(policy.maxConcurrentDownloads(ConnectionType.mobile), 1);
      });
    });

    group('mobile data tracking', () {
      test('recordMobileUsage accumulates bytes', () async {
        await policy.recordMobileUsage(100);
        await policy.recordMobileUsage(200);

        expect(policy.mobileUsedBytesThisMonth(), 300);
      });

      test('default preferences', () {
        expect(policy.syncOnMobileData, isFalse);
        expect(policy.mobileDataCapMb, 100);
        expect(policy.downloadQuality, 'original');
      });
    });
  });
}
