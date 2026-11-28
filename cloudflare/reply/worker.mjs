const MAX_BODY = 32 * 1024;
const MAX_TEXT = 3500;
const MAX_GATE_BODY = 128;
const GATE_ROOMS = [
  'Лабиринт',
  'Тёмный коридор',
  'Движущиеся балки',
  'Под травой',
  'Боевая комната',
  'Заброшенный сад',
];

async function readForm(request, maximumBytes) {
  if (!request.body) return null;
  const reader = request.body.getReader();
  const decoder = new TextDecoder();
  let size = 0;
  let body = '';
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.byteLength;
    if (size > maximumBytes) {
      await reader.cancel();
      return null;
    }
    body += decoder.decode(value, { stream: true });
  }
  return new URLSearchParams(body + decoder.decode());
}

function replyText(form) {
  const text = form.get('text')?.trim();
  return text && text.length <= MAX_TEXT && [...form.keys()].length === 1 ? text : null;
}

function deviceType(userAgent) {
  if (/iPad/i.test(userAgent) || /Macintosh.*Mobile\//i.test(userAgent)) return 'iPad';
  if (/iPhone/i.test(userAgent)) return 'iPhone';
  if (/iPod/i.test(userAgent)) return 'iPod';
  if (/Android/i.test(userAgent)) return 'Android';
  if (/Windows/i.test(userAgent)) return 'Windows';
  if (/Macintosh/i.test(userAgent)) return 'macOS';
  if (/CrOS/i.test(userAgent)) return 'ChromeOS';
  if (/Linux/i.test(userAgent)) return 'Linux';
  return 'Не определено';
}

function gateText(form, userAgent) {
  const room = form.get('room');
  const device = form.get('device');
  const mode = form.get('mode');
  if (form.size !== 3 || room === null || !/^[0-5]$/.test(room)
      || device === null || !/^(?:[a-f0-9]{12}|unknown)$/.test(device)
      || (mode !== 'demo' && mode !== 'full')) return null;

  return [
    `Открыты ворота комнаты ${Number(room) + 1} «${GATE_ROOMS[Number(room)]}»`,
    `Устройство: ${deviceType(userAgent)} · ID ${device === 'unknown' ? 'не определён' : device}`,
    `Версия: ${mode === 'demo' ? 'демо' : 'полная'}`,
  ].join('\n');
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get('Origin');
    const headers = { 'Cache-Control': 'no-store', 'Vary': 'Origin' };
    if (origin === env.GAME_ORIGIN) headers['Access-Control-Allow-Origin'] = origin;
    const reply = (status) => Response.json({ ok: status === 200 }, { status, headers });

    const path = new URL(request.url).pathname;
    if (path !== '/send' && path !== '/gate') return reply(404);
    const isGate = path === '/gate';
    if (!origin || origin !== env.GAME_ORIGIN) return reply(403);
    if (request.method === 'OPTIONS') {
      headers['Access-Control-Allow-Methods'] = 'POST';
      headers['Access-Control-Allow-Headers'] = 'Content-Type';
      return new Response(null, { status: 204, headers });
    }
    if (request.method !== 'POST') return reply(405);
    if (request.headers.get('Content-Type')?.split(';')[0] !== 'application/x-www-form-urlencoded') return reply(415);
    if (!env.TELEGRAM_BOT_TOKEN || !env.TELEGRAM_CHAT_ID) return reply(503);

    let stage = 'client_limit';
    try {
      const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
      const perClientLimit = isGate ? env.GATE_PER_CLIENT : env.REPLY_PER_CLIENT;
      if (!(await perClientLimit.limit({ key: ip })).success) return reply(429);
      stage = 'request_body';
      const form = await readForm(request, isGate ? MAX_GATE_BODY : MAX_BODY);
      if (!form) return reply(400);
      const text = isGate ? gateText(form, request.headers.get('User-Agent') || '') : replyText(form);
      if (!text) return reply(400);
      stage = 'total_limit';
      const totalLimit = isGate ? env.GATE_TOTAL : env.REPLY_TOTAL;
      if (!(await totalLimit.limit({ key: isGate ? 'gate' : 'reply' })).success) return reply(429);
      stage = 'telegram_request';
      if (!/^\d+:[A-Za-z0-9_-]+$/.test(env.TELEGRAM_BOT_TOKEN)) {
        console.warn('Telegram bot secret has invalid format');
        return reply(503);
      }
      const result = await fetch(`https://api.telegram.org/bot${env.TELEGRAM_BOT_TOKEN}/sendMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chat_id: env.TELEGRAM_CHAT_ID, text }),
        signal: AbortSignal.timeout(12000),
        redirect: 'manual',
      });
      if (!result.ok) {
        console.warn('Telegram delivery rejected', { status: result.status });
        return reply(502);
      }
      if ((await result.json()).ok !== true) return reply(502);
      return reply(200);
    } catch (error) {
      console.warn('Telegram delivery failed', { stage, kind: error?.name });
      return reply(502);
    }
  },
};
