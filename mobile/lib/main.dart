import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'services/location_service.dart';
import 'services/auth_service.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/driver_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Habilitar debug prints en desarrollo
  if (kDebugMode) {
    debugPrint('🚀 Iniciando TransporteRural en modo DEBUG');
  }

  // Inicializar Supabase Auth

  const supabaseUrl = 'https://aghbbmbbfcgtpipnrjev.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFnaGJibWJiZmNndHBpcG5yamV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5NzYwODUsImV4cCI6MjA3NjU1MjA4NX0.Q0YhA-LyaRc4EJ7iKPkiIz2qTB0xaWA3zhJ1kZlqwbQ'; // Reemplazar con tu clave real

  try {
    await AuthService.initialize(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
    );
    if (kDebugMode) {
      debugPrint('✅ Supabase Auth inicializado correctamente');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Error al inicializar Supabase Auth: $e');
    }
    // Continuar sin Supabase Auth (para desarrollo)
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
      child: Consumer2<SettingsProvider, AppProvider>(
        builder: (context, settings, appProvider, child) {
          // Determinar el modo del tema
          // El login screen siempre usa modo claro (fijo)
          // Las demás pantallas usan la preferencia del usuario
          // Si no hay usuario logueado, usar modo claro (para login/splash)
          final hasUser = appProvider.currentUser != null;
          final themeMode = hasUser
              ? (settings.darkModeEnabled ? ThemeMode.dark : ThemeMode.light)
              : ThemeMode.light; // Login siempre claro

          return MaterialApp(
            key: ValueKey(
                'app_${settings.locale.languageCode}'), // Forzar reconstrucción completa cuando cambia el idioma
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            themeMode: themeMode,

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
