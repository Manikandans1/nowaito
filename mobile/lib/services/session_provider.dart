import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the logged-in user's identity and JWT token.
/// Persisted in SharedPreferences so the user stays logged in across restarts.
class SessionProvider extends ChangeNotifier {
  String? _token;
  String? _userId;
  String? _role; // "RIDER" | "DRIVER"

  String? get token  => _token;
  String? get userId => _userId;
  String? get role   => _role;
  bool   get isLoggedIn => _token != null;
  bool   get isRider    => _role == 'RIDER';
  bool   get isDriver   => _role == 'DRIVER';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token  = prefs.getString('jwt_token');
    _userId = prefs.getString('user_id');
    _role   = prefs.getString('user_role');
    notifyListeners();
  }

  Future<void> save(String token, String userId, String role) async {
    _token  = token;
    _userId = userId;
    _role   = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('user_id', userId);
    await prefs.setString('user_role', role);
    notifyListeners();
  }

  Future<void> clear() async {
    _token = _userId = _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    notifyListeners();
  }
}
