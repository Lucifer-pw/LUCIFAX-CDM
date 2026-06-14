import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucifax_cdm/core/services/firebase_service.dart';
import 'package:lucifax_cdm/models/user_model.dart';


final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userModelProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(authServiceProvider).getUserStream(user.uid);
});

class AuthService {
  final FirebaseAuth _auth = FirebaseService().auth;
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        return await getUserData(credential.user!.uid);
      }
    } catch (e) {
      debugPrint('AuthService login error: $e');
      rethrow;
    }
    return null;
  }

  Future<UserModel?> register(String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        final uid = credential.user!.uid;
        final userModel = UserModel(
          uid: uid,
          email: email,
          displayName: displayName,
          devices: [],
          createdAt: DateTime.now(),
          role: 'user', // Default role is user
        );
        await _firestore.collection('users').doc(uid).set(userModel.toJson());
        return userModel;
      }
    } catch (e) {
      debugPrint('AuthService register error: $e');
      rethrow;
    }
    return null;
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('AuthService getUserData error: $e');
    }
    return null;
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  Future<void> savePin(String pin) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'pin': pin,
      });
    } catch (e) {
      debugPrint('AuthService savePin error: $e');
    }
  }

  Future<bool> verifyPin(String pin) async {
    final user = currentUser;
    if (user == null) return false;
    return verifyPinForUser(user.uid, pin);
  }

  Future<bool> verifyPinForUser(String targetUserId, String pin) async {
    try {
      final doc = await _firestore.collection('users').doc(targetUserId).get();
      if (doc.exists) {
        final serverPin = doc.data()?['pin'];
        return serverPin == pin;
      }
    } catch (e) {
      debugPrint('AuthService verifyPinForUser error: $e');
    }
    return false;
  }

  Future<bool> hasPinSetup() async {
    final user = currentUser;
    if (user == null) return false;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return false;
    final data = doc.data();
    if (data == null) return false;
    final pin = data['pin'];
    return pin != null && pin.toString().trim().isNotEmpty;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
