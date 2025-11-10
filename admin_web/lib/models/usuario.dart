class Usuario {
  final int id;
  final String email;
  final String role; // 'super_admin', 'company_admin', 'driver', 'user'
  final String name;
  final String? notificationTokens;
  final int? companyId;

  Usuario({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.notificationTokens,
    this.companyId,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      name: json['name'] ?? '',
      notificationTokens: json['notification_tokens'],
      companyId: json['company_id'],
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
    };
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get isCompanyAdmin => role == 'company_admin';
  bool get isAdmin => isSuperAdmin || isCompanyAdmin;
}

