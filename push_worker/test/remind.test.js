import assert from 'node:assert/strict';
import { beforeEach, test } from 'node:test';

import { remind } from '../src/index.js';
import { addDays } from '../src/due.js';
import worker from '../src/index.js';

const TODAY = '2026-11-05';
const NOW = new Date('2026-11-05T09:00:00Z');

/** Stands in for Google, remembering what was asked of it. */
function fakeGoogle({ warranties = [], tokens = [], results = {} } = {}) {
  const calls = { sends: [], records: [], tokenQueries: [], days: null };
  return {
    calls,
    failRecords: 0,
    async warrantiesEndingOn(days) {
      calls.days = days;
      return warranties;
    },
    async tokensOf(uids) {
      calls.tokenQueries.push(uids);
      return tokens.filter((t) => uids.includes(t.uid));
    },
    async send(token, message) {
      calls.sends.push({ token, message });
      return results[token] ?? 'sent';
    },
    async record(sent, stale) {
      if (this.failRecords-- > 0) throw new Error('Firestore said no');
      calls.records.push({ sent, stale });
    },
  };
}

const warranty = (id, ownerId = 'u1', daysLeft = 10) => ({
  id,
  ownerId,
  name: id,
  endsOn: addDays(TODAY, daysLeft),
  notify: true,
  createdAt: '2026-01-01T00:00:00Z',
});

let errors;
beforeEach(() => {
  errors = [];
  console.error = (message) => errors.push(message);
});

test('asks only for the days a reminder can fall on', async () => {
  const google = fakeGoogle();
  await remind(google, NOW);
  assert.equal(google.calls.days.length, 8);
});

test('with nothing due it sends and writes nothing', async () => {
  const google = fakeGoogle();
  await remind(google, NOW);
  assert.deepEqual(google.calls.sends, []);
  assert.deepEqual(google.calls.records, []);
  assert.deepEqual(google.calls.tokenQueries, []);
});

test('sends a reminder and then marks it', async () => {
  const google = fakeGoogle({
    warranties: [warranty('a')],
    tokens: [{ id: 'p1', uid: 'u1' }],
  });
  await remind(google, NOW);
  assert.equal(google.calls.sends.length, 1);
  assert.equal(google.calls.sends[0].token, 'p1');
  assert.deepEqual(google.calls.records, [
    { sent: [{ id: 'a', key: `${addDays(TODAY, 10)}:10` }], stale: [] },
  ]);
});

test('a second run after the marks sends nothing', async () => {
  const w = warranty('a');
  const first = fakeGoogle({ warranties: [w], tokens: [{ id: 'p', uid: 'u1' }] });
  await remind(first, NOW);
  const marked = { ...w, remindersSent: [first.calls.records[0].sent[0].key] };
  const second = fakeGoogle({
    warranties: [marked],
    tokens: [{ id: 'p', uid: 'u1' }],
  });
  await remind(second, NOW);
  assert.deepEqual(second.calls.sends, []);
});

test('a failed send stays unmarked, for the next run', async () => {
  const google = fakeGoogle({
    warranties: [warranty('a')],
    tokens: [{ id: 'p', uid: 'u1' }],
    results: { p: 'failed' },
  });
  await remind(google, NOW);
  assert.deepEqual(google.calls.records[0].sent, []);
});

test('a dead token is removed', async () => {
  const google = fakeGoogle({
    warranties: [warranty('a')],
    tokens: [{ id: 'dead', uid: 'u1' }],
    results: { dead: 'unregistered' },
  });
  await remind(google, NOW);
  assert.deepEqual(google.calls.records[0].stale, ['dead']);
});

test('a run sends at most its budget, from one query for the phones', async () => {
  const warranties = Array.from({ length: 40 }, (_, i) =>
    warranty(`w${i}`, `u${i}`),
  );
  const tokens = warranties.map((w) => ({ id: `p-${w.id}`, uid: w.ownerId }));
  const google = fakeGoogle({ warranties, tokens });
  await remind(google, NOW);
  assert.equal(google.calls.sends.length, 20);
  assert.equal(google.calls.tokenQueries.length, 1);
  assert.ok(google.calls.tokenQueries[0].length <= 30);
});

test('what a run could not fit goes out in the next', async () => {
  const warranties = Array.from({ length: 25 }, (_, i) =>
    warranty(`w${i}`, `u${i}`),
  );
  const tokens = warranties.map((w) => ({ id: `p-${w.id}`, uid: w.ownerId }));
  const first = fakeGoogle({ warranties, tokens });
  await remind(first, NOW);
  const sentKeys = new Map(
    first.calls.records[0].sent.map((s) => [s.id, s.key]),
  );
  const after = warranties.map((w) =>
    sentKeys.has(w.id) ? { ...w, remindersSent: [sentKeys.get(w.id)] } : w,
  );
  const second = fakeGoogle({ warranties: after, tokens });
  await remind(second, NOW);
  assert.equal(second.calls.sends.length, 5);
});

test('an account with a pile of warranties does not crowd out the others', async () => {
  const pile = Array.from({ length: 30 }, (_, i) => warranty(`w${i}`, 'greedy', 1));
  const google = fakeGoogle({
    warranties: [...pile, warranty('other', 'u2', 30)],
    tokens: [
      { id: 'g', uid: 'greedy' },
      { id: 'p', uid: 'u2' },
    ],
  });
  await remind(google, NOW);
  const tokens = google.calls.sends.map((s) => s.token);
  assert.equal(tokens.filter((t) => t === 'g').length, 5);
  assert.ok(tokens.includes('p'));
});

test('a failed record gets one more try', async () => {
  const google = fakeGoogle({
    warranties: [warranty('a')],
    tokens: [{ id: 'p', uid: 'u1' }],
  });
  google.failRecords = 1;
  await remind(google, NOW);
  assert.equal(google.calls.records.length, 1);
  assert.equal(google.calls.sends.length, 1);
});

test('a log never carries what the warranty is', async () => {
  const google = fakeGoogle({
    warranties: [warranty('Tajni frižider')],
    tokens: [{ id: 'p', uid: 'u1' }],
  });
  google.failRecords = 1;
  await remind(google, NOW);
  assert.equal(errors.some((e) => e.includes('Tajni')), false);
});

test('the worker answers nothing over HTTP', () => {
  assert.equal(worker.fetch().status, 404);
});
