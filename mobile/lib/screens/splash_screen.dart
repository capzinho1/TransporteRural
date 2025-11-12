import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'driver_screen.dart';
import '../widgets/georu_logo.dart';
import '../services/auth_service.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    // Simular tiempo de carga
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Verificar si hay una sesión activa de Supabase Auth
      // (por ejemplo, después de un redirect de OAuth)
      // IMPORTANTE: Solo procesar sesiones si hay un usuario válido y la sesión no está expirada
      try {
        if (AuthService.hasSession) {
          final currentUser = AuthService.currentSupabaseUser;
          final currentSession = AuthService.currentSupabaseSession;
          
          // Verificar que la sesión sea válida y no esté expirada
          if (currentUser != null && currentSession != null) {
            // Verificar si la sesión está expirada
            final expiresAt = currentSession.expiresAt;
            bool sessionValid = true;
            
            if (expiresAt != null) {
              final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              if (expiresAt < now) {
                print('⚠️ [SPLASH] Sesión expirada, cerrando...');
                await AuthService.signOut();
                sessionValid = false;
              }
            }
            
            // Si la sesión es válida, procesarla
            if (sessionValid) {
              try {
                print('🔄 [SPLASH] Sesión activa válida detectada, procesando usuario...');
                final usuario = await AuthService.processExistingSession();
                
                // Usuario procesado exitosamente, redirigir
                final appProvider = Provider.of<AppProvider>(context, listen: false);
                appProvider.setCurrentUser(usuario);
                
                // Cargar configuraciones del usuario
                final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                await settingsProvider.loadUserSettings(usuario.id);
                
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => usuario.role == 'driver' 
                        ? const DriverScreen() 
                        : const HomeScreen(),
                    ),
                  );
                  return;
                }
              } catch (e) {
                // Error al procesar usuario, continuar al login
                print('⚠️ [SPLASH] Error al procesar usuario después de OAuth: $e');
                // Limpiar sesión si hay error
                await AuthService.signOut();
              }
            }
          }
        }
      } catch (e) {
        // Error al verificar sesión, continuar al login
        print('⚠️ [SPLASH] Error al verificar sesión: $e');
      }
      
      // No hay sesión activa, ir al login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: const Column(
                      children: [
                        // Logo GeoRu
                        GeoRuLogo(
                          size: 120,
                          showText: false,
                          showBackground: true,
                          backgroundColor: Colors.white,
                        ),
                        SizedBox(height: 30),

                        // Título de la app con logo GeoRu
                        GeoRuLogo(
                          size: 0,
                          showText: true,
                          showSlogan: true,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 50),

            // Indicador de carga
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),

            const SizedBox(height: 20),

            // Texto de carga
            const Text(
              'Cargando...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
