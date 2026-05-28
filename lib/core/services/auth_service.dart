import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/failures/failure.dart';

class AuthService {
  final SharedPreferences _prefs;
  bool _initialized = false;

  AuthService(this._prefs);

  bool get isLoggedIn {
    if (!_initialized) return false;
    return FirebaseAuth.instance.currentUser != null;
  }

  String get userId {
    if (!_initialized) return '';
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  String get userEmail {
    if (!_initialized) return '';
    return FirebaseAuth.instance.currentUser?.email ?? '';
  }

  TaskEither<AppFailure, Unit> _ensureInitialized() {
    return TaskEither.tryCatch(
      () async {
        if (_initialized) return unit;
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
        _initialized = true;
        return unit;
      },
      (error, stackTrace) => AppFailure.unexpected('Firebase not initialized: $error'),
    );
  }

  TaskEither<AppFailure, Unit> login(String email, String password) {
    return _ensureInitialized().flatMap((_) => TaskEither.tryCatch(
      () async {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        return unit;
      },
      (error, stackTrace) => AppFailure.network('Login failed: $error'),
    ));
  }

  TaskEither<AppFailure, Unit> register(String email, String password) {
    return _ensureInitialized().flatMap((_) => TaskEither.tryCatch(
      () async {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        return unit;
      },
      (error, stackTrace) => AppFailure.network('Registration failed: $error'),
    ));
  }

  TaskEither<AppFailure, Unit> logout() {
    return TaskEither.tryCatch(
      () async {
        if (!_initialized) return unit;
        await FirebaseAuth.instance.signOut();
        return unit;
      },
      (error, stackTrace) => AppFailure.unexpected('Logout failed: $error'),
    );
  }

  TaskEither<AppFailure, Unit> refreshAuth() {
    return TaskEither.tryCatch(
      () async {
        if (!_initialized) throw Exception('Not initialized');
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('No user');
        await user.getIdToken(true);
        return unit;
      },
      (error, stackTrace) => AppFailure.network('Auth refresh failed: $error'),
    );
  }
}
