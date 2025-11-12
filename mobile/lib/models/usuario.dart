class Usuario {
  final int id;
  final String email;
  final String role; // 'super_admin', 'company_admin', 'driver', 'user'
  final String name;
  final String? notificationTokens;
  final int? companyId;
  final bool? active;
  final String? driverStatus; // Estados: 'disponible', 'en_ruta', 'fuera_de_servicio', 'en_descanso'
  final String? region; // Región de Chile
  final String? authProvider; // 'local' o 'supabase'
  final String? supabaseAuthId; // UUID de Supabase Auth

  Usuario({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.notificationTokens,
    this.companyId,
    this.active,
    this.driverStatus,
    this.region,
    this.authProvider,
    this.supabaseAuthId,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      name: json['name'] ?? '',
      notificationTokens: json['notification_tokens'],
      companyId: json['company_id'],
      active: json['active'] ?? true,
      driverStatus: json['driver_status'],
      region: json['region'],
      authProvider: json['auth_provider'],
      supabaseAuthId: json['supabase_auth_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'notification_tokens': notificationTokens,
      'company_id': companyId,
      'active': active,
      'driver_status': driverStatus,
      'region': region,
      'auth_provider': authProvider,
      'supabase_auth_id': supabaseAuthId,
    };
  }

  Usuario copyWith({
    int? id,
    String? email,
    String? role,
    String? name,
    String? notificationTokens,
    int? companyId,
    bool? active,
    String? driverStatus,
    String? region,
    String? authProvider,
    String? supabaseAuthId,
  }) {
    return Usuario(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      notificationTokens: notificationTokens ?? this.notificationTokens,
      companyId: companyId ?? this.companyId,
      active: active ?? this.active,
      driverStatus: driverStatus ?? this.driverStatus,
      region: region ?? this.region,
      authProvider: authProvider ?? this.authProvider,
      supabaseAuthId: supabaseAuthId ?? this.supabaseAuthId,
    );
  }
  
  bool get isActive => active ?? true;
  
  String get statusLabel {
    if (role != 'driver') return 'Usuario';
    switch (driverStatus) {
      case 'en_ruta':
        return 'En Ruta';
      case 'disponible':
        return 'Disponible';
      case 'fuera_de_servicio':
        return 'Fuera de Servicio';
      case 'en_descanso':
        return 'En Descanso';
      default:
        return 'Disponible';
    }
  }
}
