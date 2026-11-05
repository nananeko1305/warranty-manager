// The text and dates of the pushes: no I/O, so they can be tested alone.

const TIME_ZONE = 'Europe/Belgrade';

const DAY_SECONDS = 24 * 60 * 60;

/** The day [date] falls on in Belgrade, as yyyy-MM-dd. */
export function dayInBelgrade(date) {
  const format = new Intl.DateTimeFormat('en-GB', {
    timeZone: TIME_ZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  const parts = Object.fromEntries(
    format.formatToParts(date).map((part) => [part.type, part.value]),
  );
  return `${parts.year}-${parts.month}-${parts.day}`;
}

/** "2026-11-14" as a notification shows it: "14.11.2026." */
export function dateLabel(day) {
  const [year, month, date] = day.split('-').map(Number);
  return `${date}.${month}.${year}.`;
}

// The title is a string resource in the app, so each phone shows it in its own
// language; see android/app/src/main/res/values*/strings.xml. FCM takes the
// arguments as strings only.
function title(daysLeft) {
  if (daysLeft === 0) return { title_loc_key: 'warranty_today_title' };
  if (daysLeft === 1) return { title_loc_key: 'warranty_tomorrow_title' };
  return {
    title_loc_key: 'warranty_days_title',
    title_loc_args: [String(daysLeft)],
  };
}

/**
 * How long FCM keeps trying a phone that is off. FCM's default is four weeks,
 * which would deliver "ends tomorrow" long after it did.
 */
export function timeToLive(daysLeft) {
  const seconds =
    daysLeft === 0 ? DAY_SECONDS / 2 : Math.min(daysLeft, 3) * DAY_SECONDS;
  return `${seconds}s`;
}

/** The push for one warranty. `data` values must all be strings. */
export function reminderMessage({ id, name, endsOn }, daysLeft) {
  return {
    data: {
      type: 'warranty',
      warrantyId: id,
      name,
      endsOn,
      daysLeft: String(daysLeft),
    },
    android: {
      priority: 'high',
      ttl: timeToLive(daysLeft),
      notification: {
        ...title(daysLeft),
        body: `${name} · ${dateLabel(endsOn)}`,
        channel_id: 'warranties',
        // A repeat replaces the earlier notification rather than stacking.
        tag: id,
      },
    },
  };
}
