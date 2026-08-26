import 'user.dart';

double? parseNumber(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

ProofOfDelivery? _podFromJson(dynamic value) {
  if (value is Map<String, dynamic>) return ProofOfDelivery.fromJson(value);
  if (value is Map) return ProofOfDelivery.fromJson(Map<String, dynamic>.from(value));
  return null;
}

class GeoPoint {
  const GeoPoint({required this.lat, required this.lng, this.recordedAt});

  final double lat;
  final double lng;
  final DateTime? recordedAt;

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'].toString())
          : null,
    );
  }
}

class ProofOfDelivery {
  const ProofOfDelivery({
    required this.photoUrl,
    required this.signatureUrl,
    this.recipientName,
    this.notes,
    this.deliveredAt,
  });

  final String photoUrl;
  final String signatureUrl;
  final String? recipientName;
  final String? notes;
  final DateTime? deliveredAt;

  factory ProofOfDelivery.fromJson(Map<String, dynamic> json) {
    return ProofOfDelivery(
      photoUrl: json['photoUrl'] as String? ?? '',
      signatureUrl: json['signatureUrl'] as String? ?? '',
      recipientName: json['recipientName'] as String?,
      notes: json['notes'] as String?,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'].toString())
          : null,
    );
  }
}

class FreightLoad {
  const FreightLoad({
    required this.id,
    required this.referenceNo,
    required this.status,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.pickupDate,
    this.pickupLat,
    this.pickupLng,
    this.deliveryLat,
    this.deliveryLng,
    this.deliveryDate,
    this.cargoDescription,
    this.equipmentType,
    this.weightLbs,
    this.rate,
    this.systemPrice,
    this.distanceKm,
    this.notes,
    this.createdAt,
    this.customer,
    this.customerCompany,
    this.driver,
    this.driverVehicle,
    this.proofOfDelivery,
    this.latestLocation,
  });

  final String id;
  final String referenceNo;
  final String status;
  final String pickupAddress;
  final String deliveryAddress;
  final DateTime pickupDate;
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final DateTime? deliveryDate;
  final String? cargoDescription;
  final String? equipmentType;
  final double? weightLbs;
  final double? rate;
  final double? systemPrice;
  final double? distanceKm;
  final String? notes;
  final DateTime? createdAt;
  final NamedPerson? customer;
  final String? customerCompany;
  final NamedPerson? driver;
  final String? driverVehicle;
  final ProofOfDelivery? proofOfDelivery;
  final GeoPoint? latestLocation;

  bool get isActive => const {
        'PENDING',
        'CREATED',
        'ASSIGNED',
        'ACCEPTED',
        'IN_TRANSIT',
      }.contains(status);

  factory FreightLoad.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'] as Map<String, dynamic>?;
    final driverJson = json['driver'] as Map<String, dynamic>?;
    final locations = json['locations'] as List<dynamic>?;
    GeoPoint? latest;
    if (locations != null && locations.isNotEmpty) {
      latest = GeoPoint.fromJson(locations.first as Map<String, dynamic>);
    }

    return FreightLoad(
      id: json['id'] as String,
      referenceNo: json['referenceNo'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      pickupAddress: json['pickupAddress'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      pickupDate: DateTime.tryParse(json['pickupDate']?.toString() ?? '') ??
          DateTime.now(),
      pickupLat: parseNumber(json['pickupLat']),
      pickupLng: parseNumber(json['pickupLng']),
      deliveryLat: parseNumber(json['deliveryLat']),
      deliveryLng: parseNumber(json['deliveryLng']),
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.tryParse(json['deliveryDate'].toString())
          : null,
      cargoDescription: json['cargoDescription'] as String?,
      equipmentType: json['equipmentType'] as String?,
      weightLbs: parseNumber(json['weightLbs']),
      rate: parseNumber(json['rate']),
      systemPrice: parseNumber(json['systemPrice']),
      distanceKm: parseNumber(json['distanceKm']),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      customer: customerJson?['user'] != null
          ? NamedPerson.fromJson(customerJson!['user'] as Map<String, dynamic>)
          : null,
      customerCompany: customerJson?['company'] as String?,
      driver: driverJson?['user'] != null
          ? NamedPerson.fromJson(driverJson!['user'] as Map<String, dynamic>)
          : null,
      driverVehicle: driverJson?['vehicleType'] as String?,
      proofOfDelivery: _podFromJson(json['proofOfDelivery'] ?? json['pod']),
      latestLocation: latest,
    );
  }
}
