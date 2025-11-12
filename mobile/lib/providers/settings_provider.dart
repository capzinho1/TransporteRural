import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_localizations.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyNotificationsPrefix = 'notifications_enabled_';
  static const String _keyDarkModePrefix = 'dark_mode_enabled_';
  static const String _keyLanguagePrefix = 'language_code_';

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  Locale _locale = const Locale('es', 'ES'); // Español por defecto
  
  int? _currentUserId; // ID del usuario actual

  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  Locale get locale => _locale;

  SettingsProvider() {
    _loadGlobalSettings();
  }

  /// Cargar configuraciones globales (solo para login screen)
  Future<void> _loadGlobalSettings() async {
    // El modo oscuro global se usa solo para el login screen (fijo)
    // No se carga aquí porque el login siempre usa modo claro
    _notificationsEnabled = true; // Default
    _darkModeEnabled = false; // Default para login
    _locale = const Locale('es', 'ES'); // Default
    notifyListeners();
  }

  /// Cargar configuraciones del usuario actual
  Future<void> loadUserSettings(int? userId) async {
    if (userId == null) {
      // Si no hay usuario, usar valores por defecto
      _notificationsEnabled = true;
      _darkModeEnabled = false;
      _locale = const Locale('es', 'ES');
      _currentUserId = null;
      notifyListeners();
      return;
    }

    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    
    // Cargar configuraciones específicas del usuario
    final keyNotifications = '$_keyNotificationsPrefix$userId';
    final keyDarkMode = '$_keyDarkModePrefix$userId';
    final keyLanguage = '$_keyLanguagePrefix$userId';
    
    _notificationsEnabled = prefs.getBool(keyNotifications) ?? true;
    _darkModeEnabled = prefs.getBool(keyDarkMode) ?? false;
    
    final languageCode = prefs.getString(keyLanguage) ?? 'es';
    _locale = _getLocaleFromCode(languageCode);
    
    print('📱 [SETTINGS] Configuraciones cargadas para usuario $userId:');
    print('   - Notificaciones: $_notificationsEnabled');
    print('   - Modo oscuro: $_darkModeEnabled');
    print('   - Idioma: ${_locale.languageCode}');
    
    notifyListeners();
  }

  /// Limpiar configuraciones cuando el usuario cierra sesión
  void clearUserSettings() {
    _currentUserId = null;
    _notificationsEnabled = true;
    _darkModeEnabled = false;
    _locale = const Locale('es', 'ES');
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_currentUserId == null) {
      print('⚠️ [SETTINGS] No hay usuario logueado, no se puede guardar configuración');
      return;
    }
    
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyNotificationsPrefix$_currentUserId';
    await prefs.setBool(key, enabled);
    print('💾 [SETTINGS] Notificaciones guardadas para usuario $_currentUserId: $enabled');
    notifyListeners();
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    if (_currentUserId == null) {
      print('⚠️ [SETTINGS] No hay usuario logueado, no se puede guardar configuración');
      return;
    }
    
    _darkModeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyDarkModePrefix$_currentUserId';
    await prefs.setBool(key, enabled);
    print('💾 [SETTINGS] Modo oscuro guardado para usuario $_currentUserId: $enabled');
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_currentUserId == null) {
      print('⚠️ [SETTINGS] No hay usuario logueado, no se puede guardar configuración');
      return;
    }
    
    final newLocale = _getLocaleFromCode(languageCode);
    if (_locale.languageCode != newLocale.languageCode) {
      // Limpiar caché de traducciones antes de cambiar el idioma
      AppLocalizations.clearCache();
      _locale = newLocale;
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyLanguagePrefix$_currentUserId';
      await prefs.setString(key, languageCode);
      print('💾 [SETTINGS] Idioma guardado para usuario $_currentUserId: $languageCode');
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

