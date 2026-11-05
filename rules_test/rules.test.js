import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    // Apart from the worker's emulator tests: files run at once, and each clears
    // its data before every test.
    projectId: 'demo-warranty-manager-rules',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

const as = (uid) => env.authenticatedContext(uid).firestore();
const anonymous = () => env.unauthenticatedContext().firestore();

/** What the app writes when it creates a warranty. */
const fields = (ownerId = 'alice', changes = {}) => ({
  ownerId,
  name: 'Frižider',
  store: 'Tehnomanija',
  note: '',
  purchaseDate: '2026-01-10',
  endsOn: '2028-01-10',
  warrantyAmount: 2,
  warrantyUnit: 'years',
  amountMinor: 150000,
  currency: 'RSD',
  receiptUrl: 'https://res.cloudinary.com/x/image/upload/v1/a.jpg',
  receiptId: 'a',
  notify: true,
  updatedAt: serverTimestamp(),
  createdAt: serverTimestamp(),
  ...changes,
});

/** A warranty already stored, the way the worker may have left it. */
async function seed(id = 'w1', ownerId = 'alice', extra = {}) {
  await env.withSecurityRulesDisabled((context) =>
    setDoc(doc(context.firestore(), 'warranties', id), {
      ...fields(ownerId),
      updatedAt: new Date(),
      createdAt: new Date(),
      ...extra,
    }),
  );
}

const warranty = (db, id = 'w1') => doc(db, 'warranties', id);
const newWarranty = (db) => doc(db, 'warranties', 'new');

describe('reading', () => {
  test('the owner can read a warranty', async () => {
    await seed();
    await assertSucceeds(getDoc(warranty(as('alice'))));
  });

  test('nobody else can', async () => {
    await seed();
    await assertFails(getDoc(warranty(as('mallory'))));
    await assertFails(getDoc(warranty(anonymous())));
  });

  test('the owner can list their own', async () => {
    await seed();
    const db = as('alice');
    await assertSucceeds(
      getDocs(query(collection(db, 'warranties'), where('ownerId', '==', 'alice'))),
    );
  });

  test('nobody can list someone else\'s, or everything', async () => {
    await seed();
    const db = as('mallory');
    await assertFails(
      getDocs(query(collection(db, 'warranties'), where('ownerId', '==', 'alice'))),
    );
    await assertFails(getDocs(collection(db, 'warranties')));
  });
});

describe('creating', () => {
  test('what the app writes is accepted', async () => {
    await assertSucceeds(setDoc(newWarranty(as('alice')), fields()));
  });

  test('without a price too', async () => {
    await assertSucceeds(
      setDoc(
        newWarranty(as('alice')),
        fields('alice', { amountMinor: null, currency: null }),
      ),
    );
  });

  test('an account cannot create one for someone else', async () => {
    await assertFails(setDoc(newWarranty(as('mallory')), fields('alice')));
  });

  test('signing in is required', async () => {
    await assertFails(setDoc(newWarranty(anonymous()), fields('alice')));
  });

  test('the client cannot write what belongs to the worker', async () => {
    await assertFails(
      setDoc(newWarranty(as('alice')), fields('alice', { remindersSent: [] })),
    );
  });

  test('an unknown field is refused', async () => {
    await assertFails(
      setDoc(newWarranty(as('alice')), fields('alice', { role: 'admin' })),
    );
  });

  test('a missing field is refused', async () => {
    const { note, ...rest } = fields();
    await assertFails(setDoc(newWarranty(as('alice')), rest));
  });

  const refused = {
    'an empty name': { name: '' },
    'a name that is too long': { name: 'x'.repeat(121) },
    'a store that is too long': { store: 'x'.repeat(121) },
    'a note that is too long': { note: 'x'.repeat(1001) },
    'a date that is not a date': { purchaseDate: 'yesterday' },
    'a timestamp in place of the text': { endsOn: new Date() },
    'an end before the purchase': { endsOn: '2025-01-01' },
    'an end on the purchase date': { endsOn: '2026-01-10' },
    'an unknown unit': { warrantyUnit: 'weeks' },
    'a warranty of nothing': { warrantyAmount: 0 },
    'too many months': { warrantyUnit: 'months', warrantyAmount: 121 },
    'too many years': { warrantyAmount: 31 },
    'a number that is not whole': { warrantyAmount: 1.5 },
    'a price of nothing': { amountMinor: 0 },
    'a price without a currency': { currency: null },
    'a currency without a price': { amountMinor: null },
    'an unknown currency': { currency: 'USD' },
    'a photo from somewhere else': {
      receiptUrl: 'https://evil.example/image/upload/v1/a.jpg',
    },
    'a lookalike host': {
      receiptUrl: 'https://res.cloudinary.com.evil.example/x/image/upload/v1/a.jpg',
    },
    'a photo address that is too long': {
      receiptUrl: `https://res.cloudinary.com/x/image/upload/v1/${'x'.repeat(500)}.jpg`,
      receiptId: 'x'.repeat(500),
    },
    'an id that is not what the link says': { receiptId: 'someone-elses' },
    'a link without its id': { receiptId: '' },
    'an id without a link': { receiptUrl: '' },
    'an id that is not text': { receiptId: 5 },
    'a link that is not an upload': {
      receiptUrl: 'https://res.cloudinary.com/x/video/upload/v1/a.mp4',
    },
    'reminders that are not a yes or a no': { notify: 'yes' },
    'an invented time of writing': { updatedAt: new Date(0) },
    'an invented time of creation': { createdAt: new Date(0) },
  };
  for (const [what, change] of Object.entries(refused)) {
    test(`${what} is refused`, async () => {
      await assertFails(
        setDoc(newWarranty(as('alice')), fields('alice', change)),
      );
    });
  }

  const accepted = {
    'the longest name': { name: 'x'.repeat(120) },
    'an empty store and note': { store: '', note: '' },
    'no photo': { receiptUrl: '', receiptId: '' },
    'a link without a version': {
      receiptUrl: 'https://res.cloudinary.com/x/image/upload/a.jpg',
      receiptId: 'a',
    },
    'an id with a folder in it': {
      receiptUrl: 'https://res.cloudinary.com/x/image/upload/v1/receipts/a.jpg',
      receiptId: 'receipts/a',
    },
    '18 months': { warrantyUnit: 'months', warrantyAmount: 18 },
    '120 months': { warrantyUnit: 'months', warrantyAmount: 120 },
    '30 years': { warrantyAmount: 30 },
    'euros': { currency: 'EUR' },
    'reminders off': { notify: false },
  };
  for (const [what, change] of Object.entries(accepted)) {
    test(`${what} is accepted`, async () => {
      await assertSucceeds(
        setDoc(newWarranty(as('alice')), fields('alice', change)),
      );
    });
  }
});

describe('changing', () => {
  const edit = (changes = {}) => ({
    name: 'Novo ime',
    updatedAt: serverTimestamp(),
    ...changes,
  });

  test('the owner can edit', async () => {
    await seed();
    await assertSucceeds(updateDoc(warranty(as('alice')), edit()));
  });

  // Regression guard: `request.resource.data` is the whole resulting document,
  // so a keys().hasOnly() here would refuse every edit once a reminder went out.
  test('the owner can still edit after the worker has marked it', async () => {
    await seed('w1', 'alice', { remindersSent: ['2028-01-10:30'] });
    await assertSucceeds(updateDoc(warranty(as('alice')), edit()));
  });

  // What the app writes when the photo did not change.
  test('an edit can leave the photo out altogether', async () => {
    await seed();
    await assertSucceeds(updateDoc(warranty(as('alice')), edit({ note: 'x' })));
  });

  test('replacing the photo needs its new id', async () => {
    await seed();
    const receiptUrl = 'https://res.cloudinary.com/x/image/upload/v2/b.jpg';
    await assertFails(updateDoc(warranty(as('alice')), edit({ receiptUrl })));
    await assertSucceeds(
      updateDoc(warranty(as('alice')), edit({ receiptUrl, receiptId: 'b' })),
    );
  });

  test('removing the photo needs the id gone too', async () => {
    await seed();
    await assertFails(
      updateDoc(warranty(as('alice')), edit({ receiptUrl: '' })),
    );
    await assertSucceeds(
      updateDoc(warranty(as('alice')), edit({ receiptUrl: '', receiptId: '' })),
    );
  });

  test('moving the end date is fine', async () => {
    await seed();
    await assertSucceeds(
      updateDoc(warranty(as('alice')), edit({ endsOn: '2029-01-10' })),
    );
  });

  test('nobody else can', async () => {
    await seed();
    await assertFails(updateDoc(warranty(as('mallory')), edit()));
    await assertFails(updateDoc(warranty(anonymous()), edit()));
  });

  test('a warranty cannot be given away', async () => {
    await seed();
    await assertFails(
      updateDoc(warranty(as('alice')), edit({ ownerId: 'mallory' })),
    );
  });

  test('nor taken over', async () => {
    await seed();
    await assertFails(
      updateDoc(warranty(as('mallory')), edit({ ownerId: 'mallory' })),
    );
  });

  test('the owner cannot touch the marks of the worker', async () => {
    await seed('w1', 'alice', { remindersSent: ['2028-01-10:30'] });
    await assertFails(
      updateDoc(warranty(as('alice')), edit({ remindersSent: [] })),
    );
  });

  test('or the time of creation', async () => {
    await seed();
    await assertFails(
      updateDoc(warranty(as('alice')), edit({ createdAt: new Date(0) })),
    );
  });

  test('an edit has to stay valid', async () => {
    await seed();
    await assertFails(updateDoc(warranty(as('alice')), edit({ name: '' })));
  });

  test('an edit cannot invent its time', async () => {
    await seed();
    await assertFails(
      updateDoc(warranty(as('alice')), edit({ updatedAt: new Date(0) })),
    );
  });
});

describe('deleting', () => {
  test('the owner can delete', async () => {
    await seed();
    await assertSucceeds(deleteDoc(warranty(as('alice'))));
  });

  test('nobody else can', async () => {
    await seed();
    await assertFails(deleteDoc(warranty(as('mallory'))));
    await assertFails(deleteDoc(warranty(anonymous())));
  });
});

describe('push tokens', () => {
  const token = (db, id = 'token1') => doc(db, 'pushTokens', id);

  async function seedToken(uid = 'alice', id = 'token1') {
    await env.withSecurityRulesDisabled((context) =>
      setDoc(doc(context.firestore(), 'pushTokens', id), { uid }),
    );
  }

  test('a phone can register itself to its account', async () => {
    await assertSucceeds(setDoc(token(as('alice')), { uid: 'alice' }));
  });

  test('not to someone else\'s', async () => {
    await assertFails(setDoc(token(as('mallory')), { uid: 'alice' }));
    await assertFails(setDoc(token(anonymous()), { uid: 'alice' }));
  });

  test('nothing but the account goes in it', async () => {
    await assertFails(
      setDoc(token(as('alice')), { uid: 'alice', extra: true }),
    );
  });

  test('a token of absurd length is refused', async () => {
    await assertFails(
      setDoc(token(as('alice'), 'x'.repeat(513)), { uid: 'alice' }),
    );
  });

  test('a phone that changes hands moves to the new account', async () => {
    await seedToken('alice');
    await assertSucceeds(setDoc(token(as('bob')), { uid: 'bob' }));
  });

  test('a single token cannot be read', async () => {
    await seedToken('alice');
    await assertFails(getDoc(token(as('alice'))));
    await assertFails(getDoc(token(as('mallory'))));
  });

  test('an account can list only its own phones', async () => {
    await seedToken('alice');
    const mine = query(
      collection(as('alice'), 'pushTokens'),
      where('uid', '==', 'alice'),
    );
    await assertSucceeds(getDocs(mine));
    const theirs = query(
      collection(as('mallory'), 'pushTokens'),
      where('uid', '==', 'alice'),
    );
    await assertFails(getDocs(theirs));
    await assertFails(getDocs(collection(as('alice'), 'pushTokens')));
  });

  test('an account can delete only its own', async () => {
    await seedToken('alice');
    await assertFails(deleteDoc(token(as('mallory'))));
    await assertSucceeds(deleteDoc(token(as('alice'))));
  });
});

test('everything else is closed', async () => {
  const db = as('alice');
  await assertFails(getDoc(doc(db, 'users', 'alice')));
  await assertFails(setDoc(doc(db, 'users', 'alice'), { role: 'admin' }));
  await assertFails(getDocs(collection(db, 'meta')));
  // Where the worker keeps its place in the sweep.
  await assertFails(setDoc(doc(db, 'meta', 'sweep'), { cursor: 'x' }));
});
