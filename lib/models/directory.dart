import 'user.dart';

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.user,
    this.plateNo,
    this.vehicleType,
    this.isAvailable = true,
    this.loadCount = 0,
  });

  final String id;
  final NamedPerson user;
  final String? plateNo;
  final String? vehicleType;
  final bool isAvailable;
  final int loadCount;

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;
    return DriverProfile(
      id: json['id'] as String,
      user: NamedPerson.fromJson(json['user'] as Map<String, dynamic>?),
      plateNo: json['plateNo'] as String?,
      vehicleType: json['vehicleType'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      loadCount: count?['loads'] as int? ?? 0,
    );
  }
}

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.user,
    this.company,
    this.address,
    this.loadCount = 0,
  });

  final String id;
  final NamedPerson user;
  final String? company;
  final String? address;
  final int loadCount;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;
    return CustomerProfile(
      id: json['id'] as String,
      user: NamedPerson.fromJson(json['user'] as Map<String, dynamic>?),
      company: json['company'] as String?,
      address: json['address'] as String?,
      loadCount: count?['loads'] as int? ?? 0,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.loadId,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final String? loadId;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      loadId: json['loadId'] as String?,
    );
  }
}
