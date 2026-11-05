# Warranty Manager: architecture map

Android-only Flutter app that keeps warranties with a photo of the receipt and
reminds before they end. Anyone can sign up; each account sees only its own.

The README below is imported and holds the product rules, the data model, the
reminder design and the release process. This file adds what the README does not:
how the code fits together, and what breaks if you forget it.

@README.md

The global guidelines about Go layout and Neutrino libraries do not apply here:
there is no Go in this repository.

**Keep this true:** a change that alters anything below updates this file in the
same commit. Do not add version numbers, line counts or lists of every file; they
go stale. The repository is **public**, so nothing secret goes here.

## System

```
                     ┌─ Firebase Auth      email/password, open sign-up
 Android app ────────┼─ Firestore          direct from the app, offline cache on
 (Flutter)           ├─ Cloudinary         receipt photos, unsigned preset
                     ├─ Push worker        POST /release-receipt, deletes a photo
                     ├─ GitHub Pages       version.json, the update check
                     └─ FCM                receives pushes

 Push worker ────────┬─ Firestore REST     service account, bypasses the rules
 (Cloudflare, cron)  ├─ FCM v1             per-phone reminders, in the morning
                     └─ Cloudinary         deletes a photo when the app asks

 GitHub Actions ─────┬─ GitHub Release     the APK
 (push to main)      ├─ GitHub Pages       version.json
                     └─ FCM topic          `releases`, every install
```

There is no backend of our own. The app talks to Firestore directly, so
**`firestore.rules` is the security boundary** for everything the app does, and
open sign-up means it has to hold against anyone: test changes in `rules_test/`.
The worker uses a service account, which skips those rules, so **its own checks in
`push_worker/src/receipts.js` are the only boundary on its one route**: the photo comes
off the warranty, never from the request, the warranty must be the caller's, and a
photo another warranty names stays.

## Code map

Start-up: `main.dart` → `AuthGate` (signed in?) → `HomeScreen`. `AuthGate` keys
`HomeScreen` by uid, so switching accounts resets all state below it.

| Path | Holds |
|---|---|
| `lib/models/` | `Warranty` with `fromDoc`/`toMap`, and the pure logic: `warranty_dates`, `warranty_list` (sorting, search), `WarrantyDraft` |
| `lib/money/` | `Currency`, parsing and formatting of amounts |
| `lib/services/` | Singleton repositories (`XRepository.instance`), `LiveData`, push, auth, account deletion, updates, receipts (`ReceiptCleanup` asks the worker to delete one), `ReminderHealth` |
| `lib/screens/` | Full screens |
| `lib/widgets/` | Reusable pieces, dialogs and form fields |
| `lib/l10n/` | `app_en.arb` (template) and `app_sr.arb`; the generated Dart is committed. `kSupportedLocales` is in `locale_controller.dart` |
| `lib/theme/` | The palette in `AppColors` and `context.colors`; use these, not hard-coded colors |
| `push_worker/src/` | `index.js` the route, the cron dispatch and the reminder run, `receipts.js` the route's checks, `due.js` what is due (pure), `message.js` text and dates (pure), `cloudinary.js` listing and deleting, `sweep.js` the sweep, switched off, `google.js` Firestore and FCM calls |
| `rules_test/` | The rules, and with `push_worker/emulator/` the worker, against the emulator |
| `android/app/src/main/` | `MainActivity.kt` creates notification channels and answers `ReminderHealth`; `res/values*/strings.xml` holds push titles |

## How the app works

- **Reads go through `LiveData`.** `HomeScreen` owns one per session. It resubscribes
  with backoff, because a Firestore listener that errors never recovers.
- **Queries filter on `ownerId`**, because the rules refuse any other, and sort on
  the client, which is why `firestore.indexes.json` is empty. Adding `.orderBy` would
  need a composite index.
- **Writes go through `saveInBackground`; do not await a Firestore write in UI.** The
  future does not complete offline. The screen closes at once, `SyncBanner` shows
  progress, and a failure surfaces as a snackbar. The one exception is
  `AccountDeletion`, which cannot be finished later.
- **Serbian is `sr-Latn`, never plain `sr`.** Plain `sr` means Cyrillic to the date
  and number formats and to the date picker, in a Latin interface.
- **Dates are `yyyy-MM-dd` text in Firestore** (`dateKey`, `parseDateKey`). The worker
  compares them as text, in Belgrade days.
- **A photo goes before the write that drops it** (`WarrantyRepository`), because the
  worker reads it off the warranty as it stands. Failing to reach the worker must not
  stop the write. **`receiptId` mirrors `receiptUrl`** (`receiptIdOf`, and the same rule
  in `firestore.rules`), and **edits go through `toEditMap`**, which leaves the photo out
  unless it changed.
- **Money is an `int` in minor units.**
- **User-visible text goes through `AppLocalizations`**, in both `.arb` files, then
  `flutter gen-l10n`. Errors go through `errorText`.
- **Sign-out order matters** (`AuthService.signOut`): delete the token document, which
  needs the sign-in; sign out; then delete the FCM token, since FCM may mint the next
  one at once and with nobody signed in `_saveToken` ignores it.

## What a change has to touch

**New field on a warranty:** the rules (`editableFields`, `validWarranty`), `Warranty`
and `WarrantyDraft`, the README data model, and `rules_test/`. Old documents and old
APKs both exist, so `fromDoc` tolerates its absence, and the rules, which require
every key on create, need `d.get('field', default)`. Deploy the rules first.

**New push type:** `message.js`; the title in `res/values/strings.xml` and
`res/values-sr/strings.xml`; `res/raw/keep.xml`, or resource shrinking drops it and
the notification arrives empty; the key list in the CI step "Verify notification
strings"; and `ReminderPush.fromData` for the foreground snackbar and the tap. A new
channel also goes in `MainActivity.kt`.

**New way to drop a photo reference:** call `ReceiptCleanup.release` first, or the
photo stays on Cloudinary. A new way to store one: the sweep has to know it, or every
photo referred to only that way looks unused.

**Worker reads a new field:** add it to `select` in `warrantiesEndingOn`, and teach
`decodeValue` its type if it is new: it reads strings, booleans, timestamps and
arrays, and anything else comes back as null.

## Worker pitfalls

- **The sweep is off on purpose:** photos go when someone deletes them, not by
  themselves. It destroys receipts for good if it is wrong, so keep it failing towards
  keeping the photo, and run it with `SWEEP_DELETE = "false"` first. The README says how
  to turn it on.

- **`:batchWrite` takes one write per document**, and can answer 200 with every write
  failed, so `outcome` dedupes tokens and `record` reads each `status`.
- **A mark needs `currentDocument: {exists: true}`**, or it brings a warranty deleted
  during the run back as a document holding nothing but the marks.
- **`INVALID_ARGUMENT` deletes a token only when it names `message.token`.** A badly
  built message comes back the same way, and must not cost everyone their phones.
- **`data` and `title_loc_args` must be strings.** Android titles use `%1$s` for the
  same reason.
- **Raise `MAX_MESSAGES` only after watching CPU time:** 10 ms per run on the free
  plan.

## Shipping

| Piece | Deployed by | When |
|---|---|---|
| App | CI, on any push to `main` | Merging is the release |
| `firestore.rules` | Hand: `firebase deploy --only firestore:rules` | **Before** the merge that needs it |
| Push worker | Hand: `npm run deploy` from `push_worker/` | **Before** the merge that needs it |

- **`firebase deploy` creates a missing database**, in `firestore.location` from
  `firebase.json`, or in the US (`nam5`) without it. A location cannot be changed, so
  keep that key. Email/Password sign-in is switched on from the same file
  (`firebase deploy --only auth`).
- Work goes on `dev`; merging into `main` ships.
- **Every merge into `main` reaches every phone.** The workflow has no path filter,
  so even a docs-only merge builds an APK and notifies everyone.
- **The commit type sets the version:** `feat` bumps the minor, anything else the
  patch, a breaking change the major. Use Conventional Commits with a scope.
- **This project has its own accounts.** Firebase: `firebase login:use` is set per
  directory. Cloudflare: `push_worker/.env`, loaded by the npm scripts; a bare
  `wrangler` would use the global login, which is another account.

## Testing

```sh
flutter analyze && flutter test       # the same gate CI runs before a release
cd push_worker && npm test            # node --test, with fakes
cd rules_test && npm test             # rules and worker, on the Firestore emulator
```

Run the emulator tests for any change to the rules or to `google.js`. The fakes do
not prove Firestore behaves that way, and the emulator found what they cannot:
decoding, `select`, `appendMissingElements`, `:batchWrite`. `run.sh` starts the jar
directly, because firebase-tools refuses Java before 21, and uses port 18080.

There is no fake Firestore, and repositories bind `FirebaseFirestore.instance` when
created, so tests cannot construct them. Put logic worth testing in `models/`, or
take dependencies as arguments, as `LiveData` does.
