import {
  candidateDays,
  capPerOwner,
  dueReminders,
  outcome,
  planSends,
} from './due.js';
import { Cloudinary } from './cloudinary.js';
import { connect } from './google.js';
import { dayInBelgrade, reminderMessage } from './message.js';
import { sweep } from './sweep.js';

// Has to match the second trigger in wrangler.toml.
export const SWEEP_CRON = '10 0-6 * * *';

// The free plan allows 50 outside calls per run and 10 ms of CPU. A run takes
// the sign-in, two queries and up to two batch writes, and then one call per
// message. Raise this only after watching the CPU time in the dashboard: the
// runs repeat through the morning, so a low number only delays reminders.
const MAX_MESSAGES = 20;
const MAX_PER_OWNER = 5;
const MAX_PHONES_PER_OWNER = 5;

// A query this full may have left out something due; already-sent warranties
// count towards it too. Rules cannot limit how many warranties an account has.
const QUERY_LIMIT = 300;

/** Records a run, giving it one more try: a lost mark means sending again. */
async function record(google, sent, stale) {
  try {
    await google.record(sent, stale);
  } catch (error) {
    console.error(`${error.message}, trying once more`);
    await google.record(sent, stale);
  }
}

/** Sends the reminders due on the day of [now]. Safe to run repeatedly. */
export async function remind(google, now) {
  const today = dayInBelgrade(now);
  const found = await google.warrantiesEndingOn(
    candidateDays(today),
    QUERY_LIMIT,
  );
  if (found.length === QUERY_LIMIT) {
    console.error(`The query hit its limit of ${QUERY_LIMIT} warranties`);
  }
  const due = capPerOwner(dueReminders(found, today, now), MAX_PER_OWNER).slice(
    0,
    MAX_MESSAGES,
  );
  if (due.length === 0) return;

  const uids = [...new Set(due.map((d) => d.warranty.ownerId))];
  const tokens = await google.tokensOf(uids);
  const plan = planSends(due, tokens, MAX_MESSAGES, MAX_PHONES_PER_OWNER);
  const results = await Promise.all(
    plan.map((reminder) => {
      const message = reminderMessage(reminder.warranty, reminder.daysLeft);
      return Promise.all(
        reminder.phones.map((phone) => google.send(phone, message)),
      );
    }),
  );
  // After sending, not before: a reminder sent twice is better than none.
  const { sent, stale } = outcome(plan, results);
  await record(google, sent, stale);
}

export default {
  // Nothing calls this worker, and it has no address of its own.
  fetch: () => new Response(null, { status: 404 }),

  scheduled(event, env, ctx) {
    const now = new Date(event.scheduledTime);
    const job =
      event.cron === SWEEP_CRON
        ? (google) =>
            sweep(google, new Cloudinary(env), now, {
              deleting: env.SWEEP_DELETE === 'true',
            })
        : (google) => remind(google, now);
    ctx.waitUntil(
      connect(env)
        .then(job)
        .catch((error) => console.error(`The run failed: ${error.message}`)),
    );
  },
};
