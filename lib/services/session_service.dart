/// Manages the current pairing session.
/// PIN is entered once per connection and stored here for the session.
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  String? _pin;
  bool _authenticated = false;
  DateTime? _authTime;

  static const int _sessionTimeoutMinutes = 30;

  bool get isAuthenticated {
    if (!_authenticated || _pin == null || _authTime == null) return false;
    final elapsed = DateTime.now().difference(_authTime!);
    if (elapsed.inMinutes >= _sessionTimeoutMinutes) {
      clearSession();
      return false;
    }
    return true;
  }

  String? get pin => _authenticated ? _pin : null;

  void authenticate(String pin) {
    _pin = pin;
    _authenticated = true;
    _authTime = DateTime.now();
  }

  void clearSession() {
    _pin = null;
    _authenticated = false;
    _authTime = null;
  }
}
