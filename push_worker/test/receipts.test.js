import assert from 'node:assert/strict';
import { afterEach, beforeEach, test } from 'node:test';

import { exportJWK, exportPKCS8, generateKeyPair, SignJWT } from 'jose';

import worker from '../src/index.js';

const PROJECT = 'test-project';
const DOCUMENTS = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;
const JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

const firebaseKeys = await generateKeyPair('RS256', { extractable: true });
const otherKeys = await generateKeyPair('RS256', { extractable: true });
const accountKeys = await generateKeyPair('RS256', { extractable: true });
const publicJwk = {
  ...(await exportJWK(firebaseKeys.publicKey)),
  kid: 'firebase',
  alg: 'RS256',
  use: 'sig',
};

const env = {
  FIREBASE_PROJECT_ID: PROJECT,
  GOOGLE_SERVICE_ACCOUNT: JSON.stringify({
    client_email: 'push-worker@test.iam.gserviceaccount.com',
    private_key: await exportPKCS8(accountKeys.privateKey),
  }),
  CLOUDINARY_CLOUD: 'cloud',
  CLOUDINARY_API_KEY: 'key',
  CLOUDINARY_API_SECRET: 'secret',
};

function idToken(uid, options = {}) {
  const {
    key = firebaseKeys.privateKey,
    audience = PROJECT,
    issuer = `https://securetoken.google.com/${PROJECT}`,
    expires = '1h',
  } = options;
  return new SignJWT({})
    .setProtectedHeader({ alg: 'RS256', kid: 'firebase' })
    .setSubject(uid)
    .setAudience(audience)
    .setIssuer(issuer)
    .setIssuedAt()
    .setExpirationTime(expires)
    .sign(key);
}

// An in-memory Firestore and Cloudinary behind a fake fetch.
const realFetch = globalThis.fetch;
let warranties;
let destroyed;
let destroyResult;
let queryRows;

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), { status });

const toDocument = (id, doc) => ({
  name: `projects/${PROJECT}/databases/(default)/documents/warranties/${id}`,
  fields: Object.fromEntries(
    Object.entries(doc).map(([k, v]) => [k, { stringValue: v }]),
  ),
});

function fakeFetch(input, init = {}) {
  const url = String(input);
  if (url === JWKS_URL) return json({ keys: [publicJwk] });
  if (url === 'https://oauth2.googleapis.com/token') {
    return json({ access_token: 'google-token' });
  }
  if (url === 'https://api.cloudinary.com/v1_1/cloud/image/destroy') {
    destroyed.push(init.body.get('public_id'));
    return json({ result: destroyResult });
  }
  if (url === `${DOCUMENTS}:runQuery`) {
    const { where } = JSON.parse(init.body).structuredQuery;
    const wanted = where.fieldFilter.value.arrayValue.values[0].stringValue;
    if (queryRows) return json(queryRows);
    return json(
      Object.entries(warranties)
        .filter(([, w]) => w.receiptId === wanted)
        .map(([id, w]) => ({ document: toDocument(id, w) })),
    );
  }
  const id = url.slice(`${DOCUMENTS}/warranties/`.length);
  if (url.startsWith(`${DOCUMENTS}/warranties/`)) {
    return warranties[id]
      ? json(toDocument(id, warranties[id]))
      : json({}, 404);
  }
  throw new Error(`Unexpected ${url}`);
}

beforeEach(() => {
  warranties = {
    mine: { ownerId: 'alice', receiptId: 'photo-a' },
    plain: { ownerId: 'alice', receiptId: '' },
    theirs: { ownerId: 'bob', receiptId: 'photo-b' },
  };
  destroyed = [];
  destroyResult = 'ok';
  queryRows = null;
  globalThis.fetch = async (...args) => fakeFetch(...args);
  console.error = () => {};
});
afterEach(() => {
  globalThis.fetch = realFetch;
});

async function call(body, token, environment = env) {
  const headers = token ? { Authorization: `Bearer ${token}` } : {};
  const response = await worker.fetch(
    new Request('https://w/release-receipt', {
      method: 'POST',
      headers,
      body: typeof body === 'string' ? body : JSON.stringify(body),
    }),
    environment,
  );
  return response.status;
}

test('the owner gets the photo of their warranty deleted', async () => {
  assert.equal(await call({ warrantyId: 'mine' }, await idToken('alice')), 204);
  assert.deepEqual(destroyed, ['photo-a']);
});

test("nobody gets someone else's deleted", async () => {
  assert.equal(await call({ warrantyId: 'theirs' }, await idToken('alice')), 403);
  assert.deepEqual(destroyed, []);
});

test('the photo comes off the warranty, whatever the request says', async () => {
  const status = await call(
    { warrantyId: 'mine', receiptId: 'photo-b', public_id: 'photo-b' },
    await idToken('alice'),
  );
  assert.equal(status, 204);
  assert.deepEqual(destroyed, ['photo-a']);
});

test("a warranty naming someone else's photo cannot get it deleted", async () => {
  // The rules let anyone write any Cloudinary link on their own warranty.
  warranties.forged = { ownerId: 'mallory', receiptId: 'photo-b' };
  const status = await call({ warrantyId: 'forged' }, await idToken('mallory'));
  assert.equal(status, 204);
  assert.deepEqual(destroyed, []);
});

test('a warranty without a photo is nothing to do', async () => {
  assert.equal(await call({ warrantyId: 'plain' }, await idToken('alice')), 204);
  assert.deepEqual(destroyed, []);
});

test('a warranty that is gone is told apart', async () => {
  assert.equal(await call({ warrantyId: 'nope' }, await idToken('alice')), 404);
  assert.deepEqual(destroyed, []);
});

test('a photo already gone is fine', async () => {
  destroyResult = 'not found';
  assert.equal(await call({ warrantyId: 'mine' }, await idToken('alice')), 204);
});

test('a delete Cloudinary refuses is reported', async () => {
  destroyResult = 'error';
  assert.equal(await call({ warrantyId: 'mine' }, await idToken('alice')), 502);
});

test('a failed query deletes nothing', async () => {
  queryRows = [{ error: { code: 13 } }];
  assert.equal(await call({ warrantyId: 'mine' }, await idToken('alice')), 500);
  assert.deepEqual(destroyed, []);
});

const refused = {
  'no token': () => null,
  'a token signed by someone else': () =>
    idToken('alice', { key: otherKeys.privateKey }),
  'a token for another project': () =>
    idToken('alice', { audience: 'other-project' }),
  'a token from another issuer': () =>
    idToken('alice', { issuer: 'https://evil.example/' }),
  'an expired token': () => idToken('alice', { expires: '-1h' }),
  'garbage': () => 'not-a-token',
};
for (const [what, make] of Object.entries(refused)) {
  test(`${what} is refused`, async () => {
    assert.equal(await call({ warrantyId: 'mine' }, await make()), 401);
    assert.deepEqual(destroyed, []);
  });
}

const malformed = {
  'no id': {},
  'an id that is not text': { warrantyId: 5 },
  'an id with a path in it': { warrantyId: '../users/alice' },
  'an id far too long': { warrantyId: 'x'.repeat(129) },
  'broken JSON': '{',
};
for (const [what, body] of Object.entries(malformed)) {
  test(`${what} is refused`, async () => {
    assert.equal(await call(body, await idToken('alice')), 400);
    assert.deepEqual(destroyed, []);
  });
}

test('without Cloudinary settings it says so, and deletes nothing', async () => {
  const { CLOUDINARY_API_SECRET, ...rest } = env;
  assert.equal(await call({ warrantyId: 'mine' }, await idToken('alice'), rest), 503);
  assert.deepEqual(destroyed, []);
});
