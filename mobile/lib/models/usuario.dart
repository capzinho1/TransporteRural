class Usuario {
  final int id;
  final String email;
  final String role;
  final String name;
  final String? notificationTokens;

  Usuario({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.notificationTokens,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      name: json['name'] ?? '',
      notificationTokens: json['notification_tokens'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'notification_tokens': notificationTokens,
    };
  }

  Usuario copyWith({
    int? id,
    String? email,
    String? role,
    String? name,
    String? notificationTokens,
  }) {
    return Usuario(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      notificationTokens: notificationTokens ?? this.notificationTokens,
    );
  }
}
