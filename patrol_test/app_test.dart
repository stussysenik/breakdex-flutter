import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/main.dart';
import 'package:breakdex/shared/widgets/video_player_widget.dart';

import '../test/helpers/test_database.dart';

void main() {
  group('Breakdex integration tests', () {
    late SharedPreferences prefs;
    late AppDatabase db;

    setUp(() async {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = createTestDatabase();
      await VideoPathResolver.initialize();
    });

    tearDown(() async {
      await db.close();
    });

    Widget buildApp() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
        ],
        child: const BreakdexApp(),
      );
    }

    Future<void> dismissSystemPermissionIfVisible(
      PatrolIntegrationTester $,
    ) async {
      final visible = await $.platform.mobile.isPermissionDialogVisible(
        timeout: const Duration(seconds: 1),
      );
      if (visible) {
        await $.platform.mobile.grantPermissionWhenInUse();
      }
    }

    Future<void> pumpBreakdex(PatrolIntegrationTester $) async {
      await dismissSystemPermissionIfVisible($);
      await $.pumpWidget(buildApp());
      await $.pump(const Duration(seconds: 1));
      await dismissSystemPermissionIfVisible($);
      await $.pump(const Duration(milliseconds: 500));
    }

    Future<void> pumpFrame(PatrolIntegrationTester $) async {
      await $.pump(const Duration(milliseconds: 500));
      await dismissSystemPermissionIfVisible($);
      await $.pump(const Duration(milliseconds: 250));
    }

    Future<String> writeAssetVideo({
      required String assetPath,
      required String fileName,
    }) async {
      final relativePath = p.join('Moves', fileName);
      final file = File(VideoPathResolver.toAbsolute(relativePath));
      await file.parent.create(recursive: true);
      final data = await rootBundle.load(assetPath);
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return relativePath;
    }

    Future<void> seedMove({
      required String id,
      required String name,
      String learningState = 'NEW',
      String? videoPath,
      String? originalVideoName,
    }) async {
      await db
          .into(db.moves)
          .insert(
            MovesCompanion.insert(
              id: id,
              name: name,
              learningState: Value(learningState),
              videoPath: Value(videoPath),
              originalVideoName: Value(originalVideoName),
            ),
          );
    }

    patrolTest('Arsenal renders a seeded move', ($) async {
      await seedMove(id: 'move-1', name: 'Windmill');

      await pumpBreakdex($);
      await $('Windmill').waitUntilVisible();
    });

    patrolTest('View an individual stored video file', ($) async {
      final videoPath = await writeAssetVideo(
        assetPath: 'assets/fixtures-blue-beat.mp4',
        fileName: 'patrol-airflare.mp4',
      );
      await seedMove(
        id: 'move-test-video',
        name: 'Airflare',
        videoPath: videoPath,
        originalVideoName: 'patrol-airflare.mp4',
      );

      await pumpBreakdex($);
      await $('Airflare').waitUntilVisible();

      await $('Airflare').tap();
      await pumpFrame($);

      await $(
        RobustVideoPlayer,
      ).waitUntilVisible(timeout: const Duration(seconds: 15));
    });

    patrolTest('Navigate to all tabs', ($) async {
      await pumpBreakdex($);

      await $('Arsenal').waitUntilVisible();

      await $('Review').tap();
      await pumpFrame($);
      await $('Session').waitUntilVisible();
      await $('Schedule').waitUntilVisible();

      await $('Stats').tap();
      await pumpFrame($);
      await $('Stats').waitUntilVisible();

      await $('Settings').tap();
      await pumpFrame($);
      await $('Settings').waitUntilVisible();
    });

    patrolTest('Review tab starts a state-based session', ($) async {
      await seedMove(id: 'move-1', name: 'Windmill');

      await pumpBreakdex($);

      await $('Review').tap();
      await pumpFrame($);

      await $('New').waitUntilVisible();
      await $('Practicing').waitUntilVisible();
      await $('Strong').waitUntilVisible();

      await $('Start').first.tap();
      await pumpFrame($);

      await $('1/1').waitUntilVisible();
      await $('tap to reveal').waitUntilVisible();
    });

    patrolTest('Settings adds a custom category', ($) async {
      await pumpBreakdex($);

      await $('Settings').tap();
      await pumpFrame($);

      await $('Add Category').scrollTo().tap();
      await pumpFrame($);

      await $(TextField).waitUntilVisible();
      await $(TextField).enterText('Integration Category');
      await pumpFrame($);

      await $('Add').tap();
      await pumpFrame($);

      await $('Integration Category').waitUntilVisible();
    });

    patrolTest('Review tab starts a deck session', ($) async {
      await seedMove(id: 'move-1', name: 'Headspin');
      await db
          .into(db.decks)
          .insert(
            DecksCompanion.insert(
              id: 'deck-1',
              name: 'Battle Set',
              deckType: const Value('manual'),
              sessionSize: const Value(10),
            ),
          );
      await db
          .into(db.deckMoves)
          .insert(
            DeckMovesCompanion.insert(deckId: 'deck-1', moveId: 'move-1'),
          );

      await pumpBreakdex($);

      await $('Review').tap();
      await pumpFrame($);

      await $('Deck').tap();
      await pumpFrame($);

      await $('Battle Set').waitUntilVisible();

      await $('Battle Set').tap();
      await pumpFrame($);

      await $('1/1').waitUntilVisible();
      await $('tap to reveal').waitUntilVisible();
    });

    patrolTest('Settings renames learning tags and Review screen updates', (
      $,
    ) async {
      await seedMove(id: 'move-1', name: 'Windmill', learningState: 'NEW');

      await pumpBreakdex($);

      await $('Settings').tap();
      await pumpFrame($);

      await $('New').scrollTo().tap();
      await pumpFrame($);

      await $(TextField).waitUntilVisible();
      await $(TextField).enterText('Fresh Move');
      await pumpFrame($);

      await $('Save').tap();
      await pumpFrame($);

      await $('Review').tap();
      await pumpFrame($);

      await $('Fresh Move').waitUntilVisible();
      expect($('New'), findsNothing);

      await $('Start Fresh Move').tap();
      await pumpFrame($);

      await $('1/1').waitUntilVisible();
      await $('tap to reveal').waitUntilVisible();
    });
  });
}
