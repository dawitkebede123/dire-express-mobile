class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.company,
    this.plateNo,
    this.vehicleType,
    this.loadingCapacity,
    this.truckImageUrl,
    this.agentId,
    this.imageUrl,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? company;
  final String? plateNo;
  final String? vehicleType;
  final double? loadingCapacity;
  final String? truckImageUrl;
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
    final driver = json['driver'] is Map
        ? Map<String, dynamic>.from(json['driver'] as Map)
        : const <String, dynamic>{};
    String? pick(Map<String, dynamic> map, String key) {
      final value = map[key]?.toString().trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    double? pickNumber(Map<String, dynamic> map, String key) {
      final value = map[key];
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return AppUser(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: (json['role'] as String? ?? '').trim().toUpperCase(),
      phone: json['phone'] as String?,
      company: json['company'] as String?,
      plateNo: pick(json, 'plateNo') ?? pick(json, 'plateNumber') ?? pick(driver, 'plateNo') ?? pick(driver, 'plateNumber'),
      vehicleType: pick(json, 'vehicleType') ?? pick(driver, 'vehicleType'),
      loadingCapacity: pickNumber(json, 'loadingCapacity') ?? pickNumber(driver, 'loadingCapacity'),
      truckImageUrl: pick(json, 'truckImageUrl') ?? pick(driver, 'truckImageUrl'),
      agentId: json['agentId'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  AppUser applyProfile({
    required String name,
    String? phone,
    String? company,
    String? plateNo,
    String? vehicleType,
    double? loadingCapacity,
    String? truckImageUrl,
  }) {
    return AppUser(
      id: id,
      email: email,
      name: name,
      role: role,
      phone: phone,
      company: company ?? this.company,
      plateNo: plateNo ?? this.plateNo,
      vehicleType: vehicleType ?? this.vehicleType,
      loadingCapacity: loadingCapacity ?? this.loadingCapacity,
      truckImageUrl: truckImageUrl ?? this.truckImageUrl,
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
      company: company,
      plateNo: plateNo,
      vehicleType: vehicleType,
      loadingCapacity: loadingCapacity,
      truckImageUrl: truckImageUrl,
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
