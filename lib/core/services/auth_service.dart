import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keys for user-configured Supabase credentials in Settings.
const _supabaseUrlKey = 'supabase_url';
const _supabaseAnonKeyKey = 'supabase_anon_key';

class AuthService {
  final SharedPreferences _prefs;
  bool _initialized = false;

  AuthService(this._prefs);

  // ─── Safe getters (return defaults when Supabase is not initialized) ──

  bool get isLoggedIn {
    if (!_initialized) return false;
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  String get userId {
    if (!_initialized) return '';
    try {
      return Supabase.instance.client.auth.currentUser?.id ?? '';
    } catch (_) {
      return '';
    }
  }

  String get userEmail {
    if (!_initialized) return '';
    try {
      return Supabase.instance.client.auth.currentUser?.email ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Exposes the Supabase client for SyncService to use.
  /// Throws if not initialized — callers must check [isLoggedIn] first.
  SupabaseClient get client => Supabase.instance.client;

  // ─── Lazy initialization ──────────────────────────────────────────

  /// Initializes Supabase on demand. Reads credentials from SharedPreferences
  /// (user-configured) or falls back to compile-time env vars.
  /// Returns true if initialization succeeded.
  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;

    final url = _prefs.getString(_supabaseUrlKey) ??
        const String.fromEnvironment('SUPABASE_URL');
    final anonKey = _prefs.getString(_supabaseAnonKeyKey) ??
        const String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || anonKey.isEmpty) return false;

    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Auth actions (trigger lazy init) ─────────────────────────────

  Future<void> login(String email, String password) async {
    final ok = await _ensureInitialized();
    if (!ok) throw Exception('Supabase not configured');
    await Supabase.instance.client.auth
        .signInWithPassword(email: email, password: password);
  }

  Future<void> register(String email, String password) async {
    final ok = await _ensureInitialized();
    if (!ok) throw Exception('Supabase not configured');
    await Supabase.instance.client.auth
        .signUp(email: email, password: password);
  }

  Future<void> logout() async {
    if (!_initialized) return;
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Ignore — already logged out or never initialized
    }
  }

  Future<bool> refreshAuth() async {
    if (!_initialized) return false;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return false;
      if (session.isExpired) {
        await Supabase.instance.client.auth.refreshSession();
      }
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }
}
