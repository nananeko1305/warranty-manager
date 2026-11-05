// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get appTitle => 'Warranty Manager';

  @override
  String get appTagline => 'Sve garancije i računi, na jednom mestu';

  @override
  String get email => 'Email';

  @override
  String get password => 'Lozinka';

  @override
  String get signIn => 'Prijavi se';

  @override
  String get createAccount => 'Napravi nalog';

  @override
  String get noAccountYet => 'Nemaš nalog? Napravi ga';

  @override
  String get haveAccount => 'Već imaš nalog? Prijavi se';

  @override
  String get confirmAccountPassword => 'Potvrdi lozinku';

  @override
  String get forgotPassword => 'Zaboravljena lozinka?';

  @override
  String get invalidEmail => 'Unesi ispravan email';

  @override
  String get resetSent => 'Poslat je email za promenu lozinke.';

  @override
  String get minChars6 => 'Najmanje 6 karaktera';

  @override
  String get wait => 'Sačekaj...';

  @override
  String get save => 'Sačuvaj';

  @override
  String get cancel => 'Otkaži';

  @override
  String get delete => 'Obriši';

  @override
  String get required => 'Obavezno';

  @override
  String get edit => 'Promeni sliku';

  @override
  String get share => 'Podeli';

  @override
  String get open => 'Otvori';

  @override
  String get settings => 'Podešavanja';

  @override
  String get language => 'Jezik';

  @override
  String get systemLanguage => 'Jezik telefona';

  @override
  String get appearance => 'Izgled';

  @override
  String get themeSystem => 'Kao telefon';

  @override
  String get themeLight => 'Svetla';

  @override
  String get themeDark => 'Tamna';

  @override
  String get account => 'Nalog';

  @override
  String get signOut => 'Odjavi se';

  @override
  String get changePassword => 'Promeni lozinku';

  @override
  String get currentPassword => 'Trenutna lozinka';

  @override
  String get newPassword => 'Nova lozinka';

  @override
  String get confirmPassword => 'Potvrdi novu lozinku';

  @override
  String get passwordsNoMatch => 'Lozinke se ne poklapaju';

  @override
  String get passwordChanged => 'Lozinka je promenjena.';

  @override
  String get deleteAccount => 'Obriši nalog';

  @override
  String get deleteAccountBody =>
      'Ovo trajno briše tvoj nalog, sve tvoje garancije i slike računa. Upiši lozinku da potvrdiš.';

  @override
  String get checkUpdates => 'Proveri ažuriranja';

  @override
  String appVersion(String version) {
    return 'Verzija $version';
  }

  @override
  String get upToDate => 'Imaš najnoviju verziju.';

  @override
  String get updateCheckFailed => 'Provera ažuriranja nije uspela.';

  @override
  String get newVersionTitle => 'Dostupna je nova verzija';

  @override
  String newVersionBody(String version, String current) {
    return 'Verzija $version je spremna za preuzimanje. Ti imaš $current.';
  }

  @override
  String get later => 'Kasnije';

  @override
  String get download => 'Preuzmi';

  @override
  String get syncing => 'Sinhronizujem...';

  @override
  String get synced => 'Sinhronizovano';

  @override
  String get errInvalidEmail => 'Email nije ispravan.';

  @override
  String get errEmailInUse => 'Nalog sa ovim emailom već postoji.';

  @override
  String get errWeakPassword => 'Lozinka je preslaba (min. 6 karaktera).';

  @override
  String get errUserDisabled => 'Ovaj nalog je onemogućen.';

  @override
  String get errWrongCredentials => 'Pogrešan email ili lozinka.';

  @override
  String get errRecentLogin =>
      'Odjavi se, prijavi se ponovo i pokušaj još jednom.';

  @override
  String get errTooMany =>
      'Previše pokušaja. Pokušaj ponovo za nekoliko minuta.';

  @override
  String get errNoNetwork => 'Nema internet konekcije.';

  @override
  String get errPermission => 'Nemaš dozvolu za ovu akciju.';

  @override
  String get errGeneric => 'Nešto nije u redu. Pokušaj ponovo.';

  @override
  String get warranties => 'Garancije';

  @override
  String validTab(int count) {
    return 'Važeće ($count)';
  }

  @override
  String expiredTab(int count) {
    return 'Istekle ($count)';
  }

  @override
  String get addWarranty => 'Dodaj garanciju';

  @override
  String get newWarranty => 'Nova garancija';

  @override
  String get editWarranty => 'Garancija';

  @override
  String get searchHint => 'Traži po nazivu ili prodavnici';

  @override
  String get emptyTitle => 'Još nema garancija';

  @override
  String get emptyBody =>
      'Slikaj račun, upiši naziv proizvoda i dobićeš podsetnik pre isteka garancije.';

  @override
  String get noValid => 'Nema važećih garancija.';

  @override
  String get noExpired => 'Nema isteklih garancija.';

  @override
  String get noResults => 'Ništa nije pronađeno.';

  @override
  String get productName => 'Naziv proizvoda';

  @override
  String get productNameHint => 'npr. frižider';

  @override
  String get storeOptional => 'Prodavnica (opciono)';

  @override
  String get noteOptional => 'Napomena (opciono)';

  @override
  String get noteHint => 'npr. serijski broj';

  @override
  String get priceOptional => 'Cena (opciono)';

  @override
  String get invalidAmount => 'Unesi iznos veći od 0';

  @override
  String get purchaseDate => 'Datum kupovine';

  @override
  String get notifyOnExpiry => 'Podseti me pre isteka';

  @override
  String get notifyOnExpiryHint => '30, 10 i 1 dan pre.';

  @override
  String deleteWarrantyQ(String name) {
    return 'Obrisati $name?';
  }

  @override
  String get deleteWarrantyBody =>
      'Garancija, njeni podsetnici i slika računa biće obrisani.';

  @override
  String get receipt => 'Račun';

  @override
  String get addReceipt => 'Dodaj sliku računa';

  @override
  String get receiptHint => 'Da ti je pri ruci kad ideš na reklamaciju.';

  @override
  String get receiptUploading => 'Šaljem sliku...';

  @override
  String get receiptCamera => 'Slikaj';

  @override
  String get receiptGallery => 'Izaberi iz galerije';

  @override
  String get warranty => 'Garancija';

  @override
  String get warrantyMonths => 'Meseci';

  @override
  String get warrantyYears => 'Godine';

  @override
  String get warrantyMonthsRange => 'Od 1 do 120 meseci';

  @override
  String get warrantyYearsRange => 'Od 1 do 30 godina';

  @override
  String warrantyUntil(String date) {
    return 'Garancija do $date';
  }

  @override
  String warrantyExpiredOn(String date) {
    return 'Garancija istekla $date';
  }

  @override
  String get warrantyEndsToday => 'Garancija ističe danas';

  @override
  String warrantyDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Još $count dana',
      few: 'Još $count dana',
      one: 'Još $count dan',
    );
    return '$_temp0';
  }

  @override
  String get notificationsOffTitle => 'Obaveštenja su isključena';

  @override
  String get notificationsOffBody => 'Nećeš dobijati podsetnike za garancije.';

  @override
  String get turnOn => 'Uključi';

  @override
  String get hibernationTitle => 'Neka podsetnici stižu';

  @override
  String get hibernationBody =>
      'Android uspava aplikacije koje mesecima ne otvaraš i tada podsetnici ne stižu. Isključi to za ovu aplikaciju.';

  @override
  String get openSettings => 'Otvori podešavanja';

  @override
  String get notNow => 'Ne sada';

  @override
  String get moreDetails => 'Prodavnica, cena i napomena';

  @override
  String get shareApp => 'Podeli aplikaciju';

  @override
  String get shareAppHint =>
      'Skeniraj kod kamerom drugog telefona ili pošalji link. Android će tražiti dozvolu za instalaciju iz tog izvora.';

  @override
  String get shareAppMessage =>
      'Warranty Manager: sve garancije i računi, na jednom mestu.';

  @override
  String get copyLink => 'Kopiraj link';

  @override
  String get linkCopied => 'Link je kopiran.';

  @override
  String get sendLink => 'Pošalji';
}
