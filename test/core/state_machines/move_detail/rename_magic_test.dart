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

class FakeMoveRepository implements MoveRepository {
  final List<MovesCompanion> updates = [];

  @override
  Future<void> update(MovesCompanion move) async {
    updates.add(move);
  }

  @override
  Future<void> archive(String id, {required String reason}) async {}
  @override
  Future<void> delete(String id) async {}
  @override
  Future<List<Move>> getAll() async => [];
  @override
  Future<List<Move>> getArchived() async => [];
  @override
  Future<Move> getById(String id) async => throw UnimplementedError();
  @override
  Future<void> insert(MovesCompanion move) async {}
  @override
  Future<void> restore(String id) async {}
  @override
  Stream<List<Move>> watchAll() => const Stream.empty();
  @override
  Stream<List<Move>> watchArchived() => const Stream.empty();
  @override
  Stream<List<Move>> watchByCategory(String category) => const Stream.empty();
  @override
  Stream<Move> watchById(String id) => const Stream.empty();
  @override
  Stream<List<Move>> watchByState(String state) => const Stream.empty();
}

class FakeNamingService implements ReviewableNamingService {
  @override
  Future<bool> isNameTaken(String value, {String? excludingMoveId, String? excludingComboId}) async => false;
  
  @override
  String normalize(String value) => value.trim();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakeMoveRepository fakeRepo;
  late String tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('breakdex_test').path;
    VideoPathResolver.docsPathOverride = tempDir;

    fakeRepo = FakeMoveRepository();
    container = ProviderContainer(
      overrides: [
        moveRepositoryProvider.overrideWithValue(fakeRepo),
        reviewableNamingServiceProvider.overrideWithValue(FakeNamingService()),
      ],
    );
  });

  tearDown(() {
    try {
      Directory(tempDir).deleteSync(recursive: true);
    } catch (_) {}
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
    final newAbsPath = VideoPathResolver.toAbsolute('Moves/Toprock/New Name/video.mp4');
    expect(File(newAbsPath).existsSync(), isTrue, reason: 'File should be at the new semantic path');
    expect(File(oldAbsPath).existsSync(), isFalse, reason: 'Old file should be gone');

    // VERIFY: DB was updated with the new video path
    final nameUpdate = fakeRepo.updates.any((m) => m.name.present && m.name.value == 'New Name');
    expect(nameUpdate, isTrue, reason: 'Name should be updated in DB');
    
    final pathUpdate = fakeRepo.updates.any((m) => m.videoPath.present && m.videoPath.value == 'Moves/Toprock/New Name/video.mp4');
    expect(pathUpdate, isTrue, reason: 'Video path should be updated in DB');
  });
}
