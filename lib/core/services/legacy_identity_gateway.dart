/// Concrete `legacyIdentities` gateway (task 3.4) — the ONLY SDK-touching file
/// for the legacy-identity claim, mirroring `appwrite_account_gateway.dart`.
///
/// Reads via `TablesDB.listRows` (indexed `by_firebaseUid`) and writes via
/// `createRow` with owner-only row permissions (the table is `rowSecurity: true`
/// with empty table `$permissions`, so each mapping is readable/writable only by
/// its own Appwrite user). SDK shapes verified against resolved `appwrite`
/// 25.2.0 (`TablesDB.listRows/createRow`, `Row.data`, `RowList.rows`,
/// `Query.equal/limit`, `Permission.read/write`, `Role.user`, `ID.unique`).
library;

import 'package:appwrite/appwrite.dart';

import '../config/appwrite_env.dart';
import 'legacy_identity_service.dart';

class AppwriteLegacyIdentityGateway implements LegacyIdentityGateway {
  AppwriteLegacyIdentityGateway({required final Client client})
    : _tables = TablesDB(client);

  final TablesDB _tables;

  @override
  Future<String?> resolveByFirebaseUid(final String firebaseUid) async {
    final rows = await _tables.listRows(
      databaseId: kAppwriteDatabaseId,
      tableId: kLegacyIdentitiesTableId,
      queries: [Query.equal('firebaseUid', firebaseUid), Query.limit(1)],
    );
    if (rows.rows.isEmpty) return null;
    final mapped = rows.rows.first.data['appwriteUserId'];
    return mapped is String && mapped.isNotEmpty ? mapped : null;
  }

  @override
  Future<void> put(final LegacyIdentity identity) async {
    await _tables.createRow(
      databaseId: kAppwriteDatabaseId,
      tableId: kLegacyIdentitiesTableId,
      rowId: ID.unique(),
      data: {
        'firebaseUid': identity.firebaseUid,
        'appwriteUserId': identity.appwriteUserId,
        'email': identity.email,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      permissions: [
        Permission.read(Role.user(identity.appwriteUserId)),
        Permission.write(Role.user(identity.appwriteUserId)),
      ],
    );
  }
}
