/// Where the video editor sits in the clip add-flow.
///
/// Both orders converge on an identical move record; only the moment the editor
/// runs differs. [afterMetadata] is today's behaviour (editing is deferred to
/// move detail); [editWhileAdding] routes the picked clip straight into the
/// editor before metadata is captured.
enum AddFlowOrder {
  afterMetadata,
  editWhileAdding;

  // Absent/unknown key falls back to today's order (data-safety).
  static AddFlowOrder fromString(final String? value) => switch (value) {
        'editWhileAdding' => AddFlowOrder.editWhileAdding,
        _ => AddFlowOrder.afterMetadata,
      };

  String get displayName => switch (this) {
        AddFlowOrder.afterMetadata => 'Details first',
        AddFlowOrder.editWhileAdding => 'Trim first',
      };
}

/// Resolves the clip's video path for the chosen [order]. This is the entire
/// behavioural difference between the two flow orders: [afterMetadata] always
/// keeps the picked path, [editWhileAdding] adopts the edited path when the
/// editor returned one and otherwise falls back to the picked path. When no
/// edit is applied both orders resolve to the same path — hence identical
/// records.
String resolveAddFlowVideoPath({
  required final AddFlowOrder order,
  required final String pickedPath,
  required final String? editedPath,
}) =>
    order == AddFlowOrder.editWhileAdding ? (editedPath ?? pickedPath) : pickedPath;
