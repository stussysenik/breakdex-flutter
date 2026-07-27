import 'package:breakdex/core/database/daos/combos_dao.dart';
import 'package:breakdex/core/database/daos/moves_dao.dart';

class ReviewableNamingService {
  ReviewableNamingService({
    required final MovesDao movesDao,
    required final CombosDao combosDao,
  }) : _movesDao = movesDao,
       _combosDao = combosDao;

  final MovesDao _movesDao;
  final CombosDao _combosDao;

  /// Strict regex for filesystem-safe names: Alphanumeric, Space, Underscore, Dash.
  /// Rejects characters like / \ : * ? " < > | which break cross-platform sync.
  static final RegExp safeNamePattern = RegExp(r'^[a-zA-Z0-9 _-]+$');

  String normalize(final String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  bool isValidName(final String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return false;
    return safeNamePattern.hasMatch(normalized);
  }

  Future<bool> isNameTaken(
    final String value, {
    final String? excludingMoveId,
    final String? excludingComboId,
  }) async {
    final normalized = normalize(value);
    if (normalized.isEmpty) return false;

    final moveExists = await _movesDao.nameExists(
      normalized,
      excludingId: excludingMoveId,
    );
    if (moveExists) return true;

    return _combosDao.nameExists(normalized, excludingId: excludingComboId);
  }
}
