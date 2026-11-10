import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// The only file that knows Firebase Auth exists.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Emits the signed-in user's uid, or null when signed out.
  Stream<String?> authStateChanges() =>
      _auth.authStateChanges().map((u) => u?.uid);

  String? get currentUid => _auth.currentUser?.uid;

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = AppUser(
        uid: cred.user!.uid, name: name.trim(), email: email.trim(), role: role);
    await cred.user!.updateDisplayName(user.name);
    await _db.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  Future<void> logIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<void> logOut() => _auth.signOut();

  Future<AppUser?> fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  /// Turns Firebase error codes into sentences a person can act on.
  static String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account with this email already exists. Try logging in.';
        case 'invalid-email':
          return 'That email address does not look right.';
        case 'weak-password':
          return 'Choose a stronger password (at least 6 characters).';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'No connection. Check your internet and try again.';
      }
      return 'Something went wrong signing you in. Please try again.';
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Your account was created but your profile could not be saved.';
    }
    return 'Something went wrong. Please try again.';
  }
}
