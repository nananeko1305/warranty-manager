import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sr.dart';

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
    Locale('en'),
    Locale('sr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Warranty Manager'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Every warranty and receipt, in one place'**
  String get appTagline;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'No account yet? Create one'**
  String get noAccountYet;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccount;

  /// No description provided for @confirmAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmAccountPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent.'**
  String get resetSent;

  /// No description provided for @minChars6.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get minChars6;

  /// No description provided for @wait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get wait;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Change the photo'**
  String get edit;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get systemLanguage;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmPassword;

  /// No description provided for @passwordsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsNoMatch;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get passwordChanged;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all your warranties. Receipt photos are removed from the image service within about a month. Enter your password to confirm.'**
  String get deleteAccountBody;

  /// No description provided for @checkUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkUpdates;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You have the latest version.'**
  String get upToDate;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates.'**
  String get updateCheckFailed;

  /// No description provided for @newVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get newVersionTitle;

  /// No description provided for @newVersionBody.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is ready to download. You have {current}.'**
  String newVersionBody(String version, String current);

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'The email is not valid.'**
  String get errInvalidEmail;

  /// No description provided for @errEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errEmailInUse;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak (min. 6 characters).'**
  String get errWeakPassword;

  /// No description provided for @errUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account is disabled.'**
  String get errUserDisabled;

  /// No description provided for @errWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errWrongCredentials;

  /// No description provided for @errRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign out, sign in again and try once more.'**
  String get errRecentLogin;

  /// No description provided for @errTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a few minutes.'**
  String get errTooMany;

  /// No description provided for @errNoNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errNoNetwork;

  /// No description provided for @errPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission for this action.'**
  String get errPermission;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @warranties.
  ///
  /// In en, this message translates to:
  /// **'Warranties'**
  String get warranties;

  /// No description provided for @validTab.
  ///
  /// In en, this message translates to:
  /// **'Valid ({count})'**
  String validTab(int count);

  /// No description provided for @expiredTab.
  ///
  /// In en, this message translates to:
  /// **'Expired ({count})'**
  String expiredTab(int count);

  /// No description provided for @addWarranty.
  ///
  /// In en, this message translates to:
  /// **'Add warranty'**
  String get addWarranty;

  /// No description provided for @newWarranty.
  ///
  /// In en, this message translates to:
  /// **'New warranty'**
  String get newWarranty;

  /// No description provided for @editWarranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get editWarranty;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or store'**
  String get searchHint;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No warranties yet'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the receipt, enter the product name, and you will be reminded before the warranty ends.'**
  String get emptyBody;

  /// No description provided for @noValid.
  ///
  /// In en, this message translates to:
  /// **'No valid warranties.'**
  String get noValid;

  /// No description provided for @noExpired.
  ///
  /// In en, this message translates to:
  /// **'No expired warranties.'**
  String get noExpired;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found.'**
  String get noResults;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// No description provided for @productNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Refrigerator'**
  String get productNameHint;

  /// No description provided for @storeOptional.
  ///
  /// In en, this message translates to:
  /// **'Store (optional)'**
  String get storeOptional;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. serial number'**
  String get noteHint;

  /// No description provided for @priceOptional.
  ///
  /// In en, this message translates to:
  /// **'Price (optional)'**
  String get priceOptional;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than 0'**
  String get invalidAmount;

  /// No description provided for @purchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get purchaseDate;

  /// No description provided for @notifyOnExpiry.
  ///
  /// In en, this message translates to:
  /// **'Remind me before it ends'**
  String get notifyOnExpiry;

  /// No description provided for @notifyOnExpiryHint.
  ///
  /// In en, this message translates to:
  /// **'30, 10 and 1 day before.'**
  String get notifyOnExpiryHint;

  /// No description provided for @deleteWarrantyQ.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteWarrantyQ(String name);

  /// No description provided for @deleteWarrantyBody.
  ///
  /// In en, this message translates to:
  /// **'The warranty and its reminders will be deleted. The receipt photo is removed from the image service within about a month.'**
  String get deleteWarrantyBody;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @addReceipt.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of the receipt'**
  String get addReceipt;

  /// No description provided for @receiptHint.
  ///
  /// In en, this message translates to:
  /// **'So you have it when you claim the warranty.'**
  String get receiptHint;

  /// No description provided for @receiptUploading.
  ///
  /// In en, this message translates to:
  /// **'Sending the photo...'**
  String get receiptUploading;

  /// No description provided for @receiptCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get receiptCamera;

  /// No description provided for @receiptGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from the gallery'**
  String get receiptGallery;

  /// No description provided for @warranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get warranty;

  /// No description provided for @warrantyMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get warrantyMonths;

  /// No description provided for @warrantyYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get warrantyYears;

  /// No description provided for @warrantyMonthsRange.
  ///
  /// In en, this message translates to:
  /// **'1 to 120 months'**
  String get warrantyMonthsRange;

  /// No description provided for @warrantyYearsRange.
  ///
  /// In en, this message translates to:
  /// **'1 to 30 years'**
  String get warrantyYearsRange;

  /// No description provided for @warrantyUntil.
  ///
  /// In en, this message translates to:
  /// **'Warranty until {date}'**
  String warrantyUntil(String date);

  /// No description provided for @warrantyExpiredOn.
  ///
  /// In en, this message translates to:
  /// **'Warranty ended {date}'**
  String warrantyExpiredOn(String date);

  /// No description provided for @warrantyEndsToday.
  ///
  /// In en, this message translates to:
  /// **'Warranty ends today'**
  String get warrantyEndsToday;

  /// No description provided for @warrantyDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String warrantyDaysLeft(int count);

  /// No description provided for @notificationsOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get notificationsOffTitle;

  /// No description provided for @notificationsOffBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t get warranty reminders.'**
  String get notificationsOffBody;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @hibernationTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep reminders coming'**
  String get hibernationTitle;

  /// No description provided for @hibernationBody.
  ///
  /// In en, this message translates to:
  /// **'Android puts apps you don\'t open for months to sleep, and reminders stop reaching them. Turn that off for this app.'**
  String get hibernationBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @moreDetails.
  ///
  /// In en, this message translates to:
  /// **'Store, price and note'**
  String get moreDetails;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share the app'**
  String get shareApp;

  /// No description provided for @shareAppHint.
  ///
  /// In en, this message translates to:
  /// **'Scan the code with another phone\'s camera, or send the link. Android will ask to allow installing from that source.'**
  String get shareAppHint;

  /// No description provided for @shareAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Warranty Manager: every warranty and receipt, in one place.'**
  String get shareAppMessage;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get linkCopied;

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendLink;
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
      <String>['en', 'sr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sr':
      return AppLocalizationsSr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
