/// Riverpod wiring for the Appwrite identity layer (task 3.1). Unwired from the
/// app shell until Phase 3.3 (auth wiring) — construction is inert (no network)
/// until a consumer watches [currentAppwriteUserProvider].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/config/remote_config_providers.dart' show appwriteClientProvider;
import 'package:breakdex/core/services/appwrite_account_gateway.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart';

/// The identity service, over the live Appwrite client (reused from the
/// remote-config layer — one client per app).
final appwriteAuthServiceProvider = Provider<AppwriteAuthService>((final ref) {
  final service = AppwriteAuthService(
    AppwriteAccountSdkGateway(ref.watch(appwriteClientProvider)),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// The current account, or `null` when signed out. Seeds with a session check
/// at launch ([AppwriteAuthService.refresh]) — so consumers see `AsyncLoading`
/// once, then the resolved session — then tracks every sign-in / sign-out.
final currentAppwriteUserProvider = StreamProvider<AuthUser?>((final ref) async* {
  final service = ref.watch(appwriteAuthServiceProvider);
  yield await service.refresh();
  yield* service.userStream;
});
