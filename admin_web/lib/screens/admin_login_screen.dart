import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../services/admin_api_service.dart';
import '../widgets/georu_logo.dart';
import 'dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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
      // Cargar usuarios directamente desde el servicio sin usar el provider
      // ya que el provider puede requerir autenticación
      final apiService = AdminApiService();
      final usuarios = await apiService.getUsuariosPublic();
      final emails = usuarios
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
      // Si falla cargar usuarios (por ejemplo, si requiere autenticación),
      // simplemente no mostrar autocompletado
      setState(() {
        _userEmails = [];
        _isLoadingUsers = false;
      });
      // No mostrar error al usuario, solo no hay autocompletado
      print('⚠️ [ADMIN_LOGIN] No se pudieron cargar usuarios para autocompletado: $e');
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
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);

      final success = await adminProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adminProvider.error ?? 'Error al iniciar sesión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Eliminado: No se deben tener credenciales hardcodeadas en el código
  // Las credenciales deben venir únicamente de la base de datos

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo GeoRu y título
                      const Center(
                        child: Column(
                          children: [
                            // Logo completo con ícono y texto
                            GeoRuLogo(
                              size: 100,
                              showText: true,
                              showSlogan: false,
                              showBackground: true,
                              backgroundColor: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Panel Administrativo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

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
                              labelText: 'Email',
                              hintText: _isLoadingUsers
                                  ? 'Cargando usuarios...'
                                  : 'Ingresa tu email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.deepPurple,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu email';
                              }
                              if (!value.contains('@')) {
                                return 'Por favor ingresa un email válido';
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
                          labelText: 'Contraseña',
                          hintText: '••••••••',
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
                            borderSide: const BorderSide(
                              color: Colors.deepPurple,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Botón de login
                      Consumer<AdminProvider>(
                        builder: (context, adminProvider, child) {
                          return ElevatedButton(
                            onPressed:
                                adminProvider.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            child: adminProvider.isLoading
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
                                : const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
