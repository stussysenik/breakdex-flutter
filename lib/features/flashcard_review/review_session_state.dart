import 'providers/review_providers.dart';

String reviewSessionItemKey(final ReviewSessionItem item) =>
    '${item.entityType}:${item.entityId}';

class ReviewSessionReconciliation {
  const ReviewSessionReconciliation({
    required this.items,
    required this.currentIndex,
    required this.completed,
    required this.assessmentStageVisible,
    required this.removedCount,
    required this.currentItemRemoved,
  });

  final List<ReviewSessionItem> items;
  final int currentIndex;
  final bool completed;
  final bool assessmentStageVisible;
  final int removedCount;
  final bool currentItemRemoved;
}

ReviewSessionReconciliation reconcileReviewSession({
  required final List<ReviewSessionItem> previousItems,
  required final List<ReviewSessionItem> nextItems,
  required final int currentIndex,
  required final bool completed,
  required final bool assessmentStageVisible,
}) {
  if (nextItems.isEmpty) {
    return ReviewSessionReconciliation(
      items: nextItems,
      currentIndex: 0,
      completed: false,
      assessmentStageVisible: false,
      removedCount: previousItems.length,
      currentItemRemoved: previousItems.isNotEmpty,
    );
  }

  if (previousItems.isEmpty) {
    return ReviewSessionReconciliation(
      items: nextItems,
      currentIndex: 0,
      completed: false,
      assessmentStageVisible: false,
      removedCount: 0,
      currentItemRemoved: false,
    );
  }

  final safePreviousIndex = currentIndex.clamp(0, previousItems.length - 1);
  final currentItemKey = reviewSessionItemKey(previousItems[safePreviousIndex]);
  final nextByKey = {
    for (final item in nextItems) reviewSessionItemKey(item): item,
  };

  final reconciled = <ReviewSessionItem>[];
  var removedCount = 0;
  var currentItemRemoved = false;

  for (final item in previousItems) {
    final key = reviewSessionItemKey(item);
    final refreshed = nextByKey[key];
    if (refreshed != null) {
      reconciled.add(refreshed);
      continue;
    }
    removedCount += 1;
    if (key == currentItemKey) currentItemRemoved = true;
  }

  if (reconciled.isEmpty) {
    return ReviewSessionReconciliation(
      items: const [],
      currentIndex: 0,
      completed: false,
      assessmentStageVisible: false,
      removedCount: removedCount,
      currentItemRemoved: currentItemRemoved,
    );
  }

  final preservedIndex = reconciled.indexWhere(
    (final item) => reviewSessionItemKey(item) == currentItemKey,
  );
  final nextIndex = preservedIndex >= 0
      ? preservedIndex
      : safePreviousIndex.clamp(0, reconciled.length - 1);

  return ReviewSessionReconciliation(
    items: reconciled,
    currentIndex: nextIndex,
    completed: completed && reconciled.isNotEmpty,
    assessmentStageVisible: preservedIndex >= 0
        ? assessmentStageVisible
        : false,
    removedCount: removedCount,
    currentItemRemoved: currentItemRemoved,
  );
}
