class Empresa {
  final int id;
  final String name;
  final String email; // Ahora es obligatorio
  final String? password; // Solo para creación/actualización, no se retorna en fromJson
  final String? phone;
  final String? address;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Empresa({
    required this.id,
    required this.name,
    required this.email,
    this.password,
    this.phone,
    this.address,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      // password no se incluye en fromJson por seguridad
      phone: json['phone'],
      address: json['address'],
      active: json['active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false, bool includePassword = false}) {
    final json = <String, dynamic>{
      'name': name,
      'email': email,
      'active': active,
    };
    
    if (includeId && id > 0) {
      json['id'] = id;
    }
    
    // Solo incluir password si se está creando/actualizando
    if (includePassword && password != null && password!.isNotEmpty) {
      json['password'] = password;
    }
    
    if (phone != null) json['phone'] = phone;
    if (address != null) json['address'] = address;
    
    // Solo incluir fechas si se están actualizando
    if (includeId) {
      if (createdAt != null) json['created_at'] = createdAt?.toIso8601String();
      if (updatedAt != null) json['updated_at'] = updatedAt?.toIso8601String();
    }
    
    return json;
  }

  Empresa copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? address,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Empresa(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

