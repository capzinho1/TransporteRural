import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
      // El SDK detectará automáticamente el deep link desde AndroidManifest.xml
      // No necesitamos configurar explícitamente el deep link aquí
    );
  }

  /// Registrar usuario con email y password
  /// Intenta primero con Supabase directo, si falla usa proxy del backend
  static Future<Usuario> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String region,
  }) async {
    try {
      // 1. Intentar registrar en Supabase Auth directamente
      try {
        final response = await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'name': name,
            'region': region,
          },
        ).timeout(const Duration(seconds: 10));

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
      } on TimeoutException {
        print('⏱️ [AUTH_SERVICE] Timeout al conectar con Supabase, usando proxy...');
        // Continuar con proxy
      } catch (e) {
        final errorMsg = e.toString().toLowerCase();
        // Si es un error de conexión o red, usar proxy
        if (errorMsg.contains('failed to fetch') || 
            errorMsg.contains('connection') || 
            errorMsg.contains('network') ||
            errorMsg.contains('socket') ||
            errorMsg.contains('timeout')) {
          print('🌐 [AUTH_SERVICE] Error de conexión con Supabase, usando proxy del backend...');
          // Continuar con proxy
        } else {
          // Otro tipo de error (credenciales, etc.), re-lanzar
          rethrow;
        }
      }

      // 2. Usar proxy del backend como fallback
      print('🔄 [AUTH_SERVICE] Registrando usuario vía proxy del backend...');
      final proxyResponse = await _apiService.proxySignUp(
        email: email,
        password: password,
        name: name,
        region: region,
      );

      if (proxyResponse['success'] != true || proxyResponse['data'] == null) {
        throw Exception(proxyResponse['error'] ?? 'Error al registrar usuario vía proxy');
      }

      final responseData = proxyResponse['data'];
      if (responseData['usuario'] == null) {
        throw Exception('El proxy no retornó los datos del usuario');
      }

      return Usuario.fromJson(responseData['usuario']);
    } catch (e) {
      print('❌ [AUTH_SERVICE] Error al registrar usuario: $e');
      throw Exception('Error al registrar usuario: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  /// Iniciar sesión con email y password
  /// Intenta primero con Supabase directo, si falla usa proxy del backend
  static Future<Usuario> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Intentar autenticar con Supabase Auth directamente
      try {
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        ).timeout(const Duration(seconds: 10));

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
      } on TimeoutException {
        print('⏱️ [AUTH_SERVICE] Timeout al conectar con Supabase, usando proxy...');
        // Continuar con proxy
      } catch (e) {
        final errorMsg = e.toString().toLowerCase();
        // Si es un error de conexión o credenciales inválidas, verificar tipo
        if (errorMsg.contains('invalid login credentials') || 
            errorMsg.contains('credenciales inválidas')) {
          // Error de credenciales, re-lanzar (no es problema de conexión)
          rethrow;
        }
        // Si es un error de conexión o red, usar proxy
        if (errorMsg.contains('failed to fetch') || 
            errorMsg.contains('connection') || 
            errorMsg.contains('network') ||
            errorMsg.contains('socket') ||
            errorMsg.contains('timeout')) {
          print('🌐 [AUTH_SERVICE] Error de conexión con Supabase, usando proxy del backend...');
          // Continuar con proxy
        } else {
          // Otro tipo de error, re-lanzar
          rethrow;
        }
      }

      // 2. Usar proxy del backend como fallback
      print('🔄 [AUTH_SERVICE] Iniciando sesión vía proxy del backend...');
      final proxyResponse = await _apiService.proxySignIn(
        email: email,
        password: password,
      );

      if (proxyResponse['success'] != true || proxyResponse['data'] == null) {
        throw Exception(proxyResponse['error'] ?? proxyResponse['message'] ?? 'Error al iniciar sesión vía proxy');
      }

      final responseData = proxyResponse['data'];
      if (responseData['usuario'] == null) {
        throw Exception('El proxy no retornó los datos del usuario');
      }

      // Guardar la sesión de Supabase si está disponible (opcional)
      // Nota: No es crítico si falla, ya que el usuario está autenticado vía proxy
      if (responseData['session'] != null && responseData['session']['access_token'] != null) {
        try {
          // Intentar refrescar la sesión si es posible
          // La sesión ya está activa en el backend, esto es solo para mantener consistencia local
          print('✅ [AUTH_SERVICE] Sesión obtenida vía proxy, usuario autenticado');
        } catch (sessionError) {
          print('⚠️ [AUTH_SERVICE] Nota: Sesión manejada por proxy: $sessionError');
          // Continuar de todas formas, el usuario está autenticado
        }
      }

      return Usuario.fromJson(responseData['usuario']);
    } catch (e) {
      print('❌ [AUTH_SERVICE] Error al iniciar sesión: $e');
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      // Preservar mensajes de error de credenciales
      if (errorMsg.contains('Credenciales inválidas') || 
          errorMsg.contains('Email o contraseña incorrectos')) {
        throw Exception('Email o contraseña incorrectos');
      }
      throw Exception('Error al iniciar sesión: $errorMsg');
    }
  }

  /// Helper para procesar un usuario de Supabase Auth
  /// Verifica si existe en el backend, y si no, lo crea
  static Future<Usuario> _processSupabaseUser(User user) async {
    final email = user.email ?? '';
    if (email.isEmpty) {
      throw Exception('El email es requerido para crear el usuario');
    }
    
    // Obtener nombre de los metadatos o del email
    String name = user.userMetadata?['name'] ?? 
                 user.userMetadata?['full_name'] ?? 
                 user.userMetadata?['display_name'] ??
                 user.userMetadata?['user_name'] ??
                 '';
    
    // Si no hay nombre en los metadatos, usar la parte del email antes del @
    if (name.isEmpty || name.trim().isEmpty) {
      final emailParts = email.split('@');
      name = emailParts.isNotEmpty && emailParts[0].isNotEmpty 
          ? emailParts[0] 
          : 'Usuario';
    }
    
    // Asegurar que el nombre tenga al menos 1 carácter
    name = name.trim();
    if (name.isEmpty) {
      name = 'Usuario';
    }

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
          region: null, // Enviar null en lugar de 'No especificada' para evitar problemas de validación
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
      // IMPORTANTE: Para móvil, NO pasar redirectTo - Supabase maneja el redirect automáticamente
      if (kIsWeb) {
        // Para web, usar el origen actual (incluye puerto dinámico)
        // Uri.base.origin ya incluye el puerto (ej: http://localhost:53712)
        final origin = Uri.base.origin;
        final redirectUrl = '$origin/';
        print('🌐 [AUTH_SERVICE] Redirect URL para web: $redirectUrl');
        print('🌐 [AUTH_SERVICE] Uri.base completo: ${Uri.base}');
        print('🌐 [AUTH_SERVICE] Uri.base.origin: $origin');
        print('🌐 [AUTH_SERVICE] Uri.base.port: ${Uri.base.port}');
        
        // Validar que la URL no tenga wildcards
        if (redirectUrl.contains('*')) {
          throw Exception('Error: La URL de redirect contiene wildcards. URL: $redirectUrl');
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
      } else {
        // Para móvil, usar el proxy del backend para obtener la URL OAuth
        // Esto permite controlar mejor el flujo y evitar problemas con redirects
        print('📱 [AUTH_SERVICE] Obteniendo URL OAuth desde el proxy del backend...');
        
        try {
          // Llamar al backend para obtener la URL OAuth
          final response = await _apiService.getGoogleOAuthUrl(
            platform: 'mobile',
            finalRedirectTo: 'com.georu.app://login-callback',
          );
          
          if (response['success'] != true || response['data']?['url'] == null) {
            throw Exception(response['message'] ?? 'Error al obtener URL de autenticación');
          }
          
          final oauthUrl = response['data']['url'] as String;
          print('✅ [AUTH_SERVICE] URL OAuth obtenida del backend');
          print('🔐 [AUTH_SERVICE] URL (primeros 100 chars): ${oauthUrl.substring(0, oauthUrl.length > 100 ? 100 : oauthUrl.length)}...');
          
          // Abrir la URL OAuth en el navegador del dispositivo
          final uri = Uri.parse(oauthUrl);
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            throw Exception('No se pudo abrir el navegador para la autenticación');
          }
          
          print('🌐 [AUTH_SERVICE] URL OAuth abierta en el navegador');
          print('📱 [AUTH_SERVICE] Esperando callback desde Supabase...');
          print('📱 [AUTH_SERVICE] Supabase redirigirá a: com.georu.app://login-callback');
        } catch (e) {
          print('❌ [AUTH_SERVICE] Error al obtener/abrir URL OAuth: $e');
          throw Exception('Error al iniciar autenticación con Google: $e');
        }
      }

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
