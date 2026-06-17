class LibraryManifest {
  const LibraryManifest({
    required this.exportedAt,
    required this.moves,
    required this.combos,
    required this.comboMoves,
    required this.categories,
    required this.fsrsCards,
    required this.decks,
    required this.deckMoves,
    required this.reviews,
    required this.assets,
    this.notes = const [],
    this.plans = const [],
    this.version = 2,
  });

  final int version;
  final DateTime exportedAt;
  final List<LibraryMove> moves;
  final List<LibraryCombo> combos;
  final List<LibraryComboMove> comboMoves;
  final List<LibraryCategory> categories;
  final List<LibraryFsrsCard> fsrsCards;
  final List<LibraryDeck> decks;
  final List<LibraryDeckMove> deckMoves;
  final List<LibraryReview> reviews;
  final List<LibraryAsset> assets;

  /// User-authored journal notes (jots/status/plan markers) across all combos.
  final List<LibraryNote> notes;

  /// Practice plans (intentions) across all combos.
  final List<LibraryPlan> plans;

  Map<String, dynamic> toJson() => {
    'version': version,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'moves': moves.map((final move) => move.toJson()).toList(),
    'combos': combos.map((final combo) => combo.toJson()).toList(),
    'comboMoves': comboMoves.map((final comboMove) => comboMove.toJson()).toList(),
    'categories': categories.map((final category) => category.toJson()).toList(),
    'fsrsCards': fsrsCards.map((final card) => card.toJson()).toList(),
    'decks': decks.map((final deck) => deck.toJson()).toList(),
    'deckMoves': deckMoves.map((final deckMove) => deckMove.toJson()).toList(),
    'reviews': reviews.map((final review) => review.toJson()).toList(),
    'assets': assets.map((final asset) => asset.toJson()).toList(),
    'notes': notes.map((final note) => note.toJson()).toList(),
    'plans': plans.map((final plan) => plan.toJson()).toList(),
  };
}

class LibraryMove {
  const LibraryMove({
    required this.id,
    required this.name,
    required this.category,
    required this.contentHash,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String category;
  final String? contentHash;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'contentHash': contentHash,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

class LibraryCombo {
  const LibraryCombo({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class LibraryComboMove {
  const LibraryComboMove({
    required this.comboId,
    required this.moveId,
    required this.sequenceIndex,
  });

  final String comboId;
  final String moveId;
  final int sequenceIndex;

  Map<String, dynamic> toJson() => {
    'comboId': comboId,
    'moveId': moveId,
    'sequenceIndex': sequenceIndex,
  };
}

class LibraryCategory {
  const LibraryCategory({
    required this.name,
    required this.colorValue,
    required this.isDefault,
  });

  final String name;
  final int colorValue;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
    'name': name,
    'colorValue': colorValue,
    'isDefault': isDefault,
  };
}

class LibraryFsrsCard {
  const LibraryFsrsCard({
    required this.entityId,
    required this.entityType,
    required this.state,
    required this.stability,
    required this.difficulty,
    required this.due,
  });

  final String entityId;
  final String entityType;
  final int state;
  final double? stability;
  final double? difficulty;
  final DateTime due;

  Map<String, dynamic> toJson() => {
    'entityId': entityId,
    'entityType': entityType,
    'state': state,
    'stability': stability,
    'difficulty': difficulty,
    'due': due.toUtc().toIso8601String(),
  };
}

class LibraryDeck {
  const LibraryDeck({
    required this.id,
    required this.name,
    required this.deckType,
  });

  final String id;
  final String name;
  final String deckType;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'deckType': deckType,
  };
}

class LibraryDeckMove {
  const LibraryDeckMove({required this.deckId, required this.moveId});

  final String deckId;
  final String moveId;

  Map<String, dynamic> toJson() => {'deckId': deckId, 'moveId': moveId};
}

class LibraryReview {
  const LibraryReview({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.rating,
    required this.createdAt,
  });

  final String id;
  final String entityId;
  final String entityType;
  final String rating;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityId': entityId,
    'entityType': entityType,
    'rating': rating,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

class LibraryAsset {
  const LibraryAsset({
    required this.contentHash,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.durationMs,
    required this.width,
    required this.height,
    required this.importedAt,
    required this.sourceType,
    required this.sourceName,
    required this.deletedAt,
  });

  final String contentHash;
  final int fileSizeBytes;
  final String mimeType;
  final int? durationMs;
  final int? width;
  final int? height;
  final DateTime importedAt;
  final String sourceType;
  final String? sourceName;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() => {
    'contentHash': contentHash,
    'fileSizeBytes': fileSizeBytes,
    'mimeType': mimeType,
    'durationMs': durationMs,
    'width': width,
    'height': height,
    'importedAt': importedAt.toUtc().toIso8601String(),
    'sourceType': sourceType,
    'sourceName': sourceName,
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
  };
}

/// A user-authored combo journal entry (jot/status/plan/duplicate). The
/// optional [videoContentHash] lets a read-only viewer resolve a linked take
/// to its Drive video the same way moves resolve (`<contentHash>.mp4`).
class LibraryNote {
  const LibraryNote({
    required this.id,
    required this.comboId,
    required this.kind,
    required this.body,
    required this.videoContentHash,
    required this.createdAt,
  });

  final String id;
  final String comboId;
  final String kind;
  final String body;
  final String? videoContentHash;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'comboId': comboId,
    'kind': kind,
    'body': body,
    'videoContentHash': videoContentHash,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

/// A practice plan (intention) for a combo on a given day, with optional
/// evidence-stamped completion.
class LibraryPlan {
  const LibraryPlan({
    required this.id,
    required this.comboId,
    required this.planDate,
    required this.position,
    required this.completedAt,
  });

  final String id;
  final String comboId;
  final DateTime planDate;
  final int position;
  final DateTime? completedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'comboId': comboId,
    'planDate': planDate.toUtc().toIso8601String(),
    'position': position,
    'completedAt': completedAt?.toUtc().toIso8601String(),
  };
}
