import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// Global uygulama durumu — kullanıcı verisi + onboarding + tema.
/// ChangeNotifier kullanılarak tüm dinleyiciler otomatik rebuild edilir.
class AppState extends ChangeNotifier {
  // ── Kullanıcı Verisi ──────────────────────────────────────────────────────
  UserModel? _currentUser;
  bool _onboardingComplete = false;

  // ── Tema ve Dil ──────────────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.dark;
  String _locale = 'TR';

  // ── Güvenlik ─────────────────────────────────────────────────────────────
  bool _twoFactorEnabled = false;

  // ── Bildirimler ───────────────────────────────────────────────────────────
  bool _pushNotifications = true;
  bool _emailNotifications = true;

  // ── Getters ───────────────────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  String get name => _currentUser?.fullName ?? '';
  String get email => _currentUser?.email ?? '';
  String get companyName => _currentUser?.companyName ?? '';
  bool get onboardingComplete => _onboardingComplete;
  ThemeMode get themeMode => _themeMode;
  String get locale => _locale;
  bool get twoFactorEnabled => _twoFactorEnabled;
  bool get pushNotifications => _pushNotifications;
  bool get emailNotifications => _emailNotifications;

  bool get isLoggedIn => _currentUser != null;

  /// İsim baş harfleri avatar için.
  String get initials {
    if (_currentUser == null) return 'L';
    final parts = _currentUser!.fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'L';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void completeOnboarding() {
    _onboardingComplete = true;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLocale(String lang) {
    _locale = lang;
    notifyListeners();
  }

  void setTwoFactor(bool value) {
    _twoFactorEnabled = value;
    notifyListeners();
  }

  void setPushNotifications(bool value) {
    _pushNotifications = value;
    notifyListeners();
  }

  void setEmailNotifications(bool value) {
    _emailNotifications = value;
    notifyListeners();
  }
}
