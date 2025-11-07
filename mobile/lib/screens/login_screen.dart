import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/georu_logo.dart';
import '../models/usuario.dart';
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
  final _autocompleteKey = GlobalKey<FormFieldState<String>>();
  bool _obscurePassword = true;
  List<Usuario> _conductores = [];
  String? _selectedEmail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConductores();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadConductores() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.loadUsuarios();
    if (mounted) {
      setState(() {
        _conductores = appProvider.conductores;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Extraer email si viene en formato "Nombre (email)"
      String email = _emailController.text.trim();
      if (email.contains('(') && email.contains(')')) {
        email = email.split('(').last.split(')').first.trim();
      }
      
      // Si hay un email seleccionado, usarlo
      if (_selectedEmail != null) {
        email = _selectedEmail!;
      }

      final success = await appProvider.login(
        email,
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
            content: Text(appProvider.error ?? 'Error al iniciar sesión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      const Text(
                        'Inicia sesión para continuar',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Campo de email con autocompletado para conductores
                Autocomplete<Usuario>(
                  key: _autocompleteKey,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _conductores;
                    }
                    final query = textEditingValue.text.toLowerCase();
                    return _conductores.where((conductor) {
                      final email = conductor.email.toLowerCase();
                      final name = conductor.name.toLowerCase();
                      return email.contains(query) || name.contains(query);
                    }).toList();
                  },
                  displayStringForOption: (Usuario conductor) => 
                      '${conductor.name} (${conductor.email})',
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    // Sincronizar con el controlador principal
                    if (_emailController.text != textEditingController.text) {
                      _emailController.text = textEditingController.text;
                    }
                    textEditingController.addListener(() {
                      _emailController.text = textEditingController.text;
                    });
                    
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email o Nombre del Conductor',
                        hintText: 'Busca por nombre o email',
                        prefixIcon: const Icon(Icons.person_outline),
                        suffixIcon: _conductores.isNotEmpty
                            ? const Icon(Icons.arrow_drop_down)
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu email';
                        }
                        // Extraer email si viene en formato "Nombre (email)"
                        final email = value.contains('(') && value.contains(')')
                            ? value.split('(').last.split(')').first.trim()
                            : value.trim();
                        if (!email.contains('@')) {
                          return 'Por favor ingresa un email válido';
                        }
                        return null;
                      },
                    );
                  },
                  onSelected: (Usuario conductor) {
                    setState(() {
                      _selectedEmail = conductor.email;
                      _emailController.text = conductor.email;
                    });
                  },
                  optionsViewBuilder: (
                    BuildContext context,
                    AutocompleteOnSelected<Usuario> onSelected,
                    Iterable<Usuario> options,
                  ) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final conductor = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(conductor),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: Color(0xFF2E7D32),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              conductor.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              conductor.email,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
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
                    hintText: 'Ingresa tu contraseña',
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
                      borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Botón de login
                Consumer<AppProvider>(
                  builder: (context, appProvider, child) {
                    return ElevatedButton(
                      onPressed: appProvider.isLoading ? null : _handleLogin,
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

                const SizedBox(height: 16),

                // Enlace de registro
                TextButton(
                  onPressed: () {
                    // TODO: Implementar pantalla de registro
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad de registro próximamente'),
                      ),
                    );
                  },
                  child: const Text(
                    '¿No tienes cuenta? Regístrate aquí',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Credenciales de prueba con botón de autocompletado
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Credenciales de prueba:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _emailController.text =
                                    'usuario@transporterural.com';
                                _passwordController.text = 'usuario123';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Credenciales cargadas ✓'),
                                  duration: Duration(seconds: 1),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            icon: const Icon(Icons.flash_on, size: 16),
                            label: const Text('Autocompletar'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Email: usuario@transporterural.com'),
                      const Text('Contraseña: usuario123'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
