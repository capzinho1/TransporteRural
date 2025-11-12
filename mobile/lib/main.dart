import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'services/location_service.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/driver_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  // Habilitar debug prints en desarrollo
  if (kDebugMode) {
    debugPrint('🚀 Iniciando TransporteRural en modo DEBUG');
  }

  runApp(const TransporteRuralApp());
}

class TransporteRuralApp extends StatelessWidget {
  const TransporteRuralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<LocationService>(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            key: ValueKey('app_${settings.locale.languageCode}'), // Forzar reconstrucción completa cuando cambia el idioma
            title: 'GeoRu - App Rural en Tiempo Real',
            debugShowCheckedModeBanner: false,
            
            // Configuración de localización
            locale: settings.locale,
            supportedLocales: const [
              Locale('es', 'ES'), // Español
              Locale('en', 'US'), // Inglés
              Locale('pt', 'BR'), // Portugués
              Locale('zh', 'CN'), // Chino
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            
            // Configuración de temas
            theme: ThemeData(
              primarySwatch: Colors.green,
              primaryColor: const Color(0xFF2E7D32),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2E7D32),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.green,
              primaryColor: const Color(0xFF2E7D32),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2E7D32),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            themeMode: settings.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
            
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/driver': (context) => const DriverScreen(),
            },
          );
        },
      ),
    );
  }
}
