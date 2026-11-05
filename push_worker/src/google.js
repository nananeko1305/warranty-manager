import { importPKCS8, SignJWT } from 'jose';

const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const SCOPES = [
  'https://www.googleapis.com/auth/datastore',
  'https://www.googleapis.com/auth/firebase.messaging',
].join(' ');

const FIRESTORE_URL = 'https://firestore.googleapis.com/v1';

// Firestore answers these for a write whose document is gone, which is fine: it
// was deleted while the run was sending.
const GONE_CODES = new Set([5, 9]);

function serviceAccount(env) {
  try {
    return JSON.parse(env.GOOGLE_SERVICE_ACCOUNT);
  } catch {
    // Not the parser's message: it quotes the text it could not read.
    throw new Error('GOOGLE_SERVICE_ACCOUNT is not valid JSON');
  }
}

/** Signs in as the service account and returns a client for its token. */
export async function connect(env) {
  const account = serviceAccount(env);
  const key = await importPKCS8(account.private_key, 'RS256');
  const now = Math.floor(Date.now() / 1000);
  const assertion = await new SignJWT({ scope: SCOPES })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(account.client_email)
    .setAudience(TOKEN_URL)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);
  const response = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!response.ok) {
    throw new Error(`Google sign-in failed with ${response.status}`);
  }
  const { access_token: token } = await response.json();
  return new Google(env.FIREBASE_PROJECT_ID, token);
}

function decodeValue(value) {
  if ('arrayValue' in value) {
    // Firestore leaves `values` out of an empty array.
    return (value.arrayValue.values ?? []).map(decodeValue);
  }
  return (
    value.stringValue ?? value.booleanValue ?? value.timestampValue ?? null
  );
}

/** A Firestore document as plain values, with its id. */
function decode(document) {
  const fields = {};
  for (const [name, value] of Object.entries(document.fields ?? {})) {
    fields[name] = decodeValue(value);
  }
  return { ...fields, id: document.name.split('/').pop() };
}

const fieldsOf = (...names) => names.map((fieldPath) => ({ fieldPath }));

const stringsIn = (fieldPath, values) => ({
  fieldFilter: {
    field: { fieldPath },
    op: 'IN',
    value: {
      arrayValue: { values: values.map((stringValue) => ({ stringValue })) },
    },
  },
});

/** Whether a refused message is about the token rather than the message. */
function refusesToken(body) {
  return (body.error?.details ?? []).some(
    (detail) =>
      detail.errorCode === 'UNREGISTERED' ||
      (detail.fieldViolations ?? []).some((v) => v.field === 'message.token'),
  );
}

export class Google {
  /** [firestoreUrl] is only for pointing tests at the emulator. */
  constructor(project, token, firestoreUrl = FIRESTORE_URL) {
    this.root = `projects/${project}/databases/(default)/documents`;
    this.documents = `${firestoreUrl}/${this.root}`;
    this.messages = `https://fcm.googleapis.com/v1/projects/${project}/messages:send`;
    this.headers = {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    };
  }

  async #query(structuredQuery) {
    const response = await fetch(`${this.documents}:runQuery`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({ structuredQuery }),
    });
    if (!response.ok) {
      throw new Error(`Firestore query failed with ${response.status}`);
    }
    const rows = await response.json();
    return rows.filter((row) => row.document).map((row) => decode(row.document));
  }

  /** Warranties ending on any of [days], with only what a reminder needs. */
  warrantiesEndingOn(days, limit) {
    return this.#query({
      from: [{ collectionId: 'warranties' }],
      select: {
        fields: fieldsOf(
          'ownerId',
          'name',
          'endsOn',
          'notify',
          'remindersSent',
          'createdAt',
        ),
      },
      where: stringsIn('endsOn', days),
      limit,
    });
  }

  /** The phones of [uids], at most 30 of them, which is what `in` takes. */
  tokensOf(uids) {
    return this.#query({
      from: [{ collectionId: 'pushTokens' }],
      where: stringsIn('uid', uids),
    });
  }

  /**
   * Records a run in one call: the reminders in [sent] went out, and the tokens
   * in [stale] are dead. Throws when the call itself fails, and logs a write
   * that failed for any reason but its document being gone.
   *
   * Through :batchWrite, not :commit, so a warranty deleted meanwhile does not
   * cost the rest their marks. It takes one write per document, so [stale] must
   * not repeat a token, and it can apply nothing at all and still answer 200.
   */
  async record(sent, stale) {
    const writes = [
      ...sent.map(({ id, key }) => ({
        transform: {
          document: `${this.root}/warranties/${id}`,
          fieldTransforms: [
            {
              fieldPath: 'remindersSent',
              appendMissingElements: { values: [{ stringValue: key }] },
            },
          ],
        },
        // Without this the transform would create the deleted document again.
        currentDocument: { exists: true },
      })),
      ...stale.map((token) => ({
        delete: `${this.root}/pushTokens/${encodeURIComponent(token)}`,
      })),
    ];
    if (writes.length === 0) return;
    const response = await fetch(`${this.documents}:batchWrite`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({ writes }),
    });
    if (!response.ok) {
      throw new Error(`Firestore batch write failed with ${response.status}`);
    }
    const { status = [] } = await response.json();
    const failed = status.filter(
      (s) => (s.code ?? 0) !== 0 && !GONE_CODES.has(s.code),
    );
    if (failed.length > 0) {
      console.error(`${failed.length} of ${writes.length} writes failed`);
    }
  }

  /**
   * Sends [message] to one phone: 'sent', 'unregistered' when that token is of
   * no further use, or 'failed'. Never throws: one phone's failure must not stop
   * the others.
   */
  async send(token, message) {
    try {
      const response = await fetch(this.messages, {
        method: 'POST',
        headers: this.headers,
        body: JSON.stringify({ message: { token, ...message } }),
      });
      if (response.ok) return 'sent';
      const body = await response.json().catch(() => ({}));
      // Only when the error names the token: a badly built message also comes
      // back as INVALID_ARGUMENT, and must not cost anyone their phone.
      if (refusesToken(body)) return 'unregistered';
      // Only Google's reason: never the token or what the warranty is.
      console.error(
        `FCM refused a push with ${response.status}: ${body.error?.status}`,
      );
      return 'failed';
    } catch (error) {
      console.error(`Sending a push failed: ${error.name}`);
      return 'failed';
    }
  }
}
