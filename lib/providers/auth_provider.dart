import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class AuthProvider extends ChangeNotifier {
  bool _initialized = false;
  bool _loading = true;
  String? _error;
  StreamSubscription<AuthState>? _authSubscription;

  bool get isInitialized => _initialized;
  bool get isLoading => _loading;
  String? get error => _error;

  Session? get session => Supabase.instance.client.auth.currentSession;

  bool get isAuthenticated => session != null;

  String? get userEmail => session?.user.email;

  String? get accessToken => session?.accessToken;

  Future<void> init() async {
    if (_initialized) return;

    if (!SupabaseConfig.isConfigured) {
      _error =
          'Supabase is not configured. Run with '
          '--dart-define=SUPABASE_URL and --dart-define=SUPABASE_ANON_KEY.';
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((_) => notifyListeners());
      _initialized = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    _error = null;
    notifyListeners();
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return _error;
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _error = null;
    notifyListeners();
    try {
      await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null && fullName.isNotEmpty
            ? {'full_name': fullName.trim()}
            : null,
      );
      return null;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return _error;
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
