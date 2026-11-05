import assert from 'node:assert/strict';
import { afterEach, beforeEach, test } from 'node:test';

import { Google } from '../src/google.js';

const realFetch = globalThis.fetch;
const google = () => new Google('p', 'token');

let errors;
beforeEach(() => {
  errors = [];
  console.error = (message) => errors.push(message);
});
afterEach(() => {
  globalThis.fetch = realFetch;
});

const answer = (status, body) => {
  globalThis.fetch = async () => new Response(JSON.stringify(body), { status });
};

test('a message FCM accepts counts as sent', async () => {
  answer(200, { name: 'ok' });
  assert.equal(await google().send('t', {}), 'sent');
});

test('a token FCM no longer knows is of no further use', async () => {
  answer(404, {
    error: { status: 'NOT_FOUND', details: [{ errorCode: 'UNREGISTERED' }] },
  });
  assert.equal(await google().send('t', {}), 'unregistered');
});

test('a token FCM calls malformed is of no further use', async () => {
  answer(400, {
    error: {
      status: 'INVALID_ARGUMENT',
      details: [{ fieldViolations: [{ field: 'message.token' }] }],
    },
  });
  assert.equal(await google().send('t', {}), 'unregistered');
});

test('a badly built message does not cost the phone its token', async () => {
  answer(400, {
    error: {
      status: 'INVALID_ARGUMENT',
      details: [{ fieldViolations: [{ field: 'message.android.ttl' }] }],
    },
  });
  assert.equal(await google().send('t', {}), 'failed');
});

test('a failure on the way does not stop the run', async () => {
  globalThis.fetch = async () => {
    throw new TypeError('network');
  };
  assert.equal(await google().send('t', {}), 'failed');
});

test('logs say why, never the token or the warranty', async () => {
  answer(500, { error: { status: 'INTERNAL' } });
  await google().send('secret-token', { data: { name: 'Frižider' } });
  assert.equal(errors.length, 1);
  assert.match(errors[0], /INTERNAL/);
  assert.doesNotMatch(errors[0], /secret-token|Frižider/);
});

const recorded = async (status, sent = [{ id: 'a', key: 'k' }], stale = []) => {
  let body;
  globalThis.fetch = async (_, init) => {
    body = JSON.parse(init.body);
    return new Response(JSON.stringify(status), { status: 200 });
  };
  await google().record(sent, stale);
  return body;
};

test('a mark never brings a deleted warranty back', async () => {
  const body = await recorded({ status: [{ code: 0 }] });
  assert.deepEqual(body.writes[0].currentDocument, { exists: true });
});

test('a warranty deleted during the run is not an error', async () => {
  await recorded({ status: [{ code: 5 }, { code: 9 }, {}] });
  assert.deepEqual(errors, []);
});

test('any other failed write is logged, even though the call succeeded', async () => {
  await recorded({ status: [{ code: 7 }, {}] });
  assert.match(errors[0], /1 of 1 writes failed/);
});

test('a token goes in the path encoded', async () => {
  const body = await recorded({ status: [] }, [], ['a:b/c']);
  assert.match(body.writes[0].delete, /pushTokens\/a%3Ab%2Fc$/);
});

test('with nothing to record there is no call at all', async () => {
  globalThis.fetch = async () => {
    throw new Error('no call expected');
  };
  await google().record([], []);
});

test('a failed call throws, so the run can try again', async () => {
  answer(503, {});
  await assert.rejects(() => google().record([{ id: 'a', key: 'k' }], []));
});

const rows = (...receiptIds) =>
  receiptIds.map((receiptId, i) => ({
    document: {
      name: `projects/p/databases/(default)/documents/warranties/w${i}`,
      fields: { receiptId: { stringValue: receiptId } },
    },
  }));

test('photos in use come back as a set', async () => {
  answer(200, rows('a'));
  const used = await google().receiptsInUse(['a', 'b'], 100);
  assert.deepEqual([...used], ['a']);
});

test('no ids, no query', async () => {
  globalThis.fetch = async () => {
    throw new Error('no call expected');
  };
  assert.equal((await google().receiptsInUse([], 100)).size, 0);
});

// Thousands of warranties can name one junk photo and crowd out someone's row, so
// a full result cannot be trusted to have left nothing out.
test('a full result keeps every photo that was asked about', async () => {
  answer(200, rows('a', 'a'));
  const used = await google().receiptsInUse(['a', 'victim'], 2);
  assert.deepEqual([...used].sort(), ['a', 'victim']);
});

test('an unexpected warranty stops everything', async () => {
  answer(200, rows('not-asked-for'));
  await assert.rejects(() => google().receiptsInUse(['a'], 100));
});

test('a warranty without the id stops everything', async () => {
  answer(200, [
    {
      document: {
        name: 'projects/p/databases/(default)/documents/warranties/w',
        fields: {},
      },
    },
  ]);
  await assert.rejects(() => google().receiptsInUse(['a'], 100));
});

// An error row inside a 200 must not read as "nobody uses this photo".
test('an error inside a good answer stops everything', async () => {
  answer(200, [{ error: { code: 13, message: 'internal' } }]);
  await assert.rejects(() => google().receiptsInUse(['a'], 100));
  await assert.rejects(() => google().anyReceipt());
});

test('the sweep starts from the beginning without a saved place', async () => {
  answer(404, {});
  assert.equal(await google().sweepCursor(), '');
});

test('a failed read of the place stops the run', async () => {
  answer(500, {});
  await assert.rejects(() => google().sweepCursor());
});
