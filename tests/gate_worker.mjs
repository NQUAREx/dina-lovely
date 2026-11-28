import assert from 'node:assert/strict';
import worker from '../cloudflare/reply/worker.mjs';

const gameOrigin = 'https://nquarex.github.io';
const token = '12345:test_secret';
const chat = '67890';
const fixtureIp = '192.0.2.10';
const userAgent = 'Mozilla/5.0 (Android 12; unique-device-marker) AppleWebKit/537.36';
const hits = [];
const sent = [];
let limited = '';
const limit = name => ({
  async limit({ key }) {
    hits.push([name, key]);
    return { success: name !== limited };
  },
});
const env = {
  GAME_ORIGIN: gameOrigin,
  TELEGRAM_BOT_TOKEN: token,
  TELEGRAM_CHAT_ID: chat,
  GATE_PER_CLIENT: limit('gate-client'),
  GATE_TOTAL: limit('gate-total'),
  REPLY_PER_CLIENT: limit('reply-client'),
  REPLY_TOTAL: limit('reply-total'),
};
const post = (path, body, origin = gameOrigin) => worker.fetch(new Request(`https://relay.test${path}`, {
  method: 'POST',
  headers: {
    Origin: origin, 'Content-Type': 'application/x-www-form-urlencoded',
    'CF-Connecting-IP': fixtureIp, 'User-Agent': userAgent,
  },
  body: typeof body === 'string' ? body : new URLSearchParams(body),
}), env);

const oldFetch = globalThis.fetch;
globalThis.fetch = async (url, init) => {
  assert.equal(url, `https://api.telegram.org/bot${token}/sendMessage`);
  assert.equal(init.method, 'POST');
  assert.equal(init.redirect, 'manual');
  sent.push(JSON.parse(init.body));
  return Response.json({ ok: true });
};

try {
  const event = { room: '5', device: '0123456789ab', mode: 'full' };
  const success = await post('/gate', event);
  assert.equal(success.status, 200);
  assert.equal(success.headers.get('Access-Control-Allow-Origin'), gameOrigin);
  assert.deepEqual(await success.json(), { ok: true });
  assert.deepEqual(hits, [['gate-client', fixtureIp], ['gate-total', 'gate']]);
  assert.equal(sent[0].chat_id, chat);
  assert.match(sent[0].text, /комнаты 6 «Заброшенный сад»/);
  assert.match(sent[0].text, /Android · ID 0123456789ab/);
  assert.doesNotMatch(JSON.stringify(sent[0]), /unique-device-marker|192\.0\.2\.10|test_secret/);

  for (const invalid of [
    { ...event, room: '6' },
    { ...event, device: 'ABCDEF123456' },
    { ...event, mode: 'other' },
    { ...event, chat_id: 'alternate-chat' },
    'room=0&room=5&device=unknown',
    'room=0&device=unknown&mode=' + 'x'.repeat(200),
  ]) assert.equal((await post('/gate', invalid)).status, 400);
  const otherOrigin = await post('/gate', event, 'https://different.test');
  assert.equal(otherOrigin.status, 403);
  assert.equal(otherOrigin.headers.get('Access-Control-Allow-Origin'), null);
  limited = 'gate-client';
  assert.equal((await post('/gate', event)).status, 429);
  limited = 'gate-total';
  assert.equal((await post('/gate', event)).status, 429);
  assert.equal(sent.length, 1);

  hits.length = 0;
  assert.equal((await post('/send', { text: '  existing reply  ' })).status, 200);
  assert.deepEqual(hits, [['reply-client', fixtureIp], ['reply-total', 'reply']]);
  assert.deepEqual(sent[1], { chat_id: chat, text: 'existing reply' });
  console.log('PASS gate notification routing, validation, privacy fields, rate limits and reply compatibility');
} finally {
  globalThis.fetch = oldFetch;
}
