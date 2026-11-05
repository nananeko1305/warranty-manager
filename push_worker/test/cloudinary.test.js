import assert from 'node:assert/strict';
import { afterEach, beforeEach, test } from 'node:test';

import { Cloudinary, CursorRejected, signature } from '../src/cloudinary.js';

const realFetch = globalThis.fetch;
const client = () =>
  new Cloudinary({
    CLOUDINARY_CLOUD: 'cloud',
    CLOUDINARY_API_KEY: 'key',
    CLOUDINARY_API_SECRET: 'secret',
  });

let errors;
beforeEach(() => {
  errors = [];
  console.error = (message) => errors.push(message);
});
afterEach(() => {
  globalThis.fetch = realFetch;
});

const answer = (status, body) => {
  const calls = [];
  globalThis.fetch = async (url, init = {}) => {
    calls.push({ url: new URL(url), init });
    return new Response(JSON.stringify(body), { status });
  };
  return calls;
};

test('signs the way Cloudinary documents it', async () => {
  // The example from Cloudinary's docs on generating signatures.
  assert.equal(
    await signature(
      { eager: 'w_400,h_300,c_pad|w_260,h_200,c_crop', public_id: 'sample_image', timestamp: '1315060510' },
      'abcd',
    ),
    'bfd09f95f331f558cbd1320e67aa8d488770583e',
  );
});

test('signs the parameters in order, whatever order they come in', async () => {
  assert.equal(
    await signature({ b: '2', a: '1' }, 's'),
    await signature({ a: '1', b: '2' }, 's'),
  );
});

test('the list asks for what the checks need, from the receipts folder', async () => {
  const calls = answer(200, { resources: [], next_cursor: 'n' });
  const page = await client().list('c', 30);
  const { searchParams, pathname } = calls[0].url;
  assert.equal(pathname, '/v1_1/cloud/resources/by_asset_folder');
  assert.equal(searchParams.get('asset_folder'), 'receipts');
  assert.equal(searchParams.get('max_results'), '30');
  assert.equal(searchParams.get('next_cursor'), 'c');
  for (const field of ['public_id', 'created_at', 'asset_folder', 'resource_type', 'type']) {
    assert.ok(searchParams.get('fields').split(',').includes(field), field);
  }
  assert.equal(page.nextCursor, 'n');
});

test('the first page sends no cursor', async () => {
  const calls = answer(200, { resources: [] });
  const page = await client().list('', 30);
  assert.equal(calls[0].url.searchParams.has('next_cursor'), false);
  assert.equal(page.nextCursor, '');
});

test('a malformed list reads as empty, which deletes nothing', async () => {
  answer(200, { resources: 'nope' });
  assert.deepEqual((await client().list('', 30)).resources, []);
});

test('a refused cursor is told apart from other failures', async () => {
  answer(400, {});
  await assert.rejects(() => client().list('stale', 30), CursorRejected);
  await assert.rejects(
    () => client().list('', 30),
    (error) => !(error instanceof CursorRejected),
  );
});

test('destroy also clears the copy on the CDN, and carries a signature', async () => {
  const calls = answer(200, { result: 'ok' });
  const result = await client().destroy('abc', new Date(1000000));
  assert.equal(result, 'ok');
  const body = calls[0].init.body;
  assert.equal(calls[0].url.pathname, '/v1_1/cloud/image/destroy');
  assert.equal(body.get('invalidate'), 'true');
  assert.equal(body.get('public_id'), 'abc');
  assert.equal(body.get('timestamp'), '1000');
  assert.equal(body.get('api_key'), 'key');
  assert.match(body.get('signature'), /^[0-9a-f]{40}$/);
  assert.equal(body.has('api_secret'), false);
});

test('a photo already gone is fine', async () => {
  answer(200, { result: 'not found' });
  assert.equal(await client().destroy('abc', new Date()), 'not found');
});

test('a failed destroy does not throw, and logs no secret', async () => {
  answer(500, {});
  assert.equal(await client().destroy('abc', new Date()), 'failed');
  assert.doesNotMatch(errors.join(), /secret/);
  globalThis.fetch = async () => {
    throw new TypeError('network');
  };
  assert.equal(await client().destroy('abc', new Date()), 'failed');
});

test('an answer that is not ok counts as failed', async () => {
  answer(200, { result: 'error' });
  assert.equal(await client().destroy('abc', new Date()), 'failed');
});

test('it knows when it is not configured', () => {
  assert.equal(new Cloudinary({}).configured, false);
  assert.equal(client().configured, true);
});
