import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  addDays,
  candidateDays,
  capPerOwner,
  daysBetween,
  dueReminders,
  outcome,
  planSends,
  reminderKey,
  thresholdFor,
} from '../src/due.js';

const TODAY = '2026-11-05';
const NOW = new Date('2026-11-05T09:00:00Z');
const LONG_AGO = '2026-01-01T00:00:00Z';

const warranty = (fields = {}) => ({
  id: 'w1',
  ownerId: 'u1',
  name: 'Frižider',
  endsOn: addDays(TODAY, 10),
  notify: true,
  createdAt: LONG_AGO,
  ...fields,
});

test('adds days across the end of a month and a year', () => {
  assert.equal(addDays('2026-01-31', 1), '2026-02-01');
  assert.equal(addDays('2026-12-31', 1), '2027-01-01');
  assert.equal(addDays('2028-02-28', 1), '2028-02-29');
  assert.equal(addDays('2026-03-01', -1), '2026-02-28');
});

test('counts days across the clock changes in Belgrade', () => {
  // A local day is 23 hours long at the end of March and 25 at the end of
  // October, which must not move the count.
  assert.equal(daysBetween('2026-03-28', '2026-03-30'), 2);
  assert.equal(daysBetween('2026-10-24', '2026-10-26'), 2);
  assert.equal(daysBetween('2026-11-05', '2026-11-05'), 0);
  assert.equal(daysBetween('2026-11-05', '2026-11-04'), -1);
});

test('adding and counting agree over a whole year', () => {
  for (let i = -370; i <= 370; i++) {
    assert.equal(daysBetween(TODAY, addDays(TODAY, i)), i);
  }
});

test('a threshold covers its day and the catch-up days after it', () => {
  const expected = new Map([
    [31, null],
    [30, 30],
    [29, 30],
    [28, 30],
    [27, null],
    [11, null],
    [10, 10],
    [9, 10],
    [8, 10],
    [7, null],
    [2, null],
    [1, 1],
    [0, 1],
    [-1, null],
  ]);
  for (const [days, threshold] of expected) {
    assert.equal(thresholdFor(days), threshold, `${days} days left`);
  }
});

test('candidate days are the ones with a threshold, within what `in` takes', () => {
  const days = candidateDays(TODAY);
  assert.ok(days.length <= 30);
  assert.deepEqual(
    days.map((day) => daysBetween(TODAY, day)),
    [0, 1, 8, 9, 10, 28, 29, 30],
  );
  for (const day of days) {
    assert.notEqual(thresholdFor(daysBetween(TODAY, day)), null);
  }
});

test('a warranty on its day is due, with its key', () => {
  const [due] = dueReminders([warranty()], TODAY, NOW);
  assert.equal(due.daysLeft, 10);
  assert.equal(due.key, `${addDays(TODAY, 10)}:10`);
});

test('one already sent is not due again', () => {
  const endsOn = addDays(TODAY, 10);
  const sent = warranty({ endsOn, remindersSent: [reminderKey(endsOn, 10)] });
  assert.deepEqual(dueReminders([sent], TODAY, NOW), []);
});

test('the catch-up days do not repeat a reminder that went out', () => {
  const endsOn = addDays(TODAY, 9);
  const sent = warranty({ endsOn, remindersSent: [reminderKey(endsOn, 10)] });
  assert.deepEqual(dueReminders([sent], TODAY, NOW), []);
});

test('an outage only delays a reminder', () => {
  const [due] = dueReminders(
    [warranty({ endsOn: addDays(TODAY, 8) })],
    TODAY,
    NOW,
  );
  assert.equal(due.daysLeft, 8);
  assert.equal(due.key.endsWith(':10'), true);
});

test('moving the end date arms the reminders again', () => {
  const old = addDays(TODAY, 40);
  const moved = warranty({
    endsOn: addDays(TODAY, 10),
    remindersSent: [reminderKey(old, 30), reminderKey(old, 10)],
  });
  assert.equal(dueReminders([moved], TODAY, NOW).length, 1);
});

test('the earlier reminders do not stand in for the next one', () => {
  const endsOn = addDays(TODAY, 1);
  const w = warranty({
    endsOn,
    remindersSent: [reminderKey(endsOn, 30), reminderKey(endsOn, 10)],
  });
  assert.equal(dueReminders([w], TODAY, NOW).length, 1);
});

test('a warranty with reminders off is left alone', () => {
  assert.deepEqual(dueReminders([warranty({ notify: false })], TODAY, NOW), []);
});

test('an empty remindersSent counts as nothing sent', () => {
  assert.equal(
    dueReminders([warranty({ remindersSent: [] })], TODAY, NOW).length,
    1,
  );
});

test('a warranty entered moments ago gets no push yet', () => {
  const fresh = warranty({ createdAt: '2026-11-05T08:30:00Z' });
  assert.deepEqual(dueReminders([fresh], TODAY, NOW), []);
});

test('it does the next day, while the window is still open', () => {
  const entered = warranty({
    endsOn: addDays(TODAY, 10),
    createdAt: '2026-11-05T08:30:00Z',
  });
  const tomorrow = addDays(TODAY, 1);
  const later = new Date('2026-11-06T09:00:00Z');
  assert.equal(dueReminders([entered], tomorrow, later).length, 1);
});

test('a document without createdAt still gets its reminder', () => {
  const w = warranty();
  delete w.createdAt;
  assert.equal(dueReminders([w], TODAY, NOW).length, 1);
});

test('something malformed is left out, not sent', () => {
  for (const bad of [{ endsOn: undefined }, { endsOn: 5 }, { ownerId: '' }]) {
    assert.deepEqual(dueReminders([warranty(bad)], TODAY, NOW), [], `${bad}`);
  }
});

test('the most urgent come first', () => {
  const due = dueReminders(
    [
      warranty({ id: 'a', endsOn: addDays(TODAY, 30) }),
      warranty({ id: 'b', endsOn: addDays(TODAY, 1) }),
      warranty({ id: 'c', endsOn: addDays(TODAY, 10) }),
    ],
    TODAY,
    NOW,
  );
  assert.deepEqual(
    due.map((d) => d.warranty.id),
    ['b', 'c', 'a'],
  );
});

test('one account cannot use up a run', () => {
  const due = [1, 2, 3, 4, 5, 6, 7]
    .map((n) => ({ warranty: warranty({ id: `w${n}` }) }))
    .concat([{ warranty: warranty({ id: 'other', ownerId: 'u2' }) }]);
  const kept = capPerOwner(due, 5);
  assert.equal(kept.length, 6);
  assert.equal(kept.at(-1).warranty.ownerId, 'u2');
});

const reminder = (id, ownerId) => ({ warranty: warranty({ id, ownerId }) });
const tokens = (uid, count) =>
  Array.from({ length: count }, (_, i) => ({ id: `${uid}-${i}`, uid }));

test('a reminder goes to every phone of its owner', () => {
  const [planned] = planSends([reminder('a', 'u1')], tokens('u1', 2), 20, 5);
  assert.deepEqual(planned.phones, ['u1-0', 'u1-1']);
});

test('an owner without phones is skipped, without using the budget', () => {
  const plan = planSends(
    [reminder('a', 'nobody'), reminder('b', 'u1')],
    tokens('u1', 1),
    1,
    5,
  );
  assert.deepEqual(
    plan.map((p) => p.warranty.id),
    ['b'],
  );
});

test('a reminder that does not fit waits whole, not half sent', () => {
  const plan = planSends(
    [reminder('a', 'u1'), reminder('b', 'u2')],
    [...tokens('u1', 2), ...tokens('u2', 2)],
    3,
    5,
  );
  assert.deepEqual(
    plan.map((p) => p.warranty.id),
    ['a'],
  );
});

test('an account cannot fan out through endless phones', () => {
  const [planned] = planSends([reminder('a', 'u1')], tokens('u1', 50), 20, 5);
  assert.equal(planned.phones.length, 5);
});

const planned = (id, phones) => ({
  warranty: { id },
  key: `${id}:10`,
  phones,
});

test('a reminder is marked once any phone has it', () => {
  const { sent } = outcome(
    [planned('a', ['p1', 'p2'])],
    [['sent', 'failed']],
  );
  assert.deepEqual(sent, [{ id: 'a', key: 'a:10' }]);
});

test('a reminder is left unmarked when no phone has it', () => {
  const { sent } = outcome([planned('a', ['p1'])], [['failed']]);
  assert.deepEqual(sent, []);
});

test('a dead token shared by reminders is deleted once', () => {
  // batchWrite takes one write per document, and refuses the lot otherwise.
  const { stale } = outcome(
    [planned('a', ['dead', 'p']), planned('b', ['dead', 'p'])],
    [
      ['unregistered', 'sent'],
      ['unregistered', 'sent'],
    ],
  );
  assert.deepEqual(stale, ['dead']);
});

test('a failed send does not cost a phone its token', () => {
  const { stale } = outcome([planned('a', ['p'])], [['failed']]);
  assert.deepEqual(stale, []);
});
