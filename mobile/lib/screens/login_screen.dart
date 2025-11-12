import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/georu_logo.dart';
import '../utils/app_localizations.dart';
import 'home_screen.dart';
import 'driver_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  List<String> _userEmails = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    // Retrasar la carga hasta después del build para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserEmails();
    });
  }

  Future<void> _loadUserEmails() async {
    try {
      setState(() {
        _isLoadingUsers = true;
      });
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.loadUsuarios();
      final emails = appProvider.usuarios
          .map((u) => u.email)
          .where((email) => email.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      setState(() {
        _userEmails = emails;
        _isLoadingUsers = false;
      });
    } catch (e) {
      // Si falla cargar usuarios, simplemente no mostrar autocompletado
      setState(() {
        _userEmails = [];
        _isLoadingUsers = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      final success = await appProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        // Redirigir según el rol del usuario
        final userRole = appProvider.currentUser?.role ?? 'user';
        Widget destination;

        if (userRole == 'driver') {
          destination = const DriverScreen();
        } else {
          destination = const HomeScreen();
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => destination),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appProvider.error ??
                (AppLocalizations.of(context)?.translate('login_error') ??
                    'Error al iniciar sesión')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios de idioma para reconstruir cuando cambia
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // Forzar tema claro en el login, independientemente del tema global
        final lightTheme = ThemeData(
          primarySwatch: Colors.green,
          primaryColor: const Color(0xFF2E7D32),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[100],
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
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32)),
            ),
          ),
        );

        return Theme(
          data: lightTheme,
          child: Scaffold(
            backgroundColor: Colors.grey[100],
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // Logo GeoRu y título
                      Center(
                        child: Column(
                          children: [
                            // Logo completo con ícono y texto
                            const GeoRuLogo(
                              size: 120,
                              showText: true,
                              showSlogan: false,
                              showBackground: true,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)
                                      ?.translate('login_to_continue') ??
                                  'Inicia sesión para continuar',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Campo de email con autocompletado
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          // Actualizar el controlador cuando cambie el texto
                          _emailController.text = textEditingValue.text;
                          if (textEditingValue.text.isEmpty) {
                            return _userEmails.take(10);
                          }
                          return _userEmails
                              .where((email) => email.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase()))
                              .take(10);
                        },
                        onSelected: (String email) {
                          _emailController.text = email;
                        },
                        fieldViewBuilder: (BuildContext context,
                            TextEditingController textEditingController,
                            FocusNode focusNode,
                            VoidCallback onFieldSubmitted) {
                          // Inicializar con el valor del controlador si existe
                          if (_emailController.text.isNotEmpty &&
                              textEditingController.text.isEmpty) {
                            textEditingController.text = _emailController.text;
                          }

                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) {
                              _emailController.text = value;
                            },
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                      ?.translate('email') ??
                                  'Email',
                              hintText: _isLoadingUsers
                                  ? (AppLocalizations.of(context)
                                          ?.translate('loading_users') ??
                                      'Cargando usuarios...')
                                  : (AppLocalizations.of(context)
                                          ?.translate('enter_email') ??
                                      'Ingresa tu email'),
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFF2E7D32)),
                              ),
                            ),
                            validator: (value) {
                              final localizations =
                                  AppLocalizations.of(context);
                              if (value == null || value.isEmpty) {
                                return localizations
                                        ?.translate('please_enter_email') ??
                                    'Por favor ingresa tu email';
                              }
                              if (!value.contains('@')) {
                                return localizations?.translate(
                                        'please_enter_valid_email') ??
                                    'Por favor ingresa un email válido';
                              }
                              return null;
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Campo de contraseña
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                                  ?.translate('password') ??
                              'Contraseña',
                          hintText: AppLocalizations.of(context)
                                  ?.translate('enter_password') ??
                              'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF2E7D32)),
                          ),
                        ),
                        validator: (value) {
                          final localizations = AppLocalizations.of(context);
                          if (value == null || value.isEmpty) {
                            return localizations
                                    ?.translate('please_enter_password') ??
                                'Por favor ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return localizations
                                    ?.translate('password_min_length') ??
                                'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Botón de login
                      Consumer<AppProvider>(
                        builder: (context, appProvider, child) {
                          return ElevatedButton(
                            onPressed:
                                appProvider.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: appProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context)
                                            ?.translate('login') ??
                                        'Iniciar Sesión',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Enlace de registro
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)
                                      ?.translate('registration_coming_soon') ??
                                  'Funcionalidad de registro próximamente'),
                            ),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)
                                  ?.translate('no_account_register') ??
                              '¿No tienes cuenta? Regístrate aquí',
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // SEGURIDAD: No mostrar credenciales en el código
                      // Los usuarios deben ingresar sus credenciales manualmente
                      // Las contraseñas NO se pre-llenan por seguridad
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
