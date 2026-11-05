// Deletes receipt photos that no warranty uses any more. That one rule covers
// every way a photo gets left behind: a deleted warranty or account, a replaced
// or removed photo, an abandoned form, junk uploaded through the preset.
//
// A mistake here destroys receipts for good, so anything unclear means keeping
// the photo: every check below fails towards not deleting.

import { CursorRejected, RECEIPTS_FOLDER } from './cloudinary.js';

/**
 * How old an unused photo must be. A warranty can sit queued on a phone with no
 * network after its photo went up, and until it arrives nothing refers to the
 * photo. Age counts from the upload, so a photo of a warranty deleted after years
 * goes the same night.
 */
export const MIN_AGE_MS = 30 * 24 * 60 * 60 * 1000;

// One query's worth, since `in` takes 30. Raise these only after watching the CPU
// time in the dashboard: the free plan allows 10 ms per run.
const PAGE_SIZE = 30;
const MAX_DELETES = 10;

/**
 * Past this many warranties naming these photos, some may have been left out, so
 * all of them count as used.
 */
const IN_USE_LIMIT = 100;

/** Whether [resource] is plainly a receipt that went up in the usual way. */
function isReceipt(resource) {
  return (
    typeof resource.public_id === 'string' &&
    resource.public_id !== '' &&
    resource.asset_folder === RECEIPTS_FOLDER &&
    resource.resource_type === 'image' &&
    resource.type === 'upload'
  );
}

/** Whether [resource] says when it was made, and that was long enough ago. */
function isOldEnough(resource, now) {
  const created = Date.parse(resource.created_at);
  return Number.isFinite(created) && now.getTime() - created > MIN_AGE_MS;
}

/** The ids of the photos on a page that may be considered at all. */
export function receiptIds(resources) {
  return resources.filter(isReceipt).map((r) => r.public_id);
}

/** Those unused and old enough to delete, up to the limit for one run. */
export function deletable(resources, used, now) {
  return resources
    .filter((r) => isReceipt(r) && !used.has(r.public_id))
    .filter((r) => isOldEnough(r, now))
    .map((r) => r.public_id)
    .slice(0, MAX_DELETES);
}

/**
 * One step through the folder. Safe to repeat, and it picks up where the last one
 * stopped. Without [deleting] it only reports what it would delete.
 */
export async function sweep(google, cloudinary, now, { deleting }) {
  if (!cloudinary.configured) {
    console.error('The sweep has no Cloudinary settings');
    return;
  }
  // No warranty with a photo means the wrong project or a renamed field far more
  // often than it means nobody has any photos.
  if (!(await google.anyReceipt())) {
    console.error('The sweep found no warranty with a photo, so it stopped');
    return;
  }

  const cursor = await google.sweepCursor();
  let page;
  try {
    page = await cloudinary.list(cursor, PAGE_SIZE);
  } catch (error) {
    if (!(error instanceof CursorRejected)) throw error;
    await google.saveSweepCursor('');
    return;
  }

  const ids = receiptIds(page.resources);
  const used = await google.receiptsInUse(ids, IN_USE_LIMIT);
  const unused = ids.filter((id) => !used.has(id));
  const gone = deletable(page.resources, used, now);

  // Before deleting: a run cut short must not stay stuck on the same page.
  await google.saveSweepCursor(page.nextCursor);

  if (!deleting) {
    // Ignores age on purpose, since at first nothing is old enough to show.
    console.log(
      `Sweep dry run: ${page.resources.length} looked at, ${ids.length} receipts, ` +
        `${unused.length} unused, ${gone.length} would go [${gone.join(', ')}]`,
    );
    return;
  }
  const results = await Promise.all(
    gone.map((id) => cloudinary.destroy(id, now)),
  );
  const deleted = results.filter((r) => r === 'ok').length;
  console.log(
    `Sweep: ${page.resources.length} looked at, ${unused.length} unused, ` +
      `${deleted} deleted`,
  );
}
