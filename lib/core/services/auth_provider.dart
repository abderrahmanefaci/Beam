import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beam/core/services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = SupabaseService.client.auth.currentUser;
    SupabaseService.client.auth.onAuthStateChange.listen((event) {
      _user = event.session?.user;
      notifyListeners();
    });
  }

  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    try {
      await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await SupabaseService.client.auth.signOut();
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}