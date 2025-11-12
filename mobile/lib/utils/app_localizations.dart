import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String>? _localizedStrings;
  static Map<String, String>? _fallbackStrings;
  static Locale? _lastFallbackLocale;

  AppLocalizations(this.locale);

  // Método estático para limpiar todo el caché
  static void clearCache() {
    _fallbackStrings = null;
    _lastFallbackLocale = null;
  }

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Future<bool> load() async {
    // Siempre limpiar traducciones anteriores para forzar recarga
    _localizedStrings = null;

    // Limpiar fallback si cambió el locale
    if (_lastFallbackLocale != null &&
        _lastFallbackLocale!.languageCode != locale.languageCode) {
      _fallbackStrings = null;
      _lastFallbackLocale = null;
    }

    try {
      // En Flutter Web, a veces las rutas de assets se duplican
      // Intentar primero la ruta normal, luego sin el prefijo "assets/"
      String assetPath = 'assets/l10n/${locale.languageCode}.json';
      String jsonString;
      try {
        jsonString = await rootBundle.loadString(assetPath);
      } catch (e) {
        // Si falla, intentar sin el prefijo "assets/" (para Flutter Web)
        if (kIsWeb) {
          assetPath = 'l10n/${locale.languageCode}.json';
          jsonString = await rootBundle.loadString(assetPath);
        } else {
          rethrow;
        }
      }
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      // Cargar español como fallback si no es el idioma actual
      if (locale.languageCode != 'es') {
        // Solo cargar fallback si el locale cambió o no existe
        if (_lastFallbackLocale != locale || _fallbackStrings == null) {
          try {
            String fallbackPath = 'assets/l10n/es.json';
            String fallbackString;
            try {
              fallbackString = await rootBundle.loadString(fallbackPath);
            } catch (e) {
              if (kIsWeb) {
                fallbackPath = 'l10n/es.json';
                fallbackString = await rootBundle.loadString(fallbackPath);
              } else {
                rethrow;
              }
            }
            Map<String, dynamic> fallbackMap = json.decode(fallbackString);
            _fallbackStrings = fallbackMap.map((key, value) {
              return MapEntry(key, value.toString());
            });
            _lastFallbackLocale = locale;
          } catch (e) {
            // Si falla cargar el fallback, continuar sin él
          }
        }
      } else {
        _fallbackStrings = null;
        _lastFallbackLocale = null;
      }

      return true;
    } catch (e) {
      // Si falla cargar el idioma específico, intentar con español como fallback
      try {
        String fallbackPath = 'assets/l10n/es.json';
        String jsonString;
        try {
          jsonString = await rootBundle.loadString(fallbackPath);
        } catch (e2) {
          if (kIsWeb) {
            fallbackPath = 'l10n/es.json';
            jsonString = await rootBundle.loadString(fallbackPath);
          } else {
            rethrow;
          }
        }
        Map<String, dynamic> jsonMap = json.decode(jsonString);

        _localizedStrings = jsonMap.map((key, value) {
          return MapEntry(key, value.toString());
        });
        _fallbackStrings = _localizedStrings;
        _lastFallbackLocale = locale;

        return true;
      } catch (e2) {
        _localizedStrings = {};
        return false;
      }
    }
  }

  // Las traducciones ahora se cargan desde archivos JSON en assets/l10n/

  String translate(String key) {
    // Usar las traducciones cargadas desde JSON
    if (_localizedStrings != null && _localizedStrings!.containsKey(key)) {
      final translation = _localizedStrings![key]!;
      // Verificar que no sea la clave misma (por si acaso)
      if (translation != key) {
        return translation;
      }
    }

    // Si no se encuentra en el idioma actual, intentar con español como fallback
    if (_fallbackStrings != null && _fallbackStrings!.containsKey(key)) {
      return _fallbackStrings![key]!;
    }

    // Si no se encuentra en ningún lado, devolver una versión legible de la clave
    return _formatKeyAsReadable(key);
  }

  // Convertir claves como "no_account_register" a "No account register"
  String _formatKeyAsReadable(String key) {
    // Reemplazar guiones bajos con espacios y capitalizar palabras
    return key
        .split('_')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en', 'pt', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Limpiar todo el caché antes de cargar nuevas traducciones
    AppLocalizations.clearCache();

    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) {
    // Siempre recargar para asegurar que las traducciones se actualicen cuando cambia el locale
    return true;
  }
}
