// The Cloudinary calls of the sweep. The API secret stays in this worker: it
// cannot ship in the APK, which is why the app cannot delete photos itself.

const API = 'https://api.cloudinary.com/v1_1';

/** The folder the upload preset puts receipts in. */
export const RECEIPTS_FOLDER = 'receipts';

async function sha1Hex(text) {
  const digest = await crypto.subtle.digest(
    'SHA-1',
    new TextEncoder().encode(text),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

/** Cloudinary's signature: the parameters in order, then the secret. */
export function signature(params, secret) {
  const joined = Object.keys(params)
    .sort()
    .map((name) => `${name}=${params[name]}`)
    .join('&');
  return sha1Hex(joined + secret);
}

/** Thrown for a cursor Cloudinary no longer accepts. */
export class CursorRejected extends Error {}

export class Cloudinary {
  constructor(env) {
    this.cloud = env.CLOUDINARY_CLOUD;
    this.key = env.CLOUDINARY_API_KEY;
    this.secret = env.CLOUDINARY_API_SECRET;
  }

  get configured() {
    return Boolean(this.cloud && this.key && this.secret);
  }

  /** One page of the folder, oldest first: { resources, nextCursor }. */
  async list(cursor, maxResults) {
    const url = new URL(`${API}/${this.cloud}/resources/by_asset_folder`);
    url.searchParams.set('asset_folder', RECEIPTS_FOLDER);
    url.searchParams.set('max_results', String(maxResults));
    url.searchParams.set('direction', 'asc');
    url.searchParams.set(
      'fields',
      'public_id,created_at,asset_folder,resource_type,type',
    );
    if (cursor) url.searchParams.set('next_cursor', cursor);
    const response = await fetch(url, {
      headers: {
        Authorization: `Basic ${btoa(`${this.key}:${this.secret}`)}`,
      },
    });
    if (response.status === 400 && cursor) throw new CursorRejected();
    if (!response.ok) {
      throw new Error(`Cloudinary list failed with ${response.status}`);
    }
    const body = await response.json();
    return {
      resources: Array.isArray(body.resources) ? body.resources : [],
      nextCursor: body.next_cursor ?? '',
    };
  }

  /**
   * Deletes one photo, and its copy on the CDN: 'ok', 'not found' or 'failed'.
   * Through destroy rather than the bulk call, whose invalidate takes a support
   * request. Never throws: one file must not stop the others.
   */
  async destroy(publicId, now) {
    const params = {
      invalidate: 'true',
      public_id: publicId,
      timestamp: String(Math.floor(now.getTime() / 1000)),
    };
    try {
      const body = new URLSearchParams({
        ...params,
        api_key: this.key,
        signature: await signature(params, this.secret),
      });
      const response = await fetch(`${API}/${this.cloud}/image/destroy`, {
        method: 'POST',
        body,
      });
      if (!response.ok) {
        console.error(`Cloudinary destroy failed with ${response.status}`);
        return 'failed';
      }
      const { result } = await response.json();
      return result === 'ok' || result === 'not found' ? result : 'failed';
    } catch (error) {
      console.error(`Cloudinary destroy failed: ${error.name}`);
      return 'failed';
    }
  }
}
