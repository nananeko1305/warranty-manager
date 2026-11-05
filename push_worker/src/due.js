// Which warranties are due a reminder, and who gets one: no I/O, so it can be
// tested alone. Days are 'yyyy-MM-dd' text, the way the app stores `endsOn`.

/** Reminders go out this many days before the warranty ends. */
const THRESHOLDS = [30, 10, 1];

/**
 * A reminder still goes out this many days late, so that an outage does not
 * swallow it. The app counts the last day of a warranty as covered, so the day
 * reminder has one day of this, not two.
 */
const CATCH_UP_DAYS = 2;

/**
 * Nothing goes out for a warranty entered this recently: a push minutes after
 * typing it in tells nobody anything. It gets its next reminder as usual.
 */
const SETTLE_MS = 12 * 60 * 60 * 1000;

const DAY_MS = 24 * 60 * 60 * 1000;

/** Midday in UTC never lands on another date, whatever the clocks do. */
function toUtc(day) {
  const [year, month, date] = day.split('-').map(Number);
  return Date.UTC(year, month - 1, date, 12);
}

/** The day [count] days after [day]. */
export function addDays(day, count) {
  return new Date(toUtc(day) + count * DAY_MS).toISOString().slice(0, 10);
}

/** Whole days from [from] to [to]. */
export function daysBetween(from, to) {
  return Math.round((toUtc(to) - toUtc(from)) / DAY_MS);
}

/** The reminder [daysLeft] falls under, or null when it falls under none. */
export function thresholdFor(daysLeft) {
  if (daysLeft < 0) return null;
  const found = THRESHOLDS.find(
    (t) => daysLeft <= t && daysLeft >= t - CATCH_UP_DAYS,
  );
  return found ?? null;
}

/** Every `endsOn` that can be due on [today]; Firestore takes at most 30. */
export function candidateDays(today) {
  const days = new Set();
  for (const threshold of THRESHOLDS) {
    for (let late = 0; late <= CATCH_UP_DAYS; late++) {
      const left = threshold - late;
      if (left >= 0) days.add(addDays(today, left));
    }
  }
  return [...days].sort();
}

/**
 * The end date is part of the key, so moving it arms the reminders again
 * without anything having to reset them.
 */
export function reminderKey(endsOn, threshold) {
  return `${endsOn}:${threshold}`;
}

/**
 * The reminders due on [today], fewest days left first, each with its [key] and
 * [daysLeft]. Anything malformed is left out rather than sent.
 */
export function dueReminders(warranties, today, now) {
  const due = [];
  for (const warranty of warranties) {
    const { endsOn, ownerId, notify, remindersSent, createdAt } = warranty;
    if (notify !== true || typeof endsOn !== 'string' || !ownerId) continue;
    const daysLeft = daysBetween(today, endsOn);
    const threshold = thresholdFor(daysLeft);
    if (threshold === null) continue;
    const key = reminderKey(endsOn, threshold);
    if (Array.isArray(remindersSent) && remindersSent.includes(key)) continue;
    const created = Date.parse(createdAt);
    if (Number.isFinite(created) && now.getTime() - created < SETTLE_MS) {
      continue;
    }
    due.push({ warranty, daysLeft, key });
  }
  return due.sort((a, b) => a.daysLeft - b.daysLeft);
}

/**
 * At most [perOwner] reminders per account, so one account with a thousand
 * warranties cannot use up every run. The rest wait for the next run.
 */
export function capPerOwner(due, perOwner) {
  const counts = new Map();
  return due.filter(({ warranty: { ownerId } }) => {
    const count = counts.get(ownerId) ?? 0;
    counts.set(ownerId, count + 1);
    return count < perOwner;
  });
}

/**
 * Pairs each reminder with the owner's phones, within [budget] messages. A
 * reminder goes to all its phones or waits for the next run, so that marking it
 * as sent means the same for every phone. One without phones is left out: it
 * stays unmarked, and gets another chance while its window is open.
 */
export function planSends(due, tokens, budget, phonesPerOwner) {
  const phones = new Map();
  for (const token of tokens) {
    const list = phones.get(token.uid) ?? [];
    if (list.length < phonesPerOwner) list.push(token.id);
    phones.set(token.uid, list);
  }
  const plan = [];
  let used = 0;
  for (const reminder of due) {
    const mine = phones.get(reminder.warranty.ownerId) ?? [];
    if (mine.length === 0) continue;
    if (used + mine.length > budget) break;
    used += mine.length;
    plan.push({ ...reminder, phones: mine });
  }
  return plan;
}

/** What a run has to record, given what happened to each message. */
export function outcome(plan, results) {
  const sent = [];
  const stale = new Set();
  plan.forEach((reminder, i) => {
    // Marked once any phone has it. Not when none has: the next run tries again.
    if (results[i].some((r) => r === 'sent')) {
      sent.push({ id: reminder.warranty.id, key: reminder.key });
    }
    results[i].forEach((r, j) => {
      if (r === 'unregistered') stale.add(reminder.phones[j]);
    });
  });
  return { sent, stale: [...stale] };
}
