import 'package:breakdex/core/models/add_flow_order.dart';
import 'package:breakdex/core/models/move_creation.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Builds the request exactly as `_startClipFlow` does, so the two flow orders
// can be compared as move records rather than UI paths.
CreateMoveRequest _requestForOrder({
  required final AddFlowOrder order,
  required final String pickedPath,
  final String? editedPath,
}) =>
    CreateMoveRequest(
      name: 'Windmill',
      category: 'Power',
      localVideoPath: resolveAddFlowVideoPath(
        order: order,
        pickedPath: pickedPath,
        editedPath: editedPath,
      ),
      originalVideoName: 'clip.mov',
      videoFileSize: 1024,
      count: 8,
      learningState: 'NEW',
    );

void _expectSameRecord(final CreateMoveRequest a, final CreateMoveRequest b) {
  expect(a.name, b.name);
  expect(a.category, b.category);
  expect(a.localVideoPath, b.localVideoPath);
  expect(a.originalVideoName, b.originalVideoName);
  expect(a.videoFileSize, b.videoFileSize);
  expect(a.count, b.count);
  expect(a.learningState, b.learningState);
}

void main() {
  group('AddFlowOrder.fromString', () {
    test('absent key falls back to today\'s order (data-safety)', () {
      expect(AddFlowOrder.fromString(null), AddFlowOrder.afterMetadata);
      expect(AddFlowOrder.fromString('garbage'), AddFlowOrder.afterMetadata);
    });

    test('persisted values round-trip through .name', () {
      for (final order in AddFlowOrder.values) {
        expect(AddFlowOrder.fromString(order.name), order);
      }
    });
  });

  group('resolveAddFlowVideoPath', () {
    const picked = '/clips/original.mov';
    const edited = '/clips/trimmed.mov';

    test('details-first always keeps the picked clip', () {
      expect(
        resolveAddFlowVideoPath(
          order: AddFlowOrder.afterMetadata,
          pickedPath: picked,
          editedPath: edited, // ignored — editor never runs in this order
        ),
        picked,
      );
    });

    test('trim-first adopts the edited clip, else falls back to picked', () {
      expect(
        resolveAddFlowVideoPath(
          order: AddFlowOrder.editWhileAdding,
          pickedPath: picked,
          editedPath: edited,
        ),
        edited,
      );
      expect(
        resolveAddFlowVideoPath(
          order: AddFlowOrder.editWhileAdding,
          pickedPath: picked,
          editedPath: null, // editor cancelled
        ),
        picked,
      );
    });
  });

  group('flow-order record equivalence', () {
    const picked = '/clips/original.mov';

    test('both orders build an identical record when no crop is applied', () {
      final afterMetadata = _requestForOrder(
        order: AddFlowOrder.afterMetadata,
        pickedPath: picked,
      );
      // Trim-first with the editor cancelled == no crop applied.
      final editWhileAdding = _requestForOrder(
        order: AddFlowOrder.editWhileAdding,
        pickedPath: picked,
        editedPath: null,
      );
      _expectSameRecord(afterMetadata, editWhileAdding);
    });

    test('a deliberate crop diverges only in the video pointer', () {
      final afterMetadata = _requestForOrder(
        order: AddFlowOrder.afterMetadata,
        pickedPath: picked,
      );
      final cropped = _requestForOrder(
        order: AddFlowOrder.editWhileAdding,
        pickedPath: picked,
        editedPath: '/clips/trimmed.mov',
      );
      expect(cropped.localVideoPath, isNot(afterMetadata.localVideoPath));
      // Every other field stays identical.
      expect(cropped.name, afterMetadata.name);
      expect(cropped.category, afterMetadata.category);
      expect(cropped.count, afterMetadata.count);
      expect(cropped.learningState, afterMetadata.learningState);
    });
  });

  group('addFlowOrderProvider', () {
    test('defaults to details-first and persists a change across restart',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(addFlowOrderProvider), AddFlowOrder.afterMetadata);

      await container
          .read(addFlowOrderProvider.notifier)
          .set(AddFlowOrder.editWhileAdding);

      final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restarted.dispose);
      expect(
        restarted.read(addFlowOrderProvider),
        AddFlowOrder.editWhileAdding,
      );
    });
  });
}
