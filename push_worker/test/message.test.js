import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  dateLabel,
  dayInBelgrade,
  reminderMessage,
  timeToLive,
} from '../src/message.js';

const warranty = {
  id: 'w1',
  name: 'Frižider',
  endsOn: '2026-11-15',
};

test('the day follows Belgrade, not UTC', () => {
  // 23:30 UTC is already the next day in Belgrade, in winter and in summer.
  assert.equal(dayInBelgrade(new Date('2026-01-14T23:30:00Z')), '2026-01-15');
  assert.equal(dayInBelgrade(new Date('2026-07-14T22:30:00Z')), '2026-07-15');
  assert.equal(dayInBelgrade(new Date('2026-07-14T21:30:00Z')), '2026-07-14');
});

test('a date reads the way it does here', () => {
  assert.equal(dateLabel('2026-11-05'), '5.11.2026.');
});

test('the title comes from the app, in the language of the phone', () => {
  const { notification } = reminderMessage(warranty, 10).android;
  assert.equal(notification.title_loc_key, 'warranty_days_title');
  assert.deepEqual(notification.title_loc_args, ['10']);
  assert.equal(notification.channel_id, 'warranties');
});

test('tomorrow and today have titles of their own', () => {
  const key = (days) =>
    reminderMessage(warranty, days).android.notification.title_loc_key;
  assert.equal(key(1), 'warranty_tomorrow_title');
  assert.equal(key(0), 'warranty_today_title');
  assert.equal(
    reminderMessage(warranty, 1).android.notification.title_loc_args,
    undefined,
  );
});

test('the body says what and until when', () => {
  const { body } = reminderMessage(warranty, 10).android.notification;
  assert.equal(body, 'Frižider · 15.11.2026.');
});

test('a repeat replaces the earlier notification', () => {
  assert.equal(reminderMessage(warranty, 10).android.notification.tag, 'w1');
});

test('every data value is a string, or FCM refuses the message', () => {
  for (const value of Object.values(reminderMessage(warranty, 10).data)) {
    assert.equal(typeof value, 'string');
  }
});

test('the app can tell which warranty a tap is about', () => {
  const { data } = reminderMessage(warranty, 10);
  assert.equal(data.type, 'warranty');
  assert.equal(data.warrantyId, 'w1');
  assert.equal(data.daysLeft, '10');
});

test('a message never outlives what it says', () => {
  const day = 24 * 60 * 60;
  assert.equal(timeToLive(0), `${day / 2}s`);
  assert.equal(timeToLive(1), `${day}s`);
  assert.equal(timeToLive(2), `${2 * day}s`);
  assert.equal(timeToLive(30), `${3 * day}s`);
});
