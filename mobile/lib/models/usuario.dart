class Usuario {
  final int id;
  final String email;
  final String role; // 'super_admin', 'company_admin', 'driver', 'user'
  final String name;
  final String? notificationTokens;
  final int? companyId;
  final bool? active;
  final String? driverStatus; // Estados: 'disponible', 'en_ruta', 'fuera_de_servicio', 'en_descanso'

  Usuario({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.notificationTokens,
    this.companyId,
    this.active,
    this.driverStatus,
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
