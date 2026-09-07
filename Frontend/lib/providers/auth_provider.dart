import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

enum AuthStatus { guest, loading, authenticated, error }

/// Wraps Supabase auth state for the rest of the app. When Supabase isn't
/// configured (see SupabaseService), this provider simply stays in
/// `AuthStatus.guest` forever — the app functions fully either way.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    if (SupabaseService.isConfigured) {
      _authSub = SupabaseService.client.auth.onAuthStateChange.listen((event) {
        _user = event.session?.user;
        _status = _user != null ? AuthStatus.authenticated : AuthStatus.guest;
        notifyListeners();
      });
      _user = SupabaseService.client.auth.currentUser;
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.guest;
    }
  }

  StreamSubscription? _authSub;
  User? _user;
  AuthStatus _status = AuthStatus.guest;
  String? _errorMessage;

  User? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isSupabaseConfigured => SupabaseService.isConfigured;

  Future<bool> signIn(String email, String password) async {
    if (!SupabaseService.isConfigured) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await SupabaseService.client.auth.signInWithPassword(email: email, password: password);
      return true; // status flips to authenticated via the onAuthStateChange listener above
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Could not sign in — check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    if (!SupabaseService.isConfigured) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await SupabaseService.client.auth.signUp(email: email, password: password);
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Could not sign up — check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    if (!SupabaseService.isConfigured) return;
    await SupabaseService.client.auth.signOut();
    // status/user reset happens via the onAuthStateChange listener
  }

  void continueAsGuest() {
    _status = AuthStatus.guest;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
