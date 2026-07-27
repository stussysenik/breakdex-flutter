// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'dart:io';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/state_machines/move_detail/provider.dart';
import 'package:breakdex/core/state_machines/move_detail/event.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/services/reviewable_naming_service.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/blackbox_service.dart';

import '../../../helpers/test_database.dart';

class FakeNamingService implements ReviewableNamingService {
  @override
  Future<bool> isNameTaken(final String value, {final String? excludingMoveId, final String? excludingComboId}) async => false;
  
  @override
  String normalize(final String value) => value.trim();

  @override
  bool isValidName(final String value) => value.isNotEmpty;
}

class FakeBlackboxService implements BlackboxService {
  final logs = <String>[];

  @override
  Future<void> log(final String action, final String entityType, final String entityId, [final Map<String, dynamic>? data]) async {
    logs.add('[$action] $entityType $entityId');
  }

  @override
  Future<void> clear() async {
    logs.clear();
  }

  @override
  Future<List<String>> readRecent(final int lines) async {
    return logs.reversed.take(lines).toList().reversed.toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late AppDatabase db;
  late String tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('breakdex_test').path;
    VideoPathResolver.docsPathOverride = tempDir;
    db = createTestDatabase();

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        reviewableNamingServiceProvider.overrideWithValue(FakeNamingService()),
        blackboxServiceProvider.overrideWithValue(FakeBlackboxService()),
      ],
    );
  });

  tearDown(() {
    try {
      Directory(tempDir).deleteSync(recursive: true);
    } on Object catch (_) {}
    db.close();
    container.dispose();
  });

  test('Rename move moves video file to new semantic path', () async {
    final move = Move(
      id: 'm1',
      name: 'Old Name',
      category: 'Toprock',
      videoPath: 'Moves/Toprock/Old Name - deadbeef.mp4',
      contentHash: 'deadbeef',
      count: 0,
      learningState: 'new',
      createdAt: DateTime.now(),
    );
    await db.into(db.moves).insert(MovesCompanion.insert(
      id: move.id,
      name: move.name,
      category: Value(move.category),
      videoPath: Value(move.videoPath),
      contentHash: Value(move.contentHash),
      count: Value(move.count),
      learningState: Value(move.learningState),
    ));

    // Create the dummy video file
    final oldAbsPath = VideoPathResolver.toAbsolute(move.videoPath!);
    File(oldAbsPath).createSync(recursive: true);
    expect(File(oldAbsPath).existsSync(), isTrue);

    final notifier = container.read(moveDetailProvider.notifier);
    notifier.init(move);

    // Trigger rename
    notifier.send(const TapRename());
    notifier.send(const SaveName('New Name'));
    notifier.send(const NameAvailable());

    // Wait for async side effects to complete
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // VERIFY: File moved on disk
    // VERIFY: DB was updated with the new video path
    final dbMove = await (db.select(db.moves)..where((final t) => t.id.equals('m1'))).getSingle();
    expect(dbMove.name, 'New Name', reason: 'Name should be updated in DB');
    expect(dbMove.videoPath, matches(r'^Moves/Toprock/New Name - deadbeef\.mp4$'), reason: 'Video path should be updated in DB to flat hash scheme');

    // VERIFY: File moved on disk
    final newAbsPath = VideoPathResolver.toAbsolute(dbMove.videoPath!);
    expect(File(newAbsPath).existsSync(), isTrue, reason: 'File should be at the new semantic path');
    expect(File(oldAbsPath).existsSync(), isFalse, reason: 'Old file should be gone');
  });
}
