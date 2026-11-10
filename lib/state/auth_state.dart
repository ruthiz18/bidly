import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

/// One source of truth for who is signed in.
class AuthState extends ChangeNotifier {
  AuthState(this._repo) {
    _sub = _repo.authStateChanges().listen(_onAuthChanged);
  }

  final AuthRepository _repo;
  StreamSubscription<String?>? _sub;

  bool _initialised = false; // false until Firebase tells us the first answer
  String? _uid;
  AppUser? _user;
  bool _busy = false;
  String? _error;

  bool get initialised => _initialised;
  bool get isSignedIn => _uid != null;
  String? get uid => _uid;
  AppUser? get user => _user;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> _onAuthChanged(String? uid) async {
    _uid = uid;
    if (uid == null) {
      _user = null;
    } else {
      final fetched = await _safeFetch(uid);
      // At signup the auth event beats the profile write; don't clobber it.
      if (uid == _uid) _user = fetched ?? _user;
    }
    _initialised = true;
    notifyListeners();
  }

  Future<AppUser?> _safeFetch(String uid) async {
    try {
      return await _repo.fetchUser(uid);
    } catch (_) {
      return null; // profile is optional for the gate; screens handle null
    }
  }

  /// Returns true on success; on failure [error] holds a readable message.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) =>
      _run(() async {
        _user = await _repo.signUp(
            name: name, email: email, password: password, role: role);
      });

  Future<bool> logIn({required String email, required String password}) =>
      _run(() => _repo.logIn(email: email, password: password));

  Future<void> logOut() => _repo.logOut();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _error = AuthRepository.messageFor(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
