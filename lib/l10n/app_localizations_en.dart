// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get brandName => 'Dire Express';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEn => 'English';

  @override
  String get languageAm => 'አማርኛ';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navLoads => 'Loads';

  @override
  String get navDrivers => 'Drivers';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navProfile => 'Profile';

  @override
  String get navActive => 'Active';

  @override
  String get navHistory => 'History';

  @override
  String get navRequest => 'Request';

  @override
  String get navTrack => 'Track';

  @override
  String get headerGoBack => 'Go back';

  @override
  String get headerNotifications => 'Notifications';

  @override
  String get headerProfile => 'Profile';

  @override
  String callName(String name) {
    return 'Call $name';
  }

  @override
  String get roleBroker => 'Broker';

  @override
  String get roleDriver => 'Driver';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonBack => 'Back';

  @override
  String get commonDetails => 'Details';

  @override
  String get commonEmpty => '—';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonMarkAllRead => 'Mark all read';

  @override
  String get commonNoNotifications => 'No notifications yet.';

  @override
  String get landingBadge => 'Digital freight brokerage';

  @override
  String get landingTitle => 'Every load, every driver, one live view.';

  @override
  String get landingCopy =>
      'Dire Express connects brokers, drivers, and shippers on a single mobile-first platform — from booking a load to signing for it at the dock.';

  @override
  String get landingCta => 'Start moving freight';

  @override
  String get landingSignIn => 'Sign in';

  @override
  String get landingGetStarted => 'Get started';

  @override
  String get landingHowHeading => 'How it works';

  @override
  String get landingBookTitle => 'Book';

  @override
  String get landingBookCopy =>
      'A customer requests transport, or a broker creates the load directly.';

  @override
  String get landingDispatchTitle => 'Dispatch';

  @override
  String get landingDispatchCopy =>
      'The broker assigns a driver, who accepts and starts the trip from their phone.';

  @override
  String get landingDeliverTitle => 'Deliver';

  @override
  String get landingDeliverCopy =>
      'GPS streams the whole way, and the driver captures photo and signature at the dock.';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to manage your loads.';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginEmailPlaceholder => 'you@gmail.com';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginSubmitting => 'Signing in...';

  @override
  String get loginNoAccount => 'No account?';

  @override
  String get loginCreateOne => 'Create one';

  @override
  String get loginDemo => 'Demo accounts — password: password123';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle =>
      'Pick the role that matches how you move freight.';

  @override
  String get registerIAmA => 'I am a';

  @override
  String get registerFullName => 'Full name';

  @override
  String get registerEmail => 'Email';

  @override
  String get registerPassword => 'Password';

  @override
  String get registerPhone => 'Phone';

  @override
  String get registerCompany => 'Company';

  @override
  String get registerPlateNo => 'Plate number';

  @override
  String get registerVehicleType => 'Vehicle type';

  @override
  String get registerNamePlaceholder => 'Jane Doe';

  @override
  String get registerEmailPlaceholder => 'you@gmail.com';

  @override
  String get registerPasswordPlaceholder => 'At least 8 characters';

  @override
  String get registerPhonePlaceholder => '0912345678';

  @override
  String get registerCompanyPlaceholder => '';

  @override
  String get registerPlatePlaceholder => 'AA-1234';

  @override
  String get registerVehiclePlaceholder => 'Semi-Truck • Volvo VNL';

  @override
  String get registerSubmit => 'Create account';

  @override
  String get registerSubmitting => 'Creating account...';

  @override
  String get registerAlready => 'Already registered?';

  @override
  String get registerSignIn => 'Sign in';

  @override
  String get registerAgentId => 'Agent ID';

  @override
  String get registerAgentIdPlaceholder => 'Paste the broker\'s Agent ID';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileName => 'Name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileRole => 'Role';

  @override
  String get profileAgentId => 'Agent ID';

  @override
  String get profileAgentIdCopied => 'Agent ID copied';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileTakePhoto => 'Take photo';

  @override
  String get profileChoosePhoto => 'Choose from library';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusCreated => 'Created';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusInTransit => 'In Transit';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get equipmentDryVan => 'Dry Van';

  @override
  String get equipmentReefer => 'Reefer';

  @override
  String get equipmentFlatbed => 'Flatbed';

  @override
  String get equipmentFreight => 'Freight';

  @override
  String get loadRateTbd => 'Rate TBD';

  @override
  String get loadScheduled => 'Scheduled';

  @override
  String get loadDeliveryScheduled => 'Delivery scheduled';

  @override
  String get loadPickup => 'Pickup';

  @override
  String get loadDropoff => 'Dropoff';

  @override
  String get trackBooked => 'Booked';

  @override
  String get trackRequestReceived => 'Request received';

  @override
  String get trackPickedUp => 'Picked Up';

  @override
  String trackScheduled(String datetime) {
    return 'Scheduled $datetime';
  }

  @override
  String get trackInTransit => 'In Transit';

  @override
  String get trackLiveActive => 'Live tracking active';

  @override
  String get trackCompleted => 'Completed';

  @override
  String get trackPending => 'Pending';

  @override
  String get trackDelivered => 'Delivered';

  @override
  String formatToday(String time) {
    return 'Today, $time';
  }

  @override
  String formatTomorrow(String time) {
    return 'Tomorrow, $time';
  }

  @override
  String formatYesterday(String time) {
    return 'Yesterday, $time';
  }

  @override
  String weightLbs(String n) {
    return '$n lbs';
  }

  @override
  String get toastInvalidCredentials => 'Invalid email or password';

  @override
  String get toastConnectionFailed =>
      'Could not reach the server. Check your connection and API URL.';

  @override
  String get toastRegistrationFailed => 'Registration failed';

  @override
  String get toastAccountCreated => 'Account created';

  @override
  String get toastEmailRegistered => 'Email already registered';

  @override
  String get toastInvalidPhone =>
      'Enter a valid phone number (e.g. 0912345678, 0712345678, +25377XXXXXX, or +2917XXXXXX)';

  @override
  String get toastAgentIdRequired => 'Agent ID is required';

  @override
  String get toastAgentIdInvalid => 'This Agent ID is not valid';

  @override
  String get toastSelectCustomer => 'Select a customer to continue';

  @override
  String get toastPickupDeliveryRequired =>
      'Pickup, delivery, and pickup date are required';

  @override
  String get toastCreateLoadFailed => 'Failed to create load';

  @override
  String get toastLoadCreated => 'Load created';

  @override
  String get toastReceiptRequired =>
      'Upload a payment receipt to create more loads';

  @override
  String get toastReceiptUploaded => 'Receipt uploaded';

  @override
  String get toastDeviceIdRequired =>
      'Device ID is required. Restart the app and try again.';

  @override
  String get brokerPaymentReceipt => 'Payment receipt';

  @override
  String get brokerPaymentReceiptHint =>
      'You have used your free loads. Upload a payment receipt to continue.';

  @override
  String get brokerUploadReceipt => 'Upload receipt';

  @override
  String get brokerReceiptReady => 'Receipt attached';

  @override
  String get toastAssignFailed => 'Failed to assign driver';

  @override
  String get toastDriverAssigned => 'Driver assigned';

  @override
  String get toastNewLoadUpdate => 'New load update';

  @override
  String get toastActionFailed => 'Action failed';

  @override
  String get toastLoadAccepted => 'Load accepted';

  @override
  String get toastLoadRejected => 'Load rejected';

  @override
  String get toastTripStarted => 'Trip started';

  @override
  String get toastSignBeforeSaving => 'Please sign before saving';

  @override
  String get toastSignatureCaptured => 'Signature captured';

  @override
  String get toastPodFieldsRequired =>
      'Photo, signature, and recipient name are required';

  @override
  String get toastPodSubmitFailed => 'Failed to submit proof of delivery';

  @override
  String get toastPhotoUploaded => 'Photo uploaded';

  @override
  String get toastUploadFailed => 'Upload failed';

  @override
  String get toastRequestFailed => 'Failed to submit request';

  @override
  String get toastRequestSubmitted => 'Transport request submitted';

  @override
  String get toastProfileSaved => 'Profile saved';

  @override
  String get toastProfileSaveFailed => 'Failed to save profile';

  @override
  String get mapMissingToken => 'Add MAPBOX_ACCESS_TOKEN to enable live maps';

  @override
  String get mapRecenter => 'Recenter map';

  @override
  String get mapLiveTracking => 'Live Tracking';

  @override
  String get mapExpand => 'Expand map';

  @override
  String get mapCollapse => 'Collapse map';

  @override
  String get brokerDashboardTitle => 'Broker Dashboard';

  @override
  String get brokerProfileNotFound => 'Broker profile not found.';

  @override
  String get brokerTotalRevenue => 'Total Revenue';

  @override
  String brokerLoadsDelivered(int count) {
    return '$count loads delivered';
  }

  @override
  String get brokerActiveLoads => 'Active Loads';

  @override
  String get brokerPendingDrivers => 'Pending Drivers';

  @override
  String get brokerRecentLoads => 'Recent Loads';

  @override
  String get brokerViewAll => 'View All';

  @override
  String get brokerEmptyLoads =>
      'No loads yet. Create your first load to get started.';

  @override
  String get brokerCreateLoad => 'Create Load';

  @override
  String get brokerLoadsTitle => 'Loads Management';

  @override
  String get brokerLoadsEmpty => 'No loads found.';

  @override
  String get brokerStepDetails => 'Details';

  @override
  String get brokerStepRoute => 'Route';

  @override
  String get brokerStepConfirm => 'Confirm';

  @override
  String get brokerCustomerInfo => 'Customer Info';

  @override
  String get brokerSelectCustomer => 'Select Customer *';

  @override
  String get brokerSelectCustomerPlaceholder => 'Select a customer...';

  @override
  String get brokerLoadDetails => 'Load Details';

  @override
  String get brokerEquipmentType => 'Equipment Type';

  @override
  String get brokerWeightLbs => 'Weight (lbs)';

  @override
  String get brokerRate => 'Rate (ETB)';

  @override
  String get brokerCargo => 'Cargo';

  @override
  String get brokerPickupAddress => 'Pickup address *';

  @override
  String get brokerPickupDate => 'Pickup date *';

  @override
  String get brokerDeliveryAddress => 'Delivery address *';

  @override
  String get brokerDeliveryDate => 'Delivery date';

  @override
  String get brokerCargoDescription => 'Cargo description';

  @override
  String get brokerNotes => 'Notes';

  @override
  String get brokerConfirmLoad => 'Confirm Load';

  @override
  String get brokerConfirmCustomer => 'Customer';

  @override
  String get brokerConfirmEquipment => 'Equipment';

  @override
  String get brokerConfirmWeight => 'Weight';

  @override
  String get brokerConfirmRate => 'Rate';

  @override
  String get brokerConfirmPickup => 'Pickup';

  @override
  String get brokerConfirmDelivery => 'Delivery';

  @override
  String get brokerConfirmPickupDate => 'Pickup date';

  @override
  String get brokerConfirmCargo => 'Cargo';

  @override
  String get brokerContinueToRoute => 'Continue to Route';

  @override
  String get brokerReviewLoad => 'Review Load';

  @override
  String get brokerCreating => 'Creating...';

  @override
  String get brokerPickupPlaceholder => '123 Main St, Chicago, IL';

  @override
  String get brokerDeliveryPlaceholder => '456 Oak Ave, Dallas, TX';

  @override
  String get brokerCargoPlaceholder => '20 pallets of industrial equipment';

  @override
  String get brokerNotesPlaceholder => 'Special handling instructions';

  @override
  String get brokerWeightPlaceholder => '40,000';

  @override
  String get brokerRatePlaceholder => '2,500';

  @override
  String get brokerLoadDetailTitle => 'Load Details';

  @override
  String get brokerAssignDriver => 'Assign Driver';

  @override
  String get brokerNoDrivers => 'No available drivers.';

  @override
  String get brokerNoVehicleInfo => 'No vehicle info';

  @override
  String get brokerShipmentStatus => 'Shipment Status';

  @override
  String get brokerTripDetails => 'Trip Details';

  @override
  String get brokerAssignedDriver => 'Assigned driver';

  @override
  String get brokerProofOfDelivery => 'Proof of Delivery';

  @override
  String get brokerDeliveryPhoto => 'Delivery photo';

  @override
  String get brokerRecipientSignature => 'Recipient signature';

  @override
  String get brokerCustomer => 'Customer';

  @override
  String get brokerDriver => 'Driver';

  @override
  String get brokerDriversTitle => 'Drivers';

  @override
  String get brokerDriversEmpty => 'No drivers registered yet.';

  @override
  String get brokerDriversAvailable => 'Available';

  @override
  String get brokerDriversOnALoad => 'On a load';

  @override
  String get brokerVehicleNotSet => 'Vehicle not set';

  @override
  String brokerLoadsAssigned(int count) {
    return '$count loads assigned';
  }

  @override
  String get brokerCustomersTitle => 'Customers';

  @override
  String get brokerCustomersEmpty => 'No customers yet.';

  @override
  String brokerCustomersLoads(int count) {
    return '$count loads';
  }

  @override
  String get driverAvailableTitle => 'Available Loads';

  @override
  String get driverMyTrips => 'My Trips';

  @override
  String get driverAvailable => 'Available';

  @override
  String driverAvailableCount(int count) {
    return 'Available ($count)';
  }

  @override
  String get driverLoadingLoads => 'Loading loads...';

  @override
  String get driverEmptyAvailable => 'No loads awaiting your response';

  @override
  String get driverEmptyAvailableHint =>
      'New assignments from your broker will appear here.';

  @override
  String get driverEmptyTrips => 'No trips yet';

  @override
  String get driverEmptyTripsHint =>
      'Accepted and completed loads will show up here.';

  @override
  String get driverReject => 'Reject';

  @override
  String get driverAcceptLoad => 'Accept Load';

  @override
  String get driverActiveTitle => 'Active Trip';

  @override
  String get driverNoTrip => 'No active trip';

  @override
  String get driverNoTripHint =>
      'Start an accepted load to begin live tracking.';

  @override
  String get driverViewLoads => 'View loads';

  @override
  String get driverCustomer => 'Customer';

  @override
  String get driverPickedUp => 'Picked up';

  @override
  String get driverCompleteDelivery => 'Complete Delivery';

  @override
  String get driverHistoryTitle => 'Trip History';

  @override
  String get driverTotalEarned => 'Total Earned';

  @override
  String get driverHistoryEmpty => 'No completed trips yet.';

  @override
  String get driverPodTitle => 'Load';

  @override
  String get driverPodSuccessTitle => 'POD Submitted Successfully';

  @override
  String driverPodSuccessCopy(String ref) {
    return 'Load $ref has been finalized and sent to billing.';
  }

  @override
  String get driverReturnDashboard => 'Return to Dashboard';

  @override
  String get driverDestination => 'Destination';

  @override
  String get driverConsignee => 'Consignee';

  @override
  String get driverStartTrip => 'Start Trip';

  @override
  String get driverGpsActive => 'GPS tracking active';

  @override
  String get driverGpsHint =>
      'Your location is shared with the broker and customer.';

  @override
  String get driverUploading => 'Uploading...';

  @override
  String get driverReplacePod => 'Tap to replace BOL/POD';

  @override
  String get driverCapturePod => 'Tap to capture BOL/POD';

  @override
  String get driverPodHint =>
      'Ensure all edges of the document are visible and text is legible.';

  @override
  String get driverReceiverSignature => 'Receiver Signature';

  @override
  String get driverSignHere => 'Sign here';

  @override
  String get driverClearSignature => 'Clear Signature';

  @override
  String get driverRecipientName => 'Recipient name';

  @override
  String get driverRecipientPlaceholder => 'Who received the freight?';

  @override
  String get driverDeliveryNotes => 'Delivery Notes (Optional)';

  @override
  String get driverNotesPlaceholder => 'Left at dock door 3 per instructions.';

  @override
  String get driverProcessing => 'Processing...';

  @override
  String get driverSubmitPod => 'Submit Proof of Delivery';

  @override
  String get driverGpsUnavailable =>
      'Location services are not available on this device.';

  @override
  String get driverGpsDenied =>
      'Location permission denied. Enable it so the broker can track this trip.';

  @override
  String driverGpsReadFailed(String message) {
    return 'Unable to read GPS location: $message';
  }

  @override
  String get customerRequestTitle => 'Request Transport';

  @override
  String get customerShipping => 'What are you shipping? *';

  @override
  String get customerSpecialInstructions => 'Special instructions';

  @override
  String get customerSubmitting => 'Submitting...';

  @override
  String get customerSubmit => 'Request Transport';

  @override
  String get customerPickupPlaceholder => '123 Main St, Chicago, IL';

  @override
  String get customerDeliveryPlaceholder => '456 Oak Ave, Dallas, TX';

  @override
  String get customerCargoPlaceholder => '20 pallets of packaged goods';

  @override
  String get customerWeightPlaceholder => '40,000';

  @override
  String get customerNotesPlaceholder => 'Liftgate required at delivery';

  @override
  String get customerTrackTitle => 'Track Shipments';

  @override
  String get customerTrackEmpty => 'No shipments in progress';

  @override
  String get customerTrackEmptyHint =>
      'Shipments created by your broker appear here for live tracking.';

  @override
  String get customerRequestTransport => 'Request transport';

  @override
  String customerDriverName(String name) {
    return 'Driver: $name';
  }

  @override
  String get customerAwaitingDriver => 'Awaiting driver assignment';

  @override
  String get customerTrackDetailTitle => 'Track Shipments';

  @override
  String get customerTrackLoading => 'Loading shipment...';

  @override
  String get customerTrackingFallback => 'Tracking your shipment.';

  @override
  String get customerEstDeparture => 'Est. Departure';

  @override
  String get customerEstArrival => 'Est. Arrival';

  @override
  String get customerScheduling => 'Scheduling';

  @override
  String get customerFrom => 'From';

  @override
  String get customerTo => 'To';

  @override
  String customerAssignedDriver(String equipment) {
    return '$equipment • Assigned driver';
  }

  @override
  String get customerNoDriver => 'A driver has not been assigned yet.';

  @override
  String get customerViewDocuments => 'View Documents';

  @override
  String get customerContactSupport => 'Contact Support';

  @override
  String get bannerPending => 'We are matching your shipment with a carrier.';

  @override
  String get bannerCreated =>
      'Your shipment is booked and awaiting driver assignment.';

  @override
  String get bannerAssigned =>
      'A driver has been assigned and will pick up soon.';

  @override
  String get bannerAccepted =>
      'Your driver accepted the load and is heading to pickup.';

  @override
  String get bannerInTransit => 'Your shipment is on the move.';

  @override
  String get bannerDelivered => 'Your shipment has been delivered.';

  @override
  String get bannerRejected =>
      'We are reassigning your shipment to another driver.';

  @override
  String get bannerCancelled => 'This shipment was cancelled.';

  @override
  String get customerHistoryTitle => 'Trip History';

  @override
  String get customerHistoryEmpty => 'No completed shipments yet.';

  @override
  String get notificationsTitle => 'Notifications';
}
