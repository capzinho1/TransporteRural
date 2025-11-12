import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import 'api_service.dart';

/// Servicio de autenticación con Supabase Auth
/// Maneja registro e inicio de sesión para pasajeros
class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final ApiService _apiService = ApiService();

  /// Inicializar Supabase (debe llamarse en main.dart)
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  /// Registrar usuario con email y password
  static Future<Usuario> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String region,
  }) async {
    try {
      // 1. Registrar en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'region': region,
        },
      );

      if (response.user == null) {
        throw Exception('Error al crear usuario en Supabase Auth');
      }

      // 2. Sincronizar con backend (crear registro en tabla users)
      final syncResponse = await _apiService.syncSupabaseUser(
        supabaseAuthId: response.user!.id,
        email: email,
        name: name,
        region: region,
      );

      if (syncResponse['usuario'] == null) {
        throw Exception('Error al sincronizar usuario con backend');
      }

      return Usuario.fromJson(syncResponse['usuario']);
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  /// Iniciar sesión con email y password
  static Future<Usuario> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autenticar con Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Credenciales inválidas');
      }

      // 2. Obtener datos del usuario desde el backend
      final userResponse = await _apiService.getUserBySupabaseId(
        supabaseAuthId: response.user!.id,
      );

      if (userResponse['usuario'] == null) {
        throw Exception('Usuario no encontrado en el sistema');
      }

      return Usuario.fromJson(userResponse['usuario']);
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Helper para procesar un usuario de Supabase Auth
  /// Verifica si existe en el backend, y si no, lo crea
  static Future<Usuario> _processSupabaseUser(User user) async {
    final email = user.email ?? '';
    final name = user.userMetadata?['name'] ?? 
                user.userMetadata?['full_name'] ?? 
                user.userMetadata?['display_name'] ??
                email.split('@')[0];

    print('✅ [AUTH_SERVICE] Procesando usuario de Supabase Auth: $email');

    // Verificar si el usuario ya existe en el backend
    Usuario usuario;
    try {
      print('🔍 [AUTH_SERVICE] Verificando si el usuario existe en el backend...');
      final existingUser = await _apiService.getUserBySupabaseId(
        supabaseAuthId: user.id,
      );
      
      if (existingUser['usuario'] == null) {
        throw Exception('Usuario no encontrado en el backend');
      }
      
      usuario = Usuario.fromJson(existingUser['usuario']);
      print('✅ [AUTH_SERVICE] Usuario existente encontrado: ${usuario.email}');
    } catch (e) {
      // Usuario no existe (404) o error, crearlo
      final errorMsg = e.toString();
      print('ℹ️ [AUTH_SERVICE] Usuario no encontrado o error al buscar: $errorMsg');
      print('📝 [AUTH_SERVICE] Creando nuevo usuario en backend...');
      print('📝 [AUTH_SERVICE] Datos del usuario:');
      print('   - supabaseAuthId: ${user.id}');
      print('   - email: $email');
      print('   - name: $name');
      print('   - region: No especificada');
      
      try {
        final syncResponse = await _apiService.syncSupabaseUser(
          supabaseAuthId: user.id,
          email: email,
          name: name,
          region: 'No especificada',
        );
        
        if (syncResponse['usuario'] == null) {
          throw Exception('El backend no retornó el usuario después de sincronizar');
        }
        
        usuario = Usuario.fromJson(syncResponse['usuario']);
        print('✅ [AUTH_SERVICE] Usuario creado exitosamente: ${usuario.email}');
      } catch (syncError) {
        print('❌ [AUTH_SERVICE] Error al sincronizar usuario: $syncError');
        print('❌ [AUTH_SERVICE] Tipo de error: ${syncError.runtimeType}');
        print('❌ [AUTH_SERVICE] Mensaje: ${syncError.toString()}');
        rethrow;
      }
    }
    
    return usuario;
  }

  /// Procesar una sesión existente de Supabase (sin iniciar OAuth)
  /// Útil cuando ya hay una sesión activa (por ejemplo, después de un redirect)
  static Future<Usuario> processExistingSession() async {
    try {
      final currentSession = _supabase.auth.currentSession;
      if (currentSession == null) {
        throw Exception('No hay sesión activa para procesar');
      }
      
      print('✅ [AUTH_SERVICE] Procesando sesión existente...');
      return await _processSupabaseUser(currentSession.user);
    } catch (e) {
      print('❌ [AUTH_SERVICE] Error al procesar sesión existente: $e');
      rethrow;
    }
  }

  /// Iniciar sesión o registrar con Google OAuth
  /// Si el usuario no existe, lo crea automáticamente
  /// IMPORTANTE: Este método cierra cualquier sesión activa para forzar selección de cuenta
  static Future<Usuario> signInWithGoogle() async {
    try {
      // IMPORTANTE: Cerrar cualquier sesión activa para forzar selección de cuenta
      // Esto asegura que Google muestre el selector de cuentas en lugar de usar la sesión existente
      final currentSession = _supabase.auth.currentSession;
      if (currentSession != null) {
        print('🔄 [AUTH_SERVICE] Cerrando sesión activa para permitir selección de cuenta...');
        await _supabase.auth.signOut();
        // Esperar un momento para que se complete el cierre de sesión
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // 1. Iniciar flujo de OAuth con Google
      // En Flutter web, esto abre una nueva ventana/pestaña
      // IMPORTANTE: Supabase NO acepta wildcards en redirect URLs
      // Debe ser la URL exacta con el puerto real
      String redirectUrl;
      if (kIsWeb) {
        // Para web, usar el origen actual (incluye puerto dinámico)
        // Uri.base.origin ya incluye el puerto (ej: http://localhost:53712)
        final origin = Uri.base.origin;
        redirectUrl = '$origin/';
        print('🌐 [AUTH_SERVICE] Redirect URL para web: $redirectUrl');
        print('🌐 [AUTH_SERVICE] Uri.base completo: ${Uri.base}');
        print('🌐 [AUTH_SERVICE] Uri.base.origin: $origin');
        print('🌐 [AUTH_SERVICE] Uri.base.port: ${Uri.base.port}');
        
        // Validar que la URL no tenga wildcards
        if (redirectUrl.contains('*')) {
          throw Exception('Error: La URL de redirect contiene wildcards. URL: $redirectUrl');
        }
      } else {
        // Para móvil, usar deep link
        redirectUrl = 'com.transporterural://login-callback';
        print('📱 [AUTH_SERVICE] Redirect URL para móvil: $redirectUrl');
      }
      
      print('🔐 [AUTH_SERVICE] Iniciando OAuth con redirect: $redirectUrl');
      print('🔐 [AUTH_SERVICE] Forzando selección de cuenta (prompt=select_account)');
      
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        queryParams: {
          'prompt': 'select_account', // Forzar selector de cuentas de Google
        },
      );

      // 2. Esperar a que se complete el flujo OAuth
      // Escuchar cambios en el estado de autenticación
      final completer = Completer<Usuario>();
      late StreamSubscription<AuthState> subscription;
      
      // Timeout para cancelar la suscripción si no hay respuesta
      Timer? timeoutTimer;
      timeoutTimer = Timer(const Duration(minutes: 5), () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.completeError(
            Exception('Tiempo de espera agotado. Por favor, intenta nuevamente.')
          );
        }
      });
      
      subscription = _supabase.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        
        print('🔄 [AUTH_SERVICE] Evento de autenticación: $event');
        print('🔄 [AUTH_SERVICE] Sesión presente: ${session != null}');
        
        if (event == AuthChangeEvent.signedIn && session != null) {
          timeoutTimer?.cancel();
          try {
            final usuario = await _processSupabaseUser(session.user);
            
            await subscription.cancel();
            if (!completer.isCompleted) {
              completer.complete(usuario);
            }
          } catch (e) {
            timeoutTimer?.cancel();
            await subscription.cancel();
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        } else if (event == AuthChangeEvent.signedOut) {
          timeoutTimer?.cancel();
          await subscription.cancel();
          if (!completer.isCompleted) {
            completer.completeError(Exception('El usuario canceló la autenticación'));
          }
        } else if (event == AuthChangeEvent.tokenRefreshed) {
          // Token refrescado, verificar si hay sesión
          print('🔄 [AUTH_SERVICE] Token refrescado');
          if (session != null && !completer.isCompleted) {
            // Si hay sesión pero no se ha completado, intentar procesar
            print('🔄 [AUTH_SERVICE] Sesión encontrada después de refresh, procesando...');
            try {
              final usuario = await _processSupabaseUser(session.user);
              timeoutTimer?.cancel();
              await subscription.cancel();
              if (!completer.isCompleted) {
                completer.complete(usuario);
              }
            } catch (e) {
              // Ignorar errores en refresh, esperar al evento signedIn
            }
          }
        }
      });

      // Esperar a que se complete la autenticación
      try {
        return await completer.future;
      } catch (e) {
        timeoutTimer.cancel();
        subscription.cancel();
        rethrow;
      }
    } catch (e) {
      print('❌ [AUTH_SERVICE] Error en signInWithGoogle: $e');
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  /// Cerrar sesión
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Obtener usuario actual de Supabase Auth
  static User? get currentSupabaseUser => _supabase.auth.currentUser;

  /// Obtener sesión actual de Supabase Auth
  static Session? get currentSupabaseSession => _supabase.auth.currentSession;

  /// Verificar si hay una sesión activa
  static bool get hasSession => _supabase.auth.currentSession != null;
}
