// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Warranty Manager';

  @override
  String get appTagline => 'Every warranty and receipt, in one place';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get noAccountYet => 'No account yet? Create one';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get confirmAccountPassword => 'Confirm password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get resetSent => 'Password reset email sent.';

  @override
  String get minChars6 => 'At least 6 characters';

  @override
  String get wait => 'Please wait...';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get required => 'Required';

  @override
  String get edit => 'Change the photo';

  @override
  String get share => 'Share';

  @override
  String get open => 'Open';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'Phone language';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'Phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get account => 'Account';

  @override
  String get signOut => 'Sign out';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm new password';

  @override
  String get passwordsNoMatch => 'Passwords do not match';

  @override
  String get passwordChanged => 'Password changed.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account and all your warranties. Receipt photos are removed from the image service within about a month. Enter your password to confirm.';

  @override
  String get checkUpdates => 'Check for updates';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get upToDate => 'You have the latest version.';

  @override
  String get updateCheckFailed => 'Couldn\'t check for updates.';

  @override
  String get newVersionTitle => 'New version available';

  @override
  String newVersionBody(String version, String current) {
    return 'Version $version is ready to download. You have $current.';
  }

  @override
  String get later => 'Later';

  @override
  String get download => 'Download';

  @override
  String get syncing => 'Syncing...';

  @override
  String get synced => 'Synced';

  @override
  String get errInvalidEmail => 'The email is not valid.';

  @override
  String get errEmailInUse => 'An account with this email already exists.';

  @override
  String get errWeakPassword => 'Password is too weak (min. 6 characters).';

  @override
  String get errUserDisabled => 'This account is disabled.';

  @override
  String get errWrongCredentials => 'Wrong email or password.';

  @override
  String get errRecentLogin => 'Sign out, sign in again and try once more.';

  @override
  String get errTooMany => 'Too many attempts. Try again in a few minutes.';

  @override
  String get errNoNetwork => 'No internet connection.';

  @override
  String get errPermission => 'You don\'t have permission for this action.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get warranties => 'Warranties';

  @override
  String validTab(int count) {
    return 'Valid ($count)';
  }

  @override
  String expiredTab(int count) {
    return 'Expired ($count)';
  }

  @override
  String get addWarranty => 'Add warranty';

  @override
  String get newWarranty => 'New warranty';

  @override
  String get editWarranty => 'Warranty';

  @override
  String get searchHint => 'Search by name or store';

  @override
  String get emptyTitle => 'No warranties yet';

  @override
  String get emptyBody =>
      'Take a photo of the receipt, enter the product name, and you will be reminded before the warranty ends.';

  @override
  String get noValid => 'No valid warranties.';

  @override
  String get noExpired => 'No expired warranties.';

  @override
  String get noResults => 'Nothing found.';

  @override
  String get productName => 'Product name';

  @override
  String get productNameHint => 'e.g. Refrigerator';

  @override
  String get storeOptional => 'Store (optional)';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get noteHint => 'e.g. serial number';

  @override
  String get priceOptional => 'Price (optional)';

  @override
  String get invalidAmount => 'Enter an amount greater than 0';

  @override
  String get purchaseDate => 'Purchase date';

  @override
  String get notifyOnExpiry => 'Remind me before it ends';

  @override
  String get notifyOnExpiryHint => '30, 10 and 1 day before.';

  @override
  String deleteWarrantyQ(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteWarrantyBody =>
      'The warranty and its reminders will be deleted. The receipt photo is removed from the image service within about a month.';

  @override
  String get receipt => 'Receipt';

  @override
  String get addReceipt => 'Add a photo of the receipt';

  @override
  String get receiptHint => 'So you have it when you claim the warranty.';

  @override
  String get receiptUploading => 'Sending the photo...';

  @override
  String get receiptCamera => 'Take a photo';

  @override
  String get receiptGallery => 'Pick from the gallery';

  @override
  String get warranty => 'Warranty';

  @override
  String get warrantyMonths => 'Months';

  @override
  String get warrantyYears => 'Years';

  @override
  String get warrantyMonthsRange => '1 to 120 months';

  @override
  String get warrantyYearsRange => '1 to 30 years';

  @override
  String warrantyUntil(String date) {
    return 'Warranty until $date';
  }

  @override
  String warrantyExpiredOn(String date) {
    return 'Warranty ended $date';
  }

  @override
  String get warrantyEndsToday => 'Warranty ends today';

  @override
  String warrantyDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get notificationsOffTitle => 'Notifications are off';

  @override
  String get notificationsOffBody => 'You won\'t get warranty reminders.';

  @override
  String get turnOn => 'Turn on';

  @override
  String get hibernationTitle => 'Keep reminders coming';

  @override
  String get hibernationBody =>
      'Android puts apps you don\'t open for months to sleep, and reminders stop reaching them. Turn that off for this app.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get notNow => 'Not now';

  @override
  String get moreDetails => 'Store, price and note';

  @override
  String get shareApp => 'Share the app';

  @override
  String get shareAppHint =>
      'Scan the code with another phone\'s camera, or send the link. Android will ask to allow installing from that source.';

  @override
  String get shareAppMessage =>
      'Warranty Manager: every warranty and receipt, in one place.';

  @override
  String get copyLink => 'Copy link';

  @override
  String get linkCopied => 'Link copied.';

  @override
  String get sendLink => 'Send';
}
