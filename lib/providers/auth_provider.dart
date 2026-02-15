import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiService _api = ApiService();

  AppUser? _currentUser;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<User?>? _authSubscription;

  // ─── Getters ─────────────────────────────────────────────

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;
  User? get firebaseUser => _firebaseAuth.currentUser;

  // ─── Initialization ──────────────────────────────────────

  AuthProvider() {
    _init();
  }

  void _init() {
    _authSubscription = _firebaseAuth.authStateChanges().listen(
      _onAuthStateChanged,
      onError: (error) {
        _error = 'Auth state error: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      // User signed out
      _currentUser = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }

    // User signed in — sync with backend
    await _syncWithBackend();
  }

  /// Syncs the Firebase user with the backend database.
  /// Called automatically on auth state change and can be called manually.
  Future<void> _syncWithBackend() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _api.login();
      _error = null;
    } on ApiException catch (e) {
      _error = 'Backend sync failed: ${e.message}';
      // Don't null out _currentUser — they're still Firebase-authenticated,
      // the backend just isn't reachable. They can retry.
    } catch (e) {
      _error = 'Connection error. Is the backend running?';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Actions ─────────────────────────────────────────────

  /// Retry syncing with the backend (e.g. if it was down on first try).
  Future<void> retrySync() async {
    if (_firebaseAuth.currentUser != null) {
      await _syncWithBackend();
    }
  }

  /// Updates the user's profile and refreshes local state.
  Future<void> updateProfile({String? name}) async {
    if (_currentUser == null) return;
    _currentUser = await _api.updateMe(name: name);
    notifyListeners();
  }

  /// Signs out from Firebase and clears local state.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // ─── Cleanup ─────────────────────────────────────────────

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
