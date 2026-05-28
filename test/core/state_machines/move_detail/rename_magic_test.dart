import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/state_machines/move_detail/provider.dart';
import 'package:breakdex/core/state_machines/move_detail/event.dart';
import 'package:breakdex/core/state_machines/move_detail/state.dart';
import 'package:breakdex/core/data/repositories.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/services/reviewable_naming_service.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/blackbox_service.dart';

import '../../../helpers/test_database.dart';
import '../../../helpers/test_data.dart';

class FakeNamingService implements ReviewableNamingService {
  @override
  Future<bool> isNameTaken(String value, {String? excludingMoveId, String? excludingComboId}) async => false;
  
  @override
  String normalize(String value) => value.trim();
}

class FakeBlackboxService implements BlackboxService {
  final logs = <String>[];

  @override
  Future<void> log(String action, String entityType, String entityId, [Map<String, dynamic>? data]) async {
    logs.add('[$action] $entityType $entityId');
  }

  @override
  Future<void> clear() async {
    logs.clear();
  }

  @override
  Future<List<String>> readRecent(int lines) async {
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
    } catch (_) {}
    db.close();
    container.dispose();
  });

  test('Rename move moves video file to new semantic path', () async {
    final move = Move(
      id: 'm1',
      name: 'Old Name',
      category: 'Toprock',
      videoPath: 'Moves/Toprock/Old Name/video.mp4',
      count: 0,
      learningState: 'new',
      createdAt: DateTime.now(),
    );
    await db.into(db.moves).insert(MovesCompanion.insert(
      id: move.id,
      name: move.name,
      category: Value(move.category),
      videoPath: Value(move.videoPath),
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
    await Future.delayed(const Duration(milliseconds: 200));

    // VERIFY: File moved on disk
    final newAbsPath = VideoPathResolver.toAbsolute('Moves/Toprock/New name/video.mp4');
    expect(File(newAbsPath).existsSync(), isTrue, reason: 'File should be at the new semantic path');
    expect(File(oldAbsPath).existsSync(), isFalse, reason: 'Old file should be gone');

    // VERIFY: DB was updated with the new video path
    final dbMove = await (db.select(db.moves)..where((t) => t.id.equals('m1'))).getSingle();
    expect(dbMove.name, 'New Name', reason: 'Name should be updated in DB');
    expect(dbMove.videoPath, 'Moves/Toprock/New name/video.mp4', reason: 'Video path should be updated in DB');
  });
}
