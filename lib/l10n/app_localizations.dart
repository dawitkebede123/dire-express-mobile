import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
  ];

  /// No description provided for @brandName.
  ///
  /// In en, this message translates to:
  /// **'Dire Express'**
  String get brandName;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageAm.
  ///
  /// In en, this message translates to:
  /// **'አማርኛ'**
  String get languageAm;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navLoads.
  ///
  /// In en, this message translates to:
  /// **'Loads'**
  String get navLoads;

  /// No description provided for @navDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get navDrivers;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get navActive;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get navRequest;

  /// No description provided for @navTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get navTrack;

  /// No description provided for @headerGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get headerGoBack;

  /// No description provided for @headerNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get headerNotifications;

  /// No description provided for @headerProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get headerProfile;

  /// No description provided for @callName.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String callName(String name);

  /// No description provided for @roleBroker.
  ///
  /// In en, this message translates to:
  /// **'Broker'**
  String get roleBroker;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleDriver;

  /// No description provided for @roleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleCustomer;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get commonDetails;

  /// No description provided for @commonEmpty.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get commonEmpty;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get commonMarkAllRead;

  /// No description provided for @commonNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get commonNoNotifications;

  /// No description provided for @landingBadge.
  ///
  /// In en, this message translates to:
  /// **'Digital freight brokerage'**
  String get landingBadge;

  /// No description provided for @landingTitle.
  ///
  /// In en, this message translates to:
  /// **'Every load, every driver, one live view.'**
  String get landingTitle;

  /// No description provided for @landingCopy.
  ///
  /// In en, this message translates to:
  /// **'Dire Express connects brokers, drivers, and shippers on a single mobile-first platform — from booking a load to signing for it at the dock.'**
  String get landingCopy;

  /// No description provided for @landingCta.
  ///
  /// In en, this message translates to:
  /// **'Start moving freight'**
  String get landingCta;

  /// No description provided for @landingSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get landingSignIn;

  /// No description provided for @landingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get landingGetStarted;

  /// No description provided for @landingHowHeading.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get landingHowHeading;

  /// No description provided for @landingBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get landingBookTitle;

  /// No description provided for @landingBookCopy.
  ///
  /// In en, this message translates to:
  /// **'A customer requests transport, or a broker creates the load directly.'**
  String get landingBookCopy;

  /// No description provided for @landingDispatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get landingDispatchTitle;

  /// No description provided for @landingDispatchCopy.
  ///
  /// In en, this message translates to:
  /// **'The broker assigns a driver, who accepts and starts the trip from their phone.'**
  String get landingDispatchCopy;

  /// No description provided for @landingDeliverTitle.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get landingDeliverTitle;

  /// No description provided for @landingDeliverCopy.
  ///
  /// In en, this message translates to:
  /// **'GPS streams the whole way, and the driver captures photo and signature at the dock.'**
  String get landingDeliverCopy;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your loads.'**
  String get loginSubtitle;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'you@gmail.com'**
  String get loginEmailPlaceholder;

  /// No description provided for @loginSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSubmit;

  /// No description provided for @loginSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loginSubmitting;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account?'**
  String get loginNoAccount;

  /// No description provided for @loginCreateOne.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get loginCreateOne;

  /// No description provided for @loginDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo accounts — password: password123'**
  String get loginDemo;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the role that matches how you move freight.'**
  String get registerSubtitle;

  /// No description provided for @registerIAmA.
  ///
  /// In en, this message translates to:
  /// **'I am a'**
  String get registerIAmA;

  /// No description provided for @registerFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get registerFullName;

  /// No description provided for @registerEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get registerEmail;

  /// No description provided for @registerPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPassword;

  /// No description provided for @registerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get registerPhone;

  /// No description provided for @registerCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get registerCompany;

  /// No description provided for @registerPlateNo.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get registerPlateNo;

  /// No description provided for @registerVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get registerVehicleType;

  /// No description provided for @registerNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Jane Doe'**
  String get registerNamePlaceholder;

  /// No description provided for @registerEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'you@gmail.com'**
  String get registerEmailPlaceholder;

  /// No description provided for @registerPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get registerPasswordPlaceholder;

  /// No description provided for @registerPhonePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'0912345678'**
  String get registerPhonePlaceholder;

  /// No description provided for @registerCompanyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **''**
  String get registerCompanyPlaceholder;

  /// No description provided for @registerPlatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'AA-1234'**
  String get registerPlatePlaceholder;

  /// No description provided for @registerVehiclePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Semi-Truck • Volvo VNL'**
  String get registerVehiclePlaceholder;

  /// No description provided for @registerSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerSubmit;

  /// No description provided for @registerSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get registerSubmitting;

  /// No description provided for @registerAlready.
  ///
  /// In en, this message translates to:
  /// **'Already registered?'**
  String get registerAlready;

  /// No description provided for @registerSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get registerSignIn;

  /// No description provided for @registerAgentId.
  ///
  /// In en, this message translates to:
  /// **'Agent ID'**
  String get registerAgentId;

  /// No description provided for @registerAgentIdPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Paste the broker\'s Agent ID'**
  String get registerAgentIdPlaceholder;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRole;

  /// No description provided for @profileAgentId.
  ///
  /// In en, this message translates to:
  /// **'Agent ID'**
  String get profileAgentId;

  /// No description provided for @profileAgentIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Agent ID copied'**
  String get profileAgentIdCopied;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get profileTakePhoto;

  /// No description provided for @profileChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get profileChoosePhoto;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get statusCreated;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusInTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get statusInTransit;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @equipmentDryVan.
  ///
  /// In en, this message translates to:
  /// **'Dry Van'**
  String get equipmentDryVan;

  /// No description provided for @equipmentReefer.
  ///
  /// In en, this message translates to:
  /// **'Reefer'**
  String get equipmentReefer;

  /// No description provided for @equipmentFlatbed.
  ///
  /// In en, this message translates to:
  /// **'Flatbed'**
  String get equipmentFlatbed;

  /// No description provided for @equipmentFreight.
  ///
  /// In en, this message translates to:
  /// **'Freight'**
  String get equipmentFreight;

  /// No description provided for @loadRateTbd.
  ///
  /// In en, this message translates to:
  /// **'Rate TBD'**
  String get loadRateTbd;

  /// No description provided for @loadScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get loadScheduled;

  /// No description provided for @loadDeliveryScheduled.
  ///
  /// In en, this message translates to:
  /// **'Delivery scheduled'**
  String get loadDeliveryScheduled;

  /// No description provided for @loadPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get loadPickup;

  /// No description provided for @loadDropoff.
  ///
  /// In en, this message translates to:
  /// **'Dropoff'**
  String get loadDropoff;

  /// No description provided for @trackBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get trackBooked;

  /// No description provided for @trackRequestReceived.
  ///
  /// In en, this message translates to:
  /// **'Request received'**
  String get trackRequestReceived;

  /// No description provided for @trackPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get trackPickedUp;

  /// No description provided for @trackScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled {datetime}'**
  String trackScheduled(String datetime);

  /// No description provided for @trackInTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get trackInTransit;

  /// No description provided for @trackLiveActive.
  ///
  /// In en, this message translates to:
  /// **'Live tracking active'**
  String get trackLiveActive;

  /// No description provided for @trackCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get trackCompleted;

  /// No description provided for @trackPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get trackPending;

  /// No description provided for @trackDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get trackDelivered;

  /// No description provided for @formatToday.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String formatToday(String time);

  /// No description provided for @formatTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow, {time}'**
  String formatTomorrow(String time);

  /// No description provided for @formatYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {time}'**
  String formatYesterday(String time);

  /// No description provided for @weightLbs.
  ///
  /// In en, this message translates to:
  /// **'{n} lbs'**
  String weightLbs(String n);

  /// No description provided for @toastInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get toastInvalidCredentials;

  /// No description provided for @toastConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection and API URL.'**
  String get toastConnectionFailed;

  /// No description provided for @toastRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get toastRegistrationFailed;

  /// No description provided for @toastAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get toastAccountCreated;

  /// No description provided for @toastEmailRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email already registered'**
  String get toastEmailRegistered;

  /// No description provided for @toastInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number (e.g. 0912345678, 0712345678, +25377XXXXXX, or +2917XXXXXX)'**
  String get toastInvalidPhone;

  /// No description provided for @toastAgentIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Agent ID is required'**
  String get toastAgentIdRequired;

  /// No description provided for @toastAgentIdInvalid.
  ///
  /// In en, this message translates to:
  /// **'This Agent ID is not valid'**
  String get toastAgentIdInvalid;

  /// No description provided for @toastSelectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select a customer to continue'**
  String get toastSelectCustomer;

  /// No description provided for @toastPickupDeliveryRequired.
  ///
  /// In en, this message translates to:
  /// **'Pickup, delivery, and pickup date are required'**
  String get toastPickupDeliveryRequired;

  /// No description provided for @toastCreateLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create load'**
  String get toastCreateLoadFailed;

  /// No description provided for @toastLoadCreated.
  ///
  /// In en, this message translates to:
  /// **'Load created'**
  String get toastLoadCreated;

  /// No description provided for @toastReceiptRequired.
  ///
  /// In en, this message translates to:
  /// **'Upload a payment receipt to create more loads'**
  String get toastReceiptRequired;

  /// No description provided for @toastReceiptUploaded.
  ///
  /// In en, this message translates to:
  /// **'Receipt uploaded'**
  String get toastReceiptUploaded;

  /// No description provided for @toastDeviceIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Device ID is required. Restart the app and try again.'**
  String get toastDeviceIdRequired;

  /// No description provided for @brokerPaymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Payment receipt'**
  String get brokerPaymentReceipt;

  /// No description provided for @brokerPaymentReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'You have used your free loads. Upload a payment receipt to continue.'**
  String get brokerPaymentReceiptHint;

  /// No description provided for @brokerUploadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Upload receipt'**
  String get brokerUploadReceipt;

  /// No description provided for @brokerReceiptReady.
  ///
  /// In en, this message translates to:
  /// **'Receipt attached'**
  String get brokerReceiptReady;

  /// No description provided for @toastAssignFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign driver'**
  String get toastAssignFailed;

  /// No description provided for @toastDriverAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get toastDriverAssigned;

  /// No description provided for @toastNewLoadUpdate.
  ///
  /// In en, this message translates to:
  /// **'New load update'**
  String get toastNewLoadUpdate;

  /// No description provided for @toastActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get toastActionFailed;

  /// No description provided for @toastLoadAccepted.
  ///
  /// In en, this message translates to:
  /// **'Load accepted'**
  String get toastLoadAccepted;

  /// No description provided for @toastLoadRejected.
  ///
  /// In en, this message translates to:
  /// **'Load rejected'**
  String get toastLoadRejected;

  /// No description provided for @toastTripStarted.
  ///
  /// In en, this message translates to:
  /// **'Trip started'**
  String get toastTripStarted;

  /// No description provided for @toastSignBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Please sign before saving'**
  String get toastSignBeforeSaving;

  /// No description provided for @toastSignatureCaptured.
  ///
  /// In en, this message translates to:
  /// **'Signature captured'**
  String get toastSignatureCaptured;

  /// No description provided for @toastPodFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo, signature, and recipient name are required'**
  String get toastPodFieldsRequired;

  /// No description provided for @toastPodSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit proof of delivery'**
  String get toastPodSubmitFailed;

  /// No description provided for @toastPhotoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Photo uploaded'**
  String get toastPhotoUploaded;

  /// No description provided for @toastUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get toastUploadFailed;

  /// No description provided for @toastRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit request'**
  String get toastRequestFailed;

  /// No description provided for @toastRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Transport request submitted'**
  String get toastRequestSubmitted;

  /// No description provided for @toastProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get toastProfileSaved;

  /// No description provided for @toastProfileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile'**
  String get toastProfileSaveFailed;

  /// No description provided for @mapMissingToken.
  ///
  /// In en, this message translates to:
  /// **'Add MAPBOX_ACCESS_TOKEN to enable live maps'**
  String get mapMissingToken;

  /// No description provided for @mapRecenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter map'**
  String get mapRecenter;

  /// No description provided for @mapLiveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get mapLiveTracking;

  /// No description provided for @mapExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand map'**
  String get mapExpand;

  /// No description provided for @mapCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse map'**
  String get mapCollapse;

  /// No description provided for @brokerDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Broker Dashboard'**
  String get brokerDashboardTitle;

  /// No description provided for @brokerProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Broker profile not found.'**
  String get brokerProfileNotFound;

  /// No description provided for @brokerTotalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get brokerTotalRevenue;

  /// No description provided for @brokerLoadsDelivered.
  ///
  /// In en, this message translates to:
  /// **'{count} loads delivered'**
  String brokerLoadsDelivered(int count);

  /// No description provided for @brokerActiveLoads.
  ///
  /// In en, this message translates to:
  /// **'Active Loads'**
  String get brokerActiveLoads;

  /// No description provided for @brokerPendingDrivers.
  ///
  /// In en, this message translates to:
  /// **'Pending Drivers'**
  String get brokerPendingDrivers;

  /// No description provided for @brokerRecentLoads.
  ///
  /// In en, this message translates to:
  /// **'Recent Loads'**
  String get brokerRecentLoads;

  /// No description provided for @brokerViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get brokerViewAll;

  /// No description provided for @brokerEmptyLoads.
  ///
  /// In en, this message translates to:
  /// **'No loads yet. Create your first load to get started.'**
  String get brokerEmptyLoads;

  /// No description provided for @brokerCreateLoad.
  ///
  /// In en, this message translates to:
  /// **'Create Load'**
  String get brokerCreateLoad;

  /// No description provided for @brokerLoadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Loads Management'**
  String get brokerLoadsTitle;

  /// No description provided for @brokerLoadsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No loads found.'**
  String get brokerLoadsEmpty;

  /// No description provided for @brokerStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get brokerStepDetails;

  /// No description provided for @brokerStepRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get brokerStepRoute;

  /// No description provided for @brokerStepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get brokerStepConfirm;

  /// No description provided for @brokerCustomerInfo.
  ///
  /// In en, this message translates to:
  /// **'Customer Info'**
  String get brokerCustomerInfo;

  /// No description provided for @brokerSelectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select Customer *'**
  String get brokerSelectCustomer;

  /// No description provided for @brokerSelectCustomerPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select a customer...'**
  String get brokerSelectCustomerPlaceholder;

  /// No description provided for @brokerLoadDetails.
  ///
  /// In en, this message translates to:
  /// **'Load Details'**
  String get brokerLoadDetails;

  /// No description provided for @brokerEquipmentType.
  ///
  /// In en, this message translates to:
  /// **'Equipment Type'**
  String get brokerEquipmentType;

  /// No description provided for @brokerWeightLbs.
  ///
  /// In en, this message translates to:
  /// **'Weight (lbs)'**
  String get brokerWeightLbs;

  /// No description provided for @brokerRate.
  ///
  /// In en, this message translates to:
  /// **'Rate (ETB)'**
  String get brokerRate;

  /// No description provided for @brokerCargo.
  ///
  /// In en, this message translates to:
  /// **'Cargo'**
  String get brokerCargo;

  /// No description provided for @brokerPickupAddress.
  ///
  /// In en, this message translates to:
  /// **'Pickup address *'**
  String get brokerPickupAddress;

  /// No description provided for @brokerPickupDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup date *'**
  String get brokerPickupDate;

  /// No description provided for @brokerDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address *'**
  String get brokerDeliveryAddress;

  /// No description provided for @brokerDeliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery date'**
  String get brokerDeliveryDate;

  /// No description provided for @brokerCargoDescription.
  ///
  /// In en, this message translates to:
  /// **'Cargo description'**
  String get brokerCargoDescription;

  /// No description provided for @brokerNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get brokerNotes;

  /// No description provided for @brokerConfirmLoad.
  ///
  /// In en, this message translates to:
  /// **'Confirm Load'**
  String get brokerConfirmLoad;

  /// No description provided for @brokerConfirmCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get brokerConfirmCustomer;

  /// No description provided for @brokerConfirmEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get brokerConfirmEquipment;

  /// No description provided for @brokerConfirmWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get brokerConfirmWeight;

  /// No description provided for @brokerConfirmRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get brokerConfirmRate;

  /// No description provided for @brokerConfirmPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get brokerConfirmPickup;

  /// No description provided for @brokerConfirmDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get brokerConfirmDelivery;

  /// No description provided for @brokerConfirmPickupDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup date'**
  String get brokerConfirmPickupDate;

  /// No description provided for @brokerConfirmCargo.
  ///
  /// In en, this message translates to:
  /// **'Cargo'**
  String get brokerConfirmCargo;

  /// No description provided for @brokerContinueToRoute.
  ///
  /// In en, this message translates to:
  /// **'Continue to Route'**
  String get brokerContinueToRoute;

  /// No description provided for @brokerReviewLoad.
  ///
  /// In en, this message translates to:
  /// **'Review Load'**
  String get brokerReviewLoad;

  /// No description provided for @brokerCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get brokerCreating;

  /// No description provided for @brokerPickupPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'123 Main St, Chicago, IL'**
  String get brokerPickupPlaceholder;

  /// No description provided for @brokerDeliveryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'456 Oak Ave, Dallas, TX'**
  String get brokerDeliveryPlaceholder;

  /// No description provided for @brokerCargoPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'20 pallets of industrial equipment'**
  String get brokerCargoPlaceholder;

  /// No description provided for @brokerNotesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Special handling instructions'**
  String get brokerNotesPlaceholder;

  /// No description provided for @brokerWeightPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'40,000'**
  String get brokerWeightPlaceholder;

  /// No description provided for @brokerRatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'2,500'**
  String get brokerRatePlaceholder;

  /// No description provided for @brokerLoadDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Load Details'**
  String get brokerLoadDetailTitle;

  /// No description provided for @brokerAssignDriver.
  ///
  /// In en, this message translates to:
  /// **'Assign Driver'**
  String get brokerAssignDriver;

  /// No description provided for @brokerNoDrivers.
  ///
  /// In en, this message translates to:
  /// **'No available drivers.'**
  String get brokerNoDrivers;

  /// No description provided for @brokerNoVehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'No vehicle info'**
  String get brokerNoVehicleInfo;

  /// No description provided for @brokerShipmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Shipment Status'**
  String get brokerShipmentStatus;

  /// No description provided for @brokerTripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip Details'**
  String get brokerTripDetails;

  /// No description provided for @brokerAssignedDriver.
  ///
  /// In en, this message translates to:
  /// **'Assigned driver'**
  String get brokerAssignedDriver;

  /// No description provided for @brokerProofOfDelivery.
  ///
  /// In en, this message translates to:
  /// **'Proof of Delivery'**
  String get brokerProofOfDelivery;

  /// No description provided for @brokerDeliveryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Delivery photo'**
  String get brokerDeliveryPhoto;

  /// No description provided for @brokerRecipientSignature.
  ///
  /// In en, this message translates to:
  /// **'Recipient signature'**
  String get brokerRecipientSignature;

  /// No description provided for @brokerCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get brokerCustomer;

  /// No description provided for @brokerDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get brokerDriver;

  /// No description provided for @brokerDriversTitle.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get brokerDriversTitle;

  /// No description provided for @brokerDriversEmpty.
  ///
  /// In en, this message translates to:
  /// **'No drivers registered yet.'**
  String get brokerDriversEmpty;

  /// No description provided for @brokerDriversAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get brokerDriversAvailable;

  /// No description provided for @brokerDriversOnALoad.
  ///
  /// In en, this message translates to:
  /// **'On a load'**
  String get brokerDriversOnALoad;

  /// No description provided for @brokerVehicleNotSet.
  ///
  /// In en, this message translates to:
  /// **'Vehicle not set'**
  String get brokerVehicleNotSet;

  /// No description provided for @brokerLoadsAssigned.
  ///
  /// In en, this message translates to:
  /// **'{count} loads assigned'**
  String brokerLoadsAssigned(int count);

  /// No description provided for @brokerCustomersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get brokerCustomersTitle;

  /// No description provided for @brokerCustomersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No customers yet.'**
  String get brokerCustomersEmpty;

  /// No description provided for @brokerCustomersLoads.
  ///
  /// In en, this message translates to:
  /// **'{count} loads'**
  String brokerCustomersLoads(int count);

  /// No description provided for @driverAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Loads'**
  String get driverAvailableTitle;

  /// No description provided for @driverMyTrips.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get driverMyTrips;

  /// No description provided for @driverAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get driverAvailable;

  /// No description provided for @driverAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'Available ({count})'**
  String driverAvailableCount(int count);

  /// No description provided for @driverLoadingLoads.
  ///
  /// In en, this message translates to:
  /// **'Loading loads...'**
  String get driverLoadingLoads;

  /// No description provided for @driverEmptyAvailable.
  ///
  /// In en, this message translates to:
  /// **'No loads awaiting your response'**
  String get driverEmptyAvailable;

  /// No description provided for @driverEmptyAvailableHint.
  ///
  /// In en, this message translates to:
  /// **'New assignments from your broker will appear here.'**
  String get driverEmptyAvailableHint;

  /// No description provided for @driverEmptyTrips.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get driverEmptyTrips;

  /// No description provided for @driverEmptyTripsHint.
  ///
  /// In en, this message translates to:
  /// **'Accepted and completed loads will show up here.'**
  String get driverEmptyTripsHint;

  /// No description provided for @driverReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get driverReject;

  /// No description provided for @driverAcceptLoad.
  ///
  /// In en, this message translates to:
  /// **'Accept Load'**
  String get driverAcceptLoad;

  /// No description provided for @driverActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Trip'**
  String get driverActiveTitle;

  /// No description provided for @driverNoTrip.
  ///
  /// In en, this message translates to:
  /// **'No active trip'**
  String get driverNoTrip;

  /// No description provided for @driverNoTripHint.
  ///
  /// In en, this message translates to:
  /// **'Start an accepted load to begin live tracking.'**
  String get driverNoTripHint;

  /// No description provided for @driverViewLoads.
  ///
  /// In en, this message translates to:
  /// **'View loads'**
  String get driverViewLoads;

  /// No description provided for @driverCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get driverCustomer;

  /// No description provided for @driverPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get driverPickedUp;

  /// No description provided for @driverCompleteDelivery.
  ///
  /// In en, this message translates to:
  /// **'Complete Delivery'**
  String get driverCompleteDelivery;

  /// No description provided for @driverHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip History'**
  String get driverHistoryTitle;

  /// No description provided for @driverTotalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get driverTotalEarned;

  /// No description provided for @driverHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed trips yet.'**
  String get driverHistoryEmpty;

  /// No description provided for @driverPodTitle.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get driverPodTitle;

  /// No description provided for @driverPodSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'POD Submitted Successfully'**
  String get driverPodSuccessTitle;

  /// No description provided for @driverPodSuccessCopy.
  ///
  /// In en, this message translates to:
  /// **'Load {ref} has been finalized and sent to billing.'**
  String driverPodSuccessCopy(String ref);

  /// No description provided for @driverReturnDashboard.
  ///
  /// In en, this message translates to:
  /// **'Return to Dashboard'**
  String get driverReturnDashboard;

  /// No description provided for @driverDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get driverDestination;

  /// No description provided for @driverConsignee.
  ///
  /// In en, this message translates to:
  /// **'Consignee'**
  String get driverConsignee;

  /// No description provided for @driverStartTrip.
  ///
  /// In en, this message translates to:
  /// **'Start Trip'**
  String get driverStartTrip;

  /// No description provided for @driverGpsActive.
  ///
  /// In en, this message translates to:
  /// **'GPS tracking active'**
  String get driverGpsActive;

  /// No description provided for @driverGpsHint.
  ///
  /// In en, this message translates to:
  /// **'Your location is shared with the broker and customer.'**
  String get driverGpsHint;

  /// No description provided for @driverUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get driverUploading;

  /// No description provided for @driverReplacePod.
  ///
  /// In en, this message translates to:
  /// **'Tap to replace BOL/POD'**
  String get driverReplacePod;

  /// No description provided for @driverCapturePod.
  ///
  /// In en, this message translates to:
  /// **'Tap to capture BOL/POD'**
  String get driverCapturePod;

  /// No description provided for @driverPodHint.
  ///
  /// In en, this message translates to:
  /// **'Ensure all edges of the document are visible and text is legible.'**
  String get driverPodHint;

  /// No description provided for @driverReceiverSignature.
  ///
  /// In en, this message translates to:
  /// **'Receiver Signature'**
  String get driverReceiverSignature;

  /// No description provided for @driverSignHere.
  ///
  /// In en, this message translates to:
  /// **'Sign here'**
  String get driverSignHere;

  /// No description provided for @driverClearSignature.
  ///
  /// In en, this message translates to:
  /// **'Clear Signature'**
  String get driverClearSignature;

  /// No description provided for @driverRecipientName.
  ///
  /// In en, this message translates to:
  /// **'Recipient name'**
  String get driverRecipientName;

  /// No description provided for @driverRecipientPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Who received the freight?'**
  String get driverRecipientPlaceholder;

  /// No description provided for @driverDeliveryNotes.
  ///
  /// In en, this message translates to:
  /// **'Delivery Notes (Optional)'**
  String get driverDeliveryNotes;

  /// No description provided for @driverNotesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Left at dock door 3 per instructions.'**
  String get driverNotesPlaceholder;

  /// No description provided for @driverProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get driverProcessing;

  /// No description provided for @driverSubmitPod.
  ///
  /// In en, this message translates to:
  /// **'Submit Proof of Delivery'**
  String get driverSubmitPod;

  /// No description provided for @driverGpsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location services are not available on this device.'**
  String get driverGpsUnavailable;

  /// No description provided for @driverGpsDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Enable it so the broker can track this trip.'**
  String get driverGpsDenied;

  /// No description provided for @driverGpsReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to read GPS location: {message}'**
  String driverGpsReadFailed(String message);

  /// No description provided for @customerRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Transport'**
  String get customerRequestTitle;

  /// No description provided for @customerShipping.
  ///
  /// In en, this message translates to:
  /// **'What are you shipping? *'**
  String get customerShipping;

  /// No description provided for @customerSpecialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special instructions'**
  String get customerSpecialInstructions;

  /// No description provided for @customerSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get customerSubmitting;

  /// No description provided for @customerSubmit.
  ///
  /// In en, this message translates to:
  /// **'Request Transport'**
  String get customerSubmit;

  /// No description provided for @customerPickupPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'123 Main St, Chicago, IL'**
  String get customerPickupPlaceholder;

  /// No description provided for @customerDeliveryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'456 Oak Ave, Dallas, TX'**
  String get customerDeliveryPlaceholder;

  /// No description provided for @customerCargoPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'20 pallets of packaged goods'**
  String get customerCargoPlaceholder;

  /// No description provided for @customerWeightPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'40,000'**
  String get customerWeightPlaceholder;

  /// No description provided for @customerNotesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Liftgate required at delivery'**
  String get customerNotesPlaceholder;

  /// No description provided for @customerTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Shipments'**
  String get customerTrackTitle;

  /// No description provided for @customerTrackEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shipments in progress'**
  String get customerTrackEmpty;

  /// No description provided for @customerTrackEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Shipments created by your broker appear here for live tracking.'**
  String get customerTrackEmptyHint;

  /// No description provided for @customerRequestTransport.
  ///
  /// In en, this message translates to:
  /// **'Request transport'**
  String get customerRequestTransport;

  /// No description provided for @customerDriverName.
  ///
  /// In en, this message translates to:
  /// **'Driver: {name}'**
  String customerDriverName(String name);

  /// No description provided for @customerAwaitingDriver.
  ///
  /// In en, this message translates to:
  /// **'Awaiting driver assignment'**
  String get customerAwaitingDriver;

  /// No description provided for @customerTrackDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Shipments'**
  String get customerTrackDetailTitle;

  /// No description provided for @customerTrackLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading shipment...'**
  String get customerTrackLoading;

  /// No description provided for @customerTrackingFallback.
  ///
  /// In en, this message translates to:
  /// **'Tracking your shipment.'**
  String get customerTrackingFallback;

  /// No description provided for @customerEstDeparture.
  ///
  /// In en, this message translates to:
  /// **'Est. Departure'**
  String get customerEstDeparture;

  /// No description provided for @customerEstArrival.
  ///
  /// In en, this message translates to:
  /// **'Est. Arrival'**
  String get customerEstArrival;

  /// No description provided for @customerScheduling.
  ///
  /// In en, this message translates to:
  /// **'Scheduling'**
  String get customerScheduling;

  /// No description provided for @customerFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get customerFrom;

  /// No description provided for @customerTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get customerTo;

  /// No description provided for @customerAssignedDriver.
  ///
  /// In en, this message translates to:
  /// **'{equipment} • Assigned driver'**
  String customerAssignedDriver(String equipment);

  /// No description provided for @customerNoDriver.
  ///
  /// In en, this message translates to:
  /// **'A driver has not been assigned yet.'**
  String get customerNoDriver;

  /// No description provided for @customerViewDocuments.
  ///
  /// In en, this message translates to:
  /// **'View Documents'**
  String get customerViewDocuments;

  /// No description provided for @customerContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get customerContactSupport;

  /// No description provided for @bannerPending.
  ///
  /// In en, this message translates to:
  /// **'We are matching your shipment with a carrier.'**
  String get bannerPending;

  /// No description provided for @bannerCreated.
  ///
  /// In en, this message translates to:
  /// **'Your shipment is booked and awaiting driver assignment.'**
  String get bannerCreated;

  /// No description provided for @bannerAssigned.
  ///
  /// In en, this message translates to:
  /// **'A driver has been assigned and will pick up soon.'**
  String get bannerAssigned;

  /// No description provided for @bannerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Your driver accepted the load and is heading to pickup.'**
  String get bannerAccepted;

  /// No description provided for @bannerInTransit.
  ///
  /// In en, this message translates to:
  /// **'Your shipment is on the move.'**
  String get bannerInTransit;

  /// No description provided for @bannerDelivered.
  ///
  /// In en, this message translates to:
  /// **'Your shipment has been delivered.'**
  String get bannerDelivered;

  /// No description provided for @bannerRejected.
  ///
  /// In en, this message translates to:
  /// **'We are reassigning your shipment to another driver.'**
  String get bannerRejected;

  /// No description provided for @bannerCancelled.
  ///
  /// In en, this message translates to:
  /// **'This shipment was cancelled.'**
  String get bannerCancelled;

  /// No description provided for @customerHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip History'**
  String get customerHistoryTitle;

  /// No description provided for @customerHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed shipments yet.'**
  String get customerHistoryEmpty;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
