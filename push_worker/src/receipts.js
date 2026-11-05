// Deletes the photo of a warranty its owner is deleting. Deleting takes the API
// secret, which cannot ship in an APK, so the app asks this worker.
//
// Anyone can open an account, so a valid sign-in proves little. The photo comes off
// the warranty, never from the request, and the warranty must be the caller's.

import { createRemoteJWKSet, jwtVerify } from 'jose';

import { Cloudinary } from './cloudinary.js';
import { connect } from './google.js';

const FIREBASE_KEYS = createRemoteJWKSet(
  new URL(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  ),
);

/** The uid of a valid Firebase ID token in [request], or null. */
async function callerOf(request, env) {
  const header = request.headers.get('Authorization') ?? '';
  if (!header.startsWith('Bearer ')) return null;
  const project = env.FIREBASE_PROJECT_ID;
  try {
    const { payload } = await jwtVerify(header.slice(7), FIREBASE_KEYS, {
      issuer: `https://securetoken.google.com/${project}`,
      audience: project,
      algorithms: ['RS256'],
      requiredClaims: ['exp', 'sub'],
    });
    return payload.sub;
  } catch {
    return null;
  }
}

/** The warranty id in [request], or null when it could not be one. */
async function warrantyIdOf(request) {
  const body = await request.json().catch(() => null);
  const id = body?.warrantyId;
  return typeof id === 'string' && /^[A-Za-z0-9]{1,128}$/.test(id) ? id : null;
}

/**
 * Answers with the HTTP status to send. 204 also when there was nothing to do: the
 * app goes on to delete the warranty either way.
 */
export async function releaseReceipt(request, env) {
  const uid = await callerOf(request, env);
  if (!uid) return 401;
  const id = await warrantyIdOf(request);
  if (!id) return 400;
  const cloudinary = new Cloudinary(env);
  if (!cloudinary.configured) return 503;

  const google = await connect(env);
  const warranty = await google.get(`warranties/${id}`);
  if (!warranty) return 404;
  if (warranty.ownerId !== uid) return 403;
  const receiptId = warranty.receiptId;
  if (typeof receiptId !== 'string' || receiptId === '') return 204;

  // Nothing stops someone from putting another person's photo link on a warranty of
  // their own, and then deleting it. So a photo somebody else names stays.
  if (await google.receiptUsedElsewhere(receiptId, id)) return 204;

  const result = await cloudinary.destroy(receiptId, new Date());
  return result === 'failed' ? 502 : 204;
}
