import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Gives Firebase Auth's `User` an `.id` getter so existing call sites
/// (`auth.user?.id`) keep working unchanged.
extension FirebaseUserId on firebase_auth.User {
  String get id => uid;
}

/// Direct port of `src/contexts/AuthContext.tsx` as a `ChangeNotifier`.
class Profile {
  final String id;
  final String displayName;
  final String? initials;
  final String role;
  final String? city;
  final String? bio;
  final String? avatarUrl;
  final bool isVerified;
  final List<String> tags;

  Profile({
    required this.id,
    required this.displayName,
    required this.initials,
    required this.role,
    required this.city,
    required this.bio,
    required this.avatarUrl,
    required this.isVerified,
    required this.tags,
  });

  factory Profile.fromDb(DbProfile p) => Profile(
        id: p.id,
        displayName: p.displayName,
        initials: p.initials,
        role: p.role,
        city: p.city,
        bio: p.bio,
        avatarUrl: p.avatarUrl,
        isVerified: p.isVerified,
        tags: p.tags,
      );
}

String friendlyError(String message) {
  return message
      .replaceAll(RegExp('supabase', caseSensitive: false), 'our servers')
      .replaceAll(RegExp('firebase', caseSensitive: false), 'our servers');
}

class AuthResult {
  final String? error;
  const AuthResult({this.error});
}

class AuthProvider extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  firebase_auth.User? _firebaseUser;
  Profile? profile;
  bool loading = true;
  bool isGuest = false;

  /// `null` while in guest mode, even though a Firebase anonymous session
  /// backs guest mode internally (see `continueAsGuest`).
  firebase_auth.User? get session => isGuest ? null : _firebaseUser;
  firebase_auth.User? get user => session;

  AuthProvider() {
    // Defer to a microtask: when there's no signed-in user yet, `_init()`
    // never hits an `await` and would otherwise call `notifyListeners()`
    // synchronously while `MultiProvider` is still building the widget tree
    // in `main.dart`, which crashes with a `!_dirty` assertion.
    scheduleMicrotask(_init);
  }

  Future<void> _init() async {
    final current = _auth.currentUser;
    _firebaseUser = current;
    if (current != null && !current.isAnonymous) {
      await _fetchProfile(current.uid);
    }
    loading = false;
    notifyListeners();

    _auth.authStateChanges().listen((user) async {
      _firebaseUser = user;
      if (user == null) {
        isGuest = false;
        profile = null;
      } else if (user.isAnonymous) {
        // Guest session; leave `isGuest` as-is and skip profile lookup.
      } else {
        isGuest = false;
        await _fetchProfile(user.uid);
      }
      notifyListeners();
    });
  }

  Future<void> _fetchProfile(String userId) async {
    try {
      final doc = await _db.collection('profiles').doc(userId).get();
      final data = doc.data();
      if (data != null) {
        profile = Profile.fromDb(DbProfile.fromJson({...data, 'id': doc.id}));
      }
    } catch (_) {
      // Non-fatal: keep whatever profile we had.
    }
  }

  Future<void> refreshProfile() async {
    final uid = _firebaseUser?.uid;
    if (uid != null) {
      await _fetchProfile(uid);
      notifyListeners();
    }
  }

  Future<AuthResult> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return const AuthResult();
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult(error: friendlyError(e.message ?? 'Could not log in'));
    }
  }

  Future<AuthResult> signUp(
      String email, String password, String displayName) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid != null) {
        final trimmedName = displayName.trim();
        final initials = trimmedName
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0])
            .join()
            .toUpperCase();
        await _db.collection('profiles').doc(uid).set({
          'display_name': trimmedName,
          'initials': initials.length > 2 ? initials.substring(0, 2) : initials,
          'role': 'parent',
          'city': null,
          'bio': null,
          'avatar_url': null,
          'is_verified': false,
          'tags': <String>[],
          'created_at': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
      return const AuthResult();
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult(
          error: friendlyError(e.message ?? 'Could not create account'));
    }
  }

  Future<void> signOut() async {
    isGuest = false;
    profile = null;
    await _auth.signOut();
    notifyListeners();
  }

  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult();
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult(
          error: friendlyError(e.message ?? 'Could not send reset link'));
    }
  }

  void continueAsGuest() {
    isGuest = true;
    profile = null;
    // Fire-and-forget: gives Firestore security rules an authenticated
    // principal for guest writes without exposing the anonymous identity
    // through the public `user`/`session` getters above.
    _auth.signInAnonymously();
    notifyListeners();
  }
}

/// Direct port of `requireUserId` from `AuthContext.tsx`.
String? requireUserId(String? userId, bool isGuest) {
  if (isGuest || userId == null) return null;
  return userId;
}
