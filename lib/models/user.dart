class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.agentId,
    this.imageUrl,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? agentId;
  final String? imageUrl;

  bool get isBroker => role == 'BROKER';
  bool get isDriver => role == 'DRIVER';
  bool get isCustomer => role == 'CUSTOMER';

  String get homePath {
    switch (role) {
      case 'BROKER':
        return '/broker';
      case 'DRIVER':
        return '/driver';
      case 'CUSTOMER':
        return '/customer';
      default:
        return '/login';
    }
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      phone: json['phone'] as String?,
      agentId: json['agentId'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  AppUser applyProfile({required String name, String? phone}) {
    return AppUser(
      id: id,
      email: email,
      name: name,
      role: role,
      phone: phone,
      agentId: agentId,
      imageUrl: imageUrl,
    );
  }

  AppUser applyImageUrl(String? imageUrl) {
    return AppUser(
      id: id,
      email: email,
      name: name,
      role: role,
      phone: phone,
      agentId: agentId,
      imageUrl: imageUrl,
    );
  }
}

class NamedPerson {
  const NamedPerson({required this.name, this.email, this.phone, this.imageUrl});

  final String name;
  final String? email;
  final String? phone;
  final String? imageUrl;

  factory NamedPerson.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const NamedPerson(name: '');
    }
    return NamedPerson(
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
