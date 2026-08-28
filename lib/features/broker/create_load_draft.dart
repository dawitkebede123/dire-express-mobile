import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/system_price.dart';

class CreateLoadDraft {
  const CreateLoadDraft({
    required this.step,
    this.customerId,
    required this.equipment,
    required this.weight,
    required this.rate,
    required this.pickup,
    required this.delivery,
    required this.cargo,
    required this.notes,
    this.pickupDate,
    this.deliveryDate,
    this.pickupPlace,
    this.deliveryPlace,
    this.distanceKm,
    this.systemPrice,
    this.paymentReceiptUrl,
  });

  final int step;
  final String? customerId;
  final String equipment;
  final String weight;
  final String rate;
  final String pickup;
  final String delivery;
  final String cargo;
  final String notes;
  final DateTime? pickupDate;
  final DateTime? deliveryDate;
  final PlaceSuggestion? pickupPlace;
  final PlaceSuggestion? deliveryPlace;
  final double? distanceKm;
  final double? systemPrice;
  final String? paymentReceiptUrl;
}

final createLoadDraftProvider = StateProvider.family<CreateLoadDraft?, bool>((ref, asCustomer) => null);

void saveCreateLoadDraft(WidgetRef ref, bool asCustomer, CreateLoadDraft draft) {
  ref.read(createLoadDraftProvider(asCustomer).notifier).state = draft;
}

void clearCreateLoadDraft(WidgetRef ref, bool asCustomer) {
  ref.read(createLoadDraftProvider(asCustomer).notifier).state = null;
}

CreateLoadDraft? readCreateLoadDraft(WidgetRef ref, bool asCustomer) {
  return ref.read(createLoadDraftProvider(asCustomer));
}
