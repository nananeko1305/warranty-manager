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
  hard to guess. Deleting a warranty offline leaves its photo on Cloudinary (see
  below). The preset also ships in the APK, so capping formats in the preset is the
  only brake on someone uploading through it.
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
| `meta/sweep`        | `cursor`, where the sweep got to, if it is ever switched on; only the worker touches it |

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
sending and holds the key. A cron trigger starts every reminder; nothing outside can.

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

Deleting a photo takes the API secret, which cannot ship in an APK. So when someone
deletes a warranty, replaces or removes its photo, or deletes their account, the app
first asks the worker (`POST /release-receipt`) to delete the photo, and then writes
the change. The app is what starts it; nothing is deleted by itself.

Anyone can open an account, so a valid sign-in proves little. The route takes only a
warranty id. The photo comes off that warranty, never from the request, the warranty
must be the caller's, and a photo another warranty also names stays, since the rules
let anyone put any Cloudinary link on their own warranty.

An edit writes the photo only if it changed, or an edit queued on one phone could put
back a photo replaced on another.

**What stays behind:** a warranty deleted with no network loses its photo reference
without the photo going, and so does a form abandoned after a photo went up. Nothing
cleans these up for now.

**The nightly sweep** in `push_worker/src/sweep.js` would clean them up, and is switched
off on purpose: `wrangler.toml` has no trigger for it, and `SWEEP_DELETE` is `"false"`.
It deletes photos no warranty refers to once they are over 30 days old, counted from
the upload, because a warranty can sit queued on a phone after its photo went up. To
turn it on, add `SWEEP_CRON` from `src/index.js` to the triggers, run it with the
switch off and read the log, and then set `SWEEP_DELETE` to `"true"`. A mistake there
destroys receipts for good, so every check in it fails towards keeping the photo.

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
trigger is refused (code 10063). The account now has one, `warranty-manager-push`,
made through the API.

## Release

Every push to `main` runs [release-apk.yml](.github/workflows/release-apk.yml):
analyze → test → signed release APK → GitHub Release → download page and
`version.json` on GitHub Pages (<https://nananeko1305.github.io/warranty-manager/>)
→ a push to the `releases` topic. The page has the download button, a Share button
and a QR code; installed apps find new versions through `version.json`, so it has to
keep being published. Day-to-day work goes to `dev`; merge into `main` to ship. A
merge that only changes the page (`.github/pages/`) does not release: `pages.yml`
redeploys the page for the current APK.

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
