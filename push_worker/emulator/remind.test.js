// Real Firestore behaviour, which the fakes in test/ cannot prove: the query, the
// decoding of what comes back, and what :batchWrite does. FCM stays stubbed.
import assert from 'node:assert/strict';
import { beforeEach, test } from 'node:test';

import { addDays } from '../src/due.js';
import { Google } from '../src/google.js';
import { remind } from '../src/index.js';

const PROJECT = 'demo-warranty-manager';
const HOST = process.env.FIRESTORE_EMULATOR_HOST;
assert.ok(HOST, 'Run through `npm test` in rules_test/');

const BASE = `http://${HOST}/v1`;
const ROOT = `${BASE}/projects/${PROJECT}/databases/(default)/documents`;
const ADMIN = {
  // The emulator lets this token past the rules.
  Authorization: 'Bearer owner',
  'Content-Type': 'application/json',
};

const NOW = new Date('2026-11-05T09:00:00Z');
const TODAY = '2026-11-05';

function encode(value) {
  if (typeof value === 'boolean') return { booleanValue: value };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(encode) } };
  }
  return { stringValue: value };
}

async function put(path, data) {
  const fields = Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, encode(v)]),
  );
  const response = await fetch(`${ROOT}/${path}`, {
    method: 'PATCH',
    headers: ADMIN,
    body: JSON.stringify({ fields }),
  });
  assert.equal(response.status, 200, await response.clone().text());
}

async function get(path) {
  const response = await fetch(`${ROOT}/${path}`, { headers: ADMIN });
  return response.status === 200 ? response.json() : null;
}

const del = (path) =>
  fetch(`${ROOT}/${path}`, { method: 'DELETE', headers: ADMIN });

const seedWarranty = (id, daysLeft, extra = {}) =>
  put(`warranties/${id}`, {
    ownerId: 'alice',
    name: id,
    endsOn: addDays(TODAY, daysLeft),
    notify: true,
    secretNote: 'not selected',
    createdAt: new Date('2026-01-01T00:00:00Z'),
    ...extra,
  });

/** A client on the emulator that records messages instead of sending them. */
function client(results = {}, onSend = () => {}) {
  const google = new Google(PROJECT, 'owner', BASE);
  google.sent = [];
  google.send = async (token, message) => {
    google.sent.push({ token, message });
    await onSend(token, message);
    return results[token] ?? 'sent';
  };
  return google;
}

const marksOf = async (id) => {
  const document = await get(`warranties/${id}`);
  return (document?.fields.remindersSent?.arrayValue.values ?? []).map(
    (v) => v.stringValue,
  );
};

beforeEach(async () => {
  const response = await fetch(
    `http://${HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  assert.equal(response.status, 200);
  await put('pushTokens/phone1', { uid: 'alice' });
});

test('the query finds what is due, and only that', async () => {
  await seedWarranty('due10', 10);
  await seedWarranty('due1', 1);
  await seedWarranty('notDue', 15);
  await seedWarranty('past', -1);
  const found = await client().warrantiesEndingOn(
    [addDays(TODAY, 10), addDays(TODAY, 1)],
    300,
  );
  assert.deepEqual(found.map((w) => w.id).sort(), ['due1', 'due10']);
});

test('`select` brings only what a reminder needs', async () => {
  await seedWarranty('a', 10);
  const [found] = await client().warrantiesEndingOn([addDays(TODAY, 10)], 300);
  assert.equal(found.name, 'a');
  assert.equal(found.notify, true);
  assert.equal(found.createdAt, '2026-01-01T00:00:00Z');
  assert.equal('secretNote' in found, false);
});

test('`limit` holds', async () => {
  await seedWarranty('a', 10);
  await seedWarranty('b', 10);
  const found = await client().warrantiesEndingOn([addDays(TODAY, 10)], 1);
  assert.equal(found.length, 1);
});

test('remindersSent comes back as an array, even an empty one', async () => {
  // Regression guard: read as null, every reminder would look unsent and go out
  // again every 30 minutes.
  await seedWarranty('none', 10);
  await seedWarranty('empty', 10, { remindersSent: [] });
  await seedWarranty('some', 10, { remindersSent: ['x', 'y'] });
  const found = await client().warrantiesEndingOn([addDays(TODAY, 10)], 300);
  const byId = Object.fromEntries(found.map((w) => [w.id, w.remindersSent]));
  assert.equal(byId.none, undefined);
  assert.deepEqual(byId.empty, []);
  assert.deepEqual(byId.some, ['x', 'y']);
});

test('tokensOf finds the phones of those accounts only', async () => {
  await put('pushTokens/phone2', { uid: 'alice' });
  await put('pushTokens/other', { uid: 'bob' });
  const found = await client().tokensOf(['alice']);
  assert.deepEqual(found.map((t) => t.id).sort(), ['phone1', 'phone2']);
});

test('a whole run sends once, marks, and sends nothing the second time', async () => {
  await seedWarranty('a', 10);
  const first = client();
  await remind(first, NOW);
  assert.equal(first.sent.length, 1);
  assert.equal(first.sent[0].token, 'phone1');
  assert.deepEqual(await marksOf('a'), [`${addDays(TODAY, 10)}:10`]);

  const second = client();
  await remind(second, NOW);
  assert.deepEqual(second.sent, []);
});

test('a mark leaves the rest of the warranty alone', async () => {
  await seedWarranty('a', 10);
  await remind(client(), NOW);
  const { fields } = await get('warranties/a');
  assert.equal(fields.name.stringValue, 'a');
  assert.equal(fields.notify.booleanValue, true);
});

test('marks add up over the life of a warranty', async () => {
  const endsOn = addDays(TODAY, 10);
  await seedWarranty('a', 10, { remindersSent: [`${endsOn}:30`] });
  await remind(client(), NOW);
  assert.deepEqual(await marksOf('a'), [`${endsOn}:30`, `${endsOn}:10`]);
});

test('moving the end date sends again', async () => {
  await seedWarranty('a', 10);
  await remind(client(), NOW);
  await put('warranties/a', {
    ownerId: 'alice',
    name: 'a',
    endsOn: addDays(TODAY, 9),
    notify: true,
    remindersSent: [`${addDays(TODAY, 10)}:10`],
    createdAt: new Date('2026-01-01T00:00:00Z'),
  });
  const after = client();
  await remind(after, NOW);
  assert.equal(after.sent.length, 1);
});

test('a warranty deleted during the run stays deleted', async () => {
  // Regression guard: a transform without the precondition would bring it back
  // as a document holding nothing but the marks. The others keep their marks.
  await seedWarranty('gone', 1);
  await seedWarranty('kept', 10);
  const google = client({}, (_, message) =>
    message.data.warrantyId === 'gone' ? del('warranties/gone') : null,
  );
  await remind(google, NOW);
  assert.equal(google.sent.length, 2);
  assert.equal(await get('warranties/gone'), null);
  assert.equal((await marksOf('kept')).length, 1);
});

test('a dead token goes, and its reminder stays unmarked', async () => {
  await seedWarranty('a', 10);
  await seedWarranty('b', 10);
  // Dead for both reminders: :batchWrite takes one write per document.
  const google = client({ phone1: 'unregistered' });
  await remind(google, NOW);
  assert.equal(google.sent.length, 2);
  assert.equal(await get('pushTokens/phone1'), null);
  assert.deepEqual(await marksOf('a'), []);
});

test('a fresh warranty and one with reminders off get nothing', async () => {
  await seedWarranty('fresh', 10, { createdAt: new Date('2026-11-05T08:30:00Z') });
  await seedWarranty('off', 10, { notify: false });
  const google = client();
  await remind(google, NOW);
  assert.deepEqual(google.sent, []);
});
