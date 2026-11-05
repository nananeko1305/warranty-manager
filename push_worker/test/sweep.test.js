import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { beforeEach, test } from 'node:test';

import { CursorRejected } from '../src/cloudinary.js';
import { SWEEP_CRON } from '../src/index.js';
import { MIN_AGE_MS, deletable, receiptIds, sweep } from '../src/sweep.js';

const NOW = new Date('2026-11-05T01:10:00Z');
const OLD = new Date(NOW.getTime() - MIN_AGE_MS - 1000).toISOString();
const YOUNG = new Date(NOW.getTime() - MIN_AGE_MS + 60000).toISOString();

const photo = (id, fields = {}) => ({
  public_id: id,
  created_at: OLD,
  asset_folder: 'receipts',
  resource_type: 'image',
  type: 'upload',
  ...fields,
});

/** Stand-ins that remember the order things happened in. */
function world({
  resources = [],
  used = [],
  hasReceipt = true,
  nextCursor = '',
  cursor = '',
  listError = null,
  usedError = null,
  destroyResults = {},
} = {}) {
  const log = [];
  const google = {
    async anyReceipt() {
      log.push('control');
      return hasReceipt;
    },
    async sweepCursor() {
      return cursor;
    },
    async saveSweepCursor(value) {
      log.push(`cursor:${value}`);
    },
    async receiptsInUse(ids) {
      log.push(`used:${ids.join(',')}`);
      if (usedError) throw usedError;
      return new Set(ids.filter((id) => used.includes(id)));
    },
  };
  const cloudinary = {
    configured: true,
    async list(from) {
      log.push(`list:${from}`);
      if (listError) throw listError;
      return { resources, nextCursor };
    },
    async destroy(id) {
      log.push(`destroy:${id}`);
      return destroyResults[id] ?? 'ok';
    },
  };
  return { google, cloudinary, log, destroyed: () => log.filter((l) => l.startsWith('destroy:')) };
}

const run = (w, deleting = true) =>
  sweep(w.google, w.cloudinary, NOW, { deleting });

let printed;
beforeEach(() => {
  printed = [];
  console.log = (message) => printed.push(message);
  console.error = (message) => printed.push(message);
});

test('deletes what nobody uses, and keeps what somebody does', async () => {
  const w = world({
    resources: [photo('orphan'), photo('kept')],
    used: ['kept'],
  });
  await run(w);
  assert.deepEqual(w.destroyed(), ['destroy:orphan']);
});

test('without the switch it deletes nothing, and says what it would', async () => {
  const w = world({ resources: [photo('orphan')] });
  await run(w, false);
  assert.deepEqual(w.destroyed(), []);
  assert.match(printed.join(), /dry run.*1 unused.*orphan/);
});

test('a dry run counts photos too young to go, or it would show nothing', async () => {
  const w = world({ resources: [photo('young', { created_at: YOUNG })] });
  await run(w, false);
  assert.match(printed.join(), /1 unused, 0 would go/);
});

test('a photo still inside the waiting period stays', async () => {
  const w = world({ resources: [photo('young', { created_at: YOUNG })] });
  await run(w);
  assert.deepEqual(w.destroyed(), []);
});

test('finding no warranty with a photo stops everything', async () => {
  // A wrong project or a renamed field would make every photo look unused.
  const w = world({ resources: [photo('orphan')], hasReceipt: false });
  await run(w);
  assert.deepEqual(w.log, ['control']);
  assert.match(printed.join(), /stopped/);
});

test('a failed Firestore query deletes nothing', async () => {
  const w = world({
    resources: [photo('orphan')],
    usedError: new Error('Firestore query answered with an error'),
  });
  await assert.rejects(() => run(w));
  assert.deepEqual(w.destroyed(), []);
});

test('the place is saved before deleting, so a cut-off run moves on', async () => {
  const w = world({ resources: [photo('orphan')], nextCursor: 'next' });
  await run(w);
  const saved = w.log.indexOf('cursor:next');
  const deleted = w.log.indexOf('destroy:orphan');
  assert.ok(saved >= 0 && saved < deleted, w.log.join(' '));
});

test('it carries on from where it stopped', async () => {
  const w = world({ cursor: 'earlier' });
  await run(w);
  assert.ok(w.log.includes('list:earlier'));
});

test('the end of the folder sends it back to the start', async () => {
  const w = world({ resources: [photo('kept')], used: ['kept'], nextCursor: '' });
  await run(w);
  assert.ok(w.log.includes('cursor:'));
});

test('a cursor Cloudinary rejects is cleared, and nothing is deleted', async () => {
  const w = world({ cursor: 'stale', listError: new CursorRejected() });
  await run(w);
  assert.ok(w.log.includes('cursor:'));
  assert.deepEqual(w.destroyed(), []);
});

test('any other failure of the list stops the run', async () => {
  const w = world({ listError: new Error('Cloudinary list failed with 500') });
  await assert.rejects(() => run(w));
  assert.deepEqual(w.destroyed(), []);
});

test('one file that fails does not stop the others', async () => {
  const w = world({
    resources: [photo('a'), photo('b')],
    destroyResults: { a: 'failed' },
  });
  await run(w);
  assert.deepEqual(w.destroyed(), ['destroy:a', 'destroy:b']);
  assert.match(printed.join(), /1 deleted/);
});

test('a run deletes at most ten', async () => {
  const resources = Array.from({ length: 30 }, (_, i) => photo(`p${i}`));
  const w = world({ resources });
  await run(w);
  assert.equal(w.destroyed().length, 10);
});

test('without Cloudinary settings it does nothing at all', async () => {
  const w = world({ resources: [photo('orphan')] });
  w.cloudinary.configured = false;
  await run(w);
  assert.deepEqual(w.log, []);
});

const unknown = {
  'no id': { public_id: undefined },
  'an empty id': { public_id: '' },
  'another folder': { asset_folder: 'avatars' },
  'no folder': { asset_folder: undefined },
  'a video': { resource_type: 'video' },
  'a raw file': { resource_type: 'raw' },
  'a private file': { type: 'private' },
  'no date': { created_at: undefined },
  'a nonsense date': { created_at: 'soon' },
};
for (const [what, fields] of Object.entries(unknown)) {
  test(`${what} is left alone`, () => {
    assert.deepEqual(
      deletable([photo('x', fields)], new Set(), NOW),
      [],
    );
  });
}

test('only proper receipts are checked against the warranties', () => {
  assert.deepEqual(
    receiptIds([photo('a'), photo('b', { resource_type: 'video' })]),
    ['a'],
  );
});

test('the waiting period is measured from the upload', () => {
  assert.deepEqual(deletable([photo('old')], new Set(), NOW), ['old']);
  assert.deepEqual(
    deletable([photo('young', { created_at: YOUNG })], new Set(), NOW),
    [],
  );
});

test('the trigger in wrangler.toml is the one the worker dispatches on', () => {
  const toml = readFileSync(new URL('../wrangler.toml', import.meta.url), 'utf8');
  assert.ok(toml.includes(`"${SWEEP_CRON}"`));
});

test('the switch ships off', () => {
  const toml = readFileSync(new URL('../wrangler.toml', import.meta.url), 'utf8');
  assert.match(toml, /SWEEP_DELETE = "false"/);
});
