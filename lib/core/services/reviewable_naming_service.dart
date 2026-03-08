import '../database/daos/combos_dao.dart';
import '../database/daos/moves_dao.dart';

class ReviewableNamingService {
  ReviewableNamingService({
    required MovesDao movesDao,
    required CombosDao combosDao,
  }) : _movesDao = movesDao,
       _combosDao = combosDao;

  final MovesDao _movesDao;
  final CombosDao _combosDao;

  String normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  Future<bool> isNameTaken(
    String value, {
    String? excludingMoveId,
    String? excludingComboId,
  }) async {
    final normalized = normalize(value);
    if (normalized.isEmpty) return false;

    final moveExists = await _movesDao.nameExists(
      normalized,
      excludingId: excludingMoveId,
    );
    if (moveExists) return true;

    return _combosDao.nameExists(
      normalized,
      excludingId: excludingComboId,
    );
  }
}
