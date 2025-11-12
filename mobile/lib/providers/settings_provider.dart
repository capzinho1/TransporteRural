import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_localizations.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyDarkMode = 'dark_mode_enabled';
  static const String _keyLanguage = 'language_code';

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  Locale _locale = const Locale('es', 'ES'); // Español por defecto

  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  Locale get locale => _locale;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
    _darkModeEnabled = prefs.getBool(_keyDarkMode) ?? false;
    
    final languageCode = prefs.getString(_keyLanguage) ?? 'es';
    _locale = _getLocaleFromCode(languageCode);
    
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, enabled);
    notifyListeners();
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    _darkModeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, enabled);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    final newLocale = _getLocaleFromCode(languageCode);
    if (_locale.languageCode != newLocale.languageCode) {
      // Limpiar caché de traducciones antes de cambiar el idioma
      AppLocalizations.clearCache();
      _locale = newLocale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, languageCode);
      notifyListeners();
    }
  }

  Locale _getLocaleFromCode(String code) {
    switch (code) {
      case 'en':
        return const Locale('en', 'US');
      case 'pt':
        return const Locale('pt', 'BR');
      case 'zh':
        return const Locale('zh', 'CN');
      case 'es':
      default:
        return const Locale('es', 'ES');
    }
  }

  String getLanguageCode() {
    return _locale.languageCode;
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      case 'zh':
        return '中文';
      default:
        return 'Español';
    }
  }
}

