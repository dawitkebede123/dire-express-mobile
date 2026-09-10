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

class LoadDocument {
  const LoadDocument({
    required this.url,
    required this.fileName,
    this.id,
    this.createdAt,
  });

  final String? id;
  final String url;
  final String fileName;
  final DateTime? createdAt;

  factory LoadDocument.fromJson(Map<String, dynamic> json) {
    final url = (json['url'] as String?)?.trim() ?? '';
    final fileName = (json['fileName'] as String?)?.trim() ??
        (json['filename'] as String?)?.trim() ??
        (json['name'] as String?)?.trim() ??
        'document';
    return LoadDocument(
      id: json['id']?.toString(),
      url: url,
      fileName: fileName.isEmpty ? 'document' : fileName,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'fileName': fileName,
        if (id != null) 'id': id,
      };
}

List<LoadDocument> parseLoadDocuments(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) {
        if (e is Map<String, dynamic>) return LoadDocument.fromJson(e);
        if (e is Map) return LoadDocument.fromJson(Map<String, dynamic>.from(e));
        return null;
      })
      .whereType<LoadDocument>()
      .where((d) => d.url.isNotEmpty)
      .toList();
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
    this.paymentReceiptUrl,
    this.customer,
    this.customerCompany,
    this.driver,
    this.driverVehicle,
    this.driverLoadingCapacity,
    this.driverTruckImageUrl,
    this.driverIsAvailable,
    this.proofOfDelivery,
    this.latestLocation,
    this.documents = const [],
    this.deletionRequestedAt,
    this.deletedAt,
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
  final String? paymentReceiptUrl;
  final NamedPerson? customer;
  final String? customerCompany;
  final NamedPerson? driver;
  final String? driverVehicle;
  final double? driverLoadingCapacity;
  final String? driverTruckImageUrl;
  final bool? driverIsAvailable;
  final ProofOfDelivery? proofOfDelivery;
  final GeoPoint? latestLocation;
  final List<LoadDocument> documents;
  final DateTime? deletionRequestedAt;
  final DateTime? deletedAt;

  bool get isDeletionPending => deletionRequestedAt != null && deletedAt == null;

  bool get isReceiptPending =>
      status == 'PENDING' && (paymentReceiptUrl?.isNotEmpty ?? false);

  bool get canEditLoad =>
      !isDeletionPending &&
      !isReceiptPending &&
      const {'PENDING', 'CREATED', 'REJECTED', 'ASSIGNED'}.contains(status);

  bool get canAssignDriver => canEditLoad;

  bool get canRequestDeletion =>
      deletedAt == null && !isDeletionPending && status != 'DELIVERED';

  bool get canCancelDeletion => isDeletionPending;

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
      paymentReceiptUrl: json['paymentReceiptUrl'] as String?,
      customer: customerJson?['user'] != null
          ? NamedPerson.fromJson(customerJson!['user'] as Map<String, dynamic>)
          : null,
      customerCompany: customerJson?['company'] as String?,
      driver: driverJson?['user'] != null
          ? NamedPerson.fromJson(driverJson!['user'] as Map<String, dynamic>)
          : null,
      driverVehicle: driverJson?['vehicleType'] as String?,
      driverLoadingCapacity: parseNumber(driverJson?['loadingCapacity']),
      driverTruckImageUrl: driverJson?['truckImageUrl'] as String?,
      driverIsAvailable: driverJson?['isAvailable'] as bool?,
      proofOfDelivery: _podFromJson(json['proofOfDelivery'] ?? json['pod']),
      latestLocation: latest,
      documents: parseLoadDocuments(json['documents']),
      deletionRequestedAt: json['deletionRequestedAt'] != null
          ? DateTime.tryParse(json['deletionRequestedAt'].toString())
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toCacheJson() => {
        'id': id,
        'referenceNo': referenceNo,
        'status': status,
        'pickupAddress': pickupAddress,
        'deliveryAddress': deliveryAddress,
        'pickupDate': pickupDate.toIso8601String(),
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'deliveryLat': deliveryLat,
        'deliveryLng': deliveryLng,
        if (deliveryDate != null) 'deliveryDate': deliveryDate!.toIso8601String(),
        if (customer != null)
          'customer': {
            if (customerCompany != null) 'company': customerCompany,
            'user': {
              'name': customer!.name,
              'email': customer!.email,
              'phone': customer!.phone,
              'imageUrl': customer!.imageUrl,
            },
          },
        if (driver != null)
          'driver': {
            if (driverVehicle != null) 'vehicleType': driverVehicle,
            if (driverLoadingCapacity != null) 'loadingCapacity': driverLoadingCapacity,
            if (driverTruckImageUrl != null) 'truckImageUrl': driverTruckImageUrl,
            if (driverIsAvailable != null) 'isAvailable': driverIsAvailable,
            'user': {
              'name': driver!.name,
              'email': driver!.email,
              'phone': driver!.phone,
              'imageUrl': driver!.imageUrl,
            },
          },
        if (latestLocation != null)
          'locations': [
            {
              'lat': latestLocation!.lat,
              'lng': latestLocation!.lng,
              if (latestLocation!.recordedAt != null)
                'recordedAt': latestLocation!.recordedAt!.toIso8601String(),
            },
          ],
        if (documents.isNotEmpty)
          'documents': documents.map((d) => d.toJson()).toList(),
      };
}
