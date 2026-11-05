# Warranty Manager

Android app (Flutter + Firebase) for keeping warranties with a photo of the
receipt, and being reminded before they end. English UI with Serbian
localization.

Firebase project: `warranty-manager-261105-b5f9a` (Firestore in `eur3`).

## What it does

- **Accounts** are open: anyone can sign up with an email and a password, and
  sees only their own warranties. An account can be on several phones, and all of
  them get its reminders. It can be deleted in Settings.
- **A warranty** needs only a name. The date is today and the duration two years
  until someone says otherwise; store, price and note are optional. Durations run
  to 120 months or 30 years.
- **Valid and Expired** are worked out from the dates, so nobody files anything
  away. Valid is sorted soonest to end first, Expired most recently ended first.
  Search covers the name and the store, and ignores Serbian diacritics.
- **Receipts** are photographed in the app and stored on Cloudinary, not in
  Firebase. The cloud and preset names are build inputs
  (`--dart-define=CLOUDINARY_CLOUD=…`, `--dart-define=CLOUDINARY_PRESET=…`, set as
  repository secrets); a build without them simply hides the receipt controls.
- **Reminders** go out 30, 10 and 1 day before a warranty ends, unless switched
  off on that warranty.
- **Sharing the app** (Settings): a QR code, and the link to copy or send. It always
  points at the newest APK, so a code already handed out does not go stale.

### What it does not promise

- A receipt photo can be opened by anyone who has its link, which is random and
  hard to guess. After a warranty or an account is deleted, the photo stays on
  Cloudinary until the nightly sweep takes it, up to about a month later (see below).
  The preset also ships in the APK, so capping formats in the preset is the only
  brake on someone uploading through it; what they upload goes in the sweep.
- A reminder cannot reach a phone without Google Play services, or an app that
  Android has hibernated or that was force-stopped, and FCM reports those as
  delivered. The home screen warns about what the app can detect.
- Signing out offline leaves the phone tied to the account until the next time
  that account signs in there.
- Open sign-up on the Spark plan means abuse can use up the daily quota. That is
  an outage, not a bill, since there is no card on the project.

## Data model

| Collection          | Fields |
|---------------------|--------|
| `warranties/{id}`   | `ownerId`, `name`, `store`, `note`, `purchaseDate`, `endsOn`, `warrantyAmount`, `warrantyUnit` (`months`/`years`), `amountMinor`, `currency` (`RSD`/`EUR`), `receiptUrl`, `receiptId`, `notify`, `createdAt`, `updatedAt`, `remindersSent` (worker only) |
| `pushTokens/{token}` | `uid` of the account the phone belongs to |
| `meta/sweep`        | `cursor`, where the sweep got to; only the worker touches it |

`purchaseDate` and `endsOn` are `yyyy-MM-dd` text, because a calendar date is not
an instant: a midnight timestamp reads as the day before further west. `endsOn`
mirrors the date computed from the purchase date and the duration, so the worker
can query it; the app always recomputes it. `receiptId` is the Cloudinary id inside
`receiptUrl`, and the rules refuse a warranty where the two disagree. Amounts are stored in minor units
(para / cents) as integers. All access rules live in
[firestore.rules](firestore.rules).

## Reminders

Cloud Functions need the Blaze plan, and a service account key cannot ship in a
public APK, so a small [Cloudflare Worker](push_worker) on the free plan does the
sending and holds the key. It has no address and no HTTP routes: a cron trigger is
the only way in.

1. The app registers each phone's FCM token in `pushTokens/{token}`.
2. The trigger fires every 30 minutes from 08:00 to 12:30 UTC, which is the morning
   in Belgrade all year.
3. Each run finds warranties ending on any of the eight days a reminder can fall
   on: 30, 10 or 1 days from now, plus two days of catch-up for the first two and
   one for the last, so that an outage only delays a reminder.
4. It leaves out those with reminders off, those already sent, and those entered in
   the last 12 hours. A reminder is sent once per warranty and threshold, recorded
   in `remindersSent` as `endsOn:threshold`. The date is in the key, so moving it
   arms the reminders again.
5. It sends the most urgent first, up to 20 messages per run and 5 reminders per
   account; the free plan allows 50 outside calls and 10 ms of CPU. What does not
   fit goes out in the next run.
6. It then records what went out, and removes dead tokens, in one `:batchWrite`.

A reminder is marked after sending, once any phone has it. If a run dies in
between, the reminder goes out again, which is better than never: a repeat replaces
the earlier notification, since the warranty id is its `tag`.

## Receipt photos

Deleting a photo takes the API secret, which cannot ship in an APK, so the worker
does it at night: it deletes photos in the `receipts` folder that no warranty refers
to. That one rule covers a deleted warranty or account, a replaced or removed photo,
an abandoned form, and junk uploaded through the preset. There is no route, so
nothing new can be attacked.

A photo goes once it is **unused and over 30 days old**, counted from the upload. A
warranty deleted after years loses its photo that night; one added and deleted at
once keeps it for up to a month. The wait is for a warranty queued on a phone with no
network after its photo went up: until it arrives, nothing refers to the photo. It
has no strict bound: a save that waits longer than that loses its photo.

A mistake here destroys receipts for good, so every check fails towards keeping:

- **An edit writes the photo only if it changed**, or an edit queued on one phone could
  restore a photo replaced on another.
- **`receiptId` must match the link** in the rules, and `ReceiptUpload.uploadedUrl`
  refuses an upload whose link does not give Cloudinary's `public_id`.
- **A failed or partial answer stops the run.** So does a warranty that was not asked
  for. A full result counts every photo in the query as used, since thousands of
  warranties can name one photo and crowd out someone else's.
- **Each run first finds a warranty with a photo**, or it stops: a wrong project or a
  renamed field would make every photo look unused.
- **Only plain receipts qualify:** `receipts` folder, `image`, `upload`, a readable date.
- **`SWEEP_DELETE`** in `wrangler.toml`: anything but `"true"` only logs what it would
  delete. Set it to `"false"` and deploy to stop deleting at once.
- **At most 30 photos looked at and 10 deleted per run,** seven runs a night. Raise them
  only after watching the CPU time.

### Deploying the worker

The worker runs on its own Cloudflare account, so the credentials live in a
gitignored `push_worker/.env` and the global `wrangler login` used elsewhere stays
as it is:

```sh
CLOUDFLARE_API_TOKEN=…    # template "Edit Cloudflare Workers"
CLOUDFLARE_ACCOUNT_ID=…
```

The service account `push-worker` has only `roles/datastore.user` and
`roles/firebasecloudmessaging.admin` (Firebase Cloud Messaging **API** Admin; the
similarly named Firebase Cloud Messaging Admin cannot send), and its key lives only
in Cloudflare:

```sh
cd push_worker
npm ci
npm test
npm run secret < key.json   # then delete key.json
# CLOUDINARY_CLOUD, CLOUDINARY_API_KEY and CLOUDINARY_API_SECRET: wrangler secret put
npm run deploy
npm run tail                # watch the logs
```

A new Cloudflare account has no `workers.dev` subdomain, and without one the cron
trigger is refused (code 10063), even though this worker has no address on it. The
account now has one, `warranty-manager-push`, made through the API.

## Release

Every push to `main` runs [release-apk.yml](.github/workflows/release-apk.yml):
analyze → test → signed release APK → GitHub Release → `version.json` on GitHub
Pages → a push to the `releases` topic. There is no download page: installed apps
find new versions through that file, so it has to keep being published. Day-to-day
work goes to `dev`; merge into `main` to ship.

Versions are `major.minor.patch`, worked out in CI from the commit messages since
the last tag: a `feat` bumps the minor, anything else the patch, and a breaking
change the major. The version in `pubspec.yaml` is a floor. Android's version code
is the workflow run number.

Repository secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `CLOUDINARY_CLOUD`,
`CLOUDINARY_PRESET`, `FCM_SERVICE_ACCOUNT` (a service account with only
`roles/firebasecloudmessaging.admin`). Without the signing secrets the build falls
back to debug signing, and installs then can't be updated in place. Keep a backup
of the keystore: losing it means users must uninstall to get new versions.

## Commands

```sh
flutter run --dart-define-from-file=dart_defines.json   # gitignored
flutter analyze && flutter test
cd push_worker && npm test                              # with fakes
cd rules_test && npm install && npm test                # rules and worker, on the emulator
firebase deploy --only firestore                        # rules + indexes
flutter gen-l10n                                        # after editing lib/l10n/*.arb
```
